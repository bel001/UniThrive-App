import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppStateRepository {
  static const storageKey = 'unithrive_state_v2';

  AppStateRepository._(this._prefs);

  final SharedPreferences _prefs;
  Future<void> _writeQueue = Future.value();

  static Future<AppStateRepository> create() async {
    return AppStateRepository._(await SharedPreferences.getInstance());
  }

  Map<String, dynamic>? load() {
    final stored = _prefs.getString(storageKey);
    if (stored == null) return null;
    final decoded = jsonDecode(stored);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Future<void> save(Map<String, dynamic> state) {
    final encoded = jsonEncode(state);
    _writeQueue = _writeQueue.then(
      (_) => _prefs.setString(storageKey, encoded),
      onError: (_) => _prefs.setString(storageKey, encoded),
    );
    return _writeQueue;
  }
}
