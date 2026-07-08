import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/language_provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const UzhavanAIApp(),
    ),
  );
}

class UzhavanAIApp extends StatelessWidget {
  const UzhavanAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UzhavanAI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const DashboardScreen(),
    );
  }
}
