// routine_provider.dart
import 'package:flutter/material.dart';
import 'package:skinsense/models/product.dart';
import 'package:skinsense/services/database_helper.dart';

class RoutineProvider with ChangeNotifier {
  List<Product> _routine = [];

  List<Product> get routine => _routine;

  Future<void> addToRoutine(Product product) async {
    try {
      await DatabaseHelper.instance.addToUserRoutine(product);
      _routine.add(product);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to routine: $e');
      rethrow;
    }
  }

  Future<void> removeFromRoutine(int productId) async {
    try {
      await DatabaseHelper.instance.removeFromUserRoutine(productId);
      _routine.removeWhere((product) => product.id == productId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from routine: $e');
      rethrow;
    }
  }

  Future<void> loadRoutine() async {
    try {
      _routine = await DatabaseHelper.instance.fetchUserRoutineProducts();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading routine: $e');
      rethrow;
    }
  }
}