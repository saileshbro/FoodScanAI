import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:read_the_label/models/food_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/dv_values.dart';

class Logic {
  String _generatedText = "";
  File? _frontImage;
  File? _nutritionLabelImage;
  File? get frontImage => _frontImage;
  File? get nutritionLabelImage => _nutritionLabelImage;
  List<Map<String, dynamic>> parsedNutrients = [];
  List<Map<String, dynamic>> goodNutrients = [];
  List<Map<String, dynamic>> badNutrients = [];
  File? foodImage;
  List<FoodItem> analyzedFoodItems = [];
  Map<String, dynamic> totalPlateNutrients = {};
  double _servingSize = 0.0;
  double sliderValue = 0.0;
  Map<String, double> dailyIntake = {};
  bool _isLoading = false;
  static final navKey = GlobalKey<NavigatorState>();
  Function(void Function())? _mySetState;
  String _productName = "";
  String get productName => _productName;
  Map<String, dynamic> _nutritionAnalysis = {};
  Map<String, dynamic> get nutritionAnalysis => _nutritionAnalysis;

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

  void addToDailyIntake(BuildContext context, Function(int) updateIndex) {
    if (parsedNutrients.isNotEmpty) {
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
    } else if (totalPlateNutrients.isNotEmpty) {
      // Add Energy/Calories
      if (totalPlateNutrients['calories'] != null) {
        dailyIntake['Energy'] =
            (dailyIntake['Energy'] ?? 0.0) + totalPlateNutrients['calories'];
      }

      // Add other nutrients
      final nutrientMappings = {
        'protein': 'Protein',
        'carbohydrates': 'Carbohydrate',
        'fat': 'Total Fat',
        'fiber': 'Dietary Fiber'
      };

      nutrientMappings.forEach((key, formalName) {
        if (totalPlateNutrients[key] != null) {
          dailyIntake[formalName] =
              (dailyIntake[formalName] ?? 0.0) + totalPlateNutrients[key];
        }
      });
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

  Future<String> analyzeImages(
      {required Function(void Function()) setState}) async {
    _isLoading = true;
    setState(() {});

    final apiKey = kIsWeb
        ? const String.fromEnvironment('GEMINI_API_KEY')
        : dotenv.env['GEMINI_API_KEY'];

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey!);

    final frontImageBytes = await _frontImage!.readAsBytes();
    final labelImageBytes = await _nutritionLabelImage!.readAsBytes();

    final imageParts = [
      DataPart('image/jpeg', frontImageBytes),
      DataPart('image/jpeg', labelImageBytes),
    ];

    final nutrientParts = nutrientData
        .map((nutrient) => TextPart(
            "${nutrient['Nutrient']}: ${nutrient['Current Daily Value']}"))
        .toList();
    final prompt = TextPart(
        """Analyze the food product, product name and its nutrition label. Provide response in this strict JSON format:
{
  "product": {
    "name": "Product name from front image",
    "category": "Food category (e.g., snack, beverage, etc.)"
  },
  "nutrition_analysis": {
    "serving_size": "Serving size with unit",
    "nutrients": [
      {
        "name": "Nutrient name",
        "quantity": "Quantity with unit",
        "daily_value": "Percentage of daily value",
        "status": "High/Moderate/Low based on DV%",
        "health_impact": "Good/Bad/Moderate"
      }
    ],
    "primary_concerns": [
      {
        "issue": "Primary nutritional concern",
        "explanation": "Brief explanation of health impact",
        "recommendations": [
          {
            "food": "Complementary food suitable to add to this product, consider product name for determining suitability for complementary food additions",
            "quantity": "Recommended quantity to add",
            "reasoning": "How this addition helps balance the nutrition (e.g., slows sugar absorption, adds fiber, reduces glycemic index)"
          }
        ]
      }
    ]
  }
}

Strictly follow these rules:
1. Mention Quantity with units in the label
2. Do not include any extra characters or formatting outside of the JSON object
3. Use accurate escape sequences for any special characters
4. Avoid including nutrients that aren't mentioned in the label
5. For primary_concerns, focus on major nutritional imbalances
6. For recommendations:
   - Suggest foods that can be added to or consumed with the product to improve its nutritional balance
   - Focus on practical additions that complement the main product
   - Explain how each addition helps balance the nutrition (e.g., adding fiber to slow sugar absorption)
   - Consider cultural context and common food pairings
   - Provide specific quantities for the recommended additions
7. Use %DV to determine if a serving is high or low in an individual nutrient:
   5% DV or less is considered low
   20% DV or more is considered high
   5% < DV < 20% is considered moderate
8. For health_impact determination:
   For "At least" nutrients (like fiber, protein):
     High status → Good health_impact
     Moderate status → Moderate health_impact
     Low status → Bad health_impact
   For "Less than" nutrients (like sodium, saturated fat):
     Low status → Good health_impact
     Moderate status → Moderate health_impact
     High status → Bad health_impact
""");

    final response = await model.generateContent([
      Content.multi([prompt, ...nutrientParts, ...imageParts])
    ]);

    _generatedText = response.text!;
    print("This is response content: $_generatedText");
    try {
      final jsonString = _generatedText.substring(
          _generatedText.indexOf('{'), _generatedText.lastIndexOf('}') + 1);
      final jsonResponse = jsonDecode(jsonString);

      _productName = jsonResponse['product']['name'];
      _nutritionAnalysis = jsonResponse['nutrition_analysis'];

      if (_nutritionAnalysis.containsKey("serving_size")) {
        _servingSize = double.tryParse(_nutritionAnalysis["serving_size"]
                .replaceAll(RegExp(r'[^0-9\.]'), '')) ??
            0.0;
      }

      parsedNutrients = (_nutritionAnalysis['nutrients'] as List)
          .cast<Map<String, dynamic>>();

      // Clear and update good/bad nutrients
      goodNutrients.clear();
      badNutrients.clear();
      for (var nutrient in parsedNutrients) {
        if (nutrient["health_impact"] == "Good" ||
            nutrient["health_impact"] == "Moderate") {
          goodNutrients.add(nutrient);
        } else {
          badNutrients.add(nutrient);
        }
      }
    } catch (e) {
      print("Error parsing JSON: $e");
    }

    _isLoading = false;
    setState(() {});
    return _generatedText;
  }

  Future<String> analyzeFoodImage({
    required File imageFile,
    required Function(void Function()) setState,
  }) async {
    _isLoading = true;
    setState(() {});

    final apiKey = kIsWeb
        ? const String.fromEnvironment('GEMINI_API_KEY')
        : dotenv.env['GEMINI_API_KEY'];

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey!);

    final imageBytes = await imageFile.readAsBytes();

    final prompt = TextPart(
        """Analyze this food image and break down each visible food item. 
Provide response in this strict JSON format:
{
  "plate_analysis": {
    "items": [
      {
        "food_name": "Name of the food item",
        "estimated_quantity": {
          "amount": 0,
          "unit": "g",
        },
        "nutrients_per_100g": {
          "calories": 0,
          "protein": {"value": 0, "unit": "g"},
          "carbohydrates": {"value": 0, "unit": "g"},
          "fat": {"value": 0, "unit": "g"},
          "fiber": {"value": 0, "unit": "g"}
        },
        "total_nutrients": {
          "calories": 0,
          "protein": {"value": 0, "unit": "g"},
          "carbohydrates": {"value": 0, "unit": "g"},
          "fat": {"value": 0, "unit": "g"},
          "fiber": {"value": 0, "unit": "g"}
        },
        "visual_cues": ["List of visual indicators used for estimation"],
        "position": "Description of item location in the image"
      }
    ],
    "total_plate_nutrients": {
      "calories": 0,
      "protein": {"value": 0, "unit": "g"},
      "carbohydrates": {"value": 0, "unit": "g"},
      "fat": {"value": 0, "unit": "g"},
      "fiber": {"value": 0, "unit": "g"}
    }
  }
}

Consider:
1. Use visual cues to estimate portions (size relative to plate, height of food, etc.)
2. Provide nutrients both per 100g and for estimated total quantity
3. Consider common serving sizes and preparation methods
""");

    try {
      final response = await model.generateContent([
        Content.multi([prompt, DataPart('image/jpeg', imageBytes)])
      ]);

      if (response.text != null) {
        try {
          // Extract JSON from response
          final jsonString = response.text!.substring(
            response.text!.indexOf('{'),
            response.text!.lastIndexOf('}') + 1,
          );
          final jsonResponse = jsonDecode(jsonString);
          final plateAnalysis = jsonResponse['plate_analysis'];

          // Clear previous analysis
          analyzedFoodItems.clear();

          // Process each food item
          if (plateAnalysis['items'] != null) {
            for (var item in plateAnalysis['items']) {
              analyzedFoodItems.add(FoodItem(
                name: item['food_name'],
                quantity: item['estimated_quantity']['amount'].toDouble(),
                unit: item['estimated_quantity']['unit'],
                nutrientsPer100g: {
                  'calories': item['nutrients_per_100g']['calories'],
                  'protein': item['nutrients_per_100g']['protein']['value'],
                  'carbohydrates': item['nutrients_per_100g']['carbohydrates']
                      ['value'],
                  'fat': item['nutrients_per_100g']['fat']['value'],
                  'fiber': item['nutrients_per_100g']['fiber']['value'],
                },
              ));
            }
          }

          // Store total nutrients
          totalPlateNutrients = {
            'calories': plateAnalysis['total_plate_nutrients']['calories'],
            'protein': plateAnalysis['total_plate_nutrients']['protein']
                ['value'],
            'carbohydrates': plateAnalysis['total_plate_nutrients']
                ['carbohydrates']['value'],
            'fat': plateAnalysis['total_plate_nutrients']['fat']['value'],
            'fiber': plateAnalysis['total_plate_nutrients']['fiber']['value'],
          };

          setState(() {
            _isLoading = false;
          });

          return response.text!;
        } catch (e) {
          print("Error parsing JSON response: $e");
          setState(() {
            _isLoading = false;
          });
          return "Error parsing response";
        }
      }
      setState(() {
        _isLoading = false;
      });
      return "No response received";
    } catch (e) {
      print("Error analyzing food image: $e");
      setState(() {
        _isLoading = false;
      });
      return "Error analyzing image";
    }
  }

  Future<void> captureImage({
    required ImageSource source,
    required bool isFrontImage,
    required Function(void Function()) setState,
  }) async {
    final imagePicker = ImagePicker();
    final image = await imagePicker.pickImage(source: source);

    if (image != null) {
      if (isFrontImage) {
        _frontImage = File(image.path);
      } else {
        _nutritionLabelImage = File(image.path);
      }
      setState(() {});
    }
  }

  bool canAnalyze() => _frontImage != null && _nutritionLabelImage != null;

  void updateTotalNutrients() {
    totalPlateNutrients = {
      'calories': 0.0,
      'protein': 0.0,
      'carbohydrates': 0.0,
      'fat': 0.0,
      'fiber': 0.0,
    };

    for (var item in analyzedFoodItems) {
      var itemNutrients = item.calculateTotalNutrients();
      totalPlateNutrients['calories'] =
          (totalPlateNutrients['calories'] ?? 0.0) +
              (itemNutrients['calories'] ?? 0.0);
      totalPlateNutrients['protein'] = (totalPlateNutrients['protein'] ?? 0.0) +
          (itemNutrients['protein'] ?? 0.0);
      totalPlateNutrients['carbohydrates'] =
          (totalPlateNutrients['carbohydrates'] ?? 0.0) +
              (itemNutrients['carbohydrates'] ?? 0.0);
      totalPlateNutrients['fat'] =
          (totalPlateNutrients['fat'] ?? 0.0) + (itemNutrients['fat'] ?? 0.0);
      totalPlateNutrients['fiber'] = (totalPlateNutrients['fiber'] ?? 0.0) +
          (itemNutrients['fiber'] ?? 0.0);
    }
  }
}
