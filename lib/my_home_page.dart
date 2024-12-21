import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:read_the_label/widgets/nutrient_balance_card.dart';
import 'package:read_the_label/widgets/nutrient_tile.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';

import 'package:read_the_label/data/nutrient_insights.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/percent_indicator.dart';
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
  final _gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.fromARGB(255, 25, 36, 59),
        Color.fromARGB(255, 4, 9, 22),
      ]);
  final _duration = const Duration(milliseconds: 300);
  bool _isScanning = false;
  double _scanLinePosition = 0.0;
  Timer? _scanTimer;

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

  _pickImage(ImageSource imageSource) async {
    final file = await imagePicker.pickImage(source: imageSource);
    setState(() {
      _selectedFile = File(file!.path);
    });
  }

  void _fetchData() {
    _startScanAnimation();
    _logic.fetchGeneratedText(selectedFile: _selectedFile, setState: setState);
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
      backgroundColor: const Color.fromARGB(0, 5, 23, 35),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 9, 28)
          ..withValues(alpha: 1),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1000, sigmaY: 1000),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        title: const Text(
          "ReadTheLabel",
          style: TextStyle(
              color: Color(0xFF2763eb),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500),
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: _duration,
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 4, 9, 28)..withValues(alpha: 1),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1000, sigmaY: 1000),
              child: Container(
                color: Colors.transparent,
                child: BottomNavigationBar(
                  selectedLabelStyle: const TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w400),
                  unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w400),
                  backgroundColor: Colors.transparent,
                  selectedItemColor: const Color(0xFF2763eb),
                  unselectedItemColor: Colors.grey,
                  currentIndex: _currentIndex,
                  onTap: _switchTab,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.food_bank_outlined),
                        label: 'Daily Intake'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: _gradient,
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
    double tileWidth = MediaQuery.of(context).size.width / 2;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom +
                80), // 80 is approximate height of bottom nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 100,
            ),
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.transparent,
                ),
              ),
              child: DottedBorder(
                borderPadding: const EdgeInsets.all(-20),
                borderType: BorderType.RRect,
                radius: const Radius.circular(20),
                color: Colors.white24,
                strokeWidth: 1,
                dashPattern: const [
                  6,
                  4
                ], // Adjust dash and gap lengths as needed
                child: Column(
                  children: [
                    _selectedFile != null
                        ? Stack(
                            children: [
                              Image(image: FileImage(_selectedFile!)),
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
                                          Colors.blue.withOpacity(0),
                                          Colors.blue.withOpacity(0.8),
                                          Colors.blue.withOpacity(0),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : const Icon(
                            Icons.camera_alt_outlined,
                            size: 70,
                            color: Colors.grey,
                          ),
                    const SizedBox(height: 20),
                    const Text(
                      "Scan nutrition label or choose from gallery",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.qr_code_scanner_outlined,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Scan Now",
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            backgroundColor: const Color(0xff2563eb),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Gallery",
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            backgroundColor: const Color(0xff1f2937),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedFile != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2763eb), Color(0xFF6B8CEF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2763eb).withOpacity(0.3),
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
                    _fetchData();
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
                            color: const Color(0xFF2763eb).withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF2763eb)),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Analyzing nutrition label...",
                      style: TextStyle(
                        color: Colors.white70,
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
                          const Text(
                            "Optimal Nutrients",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _logic
                            .getGoodNutrients()
                            .map((nutrient) => Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: NutrientTile(
                                    nutrient: nutrient['name'],
                                    healthSign: nutrient['health_sign'],
                                    quantity: nutrient['quantity'],
                                    insight: nutrientInsights[nutrient['name']],
                                  ),
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
                          const Text(
                            "Watch Out",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _logic
                            .getBadNutrients()
                            .map((nutrient) => Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: NutrientTile(
                                    nutrient: nutrient['name'],
                                    healthSign: nutrient['health_sign'],
                                    quantity: nutrient['quantity'],
                                    insight: nutrientInsights[nutrient['name']],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            if (_logic.getServingSize() > 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_logic.currentRecommendation != null)
                      NutrientBalanceCard(
                        recommendation: _logic.currentRecommendation!,
                        currentPreference: _logic.currentDietaryPreference,
                        onPreferenceChanged: (preference) {
                          _logic.updateDietaryPreference(preference);
                        },
                      ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 4, 9, 22),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF2763eb),
                            ),
                          ),
                          child: Text(
                            "Serving Size: ${_logic.getServingSize().round()} g",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Poppins'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.white60, size: 20),
                          onPressed: () {
                            // Show edit dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xff1f2937),
                                title: const Text('Edit Serving Size',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Poppins')),
                                content: TextField(
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter serving size in grams',
                                    hintStyle: TextStyle(
                                        color: Colors.white54,
                                        fontFamily: 'Poppins'),
                                  ),
                                  onChanged: (value) {
                                    _logic.updateServingSize(
                                        double.tryParse(value) ?? 0.0);
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('OK',
                                        style:
                                            TextStyle(fontFamily: 'Poppins')),
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
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "How much did you consume?",
                        style: TextStyle(
                            color: Colors.white,
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
                            backgroundColor: const Color(0xff2563eb),
                            foregroundColor: Colors.white,
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
                                      _currentIndex = 1;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Add to today's intake",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "${_logic.sliderValue.toStringAsFixed(0)} grams, ${(_logic.getCalories() * (_logic.sliderValue / _logic.getServingSize())).toStringAsFixed(0)} calories",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
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
            const Color(0xFF2763eb).withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF2763eb).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Calories',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                calories.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              const Text(
                ' / 2000 kcal',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              Expanded(child: Container()),
              if (percent > 0.1)
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _getColorForPercent(percent),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: percent > 1.0 ? 1.0 : percent,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForPercent(percent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrient Intake',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
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
                      style: const TextStyle(
                        color: Colors.white,
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
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getColorForPercent(percent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${current.toStringAsFixed(1)}/${total.toStringAsFixed(1)}${_getUnit(name)}',
                      style: const TextStyle(
                        color: Colors.white70,
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
    if (percent > 1.0) return Colors.red;
    if (percent > 0.8) return Colors.orange;
    if (percent > 0.6) return Colors.yellow;
    return Colors.greenAccent;
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
          color: isSelected ? const Color(0xFF2763eb) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
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
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                percent > 1.0
                    ? Colors.red
                    : percent > 0.7
                        ? Colors.amber
                        : Colors.greenAccent,
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
