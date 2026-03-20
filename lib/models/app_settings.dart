/// User-adjustable app settings.
class AppSettings {
  /// Font size for all UI text (connect/session screens). Default 14.
  final double uiFontSize;

  /// Font size inside the xterm terminal view. Default 15.
  final double termFontSize;

  const AppSettings({
    this.uiFontSize = 14.0,
    this.termFontSize = 15.0,
  });

  AppSettings copyWith({double? uiFontSize, double? termFontSize}) => AppSettings(
        uiFontSize: uiFontSize ?? this.uiFontSize,
        termFontSize: termFontSize ?? this.termFontSize,
      );
}
