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

  String _getStorageKey() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return 'dailyIntake_${today.toIso8601String()}';
  }


  Future<void> loadDailyIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = _getStorageKey();
    dailyIntake = (prefs.getString(storageKey) != null)
        ? (jsonDecode(prefs.getString(storageKey)!) as Map).cast<String, double>()
        : {};
  }

  Future<void> saveDailyIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = _getStorageKey();
    await prefs.setString(storageKey, jsonEncode(dailyIntake));
  }


  Future<String> fetchGeneratedText({required File? selectedFile, required Function(void Function()) setState}) async {
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
      if (jsonResponse.containsKey("serving_size") && jsonResponse["serving_size"] != null) {
        _servingSize = jsonResponse["serving_size"] == "NA"? 0.0 : double.parse(jsonResponse["serving_size"].replaceAll(RegExp(r'[^0-9\.]'), ''));
      }
      else {
        _servingSize = 0.0;
      }
      parsedNutrients =
          (jsonResponse['nutrients'] as List).cast<Map<String, dynamic>>();
      //clear the good/bad nutrients before adding to avoid duplicates
      goodNutrients.clear();
      badNutrients.clear();
      for(var nutrient in parsedNutrients)
      {
        if(nutrient["health_sign"] == "Good" || nutrient["health_sign"] == "Moderate"){
          goodNutrients.add(nutrient);
        } else {
          badNutrients.add(nutrient);
        }
      }
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
    if(parsedNutrients.isEmpty) return;
    for (var nutrient in parsedNutrients){
      final name = nutrient['name'];
      final quantity = double.tryParse(nutrient['quantity'].replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 0;
      double adjustedQuantity = quantity * (sliderValue / _servingSize) ;

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

  void setSetState (Function(void Function()) setState){
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
      if(dailyIntake.containsKey(nutrientName)){
        try {
          double dvValue = double.parse(nutrient['Current Daily Value'].replaceAll(RegExp(r'[^0-9\.]'), ''));
          double percent = dailyIntake[nutrientName]! / dvValue;
          if(percent > 0.0) {
            chartData[nutrientName] = percent > 1.0 ? 1.0 : percent;
          }
        }
        catch (e){
          print("Error in parsing to double in pie chart builder: $e");
        }
      }
    }
    return chartData;
  }

  String? getInsights(Map<String, double> dailyIntake)
  {
    for (var nutrient in nutrientData){
      String nutrientName = nutrient['Nutrient'];
      if(dailyIntake.containsKey(nutrientName)) {
        try {
          double dvValue = double.parse(nutrient['Current Daily Value'].replaceAll(RegExp(r'[^0-9\.]'), ''));
          double percent = dailyIntake[nutrientName]! / dvValue;
          if(percent > 1.0){
            return "You have exceeded the recommended daily intake of $nutrientName";
          }
        }
        catch (e) {
          print("Error parsing to double: $e");
        }

      }
    }
    return null;
  }
}