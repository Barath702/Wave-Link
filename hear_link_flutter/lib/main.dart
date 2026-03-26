import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaveLink Test',
      debugShowCheckedModeBanner: false,
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'WAVELINK',
              style: TextStyle(
                color: Color(0xFF00D4FF),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'If you see this, the app is working!',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
