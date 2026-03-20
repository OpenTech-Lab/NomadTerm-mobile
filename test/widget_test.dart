import 'package:flutter_test/flutter_test.dart';

import 'package:nomadterm/main.dart';
import 'package:nomadterm/providers/settings_provider.dart';

void main() {
  testWidgets('Shows ConnectScreen when no saved config', (tester) async {
    final settings = SettingsProvider();
    await tester.pumpWidget(NomadTermApp(savedConfig: null, settings: settings));
    expect(find.text('nomadterm'), findsOneWidget);
  });
}
