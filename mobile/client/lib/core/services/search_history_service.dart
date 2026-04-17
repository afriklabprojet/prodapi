import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer l'historique de recherche local
class SearchHistoryService {
  static const String _key = 'search_history';
  static const int _maxItems = 8;

  final SharedPreferences _prefs;

  SearchHistoryService(this._prefs);

  List<String> getHistory() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    return List<String>.from(json.decode(raw));
  }

  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;

    final history = getHistory();
    history.remove(trimmed);
    history.insert(0, trimmed);
    if (history.length > _maxItems) {
      history.removeRange(_maxItems, history.length);
    }
    await _prefs.setString(_key, json.encode(history));
  }

  Future<void> removeSearch(String query) async {
    final history = getHistory();
    history.remove(query);
    await _prefs.setString(_key, json.encode(history));
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_key);
  }
}
