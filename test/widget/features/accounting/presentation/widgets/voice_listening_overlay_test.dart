// Widget test for VoiceListeningOverlay (quick task 260622-nhs Task 2).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/voice_listening_overlay.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/voice_waveform.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets(
    'renders transcript, localized listening title + release hint, and a waveform',
    (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const Scaffold(
            body: Stack(
              children: [
                VoiceListeningOverlay(
                  transcript: '拿铁 一千二百八',
                  soundLevel: 0.6,
                ),
              ],
            ),
          ),
          locale: const Locale('zh'),
        ),
      );
      await tester.pump();

      final l10n = S.of(tester.element(find.byType(VoiceListeningOverlay)));

      expect(find.text('拿铁 一千二百八'), findsOneWidget);
      expect(find.text(l10n.listeningTitle), findsOneWidget);
      expect(find.text(l10n.releaseToFill), findsOneWidget);
      expect(find.byType(VoiceWaveform), findsOneWidget);
    },
  );
}
