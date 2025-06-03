import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthTip {
  final String emoji;
  final String text;

  HealthTip({required this.emoji, required this.text});

  factory HealthTip.fromJson(Map<String, dynamic> json) {
    return HealthTip(
      emoji: json['emoji'],
      text: json['text'],
    );
  }
}

class HealthTipWidget extends StatefulWidget {
  const HealthTipWidget({super.key});

  @override
  State<HealthTipWidget> createState() => _HealthTipWidgetState();
}

class _HealthTipWidgetState extends State<HealthTipWidget> {
  HealthTip _currentTip = HealthTip(emoji: "", text: "Loading health tip...");
  List<HealthTip> _allTips = [];
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    try {
      final String response = await rootBundle.loadString('assets/tips.json');
      final List<dynamic> data = json.decode(response);
      _allTips = data.map((tipJson) => HealthTip.fromJson(tipJson)).toList();
      await _loadStoredTip();
    } catch (e) {
      setState(() {
        _currentTip = HealthTip(emoji: "X", text: "Failed to load tips. Please try again.");
      });
    }
  }

  Future<void> _loadStoredTip() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastUpdateDate = prefs.getString('lastUpdateDate');
    final int? storedIndex = prefs.getInt('currentTipIndex');
    final String today = DateTime.now().toIso8601String().split('T')[0]; // Get only the date part

    if (lastUpdateDate == today && storedIndex != null && storedIndex >= 0 && storedIndex < _allTips.length) {
      // Use the stored tip if it's from today
      setState(() {
        _currentTip = _allTips[storedIndex];
        _currentIndex = storedIndex;
      });
    } else {
      // Otherwise, get a new random tip
      _getRandomTip();
      // Save the new tip and date
      prefs.setString('lastUpdateDate', today);
      prefs.setInt('currentTipIndex', _currentIndex);
    }
  }

  void _getRandomTip() {
    if (_allTips.isEmpty) return;

    int newIndex;
    do {
      newIndex = Random().nextInt(_allTips.length);
    } while (newIndex == _currentIndex && _allTips.length > 1);

    setState(() {
      _currentTip = _allTips[newIndex];
      _currentIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0x90FFFFFF),
      margin: const EdgeInsets.all(16),
      elevation: 9,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: "${_currentTip.emoji} ",
                    style: const TextStyle(fontSize: 40),
                  ),
                  TextSpan(text: _currentTip.text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}