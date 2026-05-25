import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..loadThreads()..loadSentences()),
      ],
      child: const KothaCollectorApp(),
    ),
  );
}

class KothaCollectorApp extends StatelessWidget {
  const KothaCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kotha Collector',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}