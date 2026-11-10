import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas/providers/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('La localización del calendario está en español', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        supportedLocales: [Locale('es')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: _SpanishMonthLabel()),
      ),
    );

    expect(find.text('noviembre de 2026'), findsOneWidget);
  });

  testWidgets('La personalización actualiza el color y el modo oscuro', (
    tester,
  ) async {
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeProvider,
        child: Consumer<ThemeProvider>(
          builder: (context, theme, _) => MaterialApp(
            theme: ThemeData(
              colorSchemeSeed: theme.seed,
              brightness: theme.isDark ? Brightness.dark : Brightness.light,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: Text(
                  'Gestor de Tareas',
                  key: const ValueKey('theme-state'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final lightPrimary = tester
        .widget<Text>(find.byKey(const ValueKey('theme-state')))
        .style!
        .color;
    expect(themeProvider.isDark, isFalse);

    themeProvider.setColor(Colors.teal);
    await tester.pumpAndSettle();
    final tealPrimary = tester
        .widget<Text>(find.byKey(const ValueKey('theme-state')))
        .style!
        .color;
    expect(tealPrimary, isNot(lightPrimary));

    themeProvider.toggleDark();
    await tester.pumpAndSettle();
    expect(themeProvider.isDark, isTrue);
    expect(
      Theme.of(tester.element(find.byKey(const ValueKey('theme-state'))))
          .brightness,
      Brightness.dark,
    );
  });
}

class _SpanishMonthLabel extends StatelessWidget {
  const _SpanishMonthLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      MaterialLocalizations.of(context).formatMonthYear(DateTime(2026, 11)),
    );
  }
}
