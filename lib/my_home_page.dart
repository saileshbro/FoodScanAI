import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  String _generatedText = "";
  File? _selectedFile;

  final ImagePicker imagePicker = ImagePicker();
  List<Map<String, dynamic>> parsedNutrients = [];

  _pickImage(ImageSource imageSource) async {
    final file = await imagePicker.pickImage(source: imageSource);
    _selectedFile = File(file!.path);
    setState(() {});
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
  "nutrients": [
    {"name": "Nutrient Name", "status": "High" or "Low" or "Moderate", "quantity": "Quantity"}
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
  5% < DV < 20% of a nutrient per serving is considered moderate""");

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
    print("This is response content: ${response.text}");
    print("This is updated generatedText: $_generatedText");
    // Return the generated text
    _isLoading = false;
    setState(() {});
    return response.text!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black45,
      // extendBody: true,
      // extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black45,
        forceMaterialTransparency: true,
        title: const Text("ReadTheLabel", style: TextStyle(color: Colors.white),),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ElevatedButton(
                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.black)),
                  onPressed: () {
                    _pickImage(ImageSource.gallery);
                  },
                  child: const Text("Scan from gallery"),
                ),
                ElevatedButton(
                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.black)),
                  onPressed: () {
                    _pickImage(ImageSource.camera);
                  },
                  child: const Text("Scan label"),
                ),
              ],
            ),
            if (_selectedFile != null) Image(image: FileImage(_selectedFile!)),
            ElevatedButton(
              style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.white10)),
                onPressed: () {
                  _fetchGeneratedText();
                },
                child: Animate(
                  onComplete: (controller) => controller.repeat(),
                  child: const Text("Analyze"),
                ).custom(
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) {
                    if (child is! Text) {
                      return child;
                    }
                    final text = child.data;
                    if (text == null) {
                      return child;
                    }
                    final letters = text.characters.toList();
                    List<TextSpan> spans = [];

                    for (int i = 0; i < letters.length; i++) {
                      final hue = (value * 360 + (i * (360 / letters.length))) % 360; // Stagger colors
                      final color = HSLColor.fromAHSL(1.0, hue, 1.0, 0.5).toColor();

                      spans.add(TextSpan(
                          text: letters[i],
                          style: TextStyle(color: color)
                      )
                      );
                    }

                    return RichText(
                      text: TextSpan(
                          children: spans
                      ),
                    );
                  },
                )
            ),
            if (_isLoading) CircularProgressIndicator(),
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
              ),
          ],
        ),
      ),
    );
  }
}
