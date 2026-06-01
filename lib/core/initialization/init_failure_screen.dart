import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../generated/app_localizations.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Localized fallback screen rendered by main() when AppInitializer.initialize()
/// returns InitFailure. Runs before ProviderScope is mounted — no Riverpod.
class InitFailureScreen extends StatefulWidget {
  const InitFailureScreen({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<InitFailureScreen> createState() => _InitFailureScreenState();
}

class _InitFailureScreenState extends State<InitFailureScreen> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    setState(() => _isRetrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: palette.textSecondary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.initFailedTitle,
                    style: AppTextStyles.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.initFailedMessage,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isRetrying ? null : _handleRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accentPrimary,
                      foregroundColor: palette.textPrimary,
                    ),
                    child: _isRetrying
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation(
                                palette.textPrimary,
                              ),
                            ),
                          )
                        : Text(
                            l10n.initFailedRetry,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A minimal standalone MaterialApp wrapping InitFailureScreen.
/// Used by main() before the real ProviderScope is mounted.
class InitFailureApp extends StatelessWidget {
  const InitFailureApp({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: InitFailureScreen(onRetry: onRetry),
    );
  }
}
