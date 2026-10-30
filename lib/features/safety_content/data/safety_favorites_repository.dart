import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final safetyFavoritesProvider =
    StateNotifierProvider<SafetyFavoritesController, Set<String>>((ref) {
  return SafetyFavoritesController()..load();
});

class SafetyFavoritesController extends StateNotifier<Set<String>> {
  SafetyFavoritesController() : super(<String>{});

  static const _key = 'protegeela.safety_favorites.v1';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = {...?prefs.getStringList(_key)};
  }

  Future<void> toggle(String id) async {
    state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList()..sort());
  }
}
