import 'package:flutter/material.dart';

class PlaceholderImage extends StatelessWidget {
  const PlaceholderImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD9D9D9),
      child: const Center(child: Icon(Icons.image, size: 80, color: Colors.white)),
    );
  }
}
