import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortField { name, duration }

enum SortDirection { asc, desc }

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode;
  bool _groupByCategory;
  SortField _sortField;
  SortDirection _sortDirection;

  SettingsProvider({
    required bool isDarkMode,
    required bool groupByCategory,
    required SortField sortField,
    required SortDirection sortDirection,
  }) : _isDarkMode = isDarkMode,
       _groupByCategory = groupByCategory,
       _sortField = sortField,
       _sortDirection = sortDirection;

  bool get isDarkMode => _isDarkMode;
  bool get groupByCategory => _groupByCategory;
  SortField get sortField => _sortField;
  SortDirection get sortDirection => _sortDirection;

  static Future<SettingsProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsProvider(
      isDarkMode: prefs.getBool('isDarkMode') ?? true,
      groupByCategory: prefs.getBool('groupByCategory') ?? false,
      sortField: SortField.values[prefs.getInt('sortField') ?? 0],
      sortDirection: SortDirection.values[prefs.getInt('sortDirection') ?? 0],
    );
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> setGroupByCategory(bool value) async {
    _groupByCategory = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('groupByCategory', value);
  }

  Future<void> setSortField(SortField field) async {
    _sortField = field;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sortField', field.index);
  }

  Future<void> setSortDirection(SortDirection dir) async {
    _sortDirection = dir;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sortDirection', dir.index);
  }
}
