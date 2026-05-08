import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_model.dart';
import 'audio_cache.dart';

class SoundsProvider extends ChangeNotifier {
  List<SoundModel> _builtInSounds = [];
  List<SoundModel> _userSounds = [];
  Set<String> _favoriteIds = {};

  List<SoundModel> get builtInSounds => _builtInSounds;
  List<SoundModel> get userSounds => _userSounds;
  Set<String> get favoriteIds => _favoriteIds;

  List<SoundModel> get allSounds => [..._builtInSounds, ..._userSounds];

  List<SoundModel> get favoriteSounds =>
      allSounds.where((s) => _favoriteIds.contains(s.id)).toList();

  bool isFavorite(String id) => _favoriteIds.contains(id);

  List<String> get allTags {
    final tags = <String>{};
    for (final s in allSounds) {
      tags.addAll(s.tags);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  SoundsProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadBuiltInSounds();
    await _loadUserSounds();
    await _loadFavorites();
  }

  Future<void> _loadBuiltInSounds() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/sounds_config.json');
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      _builtInSounds = jsonList.map((e) {
        final file = e['file'] as String;
        final id = (e['id'] as String?) ?? file;
        return SoundModel(
          id: id,
          name: e['name'] as String,
          nameHe: e['name_he'] as String?,
          filePath: 'assets/sounds/$file',
          tags: (e['tags'] as List<dynamic>?)?.cast<String>() ?? [],
          isBuiltIn: true,
        );
      }).toList();
      notifyListeners();
      final assetPaths = _builtInSounds.map((s) => s.filePath).toList();
      await AudioCacheManager().preloadAll(assetPaths);
    } catch (_) {}
  }

  Future<void> _loadUserSounds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('user_sounds');
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      _userSounds = jsonList.map((e) => SoundModel.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];
    _favoriteIds = list.toSet();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favoriteIds.toList());
  }

  Future<void> toggleFavorite(String id) async {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
    await _saveFavorites();
  }

  Future<void> _saveUserSounds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_userSounds.map((s) => s.toJson()).toList());
    await prefs.setString('user_sounds', jsonStr);
  }

  Future<void> addSound(SoundModel sound) async {
    _userSounds.add(sound);
    notifyListeners();
    await _saveUserSounds();
  }

  Future<void> removeSound(String id) async {
    _userSounds.removeWhere((s) => s.id == id);
    _favoriteIds.remove(id);
    notifyListeners();
    await _saveUserSounds();
    await _saveFavorites();
  }

  Future<void> renameSound(String id, String newName) async {
    final index = _userSounds.indexWhere((s) => s.id == id);
    if (index != -1) {
      final old = _userSounds[index];
      _userSounds[index] = SoundModel(
        id: old.id,
        name: newName,
        filePath: old.filePath,
        tags: old.tags,
        isBuiltIn: false,
      );
      notifyListeners();
      await _saveUserSounds();
    }
  }

  Future<void> updateSoundTags(String id, List<String> newTags) async {
    final index = _userSounds.indexWhere((s) => s.id == id);
    if (index != -1) {
      final old = _userSounds[index];
      _userSounds[index] = SoundModel(
        id: old.id,
        name: old.name,
        filePath: old.filePath,
        tags: newTags,
        isBuiltIn: false,
      );
      notifyListeners();
      await _saveUserSounds();
    }
  }

  List<SoundModel> getSoundsByTag(String? tag) {
    if (tag == null) return allSounds;
    return allSounds.where((s) => s.tags.contains(tag)).toList();
  }
}
