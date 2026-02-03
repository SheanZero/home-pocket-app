import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/warm_japanese_theme.dart';
import 'generated/app_localizations.dart';

class HomePocketApp extends ConsumerWidget {
  const HomePocketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Home Pocket',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: WarmJapaneseTheme.lightTheme,
      darkTheme: WarmJapaneseTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Localization
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      locale: const Locale('ja'), // Default to Japanese

      // Router
      routerConfig: router,
    );
  }
}
