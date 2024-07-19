import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _generatedText = "";
  File? _selectedFile;
  final ImagePicker imagePicker = ImagePicker();

  _pickImage(ImageSource imageSource) async {
    final file = await imagePicker.pickImage(source: imageSource);
    _selectedFile = File(file!.path);
    setState(() {
    });
  }

  Future<String> _fetchGeneratedText() async {
    print("_fetchGeneratedText() is called");
    // Access your API key (assuming you have a way to access it)
    final apiKey =
        "AIzaSyAmdNqePM8rcMy3AuYWRyYFc-UQkUDRYEE"; // Replace with your API key

    // Initialize the GenerativeModel
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final imageBytes = await _selectedFile!.readAsBytes();

    final prompt = TextPart("Analyze the picture");
    final imageParts = [
      DataPart('image/jpeg', imageBytes),
    ];
    final response = await model.generateContent([
      Content.multi([prompt, ...imageParts])
    ]);

    _generatedText=response.text!;
    print("This is responce content: ${response.text}");
    print("This is updated generatedText: $_generatedText");
    // Return the generated text
    setState(() {

    });
    return response.text!;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan the Label"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                _pickImage(ImageSource.camera);
              },
              child: const Text("Scan label"),
            ),
            if(_selectedFile!=null)
              Image(image: FileImage(_selectedFile!)),
            ElevatedButton(
              onPressed: () {
                _fetchGeneratedText();
              },
              child: const Text("Analyze"),
            ),
            Center(
              child: Text(_generatedText)

            ),
          ],
        ),
      ),
    );
  }
}


