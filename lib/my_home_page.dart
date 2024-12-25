import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:read_the_label/models/food_item.dart';
import 'package:read_the_label/widgets/nutrient_balance_card.dart';
import 'package:read_the_label/widgets/nutrient_tile.dart';
import 'package:read_the_label/data/nutrient_insights.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:read_the_label/logic.dart';
import 'data/dv_values.dart';
import 'widgets/portion_buttons.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _selectedFile;
  final ImagePicker imagePicker = ImagePicker();
  final Logic _logic = Logic();
  int _currentIndex = 0;
  final _duration = const Duration(milliseconds: 300);
  bool _isScanning = false;
  double _scanLinePosition = 0.0;
  Timer? _scanTimer;

  LinearGradient _getGradient(BuildContext context) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Theme.of(context).colorScheme.surface,
        Theme.of(context).colorScheme.surface,
      ],
    );
  }

  void _startScanAnimation() {
    setState(() {
      _isScanning = true;
      _scanLinePosition = 0.0;
    });

    _scanTimer?.cancel();

    _scanTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !_logic.getIsLoading()) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isScanning = false;
            _scanLinePosition = 0.0;
          });
        }
        return;
      }

      if (mounted && _isScanning) {
        setState(() {
          _scanLinePosition += 2;
          if (_scanLinePosition > MediaQuery.of(context).size.height) {
            _scanLinePosition = 0;
          }
        });
      }
    });
  }

  Widget _buildImageCaptureButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.qr_code_scanner_outlined, color: Colors.white),
          label: const Text("Scan Now",
              style: TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w400)),
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () => _handleImageCapture(ImageSource.camera),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.photo_library, color: Colors.black),
          label: const Text("Gallery",
              style: TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w400)),
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () => _handleImageCapture(ImageSource.gallery),
        ),
      ],
    );
  }

  void _handleImageCapture(ImageSource source) async {
    // First, capture front image
    await _logic.captureImage(
      source: source,
      isFrontImage: true,
      setState: setState,
    );

    if (_logic.frontImage != null) {
      // Show dialog for nutrition label
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Now capture nutrition label',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Poppins'),
            ),
            content: Text(
              'Please capture or select the nutrition facts label of the product',
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontFamily: 'Poppins'),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _logic.captureImage(
                    source: source,
                    isFrontImage: false,
                    setState: setState,
                  );
                  if (_logic.canAnalyze()) {
                    _analyzeImages();
                  }
                },
                child: const Text('Continue',
                    style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        );
      }
    }
  }

  void _analyzeImages() {
    if (_logic.canAnalyze()) {
      _startScanAnimation();
      _logic.analyzeImages(setState: setState);
    }
  }

  @override
  void initState() {
    super.initState();
    _logic.loadDailyIntake();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _isScanning = false;
    super.dispose();
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _logic.setSetState(setState);
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).colorScheme.background.withOpacity(0.8),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1000, sigmaY: 1000),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        title: Text(
          "ReadTheLabel",
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500),
        ),
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.background.withOpacity(0.8),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1000, sigmaY: 1000),
            child: BottomNavigationBar(
              elevation: 0,
              selectedLabelStyle: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              backgroundColor: Colors.transparent,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context).colorScheme.tertiary,
              currentIndex: _currentIndex,
              onTap: _switchTab,
              items: [
                BottomNavigationBarItem(
                  icon: _currentIndex == 0
                      ? const Icon(Icons.document_scanner)
                      : const Icon(Icons.document_scanner_outlined),
                  label: 'Scan Label',
                ),
                BottomNavigationBarItem(
                  icon: _currentIndex == 1
                      ? const Icon(Icons.food_bank)
                      : const Icon(Icons.food_bank_outlined),
                  label: 'Scan Food',
                ),
                BottomNavigationBarItem(
                  icon: _currentIndex == 2
                      ? const Icon(Icons.pie_chart)
                      : const Icon(Icons.pie_chart_outline),
                  label: 'Daily Intake',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: _getGradient(context),
        ),
        child: AnimatedSwitcher(
          duration: _duration,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: IndexedStack(
            key: ValueKey<int>(_currentIndex),
            index: _currentIndex,
            children: [
              AnimatedOpacity(
                  opacity: _currentIndex == 0 ? 1.0 : 0.0,
                  duration: _duration,
                  child: _buildHomePage(context)),
              AnimatedOpacity(
                opacity: _currentIndex == 1 ? 1.0 : 0.0,
                duration: _duration,
                child: FoodScanPage(logic: _logic),
              ),
              AnimatedOpacity(
                opacity: _currentIndex == 2 ? 1.0 : 0.0,
                duration: _duration,
                child: DailyIntakePage(
                  dailyIntake: _logic.dailyIntake,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 100),
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.transparent),
              ),
              child: DottedBorder(
                borderPadding: const EdgeInsets.all(-20),
                borderType: BorderType.RRect,
                radius: const Radius.circular(20),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                strokeWidth: 1,
                dashPattern: const [6, 4],
                child: Column(
                  children: [
                    if (_logic.frontImage != null)
                      Stack(
                        children: [
                          Image(image: FileImage(_logic.frontImage!)),
                          if (_logic.getIsLoading() && _isScanning)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: _scanLinePosition,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0),
                                      Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.8),
                                      Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    else
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 70,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      "Scan product front or choose from gallery",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 20),
                    _buildImageCaptureButtons(),
                  ],
                ),
              ),
            ),
            if (_selectedFile != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                  ),
                  onPressed: () {
                    _analyzeImages();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _isScanning ? "Analyzing..." : "Analyze",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_logic.getIsLoading())
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Analyzing nutrition label...",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

            //Good/Moderate nutrients
            if (_logic.getGoodNutrients().isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).colorScheme.tertiary,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: Text(
                          _logic.productName,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: 24),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Optimal Nutrients",
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.titleLarge!.color,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _logic
                            .getGoodNutrients()
                            .map((nutrient) => NutrientTile(
                                  nutrient: nutrient['name'],
                                  healthSign: nutrient['health_impact'],
                                  quantity: nutrient['quantity'],
                                  insight: nutrientInsights[nutrient['name']],
                                  dailyValue: nutrient['daily_value'],
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

            //Bad nutrients
            if (_logic.getBadNutrients().isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5252), // Red accent bar
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Watch Out",
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.titleLarge!.color,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _logic
                            .getBadNutrients()
                            .map((nutrient) => NutrientTile(
                                  nutrient: nutrient['name'],
                                  healthSign: nutrient['health_impact'],
                                  quantity: nutrient['quantity'],
                                  insight: nutrientInsights[nutrient['name']],
                                  dailyValue: nutrient['daily_value'],
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            if (_logic.getBadNutrients().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                            255, 94, 255, 82), // Red accent bar
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Recommendations",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge!.color,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            if (_logic.nutritionAnalysis != null &&
                _logic.nutritionAnalysis['primary_concerns'] != null)
              ..._logic.nutritionAnalysis['primary_concerns'].map(
                (concern) => NutrientBalanceCard(
                  issue: concern['issue'] ?? '',
                  explanation: concern['explanation'] ?? '',
                  recommendations: (concern['recommendations'] as List?)
                          ?.map((rec) => {
                                'food': rec['food'] ?? '',
                                'quantity': rec['quantity'] ?? '',
                                'reasoning': rec['reasoning'] ?? '',
                              })
                          .toList() ??
                      [],
                ),
              ),

            if (_logic.getServingSize() > 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          child: Text(
                            "Serving Size: ${_logic.getServingSize().round()} g",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .color,
                                fontSize: 16,
                                fontFamily: 'Poppins'),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit,
                              color:
                                  Theme.of(context).textTheme.titleSmall!.color,
                              size: 20),
                          onPressed: () {
                            // Show edit dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor:
                                    Theme.of(context).colorScheme.tertiary,
                                title: Text('Edit Serving Size',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .color,
                                        fontFamily: 'Poppins')),
                                content: TextField(
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .color),
                                  decoration: InputDecoration(
                                    hintText: 'Enter serving size in grams',
                                    hintStyle: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .color,
                                        fontFamily: 'Poppins'),
                                  ),
                                  onChanged: (value) {
                                    _logic.updateServingSize(
                                        double.tryParse(value) ?? 0.0);
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    child: Text('OK',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .color)),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // In your _buildHomePage method, after the nutrient tiles

                    // Replace slider with a more intuitive portion selector
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "How much did you consume?",
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium!.color,
                            fontSize: 16,
                            fontFamily: 'Poppins'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        PortionButton(
                          context: context,
                          portion: 0.25,
                          label: "¼",
                          logic: _logic,
                          setState: setState,
                        ),
                        PortionButton(
                          context: context,
                          portion: 0.5,
                          label: "½",
                          logic: _logic,
                          setState: setState,
                        ),
                        PortionButton(
                          context: context,
                          portion: 0.75,
                          label: "¾",
                          logic: _logic,
                          setState: setState,
                        ),
                        PortionButton(
                          context: context,
                          portion: 1.0,
                          label: "1",
                          logic: _logic,
                          setState: setState,
                        ),
                        CustomPortionButton(
                          logic: _logic,
                          setState: setState,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            minimumSize: const Size(
                                200, 50), // Set minimum width and height
                          ),
                          onPressed: () {
                            _logic.addToDailyIntake(context, (index) {
                              setState(() {
                                _currentIndex = index;
                              });
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Added to today\'s intake!'), // Updated message
                                action: SnackBarAction(
                                  label:
                                      'VIEW', // Changed from 'SHOW' to 'VIEW'
                                  onPressed: () {
                                    setState(() {
                                      _currentIndex = 2;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: Theme.of(context)
                                        .textTheme
                                        .labelLarge!
                                        .color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Add to today's intake",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: Theme.of(context)
                                          .textTheme
                                          .labelLarge!
                                          .color,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "${_logic.sliderValue.toStringAsFixed(0)} grams, ${(_logic.getCalories() * (_logic.sliderValue / _logic.getServingSize())).toStringAsFixed(0)} calories",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .color,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            if (_logic.getServingSize() == 0 &&
                _logic.parsedNutrients.isNotEmpty)
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
                          _logic.updateSliderValue(
                              double.tryParse(value) ?? 0.0, setState);
                        });
                      },
                      decoration: const InputDecoration(
                          hintText: "Enter serving size in grams or ml",
                          hintStyle: TextStyle(color: Colors.white54)),
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (_logic.getServingSize() > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Slider(
                            value: _logic.sliderValue,
                            min: 0,
                            max: _logic.getServingSize(),
                            onChanged: (newValue) {
                              _logic.updateSliderValue(newValue, setState);
                            }),
                      ),
                    if (_logic.getServingSize() > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Serving Size: ${_logic.getServingSize().round()} g",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                    if (_logic.getServingSize() > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Builder(
                          builder: (context) {
                            return ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(
                                        Colors.white10)),
                                onPressed: () {
                                  _logic.addToDailyIntake(context, (index) {
                                    setState(() {
                                      _currentIndex = index;
                                    });
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'Added to today\'s intake!',
                                          style:
                                              TextStyle(fontFamily: 'Poppins')),
                                      action: SnackBarAction(
                                        label: 'SHOW',
                                        onPressed: () {
                                          setState(() {
                                            _currentIndex = 1;
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: const Text("Add to today's intake",
                                    style: TextStyle(fontFamily: 'Poppins')));
                          },
                        ),
                      ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}

class FoodScanPage extends StatefulWidget {
  final Logic logic;

  const FoodScanPage({
    required this.logic,
    super.key,
  });

  @override
  State<FoodScanPage> createState() => _FoodScanPageState();
}

class _FoodScanPageState extends State<FoodScanPage> {
  int _currentIndex = 1;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            // Scanning Section
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.transparent),
              ),
              child: DottedBorder(
                borderPadding: const EdgeInsets.all(-20),
                borderType: BorderType.RRect,
                radius: const Radius.circular(20),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                strokeWidth: 1,
                dashPattern: const [6, 4],
                child: Column(
                  children: [
                    if (widget.logic.foodImage != null)
                      Image(image: FileImage(widget.logic.foodImage!))
                    else
                      Icon(
                        Icons.restaurant_outlined,
                        size: 70,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      "Take a photo of your food or choose from gallery",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildImageCaptureButtons(),
                  ],
                ),
              ),
            ),

            //Loading animation
            if (widget.logic.getIsLoading())
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Analyzing nutrition label...",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            // Results Section
            if (widget.logic.foodImage != null &&
                widget.logic.analyzedFoodItems.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Analysis Results',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.logic.analyzedFoodItems
                      .map((item) => _buildFoodItemCard(item)),
                  _buildTotalNutrientsCard(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCaptureButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
          label: const Text(
            "Take Photo",
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          ),
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () => _handleFoodImageCapture(ImageSource.camera),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.photo_library, color: Colors.black),
          label: const Text(
            "Gallery",
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          ),
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () => _handleFoodImageCapture(ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildFoodItemCard(FoodItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with food name and quantity
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${item.quantity}${item.unit}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Nutrient grid
          Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildNutrientTile(
                  'Calories',
                  '${item.calculateTotalNutrients()['calories']?.toStringAsFixed(1)}',
                  'kcal',
                  Icons.local_fire_department_outlined,
                ),
                _buildNutrientTile(
                  'Protein',
                  '${item.calculateTotalNutrients()['protein']?.toStringAsFixed(1)}',
                  'g',
                  Icons.fitness_center_outlined,
                ),
                _buildNutrientTile(
                  'Carbs',
                  '${item.calculateTotalNutrients()['carbohydrates']?.toStringAsFixed(1)}',
                  'g',
                  Icons.grain_outlined,
                ),
                _buildNutrientTile(
                  'Fat',
                  '${item.calculateTotalNutrients()['fat']?.toStringAsFixed(1)}',
                  'g',
                  Icons.opacity_outlined,
                ),
                _buildNutrientTile(
                  'Fiber',
                  '${item.calculateTotalNutrients()['fiber']?.toStringAsFixed(1)}',
                  'g',
                  Icons.grass_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientTile(
      String label, String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$value$unit',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalNutrientsCard() {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    }

    final nutrients = {
      'Calories': {
        'value': toDouble(widget.logic.totalPlateNutrients['calories']),
        'unit': 'kcal',
        'icon': Icons.local_fire_department_outlined,
      },
      'Protein': {
        'value': toDouble(widget.logic.totalPlateNutrients['protein']),
        'unit': 'g',
        'icon': Icons.fitness_center_outlined,
      },
      'Carbohydrates': {
        'value': toDouble(widget.logic.totalPlateNutrients['carbohydrates']),
        'unit': 'g',
        'icon': Icons.grain_outlined,
      },
      'Fat': {
        'value': toDouble(widget.logic.totalPlateNutrients['fat']),
        'unit': 'g',
        'icon': Icons.opacity_outlined,
      },
      'Fiber': {
        'value': toDouble(widget.logic.totalPlateNutrients['fiber']),
        'unit': 'g',
        'icon': Icons.grass_outlined,
      },
    };

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Nutrients',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.logic.analyzedFoodItems.length} items',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: nutrients.entries.map((entry) {
                final isLast = entry.key == nutrients.keys.last;
                return _buildTotalNutrientRow(
                  entry.key,
                  entry.value['value'] as double,
                  entry.value['unit'] as String,
                  entry.value['icon'] as IconData,
                  isLast: isLast,
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: () {
                widget.logic.addToDailyIntake(context, (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to daily intake'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add to Daily Intake'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalNutrientRow(
    String label,
    double value,
    String unit,
    IconData icon, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(child: Container()),
              Text(
                '${value.toStringAsFixed(1)}$unit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
      ],
    );
  }

  void _handleFoodImageCapture(ImageSource source) async {
    final imagePicker = ImagePicker();
    final image = await imagePicker.pickImage(source: source);

    if (image != null) {
      setState(() {
        widget.logic.foodImage = File(image.path);
      });
      await widget.logic.analyzeFoodImage(
        imageFile: widget.logic.foodImage!,
        setState: setState,
      );
    }
  }
}

class DailyIntakePage extends StatefulWidget {
  final Map<String, double> dailyIntake;
  const DailyIntakePage({super.key, required this.dailyIntake});

  @override
  State<DailyIntakePage> createState() => _DailyIntakePageState();
}

class _DailyIntakePageState extends State<DailyIntakePage> {
  late Map<String, double> _dailyIntake;
  DateTime _selectedDate = DateTime.now();
  final List<DateTime> _dates = List.generate(
      6, (index) => DateTime.now().subtract(Duration(days: 5 - index)));

  @override
  void initState() {
    super.initState();
    _dailyIntake = widget.dailyIntake;
  }

  Future<void> _loadDailyIntake(DateTime date) async {
    final Logic logic = Logic();
    final String storageKey = _getStorageKey(date);
    final prefs = await SharedPreferences.getInstance();
    final dailyIntake = (prefs.getString(storageKey) != null)
        ? (jsonDecode(prefs.getString(storageKey)!) as Map)
            .cast<String, double>()
        : <String, double>{};
    setState(() {
      _selectedDate = date;
      _dailyIntake = dailyIntake;
    });
  }

  String _getStorageKey(DateTime date) {
    final today = DateTime(date.year, date.month, date.day);
    return 'dailyIntake_${today.toIso8601String()}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            top: 24,
            left: 24,
            right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            _buildDateSelector(),
            const SizedBox(height: 24),
            _buildCalorieProgress(),
            const SizedBox(height: 24),
            _buildNutrientsList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _selectedDate.day == date.day;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _DateButton(
              date: date,
              isSelected: isSelected,
              onTap: () => _loadDailyIntake(date),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalorieProgress() {
    final calories = _dailyIntake['Energy'] ?? 0.0;
    final percent = calories / 2000;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Calories',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    calories.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    ' / 2000 kcal',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(child: Container()),
          Column(
            children: [
              if (percent > 0.1)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Calories',
                        semanticsValue: '${calories.toStringAsFixed(1)} kcal',
                        color: Theme.of(context).colorScheme.primary,
                        value: percent > 1.0 ? 1.0 : percent,
                        strokeWidth: 8,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getColorForPercent(percent),
                        ),
                      ),
                    ),
                    Text(
                      '${(percent * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _getColorForPercent(percent),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrient Intake',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 24),
        ...nutrientData.where((nutrient) {
          final name = nutrient['Nutrient'];
          final current = _dailyIntake[name] ?? 0.0;
          return current > 0.0;
        }).map((nutrient) {
          final name = nutrient['Nutrient'];
          final current = _dailyIntake[name] ?? 0.0;
          final total = double.tryParse(nutrient['Current Daily Value']
                  .replaceAll(RegExp(r'[^0-9\.]'), '')) ??
              0.0;
          final percent = current / total;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '${(percent * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _getColorForPercent(percent),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent > 1.0 ? 1.0 : percent,
                          minHeight: 8,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getColorForPercent(percent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${current.toStringAsFixed(1)}/${total.toStringAsFixed(1)}${_getUnit(name)}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _getUnit(String nutrient) {
    switch (nutrient.toLowerCase()) {
      case 'energy':
        return ' kcal';
      case 'protein':
      case 'carbohydrate':
      case 'fat':
      case 'fiber':
      case 'sugar':
        return 'g';
      case 'sodium':
      case 'potassium':
      case 'calcium':
      case 'iron':
        return 'mg';
      default:
        return '';
    }
  }

  Color _getColorForPercent(double percent) {
    if (percent > 1.0) return Theme.of(context).colorScheme.error;
    if (percent > 0.8)
      return Theme.of(context).colorScheme.error.withOpacity(0.8);
    if (percent > 0.6) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).colorScheme.secondary;
  }
}

class _DateButton extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateButton({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
              fontSize: isSelected ? 20 : 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _NutrientProgressBar extends StatelessWidget {
  final String name;
  final double current;
  final double total;
  final double percent;

  const _NutrientProgressBar({
    required this.name,
    required this.current,
    required this.total,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name: ${current.toStringAsFixed(2)} / $total ${_getUnit(name)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent > 1.0 ? 1.0 : percent,
              minHeight: 8,
              backgroundColor:
                  Theme.of(context).colorScheme.surface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                percent > 1.0
                    ? Theme.of(context).colorScheme.error
                    : percent > 0.7
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUnit(String nutrient) {
    switch (nutrient.toLowerCase()) {
      case 'energy':
        return 'kcal';
      case 'protein':
      case 'carbohydrate':
      case 'fat':
      case 'fiber':
      case 'sugar':
        return 'g';
      case 'sodium':
      case 'potassium':
      case 'calcium':
      case 'iron':
        return 'mg';
      default:
        return '';
    }
  }
}
