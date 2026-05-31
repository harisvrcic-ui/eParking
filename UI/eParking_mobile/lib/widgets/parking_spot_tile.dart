import 'package:flutter/material.dart';

class ParkingSpotTile extends StatelessWidget {
  const ParkingSpotTile({
    super.key,
    required this.code,
    required this.isAvailable,
    required this.isSelected,
    required this.onTap,
  });

  final String code;
  final bool isAvailable;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color border;
    Color textColor;
    IconData? icon;

    if (isSelected) {
      background = Theme.of(context).colorScheme.primary;
      border = Theme.of(context).colorScheme.primary;
      textColor = Colors.white;
      icon = Icons.check;
    } else if (isAvailable) {
      background = Colors.green.shade50;
      border = Colors.green.shade400;
      textColor = Colors.green.shade800;
    } else {
      background = Colors.red.shade50;
      border = Colors.red.shade300;
      textColor = Colors.red.shade800;
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: isSelected ? 2 : 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(icon, size: 18, color: textColor)
              else
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
              const SizedBox(height: 6),
              Text(
                code,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isAvailable ? 'Slobodno' : 'Zauzeto',
                style: TextStyle(fontSize: 10, color: textColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
