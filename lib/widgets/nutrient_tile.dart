import 'package:flutter/material.dart';

class NutrientGrid extends StatelessWidget {
  final List<NutrientData> nutrients;

  const NutrientGrid({
    super.key,
    required this.nutrients,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: nutrients.map((nutrient) => NutrientTile(
        nutrient: nutrient.name,
        healthSign: nutrient.healthSign,
        quantity: nutrient.quantity,
        insight: nutrient.insight,
      )).toList(),
    );
  }
}

class NutrientTile extends StatefulWidget {
  final String nutrient;
  final String healthSign;
  final String quantity;
  final String? insight;

  const NutrientTile({
    super.key,
    required this.nutrient,
    required this.healthSign,
    required this.quantity,
    this.insight,
  });

  @override
  State<NutrientTile> createState() => _NutrientTileState();
}

class _NutrientTileState extends State<NutrientTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    Color startColor;
    Color endColor;

    switch (widget.healthSign) {
      case "Good":
        startColor = Colors.green.shade300;
        endColor = Colors.green;
        break;
      case "Bad":
        startColor = Colors.red.shade300;
        endColor = Colors.red;
        break;
      default: // "Moderate"
        startColor = Colors.amber.shade300;
        endColor = Colors.amber;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        width: _isExpanded ? MediaQuery.of(context).size.width : null,
        constraints: BoxConstraints(
          maxWidth: _isExpanded ? double.infinity : 150, // Adjust this value for desired collapsed width
          minWidth: 120, // Minimum width when collapsed
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: const [
            BoxShadow(
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(seconds: 1),
          curve: Curves.fastOutSlowIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 11.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.nutrient,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.quantity,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_sharp
                          : Icons.keyboard_arrow_down_sharp,
                      color: Colors.white,
                      size: 12.0,
                    ),
                  ],
                ),
                if (_isExpanded && widget.insight != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      widget.insight!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Data model for nutrient information
class NutrientData {
  final String name;
  final String healthSign;
  final String quantity;
  final String? insight;

  NutrientData({
    required this.name,
    required this.healthSign,
    required this.quantity,
    this.insight,
  });
}