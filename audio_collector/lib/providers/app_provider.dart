import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier {
  List<Directory> threads = [];
  List<String> sentences = [];
  int currentSentenceIndex = 0;

  Future<void> loadThreads() async {
    threads = await StorageService.getAllThreads();
    notifyListeners();
  }

  Future<void> createNewThread(String region, String gender, String name) async {
    await StorageService.createThread(region, gender, name);
    await loadThreads();
  }

  Future<void> loadSentences() async {
    if (sentences.isNotEmpty) return;
    try {
      final String response = await rootBundle.loadString('assets/sentences.json');
      final data = await json.decode(response);
      sentences = List<String>.from(data);
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading sentences: $e");
    }
  }

  void nextSentence() {
    if (currentSentenceIndex < sentences.length - 1) {
      currentSentenceIndex++;
      notifyListeners();
    }
  }

  void previousSentence() {
    if (currentSentenceIndex > 0) {
      currentSentenceIndex--;
      notifyListeners();
    }
  }

  void resetIndex() {
    currentSentenceIndex = 0;
    notifyListeners();
  }
}