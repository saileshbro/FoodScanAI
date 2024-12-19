import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:read_the_label/widgets/nutrient_tile.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';

import 'package:read_the_label/data/nutrient_insights.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:read_the_label/logic.dart';

import 'data/dv_values.dart';

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

  @override
  void initState() {
    super.initState();
    _logic.loadDailyIntake();
  }

  _pickImage(ImageSource imageSource) async {
    final file = await imagePicker.pickImage(source: imageSource);
    setState(() {
      _selectedFile = File(file!.path);
    });
  }

  void _fetchData() {
    _logic.fetchGeneratedText(selectedFile: _selectedFile, setState: setState);
  }

  @override
  Widget build(BuildContext context) {
    _logic.setSetState(setState);
    return MaterialApp(
        navigatorKey: Logic.navKey,
        home: Scaffold(
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
                    color: const Color(0xFF2763eb),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500),
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 4, 9, 28)
                  ..withValues(alpha: 1),
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1000, sigmaY: 1000),
                  child: Container(
                    color: Colors.transparent,
                    child: BottomNavigationBar(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      selectedItemColor: const Color(0xFF2763eb),
                      unselectedItemColor: Colors.grey,
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      items: const [
                        BottomNavigationBarItem(
                            icon: Icon(Icons.home), label: 'Home'),
                        BottomNavigationBarItem(
                            icon: Icon(Icons.food_bank), label: 'Daily Intake'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: _gradient,
              ),
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomePage(context),
                  DailyIntakePage(
                    dailyIntake: _logic.dailyIntake,
                  ),
                ],
              ),
            )));
  }

  Widget _buildHomePage(BuildContext context) {
    double tileWidth = MediaQuery.of(context).size.width / 2;
    // Add this helper method to the class
    Widget _buildPortionButton(
        BuildContext context, double portion, String label) {
      bool isSelected =
          (_logic.sliderValue / _logic.getServingSize()).round() == portion;
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? const Color(0xff2563eb) : const Color(0xff1f2937),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          setState(() {
            _logic.updateSliderValue(
                _logic.getServingSize() * portion, setState);
          });
        },
        child: Text(label, style: const TextStyle(color: Colors.white)),
      );
    }

    Widget _buildCustomPortionButton(BuildContext context) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff1f2937),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xff1f2937),
              title: const Text('Enter Custom Amount',
                  style: TextStyle(color: Colors.white)),
              content: TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter amount in grams',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                onChanged: (value) {
                  _logic.updateSliderValue(
                      double.tryParse(value) ?? 0.0, setState);
                },
              ),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
        child: const Text("Custom", style: TextStyle(color: Colors.white)),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom +
                80), // 80 is approximate height of bottom nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
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
                        ? Image(image: FileImage(_selectedFile!))
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
            ElevatedButton(
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
              onPressed: () {
                _fetchData();
              },
              child: const Text("Analyze"),
            ),
            if (_logic.getIsLoading()) const CircularProgressIndicator(),

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
                    Row(
                      children: [
                        Text(
                          "Serving Size: ${_logic.getServingSize().toStringAsFixed(2)} g",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
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
                                    style: TextStyle(color: Colors.white)),
                                content: TextField(
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter serving size in grams',
                                    hintStyle: TextStyle(color: Colors.white54),
                                  ),
                                  onChanged: (value) {
                                    _logic.updateServingSize(
                                        double.tryParse(value) ?? 0.0);
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('OK'),
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

                    // Replace slider with a more intuitive portion selector
                    const Text(
                      "How much did you consume?",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPortionButton(context, 0.25, "¼"),
                        _buildPortionButton(context, 0.5, "½"),
                        _buildPortionButton(context, 0.75, "¾"),
                        _buildPortionButton(context, 1.0, "1"),
                        _buildCustomPortionButton(context),
                      ],
                    ),
                    // Show selected amount
                    if (_logic.sliderValue > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          "Selected: ${_logic.sliderValue.toStringAsFixed(2)} g",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ),
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 20,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Add to today's intake", // New, more concise title
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
                          "Serving Size: ${_logic.sliderValue.toStringAsFixed(2)} g",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    if (_logic.getServingSize() > 0)
                      Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Builder(builder: (context) {
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
                                          'Added to today\'s intake!'),
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
                                child: const Text("Add to today's intake"));
                          }))
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
  DailyIntakePage({super.key, required this.dailyIntake});

  @override
  State<DailyIntakePage> createState() => _DailyIntakePageState();
}

class _DailyIntakePageState extends State<DailyIntakePage> {
  late Map<String, double> _dailyIntake;
  DateTime _selectedDate = DateTime.now();
  List<DateTime> _dates = [];
  @override
  void initState() {
    super.initState();
    _dailyIntake = widget.dailyIntake;
    _generateDateRange();
  }

  void _generateDateRange() {
    _dates = List.generate(
        7, (index) => DateTime.now().subtract(Duration(days: 6 - index)));
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
    final Logic logic = Logic();
    double totalCalories = _dailyIntake['Energy'] ?? 0.0;
    final chartData = logic.getPieChartData(_dailyIntake);
    print("Chart Data inside _buildPieChart is: $chartData");
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 80,
            ),
            SizedBox(
              height: 40,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  itemBuilder: (context, index) {
                    final date = _dates[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => _loadDailyIntake(date),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: _selectedDate.year == date.year &&
                                      _selectedDate.month == date.month &&
                                      _selectedDate.day == date.day
                                  ? Colors.red
                                  : Colors
                                      .transparent, // Red border for the selected date
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              DateFormat('dd').format(date),
                              style: TextStyle(
                                color: _selectedDate.year == date.year &&
                                        _selectedDate.month == date.month &&
                                        _selectedDate.day == date.day
                                    ? Colors.red
                                    : Colors.white,
                                fontSize: _selectedDate.year == date.year &&
                                        _selectedDate.month == date.month &&
                                        _selectedDate.day == date.day
                                    ? 20
                                    : 14,
                                fontWeight: _selectedDate.year == date.year &&
                                        _selectedDate.month == date.month &&
                                        _selectedDate.day == date.day
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
            ),
            Text(
              'Total Calories: ${totalCalories.toStringAsFixed(2)} / 2000',
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: LinearPercentIndicator(
                percent: totalCalories / 2000,
                lineHeight: 14.0,
                progressColor: Colors.blueAccent,
              ),
            ),
            const Text(
              "Nutrient Intake",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            ..._buildNutrientProgress(_dailyIntake),
            const SizedBox(height: 16.0),
            _buildPieChart(chartData),
            if (logic.getInsights(_dailyIntake) != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  logic.getInsights(_dailyIntake)!,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNutrientProgress(Map<String, double> dailyIntake) {
    List<Widget> nutrientWidgets = [];

    for (var nutrient in nutrientData) {
      String nutrientName = nutrient['Nutrient'];
      if (dailyIntake.containsKey(nutrientName)) {
        double currentIntake = dailyIntake[nutrientName]!;
        try {
          double dvValue = double.parse(nutrient['Current Daily Value']
              .replaceAll(RegExp(r'[^0-9\.]'), ''));
          double percent = currentIntake / dvValue;
          nutrientWidgets.add(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$nutrientName: ${currentIntake.toStringAsFixed(2)} / ${nutrient['Current Daily Value']}',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: LinearPercentIndicator(
                  percent: percent > 1.0 ? 1.0 : percent,
                  lineHeight: 12.0,
                  progressColor: percent > 1.0
                      ? Colors.red
                      : percent > 0.7
                          ? Colors.amber
                          : Colors.greenAccent,
                ),
              ),
            ],
          ));
        } catch (e) {
          print("Error parsing double: $e");
        }
      }
    }

    return nutrientWidgets;
  }

  Widget _buildPieChart(Map<String, double> chartData) {
    print("Chart Data inside _buildPieChart is: $chartData");
    return chartData.isNotEmpty
        ? PieChart(
            dataMap: chartData,
            colorList: const [
              Colors.greenAccent,
              Colors.amberAccent,
              Colors.blueAccent,
              Colors.deepPurple,
              Colors.red,
              Colors.orange,
              Colors.pink,
              Colors.teal
            ],
            chartValuesOptions:
                const ChartValuesOptions(showChartValuesInPercentage: true),
          )
        : const Text(
            "No Data to display Pie Chart",
            style: TextStyle(color: Colors.white, fontSize: 16),
          );
  }
}
