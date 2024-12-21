import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pie_chart/pie_chart.dart';

import 'data/dv_values.dart';
import 'data/nutrient_balance_analyzer.dart';

class Logic {
  String _generatedText = "";
  File? _selectedFile;
  List<Map<String, dynamic>> parsedNutrients = [];
  List<Map<String, dynamic>> goodNutrients = [];
  List<Map<String, dynamic>> badNutrients = [];
  double _servingSize = 0.0;
  double sliderValue = 0.0;
  Map<String, double> dailyIntake = {};
  bool _isLoading = false;
  static final navKey = GlobalKey<NavigatorState>();
  Function(void Function())? _mySetState;
  NutrientBalanceAnalyzer _nutrientAnalyzer = NutrientBalanceAnalyzer();
  DietaryPreference get currentDietaryPreference =>
      _nutrientAnalyzer.dietaryPreference;
  BalanceRecommendation? _currentRecommendation;
  double _currentCarbs = 0.0;
  double _currentSugar = 0.0;
  double _currentFiber = 0.0;
  double _currentProtein = 0.0;

  String _getStorageKey() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return 'dailyIntake_${today.toIso8601String()}';
  }

  Future<void> loadDailyIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = _getStorageKey();
    dailyIntake = (prefs.getString(storageKey) != null)
        ? (jsonDecode(prefs.getString(storageKey)!) as Map)
            .cast<String, double>()
        : {};
  }

  Future<void> saveDailyIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = _getStorageKey();
    await prefs.setString(storageKey, jsonEncode(dailyIntake));
  }

  Future<String> fetchGeneratedText(
      {required File? selectedFile,
      required Function(void Function()) setState}) async {
    _isLoading = true;
    setState(() {});
    print("_fetchGeneratedText() is called");
    // Access your API key (assuming you have a way to access it)
    final apiKey = kIsWeb
        ? const String.fromEnvironment('GEMINI_API_KEY')
        : dotenv.env['GEMINI_API_KEY'];

    // Initialize the GenerativeModel
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey!);
    final imageBytes = await selectedFile!.readAsBytes();
    print("model selection is a success");
    final imageParts = [
      DataPart('image/jpeg', imageBytes),
    ];

    final prompt = TextPart(
        """Analyze the label, considering the attached daily value recommendations data.  Provide your response in a strictly valid JSON format with this structure:
{
  "serving_size": "Serving size with unit or 'NA' if not found",
  "nutrients": [
    {"name": "Nutrient Name", "status": "High" or "Low" or "Moderate", "quantity": "Quantity", "health_sign": "Good" or "Bad" or "Moderate"}
  ]
}

Strictly follow the rules below for generating the response:
1. Mention Quantity with units in the label
2. Do not include any extra characters or formatting outside of the JSON object. 
3. Use accurate escape sequences for any special characters. 
4. Avoid including other such nutrients from the attached daily value recommendations data that aren't mentioned in the label.
5. Use %DV to determine if a serving of the food is high or low in an individual nutrient. As a general guide:
  5% DV or less of a nutrient per serving is considered low.
  20% DV or more of a nutrient per serving is considered high.
  5% < DV < 20% of a nutrient per serving is considered moderate
6. Use the following rule to determine the health_sign of the nutrient:
    If the goal is "At least", then:
    if status is "High", then health_sign should be "Good",
    if status is "Moderate", then health_sign should be "Moderate",
    if status is "Low", then health_sign should be "Bad",
    If the goal is "Less than", then:
    if status is "Low", then health_sign should be "Good",
    if status is "Moderate", then health_sign should be "Moderate",
    if status is "High", then health_sign should be "Bad"
    If the goal is "Equal to", then:
    if status is "Low", then health_sign should be "Bad",
    if status is "Moderate", then health_sign should be "Good",
    if status is "High", then health_sign should be "Moderate"
 """);

    final nutrientParts = nutrientData
        .map((nutrient) => TextPart(
            "${nutrient['Nutrient']}: ${nutrient['Current Daily Value']} (${nutrient['Goal']})"))
        .toList();

    final response = await model.generateContent([
      Content.multi([prompt, ...nutrientParts, ...imageParts])
    ]);
    _generatedText = response.text!;

    try {
      final jsonString = _generatedText.substring(
          _generatedText.indexOf('{'), _generatedText.lastIndexOf('}') + 1);
      final jsonResponse = jsonDecode(jsonString);
      if (jsonResponse.containsKey("serving_size") &&
          jsonResponse["serving_size"] != null) {
        _servingSize = jsonResponse["serving_size"] == "NA"
            ? 0.0
            : double.parse(jsonResponse["serving_size"]
                .replaceAll(RegExp(r'[^0-9\.]'), ''));
      } else {
        _servingSize = 0.0;
      }
      parsedNutrients =
          (jsonResponse['nutrients'] as List).cast<Map<String, dynamic>>();
      //clear the good/bad nutrients before adding to avoid duplicates
      goodNutrients.clear();
      badNutrients.clear();
      for (var nutrient in parsedNutrients) {
        if (nutrient["name"] == "Carbohydrate") {
          // Don't categorize carbs directly into good/bad
          // Instead, look at the quality indicators
          double carbQuality = _assessCarbQuality(
              carbs: double.tryParse(nutrient['quantity']
                      .replaceAll(RegExp(r'[^0-9\.]'), '')) ??
                  0.0,
              fiber: _currentFiber,
              sugar: _currentSugar,
              protein: _currentProtein);

          if (carbQuality >= 0.7) {
            // Good balance
            goodNutrients.add(
                {...nutrient, "health_sign": "Good", "status": "Balanced"});
          } else if (carbQuality <= 0.3) {
            // Poor balance
            badNutrients.add(
                {...nutrient, "health_sign": "Bad", "status": "Unbalanced"});
          } else {
            goodNutrients.add(
                {...nutrient, "health_sign": "Moderate", "status": "Moderate"});
          }
          continue; // Skip the default categorization for carbs
        }
        if (nutrient["health_sign"] == "Good" ||
            nutrient["health_sign"] == "Moderate") {
          goodNutrients.add(nutrient);
        } else {
          badNutrients.add(nutrient);
        }
        final quantity = double.tryParse(
                nutrient['quantity'].replaceAll(RegExp(r'[^0-9\.]'), '')) ??
            0.0;

        switch (nutrient['name']) {
          case 'Carbohydrate':
            _currentCarbs = quantity;
            break;
          case 'Sugar':
            _currentSugar = quantity;
            break;
          case 'Fiber':
            _currentFiber = quantity;
            break;
          case 'Protein':
            _currentProtein = quantity;
            break;
        }
      }

      // Add nutrient balance analysis
      double carbs = 0.0, sugar = 0.0, fiber = 0.0, protein = 0.0;
      double sodium = 0.0;

      for (var nutrient in parsedNutrients) {
        final quantity = double.tryParse(
                nutrient['quantity'].replaceAll(RegExp(r'[^0-9\.]'), '')) ??
            0.0;
        if (nutrient['name'] == 'Sodium') {
          sodium = double.tryParse(
                  nutrient['quantity'].replaceAll(RegExp(r'[^0-9\.]'), '')) ??
              0.0;
        }

        switch (nutrient['name']) {
          case 'Carbohydrate':
            carbs = quantity;
            break;
          case 'Sugar':
            sugar = quantity;
            break;
          case 'Fiber':
            fiber = quantity;
            break;
          case 'Protein':
            protein = quantity;
            break;
          case 'Sodium':
            sodium = quantity;
            break;
        }
      }

      _currentRecommendation = _nutrientAnalyzer.analyzeAndRecommend(
        carbs: carbs,
        sugar: sugar,
        fiber: fiber,
        protein: protein,
        servingSize: _servingSize,
        sodium: sodium,
      );
    } catch (e) {
      print("Error parsing JSON: $e");
      // Handle the error gracefully, maybe display a message to the user
    }
    print(parsedNutrients);
    _generatedText = response.text!;
    print("This is response content: ${response.text}");
    print("This is updated generatedText: $_generatedText");
    // Return the generated text
    _isLoading = false;
    setState(() {});
    return _generatedText;
  }

  void addToDailyIntake(BuildContext context, Function(int) updateIndex) {
    if (parsedNutrients.isEmpty) return;
    for (var nutrient in parsedNutrients) {
      final name = nutrient['name'];
      final quantity = double.tryParse(
              nutrient['quantity'].replaceAll(RegExp(r'[^0-9\.]'), '')) ??
          0;
      double adjustedQuantity = quantity * (sliderValue / _servingSize);

      if (dailyIntake.containsKey(name)) {
        dailyIntake[name] = dailyIntake[name]! + adjustedQuantity;
      } else {
        dailyIntake[name] = adjustedQuantity;
      }
    }
    saveDailyIntake();
  }

  double getServingSize() => _servingSize;
  List<Map<String, dynamic>> getGoodNutrients() => goodNutrients;
  List<Map<String, dynamic>> getBadNutrients() => badNutrients;

  bool getIsLoading() => _isLoading;

  void setSetState(Function(void Function()) setState) {
    _mySetState = setState;
  }

  void updateSliderValue(double newValue, Function(void Function()) setState) {
    sliderValue = newValue;
    setState(() {});
  }

  static GlobalKey<NavigatorState> getNavKey() => navKey;

  Map<String, double> getPieChartData(Map<String, double> dailyIntake) {
    Map<String, double> chartData = {};
    for (var nutrient in nutrientData) {
      String nutrientName = nutrient['Nutrient'].trim();
      if (dailyIntake.containsKey(nutrientName)) {
        try {
          double dvValue = double.parse(nutrient['Current Daily Value']
              .replaceAll(RegExp(r'[^0-9\.]'), ''));
          double percent = (dailyIntake[nutrientName]! / dvValue) * 100;
          if (percent > 0.0) {
            // Cap at 100% for visualization purposes
            chartData[nutrientName] = percent > 100.0 ? 100.0 : percent;
          }
        } catch (e) {
          print("Error in parsing to double in pie chart builder: $e");
        }
      }
    }
    return chartData;
  }

  String? getInsights(Map<String, double> dailyIntake) {
    for (var nutrient in nutrientData) {
      String nutrientName = nutrient['Nutrient'];
      if (dailyIntake.containsKey(nutrientName)) {
        try {
          double dvValue = double.parse(nutrient['Current Daily Value']
              .replaceAll(RegExp(r'[^0-9\.]'), ''));
          double percent = dailyIntake[nutrientName]! / dvValue;
          if (percent > 1.0) {
            return "You have exceeded the recommended daily intake of $nutrientName";
          }
        } catch (e) {
          print("Error parsing to double: $e");
        }
      }
    }
    return null;
  }

  void updateServingSize(double newSize) {
    _servingSize = newSize;
    // Reset slider value when serving size changes
    sliderValue = 0.0;
    if (_mySetState != null) {
      _mySetState!(() {});
    }
  }

  double getCalories() {
    var energyNutrient = parsedNutrients.firstWhere(
      (nutrient) => nutrient['name'] == 'Energy',
      orElse: () => {'quantity': '0.0'},
    );
    // Parse the quantity string to remove any non-numeric characters except decimal points
    var quantity = energyNutrient['quantity']
        .toString()
        .replaceAll(RegExp(r'[^0-9\.]'), '');
    return double.tryParse(quantity) ?? 0.0;
  }

  BalanceRecommendation? get currentRecommendation => _currentRecommendation;

  void updateDietaryPreference(DietaryPreference preference) {
    _nutrientAnalyzer = NutrientBalanceAnalyzer(dietaryPreference: preference);
    if (_currentRecommendation != null) {
      _currentRecommendation = _nutrientAnalyzer.analyzeAndRecommend(
        carbs: _currentCarbs,
        sugar: _currentSugar,
        fiber: _currentFiber,
        protein: _currentProtein,
        servingSize: _servingSize,
      );
      if (_mySetState != null) {
        _mySetState!(() {});
      }
    }
  }

  double _assessCarbQuality({
    required double carbs,
    required double fiber,
    required double sugar,
    required double protein,
  }) {
    if (carbs == 0) return 0.5; // Neutral if no carbs

    double score = 0.0;

    // Fiber to carb ratio (higher is better)
    double fiberRatio = fiber / carbs;
    score += (fiberRatio >= 0.1)
        ? 0.4
        : (fiberRatio * 4); // 10% or more fiber is ideal

    // Sugar to carb ratio (lower is better)
    double sugarRatio = sugar / carbs;
    score += (sugarRatio <= 0.2)
        ? 0.4
        : (0.4 - (sugarRatio * 0.5)); // Less than 20% sugar is ideal

    // Protein balance (presence of protein helps with glycemic response)
    score +=
        (protein >= 5) ? 0.2 : (protein / 25); // 5g or more protein is ideal

    return score.clamp(0.0, 1.0); // Normalize between 0 and 1
  }
}
