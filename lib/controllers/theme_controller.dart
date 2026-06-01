// Theme Controller - Manage light and dark mode preference with persistent storage

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  late RxBool isDarkMode;

  @override
  void onInit() {
    super.onInit();
    // Read saved preference on startup, defaulting to light mode
    isDarkMode = RxBool(_box.read(_key) ?? false);
  }

  // Toggle theme mode and persist the new preference
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _box.write(_key, isDarkMode.value);
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}