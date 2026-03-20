import '../theme.dart';

/// User-adjustable app settings.
class AppSettings {
  /// Font size for all UI text (connect/session screens). Default 14.
  final double uiFontSize;

  /// Font size inside the xterm terminal view. Default 15.
  final double termFontSize;

  /// Active theme index: 0 = Matrix, 1 = Pixel RPG. Default 0.
  final int themeIndex;

  const AppSettings({
    this.uiFontSize = 14.0,
    this.termFontSize = 15.0,
    this.themeIndex = 0,
  });

  AppSettings copyWith({
    double? uiFontSize,
    double? termFontSize,
    int? themeIndex,
  }) =>
      AppSettings(
        uiFontSize: uiFontSize ?? this.uiFontSize,
        termFontSize: termFontSize ?? this.termFontSize,
        themeIndex: themeIndex ?? this.themeIndex,
      );

  AppTheme get appTheme =>
      themeIndex == 1 ? AppTheme.pixelRpg : AppTheme.matrix;
}
