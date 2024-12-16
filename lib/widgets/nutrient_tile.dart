import 'package:flutter/material.dart';

class NutrientTile extends StatelessWidget {
  final String nutrient;
  final bool isHigh;
  final String quantity;

  const NutrientTile({
    Key? key,
    required this.nutrient,
    required this.isHigh,
    required this.quantity,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10),
      child: Container(
        padding: const EdgeInsets.only(top: 10.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              colors: isHigh
                  ? [Colors.red.shade300, Colors.red]
                  : [Colors.green.shade300, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: const [
              BoxShadow(
                spreadRadius: 3, // Spread radius
                blurRadius: 5, // Blur radius
                offset: Offset(0, 5), // Offset from the widget
              ),
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nutrient,
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 30),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  quantity,
                  style: const TextStyle(color: Colors.white, fontSize: 32),
                ),
                Icon(
                  isHigh ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.white,
                  size: 32.0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
