import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

// ✅ [Added] ThemeController: handles dark/light mode toggle with persistent storage
class ThemeController extends GetxController {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  late RxBool isDarkMode;

  @override
  void onInit() {
    super.onInit();
    // ✅ [Added] Read saved preference, default to false (light)
    isDarkMode = RxBool(_box.read(_key) ?? false);
  }

  // ✅ [Added] Toggle and persist
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _box.write(_key, isDarkMode.value);
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}