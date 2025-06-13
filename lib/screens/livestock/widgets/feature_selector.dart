import 'package:bovitrack/core/utils/constants.dart';
import 'package:flutter/material.dart';


class FeatureSelector extends StatelessWidget {
  final LivestockFeature selectedFeature;
  final Function(LivestockFeature) onFeatureSelected;

  const FeatureSelector({
    Key? key,
    required this.selectedFeature,
    required this.onFeatureSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Feature',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var feature in LivestockFeature.values) ...[
              _buildFeatureButton(context, feature),
              if (feature != LivestockFeature.values.last) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureButton(BuildContext context, LivestockFeature feature) {
    final isSelected = selectedFeature == feature;
    final primaryColor = const Color.fromARGB(255, 0, 255, 115);
    
    return Expanded(
      child: InkWell(
        onTap: () => onFeatureSelected(feature),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : const Color.fromARGB(255, 197, 254, 222),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primaryColor : const Color.fromARGB(255, 0, 200, 83),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Text(
            feature.displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}