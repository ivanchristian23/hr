import 'package:flutter/material.dart';

class CardTile extends StatelessWidget {
  final String title;
  final String value;

  const CardTile({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
