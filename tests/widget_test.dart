import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('Shows ConnectScreen when no saved config', (tester) async {
    // No savedConfig → should render ConnectScreen (has "NomadTerm" title text).
    await tester.pumpWidget(const NomadTermApp(savedConfig: null));
    expect(find.text('NomadTerm'), findsOneWidget);
  });
}
