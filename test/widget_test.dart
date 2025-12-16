import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_thrive/main.dart';
import 'package:uni_thrive/state/app_state.dart';

void main() {
  testWidgets('App arranca sin errores', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(AppStateProvider(appState: appState, child: const UniThriveApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
