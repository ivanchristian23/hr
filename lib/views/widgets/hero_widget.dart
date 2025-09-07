import 'package:flutter/material.dart';

class HeroWidget extends StatelessWidget {
  const HeroWidget({super.key, required this.title, this.nextPage});

  final String title;
  final Widget? nextPage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: nextPage != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return nextPage!;
                  },
                ),
              );
            }
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Hero(
            tag: 'hero1',
            child: SizedBox(
              width: 400,
              child: AspectRatio(
                aspectRatio: 4 / 3, // Adjust the aspect ratio as needed
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Image.asset(
                    'assets/images/bg-2.jpg',
                    fit: BoxFit.contain,
                    // color: Colors.teal,
                    // colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 1.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 20.0,
            ),
          ),
        ],
      ),
    );
  }
}
