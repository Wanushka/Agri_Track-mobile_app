import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/firebase_service.dart';

class DeviceProvider with ChangeNotifier {
  Device? _device;
  bool _isLoading = true;

  Device? get device => _device;
  bool get isLoading => _isLoading;

  DeviceProvider() {
    _initializeData();
  }

  void _initializeData() {
    try {
      // Listen to realtime updates
      FirebaseService.getFunction1Stream().listen(
        (data) {
          if (data != null) {
            _device = Device.fromJson(data);
          } else {
            _device = null;
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to manually refresh data if needed
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    _initializeData();
  }
}