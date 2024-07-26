import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:read_the_label/widgets/nutrient_tile.dart';

import 'data/dv_values.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double containerHeight = 900;
  String _generatedText = "";
  File? _selectedFile;

  final ImagePicker imagePicker = ImagePicker();
  List<Map<String, dynamic>> parsedNutrients = [];

  _pickImage(ImageSource imageSource) async {
    final file = await imagePicker.pickImage(source: imageSource);
    _selectedFile = File(file!.path);
    setState(() {});
  }

  Future<String> _fetchGeneratedText() async {
    print("_fetchGeneratedText() is called");
    // Access your API key (assuming you have a way to access it)
    final apiKey =
        "AIzaSyAmdNqePM8rcMy3AuYWRyYFc-UQkUDRYEE"; // Replace with your API key

    // Initialize the GenerativeModel
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final imageBytes = await _selectedFile!.readAsBytes();

    final imageParts = [
      DataPart('image/jpeg', imageBytes),
    ];

    final prompt = TextPart(
        """Analyze the label, considering the attached daily value recommendations data.  Provide your response in a strictly valid JSON format with this structure:
{
  "nutrients": [
    {"name": "Nutrient Name", "status": "High" or "Low", "quantity": "Quantity"}
  ]
}
Do not include any extra characters or formatting outside of the JSON object. Use accurate escape sequences for any special characters. Also, mention nutrients only present in the label""");

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
      parsedNutrients =
          (jsonResponse['nutrients'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print("Error parsing JSON: $e");
      // Handle the error gracefully, maybe display a message to the user
    }
    print(parsedNutrients);
    _generatedText = response.text!;
    print("This is responce content: ${response.text}");
    print("This is updated generatedText: $_generatedText");
    // Return the generated text
    setState(() {});
    return response.text!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ReadTheLabel"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                _pickImage(ImageSource.gallery);
              },
              child: const Text("Scan label"),
            ),
            if (_selectedFile != null) Image(image: FileImage(_selectedFile!)),
            ElevatedButton(
              onPressed: () {
                _fetchGeneratedText();
              },
              child: const Text("Analyze"),
            ),
            if (parsedNutrients.isNotEmpty)
              Flexible(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Number of columns
                    crossAxisSpacing: 0, // Spacing between columns
                    mainAxisSpacing: 10, // Spacing between rows
                    childAspectRatio: 1,
                  ),
                  itemCount: parsedNutrients.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return NutrientTile(
                      nutrient: parsedNutrients[index]['name'],
                      isHigh: parsedNutrients[index]['status'] == 'High',
                      quantity: parsedNutrients[index]['quantity'],
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}
