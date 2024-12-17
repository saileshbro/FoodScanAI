import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../data/dv_values.dart';

class DailyIntakePage extends StatelessWidget {

  final Map<String, double> dailyIntake;
  DailyIntakePage({super.key, required this.dailyIntake});

  @override
  Widget build(BuildContext context) {
    double totalCalories = dailyIntake['Energy'] ?? 0.0;
    return Scaffold(
      backgroundColor: Colors.black45,
      appBar: AppBar(
          title: const Text('Daily Intake', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black45,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white,),
            onPressed: (){
              Navigator.pop(context);
            },
          )
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Calories: ${totalCalories.toStringAsFixed(2)} / 2000',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: LinearPercentIndicator(
                  percent: totalCalories/2000,
                  lineHeight: 14.0,
                  progressColor: Colors.blueAccent,
                ),
              ),
              const Text("Nutrient Intake", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),),
              const SizedBox(height: 16.0),
              ..._buildNutrientProgress(dailyIntake),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNutrientProgress(Map<String, double> dailyIntake){
    List<Widget> nutrientWidgets = [];

    for (var nutrient in nutrientData){
      String nutrientName = nutrient['Nutrient'];
      if(dailyIntake.containsKey(nutrientName)) {
        double currentIntake = dailyIntake[nutrientName]!;
        try {
          double dvValue = double.parse(nutrient['Current Daily Value'].replaceAll(RegExp(r'[^0-9\.]'), ''));
          double percent = currentIntake / dvValue;
          nutrientWidgets.add(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$nutrientName: ${currentIntake.toStringAsFixed(2)} / ${nutrient['Current Daily Value']}',
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: LinearPercentIndicator(
                      percent: percent > 1.0 ? 1.0 : percent,
                      lineHeight: 12.0,
                      progressColor: percent > 1.0 ? Colors.red :  percent > 0.7 ? Colors.amber : Colors.greenAccent,
                    ),
                  ),
                ],
              )
          );
        }
        catch (e){
          print("Error parsing double: $e");
        }

      }
    }

    return nutrientWidgets;
  }
}