import 'package:flutter/material.dart';

class MilkColorPicker extends StatelessWidget {
  final Function(int) onColorSelected;
  final int selectedColor;

  const MilkColorPicker({
    Key? key,
    required this.onColorSelected,
    required this.selectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<int> colorValues = [240, 245, 250, 255];
    final Color primaryColor = const Color.fromARGB(255, 140, 84, 252);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.color_lens, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Select Milk Color',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: colorValues.map((colorValue) => Flexible(
                  child: GestureDetector(
                    onTap: () => onColorSelected(colorValue),
                    child: Container(
                      width: 55, // Reduced from 60
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 2), // Reduced from 4
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(colorValue, colorValue, colorValue, 1),
                        border: Border.all(
                          color: selectedColor == colorValue 
                              ? primaryColor
                              : Colors.transparent,
                          width: selectedColor == colorValue ? 3 : 0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}