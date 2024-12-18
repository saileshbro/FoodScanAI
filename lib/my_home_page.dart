import 'dart:convert';
import 'dart:io';
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
            backgroundColor: Colors.black45,
            appBar: AppBar(
              backgroundColor: Colors.black45,
              forceMaterialTransparency: true,
              title: const Text(
                "ReadTheLabel",
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500),
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
                backgroundColor: Colors.black26,
                selectedItemColor: Colors.red,
                unselectedItemColor: Colors.grey,
                currentIndex: _currentIndex,
                unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w400),
                selectedLabelStyle: const TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w400),
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
                ]),
            body: IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomePage(context),
                DailyIntakePage(
                  dailyIntake: _logic.dailyIntake,
                ),
              ],
            )));
  }

  Widget _buildHomePage(BuildContext context) {
    double tileWidth = MediaQuery.of(context).size.width / 2;
    return SingleChildScrollView(
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
                child: const Text(
                  "Scan from gallery",
                  style: TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w400),
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.black)),
                onPressed: () {
                  _pickImage(ImageSource.camera);
                },
                child: const Text(
                  "Scan label",
                  style: TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
          if (_selectedFile != null) Image(image: FileImage(_selectedFile!)),
          ElevatedButton(
            style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white10)),
            onPressed: () {
              _fetchData();
            },
            child: const Text(
              "Analyze",
              style:
                  TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
            ),
          ),
          if (_logic.getIsLoading()) const CircularProgressIndicator(),

          //Good/Moderate nutrients
          if (_logic.getGoodNutrients().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20.0, top: 10.0),
                  child: Text("NUTRIENT IN GOOD AMOUNTS",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600)),
                ),
                Wrap(
                  spacing: 8.0, // Spacing between the tiles
                  runSpacing: 8.0, //Spacing between the rows
                  children: _logic
                      .getGoodNutrients()
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
          if (_logic.getBadNutrients().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20.0, top: 10.0),
                  child: Text("NUTRIENTS IN BAD QUANTITY",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600)),
                ),
                Wrap(
                  spacing: 8.0, // Spacing between the tiles
                  runSpacing: 8.0, //Spacing between the rows
                  children: _logic
                      .getBadNutrients()
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
          if (_logic.getServingSize() > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Slider(
                      value: _logic.sliderValue,
                      min: 0,
                      max: _logic.getServingSize(),
                      onChanged: (newValue) {
                        _logic.updateSliderValue(newValue, setState);
                      }),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Serving Size: ${_logic.sliderValue.toStringAsFixed(2)} g",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  Builder(builder: (context) {
                    return ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(Colors.white10)),
                      onPressed: () {
                        _logic.addToDailyIntake(context, (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Added to today\'s intake!',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400)),
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
                      child: const Text(
                        "Add to today's intake",
                        style: TextStyle(
                            fontFamily: 'Poppins', fontWeight: FontWeight.w400),
                      ),
                    );
                  })
                ],
              ),
            ),
          if (_logic.getServingSize() == 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Serving size not found, please enter it manually',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400),
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
                        hintStyle: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600)),
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600),
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
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                  if (_logic.getServingSize() > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Builder(builder: (context) {
                        return ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.all(Colors.white10)),
                          onPressed: () {
                            _logic.addToDailyIntake(context, (index) {
                              setState(() {
                                _currentIndex = index;
                              });
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Added to today\'s intake!'),
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
                          child: const Text("Add to today's intake"),
                        );
                      }),
                    )
                ],
              ),
            )
        ],
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
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontFamily: 'Poppins',
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
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
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
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
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
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600),
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
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400),
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
            legendOptions: const LegendOptions(
                legendTextStyle: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400)),
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
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600),
          );
  }
}
