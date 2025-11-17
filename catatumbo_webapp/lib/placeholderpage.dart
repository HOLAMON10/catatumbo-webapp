import 'package:flutter/material.dart';
import 'navbar.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      body: Center(
        child: Text(
          "$title Page (not built yet)",
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
