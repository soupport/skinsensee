// tips_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TipsProvider extends ChangeNotifier {
  bool _showTips = true;
  String _currentTip = "";
  List<String> _tips = [];
  Timer? _tipTimer;
  static const String _prefKey = 'showTips';

  bool get showTips => _showTips;
  String get currentTip => _currentTip;
  List<String> get tips => _tips;

  TipsProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadPreferences();
    await _loadTips();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showTips = prefs.getBool(_prefKey) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tips preference: $e');
      _showTips = true;
      notifyListeners();
    }
  }

  Future<void> _loadTips() async {
    try {
      final String tipsData = await rootBundle.loadString('assets/messages/home_page_tips.txt');
      _tips = tipsData.split('\n').where((tip) => tip.trim().isNotEmpty).toList();

      if (_tips.isNotEmpty) {
        _currentTip = _tips[0];
        if (_showTips) {
          _startTipTimer();
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tips: $e');
      _tips = [];
      _currentTip = "";
      notifyListeners();
    }
  }

  void _startTipTimer() {
    _tipTimer?.cancel();
    if (!_showTips || _tips.isEmpty) return;

    _tipTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _rotateTip();
    });
  }

  void _rotateTip() {
    if (_tips.isEmpty) return;

    final currentIndex = _tips.indexOf(_currentTip);
    final nextIndex = (currentIndex + 1) % _tips.length;
    _currentTip = _tips[nextIndex];
    notifyListeners();
  }

  Future<void> toggleTips(bool value) async {
    if (_showTips == value) return;

    _showTips = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);

      if (value) {
        if (_tips.isEmpty) {
          await _loadTips();
        } else {
          _startTipTimer();
        }
      } else {
        _tipTimer?.cancel();
      }
    } catch (e) {
      debugPrint('Error saving tips preference: $e');
      _showTips = !value;
      notifyListeners();
    }
  }

  Future<void> refreshTips() async {
    await _loadTips();
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }
}