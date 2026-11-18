import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_thrive/screens/calendar/calendar_screen.dart';
import 'package:uni_thrive/state/app_state.dart';

void main() {
  testWidgets('Search button does not freeze', (WidgetTester tester) async {
    final appState = AppState();
    
    await tester.pumpWidget(
      AppStateProvider(
        appState: appState,
        child: const MaterialApp(
          home: CalendarScreen(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    final moreMenu = find.byIcon(Icons.more_vert_rounded);
    expect(moreMenu, findsOneWidget);
    
    await tester.tap(moreMenu);
    await tester.pumpAndSettle();
    
    final searchOption = find.text('Buscar');
    expect(searchOption, findsOneWidget);

    await tester.tap(searchOption);
    await tester.pumpAndSettle();
    
    expect(find.byType(TextField), findsOneWidget);
  });
}
