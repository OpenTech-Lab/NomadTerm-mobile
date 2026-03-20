import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_settings.dart';

/// Persists [AppSettings] via flutter_secure_storage.
class SettingsService {
  static const _storage = FlutterSecureStorage();
  static const _keyUiFontSize   = 'settings.uiFontSize';
  static const _keyTermFontSize = 'settings.termFontSize';

  Future<AppSettings> load() async {
    final ui   = await _storage.read(key: _keyUiFontSize);
    final term = await _storage.read(key: _keyTermFontSize);
    return AppSettings(
      uiFontSize:   double.tryParse(ui   ?? '') ?? 14.0,
      termFontSize: double.tryParse(term ?? '') ?? 15.0,
    );
  }

  Future<void> save(AppSettings s) async {
    await _storage.write(key: _keyUiFontSize,   value: s.uiFontSize.toString());
    await _storage.write(key: _keyTermFontSize, value: s.termFontSize.toString());
  }
}
