import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_thrive/screens/calendar/calendar_screen.dart';
import 'package:uni_thrive/state/app_state.dart';

void main() {
  testWidgets('Search button does not freeze', (WidgetTester tester) async {
    final appState = AppState();
    await appState.initialize();
    
    await tester.pumpWidget(
      AppStateProvider(
        appState: appState,
        child: MaterialApp(
          home: const CalendarScreen(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    final searchButton = find.byTooltip('Buscar');
    expect(searchButton, findsWidgets);
    
    await tester.tap(searchButton.first);
    await tester.pump();
    await tester.pumpAndSettle();
    
    expect(find.byType(TextField), findsOneWidget); // The search sheet should be up
  });
}
