import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'theme.dart';
import 'ui/home_page.dart';

class ConilletAmagatApp extends StatelessWidget {
  const ConilletAmagatApp({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final strings = app.strings;
        return MaterialApp(
          title: strings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: app.themeMode,
          locale: app.locale,
          supportedLocales: const [Locale('es'), Locale('ca')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => AppScope(
            state: app,
            child: DefaultTextStyle(
              style:
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              child: child!,
            ),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}
