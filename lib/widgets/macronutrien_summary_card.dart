import 'package:flutter/material.dart';

Widget MacronutrientSummaryCard(
    BuildContext context, Map<String, double> dailyIntake) {
  final calories = dailyIntake['Energy'] ?? 0.0;
  const calorieGoal = 2000.0;
  final caloriePercent = (calories / calorieGoal);
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calories',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '${calories.toStringAsFixed(0)} / ${calorieGoal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 75,
                  height: 75,
                  child: CircularProgressIndicator(
                    value: caloriePercent,
                    backgroundColor: Colors.white24,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Center(
                  child: Text(
                    '${(caloriePercent * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMacronutrientIndicator(
              'Protein',
              dailyIntake['Protein'] ?? 0.0,
              50.0,
              Icons.fitness_center,
            ),
            _buildMacronutrientIndicator(
              'Carbs',
              dailyIntake['Carbohydrate'] ?? 0.0,
              275.0,
              Icons.grain,
            ),
            _buildMacronutrientIndicator(
              'Fat',
              dailyIntake['Fat'] ?? 0.0,
              78.0,
              Icons.opacity,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildMacronutrientIndicator(
  String label,
  double value,
  double goal,
  IconData icon,
) {
  final percent = (value / goal).clamp(0.0, 1.0);
  return Column(
    spacing: 4,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 32,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
            fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${value.toStringAsFixed(1)}g',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            ' / ${goal.toStringAsFixed(1)}g',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
      SizedBox(
        height: 6,
        width: 80,
        child: LinearProgressIndicator(
          value: percent,
          minHeight: 5,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ],
  );
}
