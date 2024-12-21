import 'package:flutter/material.dart';
import '../data/nutrient_balance_analyzer.dart';

class NutrientBalanceCard extends StatelessWidget {
  final BalanceRecommendation recommendation;
  final DietaryPreference currentPreference;
  final Function(DietaryPreference) onPreferenceChanged;

  const NutrientBalanceCard({
    Key? key,
    required this.recommendation,
    required this.currentPreference,
    required this.onPreferenceChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 4, 9, 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.balance, color: Color(0xFF2763eb)),
                const SizedBox(width: 8),
                const Text(
                  'Nutrient Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                DropdownButton<DietaryPreference>(
                  value: currentPreference,
                  dropdownColor: const Color.fromARGB(255, 4, 9, 22),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (DietaryPreference? newValue) {
                    if (newValue != null) {
                      onPreferenceChanged(newValue);
                    }
                  },
                  items: DietaryPreference.values.map((preference) {
                    return DropdownMenuItem<DietaryPreference>(
                      value: preference,
                      child: Text(
                        preference.toString().split('.').last,
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            if (recommendation.concern.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                recommendation.concern,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
            if (recommendation.complementaryFoods.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Recommended Additions:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recommendation.complementaryFoods.map((food) {
                  return Chip(
                    backgroundColor: const Color(0xFF2763eb).withOpacity(0.7),
                    side: BorderSide(
                      color: const Color(0xFF2763eb).withOpacity(0.3),
                    ),
                    label: Text(
                      food,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (recommendation.portionAdvice.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2763eb).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.restaurant_menu_outlined,
                            size: 16, color: Color(0xFF2763eb)),
                        SizedBox(width: 8),
                        Text(
                          'Portion Advice',
                          style: TextStyle(
                            color: Color(0xFF2763eb),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recommendation.portionAdvice,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (recommendation.timingAdvice.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2763eb).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 16, color: Color(0xFF2763eb)),
                        SizedBox(width: 8),
                        Text(
                          'Timing Recommendation',
                          style: TextStyle(
                            color: Color(0xFF2763eb),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recommendation.timingAdvice,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (recommendation.scientificReason.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2763eb).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.science_outlined,
                            size: 16, color: Color(0xFF2763eb)),
                        SizedBox(width: 8),
                        Text(
                          'Scientific Explanation',
                          style: TextStyle(
                            color: Color(0xFF2763eb),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recommendation.scientificReason,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
