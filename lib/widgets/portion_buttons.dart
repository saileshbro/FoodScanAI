import 'package:flutter/material.dart';
import 'package:read_the_label/logic.dart';

class PortionButton extends StatelessWidget {
  final BuildContext context;
  final double portion;
  final String label;
  final Logic logic;
  final Function(void Function()) setState;

  const PortionButton({
    super.key,
    required this.context,
    required this.portion,
    required this.label,
    required this.logic,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = (logic.sliderValue / logic.getServingSize()) == portion;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? const Color(0xff2563eb) : const Color(0xff1f2937),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        setState(() {
          logic.updateSliderValue(logic.getServingSize() * portion, setState);
        });
      },
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins')),
    );
  }
}

class CustomPortionButton extends StatelessWidget {
  final Logic logic;
  final Function(void Function()) setState;

  const CustomPortionButton({
    super.key,
    required this.logic,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
            content: TextField(
              keyboardType: TextInputType.number,
              style:
                  const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              decoration: const InputDecoration(
                hintText: 'Enter amount in grams',
                hintStyle: TextStyle(color: Colors.white54),
              ),
              onChanged: (value) {
                logic.updateSliderValue(
                    double.tryParse(value) ?? 0.0, setState);
              },
            ),
            actions: [
              TextButton(
                child: const Text('OK',
                    style:
                        TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
      child: const Text("Custom",
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
    );
  }
}
