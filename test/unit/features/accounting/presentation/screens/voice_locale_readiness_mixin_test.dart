/// Quick task 260706-tm6 (voice-consolidation P0-5): direct tests for
/// VoiceLocaleReadinessMixin — the D-07 cold-start gate that blocks the mic
/// until voiceLocaleIdProvider resolves.
///
/// Coverage (behavior contract):
///   1. provider pending  → isLocaleReady == false (mic gated), no callback.
///   2. AsyncData         → isLocaleReady == true + onVoiceLocaleResolved(locale).
///   3. AsyncError        → isLocaleReady == true (graceful degradation) but
///                          the mirror callback is NOT invoked.
///   4. locale switch     → onVoiceLocaleResolved fires again with the new
///                          value; readiness stays true (single-direction gate,
///                          even through the rebuild's AsyncLoading gap).
///   5. dispose           → the listenManual subscription is closed: no further
///                          callbacks and no exceptions after unmount.
///
/// Riverpod 3 async convention: no bare `container.read(provider.future)` —
/// the provider is observed through the mixin's own listenManual subscription
/// and asserted via widget pumps (CLAUDE.md).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_locale_readiness_mixin.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart'
    show voiceLocaleIdProvider;

/// Mutable locale source for the switch scenario — the override maps this into
/// voiceLocaleIdProvider so flipping the state emits a second AsyncData.
final _localeSource = StateProvider<String>((ref) => 'zh-CN');

class _ReadinessHost extends ConsumerStatefulWidget {
  const _ReadinessHost({required this.resolvedLocales});

  /// Recording sink for onVoiceLocaleResolved invocations.
  final List<String> resolvedLocales;

  @override
  ConsumerState<_ReadinessHost> createState() => _ReadinessHostState();
}

class _ReadinessHostState extends ConsumerState<_ReadinessHost>
    with VoiceLocaleReadinessMixin<_ReadinessHost> {
  @override
  void onVoiceLocaleResolved(String localeId) =>
      widget.resolvedLocales.add(localeId);

  @override
  void initState() {
    super.initState();
    initLocaleReadiness();
  }

  @override
  Widget build(BuildContext context) => Text(
        isLocaleReady ? 'ready' : 'gated',
        textDirection: TextDirection.ltr,
      );
}

void main() {
  testWidgets('pending provider gates the mic: isLocaleReady false, no mirror '
      'callback', (tester) async {
    final resolved = <String>[];
    final completer = Completer<String>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceLocaleIdProvider.overrideWith((ref) => completer.future),
        ],
        child: _ReadinessHost(resolvedLocales: resolved),
      ),
    );
    await tester.pump();

    expect(find.text('gated'), findsOneWidget,
        reason: 'D-07: the mic must stay gated while the locale is pending');
    expect(resolved, isEmpty,
        reason: 'no mirror update before the provider resolves');

    // Resolution flips the gate and fires the mirror exactly once.
    completer.complete('ja-JP');
    await tester.pump();
    await tester.pump();

    expect(find.text('ready'), findsOneWidget);
    expect(resolved, ['ja-JP']);
  });

  testWidgets('warm resolve (AsyncData) unlocks and mirrors the locale',
      (tester) async {
    final resolved = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceLocaleIdProvider.overrideWith((ref) async => 'zh-CN'),
        ],
        child: _ReadinessHost(resolvedLocales: resolved),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('ready'), findsOneWidget);
    expect(resolved, ['zh-CN'],
        reason: 'onVoiceLocaleResolved fires exactly once with the value');
  });

  testWidgets('AsyncError degrades gracefully: mic unlocked, mirror NOT '
      'invoked (host keeps its default fallback)', (tester) async {
    final resolved = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceLocaleIdProvider.overrideWith(
            (ref) => Future<String>.error(StateError('corrupted prefs')),
          ),
        ],
        child: _ReadinessHost(resolvedLocales: resolved),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('ready'), findsOneWidget,
        reason: 'RESEARCH Pitfall 3: an error must not soft-lock the mic');
    expect(resolved, isEmpty,
        reason: 'AsyncError never calls onVoiceLocaleResolved — the host '
            'keeps its default locale fallback');
  });

  testWidgets('locale switch fires the mirror again with the new value; '
      'readiness stays true through the reload gap', (tester) async {
    final resolved = <String>[];
    final overrides = [
      voiceLocaleIdProvider.overrideWith(
        (ref) async => ref.watch(_localeSource),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: _ReadinessHost(resolvedLocales: resolved),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(resolved, ['zh-CN']);
    expect(find.text('ready'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(_ReadinessHost)),
    );
    container.read(_localeSource.notifier).state = 'ja-JP';
    // First pump: provider rebuild passes through AsyncLoading — the gate must
    // NOT regress to gated (single-direction door).
    await tester.pump();
    expect(find.text('ready'), findsOneWidget,
        reason: 'readiness is a one-way gate — a reload never re-locks');
    await tester.pump();

    expect(resolved, ['zh-CN', 'ja-JP'],
        reason: 'the mirror re-fires so the host locale string stays current');
    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('dispose closes the subscription: no callback and no exception '
      'after unmount', (tester) async {
    final resolved = <String>[];
    // Same Override instances reused across both pumpWidget calls so the
    // ProviderScope keeps its container (identity-stable overrides).
    final overrides = [
      voiceLocaleIdProvider.overrideWith(
        (ref) async => ref.watch(_localeSource),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: _ReadinessHost(resolvedLocales: resolved),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(resolved, ['zh-CN']);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(_ReadinessHost)),
    );

    // Unmount the host (same scope/container stays alive).
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const SizedBox()),
    );

    // A post-dispose provider emission must be a no-op (subscription closed).
    container.read(_localeSource.notifier).state = 'en-US';
    await tester.pump();
    await tester.pump();

    expect(resolved, ['zh-CN'],
        reason: 'no onVoiceLocaleResolved after dispose — the listenManual '
            'subscription was closed without leaking');
    expect(tester.takeException(), isNull);
  });
}
