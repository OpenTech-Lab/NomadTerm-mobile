import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../theme.dart';

/// Holds the current [AppSettings] and persists changes.
class SettingsProvider extends ChangeNotifier {
  final _service = SettingsService();
  AppSettings _settings = const AppSettings();

  AppSettings get settings    => _settings;
  double get uiFontSize       => _settings.uiFontSize;
  double get termFontSize     => _settings.termFontSize;
  AppTheme get appTheme       => _settings.appTheme;
  NomadTheme get nomadTheme   => appTheme == AppTheme.pixelRpg
      ? PixelRpgTheme.instance
      : MatrixTheme.instance;

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

  Future<void> setTheme(AppTheme theme) async {
    _settings = _settings.copyWith(
      themeIndex: theme == AppTheme.pixelRpg ? 1 : 0,
    );
    notifyListeners();
    await _service.save(_settings);
  }
}
