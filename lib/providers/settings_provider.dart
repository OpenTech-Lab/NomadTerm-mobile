import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';

/// Holds the current [AppSettings] and persists changes.
class SettingsProvider extends ChangeNotifier {
  final _service = SettingsService();
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;
  double get uiFontSize   => _settings.uiFontSize;
  double get termFontSize => _settings.termFontSize;

  Future<void> load() async {
    _settings = await _service.load();
    notifyListeners();
  }

  Future<void> setUiFontSize(double v) async {
    _settings = _settings.copyWith(uiFontSize: v);
    notifyListeners();
    await _service.save(_settings);
  }

  Future<void> setTermFontSize(double v) async {
    _settings = _settings.copyWith(termFontSize: v);
    notifyListeners();
    await _service.save(_settings);
  }
}
