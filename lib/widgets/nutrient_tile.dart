import 'package:flutter/material.dart';
import 'package:read_the_label/data/dv_values.dart';

class NutrientGrid extends StatefulWidget {
  final List<NutrientData> nutrients;

  const NutrientGrid({
    super.key,
    required this.nutrients,
  });

  @override
  State<NutrientGrid> createState() => _NutrientGridState();
}

class _NutrientGridState extends State<NutrientGrid> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: widget.nutrients
          .map((nutrient) => NutrientTile(
                nutrient: nutrient.name,
                healthSign: nutrient.healthSign,
                quantity: nutrient.quantity,
                insight: nutrient.insight,
              ))
          .toList(),
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

  String _calculateDV() {
    // Find the DV value from nutrientData
    final nutrientInfo = nutrientData.firstWhere(
      (n) => n['Nutrient'] == nutrient,
      orElse: () => {'Current Daily Value': 'NA'},
    );

    if (nutrientInfo['Current Daily Value'] == 'NA') {
      return '';
    }

    try {
      // Extract numeric values
      double dvValue = double.parse(nutrientInfo['Current Daily Value']
          .replaceAll(RegExp(r'[^0-9\.]'), ''));
      double currentValue =
          double.parse(quantity.replaceAll(RegExp(r'[^0-9\.]'), ''));

      // Calculate percentage
      double percentage = (currentValue / dvValue) * 100;
      return '| ${percentage.toStringAsFixed(1)}% DV';
    } catch (e) {
      return '';
    }
  }

  @override
  State<NutrientTile> createState() => _NutrientTileState();
}

class _NutrientTileState extends State<NutrientTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData statusIcon;

    switch (widget.healthSign) {
      case "Good":
        backgroundColor = const Color(0xFF4CAF50).withOpacity(0.15);
        statusIcon = Icons.check_circle_outline;
        break;
      case "Bad":
        backgroundColor = const Color(0xFFFF5252).withOpacity(0.15);
        statusIcon = Icons.warning_outlined;
        break;
      default: // "Moderate"
        backgroundColor = const Color(0xFFFFC107).withOpacity(0.15);
        statusIcon = Icons.info_outline;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
          if (_isExpanded) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        width: _isExpanded ? MediaQuery.of(context).size.width - 32 : null,
        constraints: BoxConstraints(
          maxWidth: _isExpanded ? double.infinity : 170,
          minWidth: 140,
          minHeight: 70, // Add minimum height
          maxHeight: _isExpanded ? 300 : 70,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: widget.healthSign == "Good"
                ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                : widget.healthSign == "Bad"
                    ? const Color(0xFFFF5252).withValues(alpha: 0.3)
                    : const Color(0xFFFFC107).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: SingleChildScrollView(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 20,
                              color: widget.healthSign == "Good"
                                  ? const Color(0xFF4CAF50)
                                  : widget.healthSign == "Bad"
                                      ? const Color(0xFFFF5252)
                                      : const Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.nutrient,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(),
                                      ),
                                      RotationTransition(
                                        turns: Tween(begin: 0.0, end: 0.5)
                                            .animate(_animationController),
                                        child: const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        widget.quantity,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget._calculateDV(),
                                        style: TextStyle(
                                          color: widget.healthSign == "Good"
                                              ? const Color(0xFF4CAF50)
                                              : widget.healthSign == "Bad"
                                                  ? const Color(0xFFFF5252)
                                                  : const Color(0xFFFFC107),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_isExpanded && widget.insight != null)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _isExpanded ? 1.0 : 0.0,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                widget.insight!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.5,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
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
