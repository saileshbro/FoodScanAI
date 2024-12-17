import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:read_the_label/widgets/nutrient_tile.dart';
import 'package:read_the_label/data/nutrient_insights.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:read_the_label/daily_intake_page.dart';

import 'data/dv_values.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _generatedText = "";
  File? _selectedFile;

  final ImagePicker imagePicker = ImagePicker();
  List<Map<String, dynamic>> parsedNutrients = [];
  List<Map<String, dynamic>> goodNutrients = [];
  List<Map<String, dynamic>> badNutrients = [];
  final int _tilesPerRow = 2;
  double _servingSize = 0.0;
  double _sliderValue = 0.0;
  Map<String, double> _dailyIntake = {};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDailyIntake();
  }

  _pickImage(ImageSource imageSource) async {
    final file = await imagePicker.pickImage(source: imageSource);
    _selectedFile = File(file!.path);
    setState(() {});
  }

  Future<void> _loadDailyIntake() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyIntake = (prefs.getString('dailyIntake') != null)
          ? (jsonDecode(prefs.getString('dailyIntake')!) as Map)
              .cast<String, double>()
          : {};
    });
  }

  Future<void> _saveDailyIntake() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dailyIntake', jsonEncode(_dailyIntake));
  }

  bool _isLoading = false;
  Future<String> _fetchGeneratedText() async {
    _isLoading = true;
    print("_fetchGeneratedText() is called");
    // Access your API key (assuming you have a way to access it)
    final apiKey = kIsWeb
        ? const String.fromEnvironment('GEMINI_API_KEY')
        : dotenv.env['GEMINI_API_KEY'];

    // Initialize the GenerativeModel
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey!);
    final imageBytes = await _selectedFile!.readAsBytes();
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
        if (nutrient["health_sign"] == "Good" ||
            nutrient["health_sign"] == "Moderate") {
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
    return response.text!;
  }

  void _addToDailyIntake(BuildContext context) {
    if (parsedNutrients.isEmpty) return;

    for (var nutrient in parsedNutrients) {
      final name = nutrient['name'];
      final quantity = double.tryParse(
              nutrient['quantity'].replaceAll(RegExp(r'[^0-9\.]'), '')) ??
          0;
      double adjustedQuantity = quantity * (_sliderValue / _servingSize);

      if (_dailyIntake.containsKey(name)) {
        _dailyIntake[name] = _dailyIntake[name]! + adjustedQuantity;
      } else {
        _dailyIntake[name] = adjustedQuantity;
      }
    }
    _saveDailyIntake();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to today\'s intake!'),
        action: SnackBarAction(
          label: 'SHOW',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DailyIntakePage(
                        dailyIntake: _dailyIntake,
                      )),
            );
          },
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    double tileWidth = MediaQuery.of(context).size.width / _tilesPerRow;
    return Scaffold(
      backgroundColor: Colors.black45,
      // extendBody: true,
      // extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black45,
        forceMaterialTransparency: true,
        title: const Text(
          "ReadTheLabel",
          style: TextStyle(color: Colors.white),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white10,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });

            if (_currentIndex == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DailyIntakePage(
                          dailyIntake: _dailyIntake,
                        )),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.food_bank), label: 'Daily Intake'),
          ]),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.black)),
                  onPressed: () {
                    _pickImage(ImageSource.gallery);
                  },
                  child: const Text("Scan from gallery"),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.black)),
                  onPressed: () {
                    _pickImage(ImageSource.camera);
                  },
                  child: const Text("Scan label"),
                ),
              ],
            ),
            if (_selectedFile != null) Image(image: FileImage(_selectedFile!)),
            ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.white10)),
                onPressed: () {
                  _fetchGeneratedText();
                },
                child: const Text("Analyze")),
            if (_isLoading) const CircularProgressIndicator(),

            //Good/Moderate nutrients
            if (goodNutrients.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20.0, top: 10.0),
                    child: Text("Good/Moderate Nutrients",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                  Wrap(
                    spacing: 8.0, // Spacing between the tiles
                    runSpacing: 8.0, //Spacing between the rows
                    children: goodNutrients
                        .map((nutrient) => NutrientTile(
                              nutrient: nutrient['name'],
                              healthSign: nutrient['health_sign'],
                              quantity: nutrient['quantity'],
                            ))
                        .toList(),
                  ),
                ],
              ),

            //Bad nutrients
            if (badNutrients.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20.0, top: 10.0),
                    child: Text("Bad Nutrients",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                  Wrap(
                    spacing: 8.0, // Spacing between the tiles
                    runSpacing: 8.0, //Spacing between the rows
                    children: badNutrients
                        .map((nutrient) => NutrientTile(
                              nutrient: nutrient['name'],
                              healthSign: nutrient['health_sign'],
                              quantity: nutrient['quantity'],
                              insight: nutrientInsights[nutrient['name']],
                            ))
                        .toList(),
                  ),
                ],
              ),
            if (_servingSize > 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Slider(
                        value: _sliderValue,
                        min: 0,
                        max: _servingSize,
                        onChanged: (newValue) {
                          setState(() {
                            _sliderValue = newValue;
                          });
                        }),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Serving Size: ${_sliderValue.toStringAsFixed(2)} g",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all(Colors.white10)),
                        onPressed: () {
                          _addToDailyIntake(context);
                        },
                        child: const Text("Add to today's intake")),
                  ],
                ),
              ),
            if (_servingSize == 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Serving size not found, please enter it manually',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _servingSize = double.tryParse(value) ?? 0.0;
                        });
                      },
                      decoration: const InputDecoration(
                          hintText: "Enter serving size in grams or ml",
                          hintStyle: TextStyle(color: Colors.white54)),
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (_servingSize > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Slider(
                            value: _sliderValue,
                            min: 0,
                            max: _servingSize,
                            onChanged: (newValue) {
                              setState(() {
                                _sliderValue = newValue;
                              });
                            }),
                      ),
                    if (_servingSize > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Serving Size: ${_sliderValue.toStringAsFixed(2)} g",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    if (_servingSize > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ElevatedButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.all(Colors.white10)),
                            onPressed: () {
                              _addToDailyIntake(context);
                            },
                            child: const Text("Add to today's intake")),
                      )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
