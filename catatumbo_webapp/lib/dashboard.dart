import 'package:flutter/material.dart';
import 'navbar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      body: const Center(
        child: Text("Dashboard content here"),
      ),
    );
  }
}
