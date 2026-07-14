import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_state.dart';

class LocalStorageService {
  LocalStorageService(this._preferences);

  static const stateKey = 'coleggo_app_state_v1';
  final SharedPreferences _preferences;

  Future<AppState> load() async {
    final encoded = _preferences.getString(stateKey);
    if (encoded == null) return const AppState();
    try {
      return AppState.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
    } on Object {
      return const AppState();
    }
  }

  Future<void> save(AppState state) async {
    await _preferences.setString(stateKey, jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    await _preferences.remove(stateKey);
  }
}
