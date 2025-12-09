// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/auth_page.dart';

void main() {
  runApp(const SmartXeroxApp());
}

class SmartXeroxApp extends StatelessWidget {
  const SmartXeroxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Xerox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const AuthPage(),
    );
  }
}
