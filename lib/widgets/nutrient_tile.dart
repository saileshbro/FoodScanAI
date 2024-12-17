import 'package:flutter/material.dart';

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
  double _containerHeight = 30.0; // Initial height
  double _paddingVertical = 5.0; // Initial padding

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
          _containerHeight =
              _isExpanded ? 80.0 : 30.0; // Adjust expanded height as needed
          _paddingVertical = _isExpanded ? 10.0 : 5.0;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        padding:
            EdgeInsets.symmetric(vertical: _paddingVertical, horizontal: 11.0),
        height: _containerHeight, // Assign container height here
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
        child: SingleChildScrollView(
          child: _isExpanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.nutrient,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.quantity,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_up_sharp,
                          color: Colors.white,
                          size: 12.0,
                        ),
                      ],
                    ),
                    if (widget.insight != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          widget.insight!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.justify,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.nutrient,
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.quantity,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_sharp,
                      color: Colors.white,
                      size: 12.0,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
