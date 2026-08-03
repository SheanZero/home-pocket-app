import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/family_invite_ticket.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets('keeps the complete six-digit code visible on a 320dp screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: FamilyInviteTicket(
              code: '256 931',
              expiresAt: DateTime(2026, 8, 3, 12),
              now: () => DateTime(2026, 8, 3, 11, 50),
              onCopy: () {},
              onRegenerate: () {},
              isRefreshing: false,
            ),
          ),
        ),
        locale: const Locale('zh'),
      ),
    );

    final code = find.byKey(const Key('family-invite-ticket-code'));
    expect(code, findsOneWidget);
    expect(find.text('256 931'), findsOneWidget);
    expect(tester.widget<Text>(code).style?.fontSize, 45);
    expect(tester.widget<Text>(code).overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);

    final surface = find.byKey(const Key('family-invite-ticket-surface'));
    expect(tester.getSize(surface).width, 280);
    expect(tester.getSize(surface).height, lessThanOrEqualTo(270));
    expect(
      tester.getCenter(find.text('家庭邀请码')).dx,
      closeTo(tester.getCenter(surface).dx, 0.5),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('family-invite-ticket-code-fit')))
          .width,
      lessThanOrEqualTo(280),
    );
  });

  testWidgets('uses a scalloped physical ticket with shadow and 44dp actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: SizedBox(
            width: 350,
            child: FamilyInviteTicket(
              code: '256 931',
              expiresAt: DateTime(2026, 8, 3, 12),
              now: () => DateTime(2026, 8, 3, 11, 55),
              onCopy: () {},
              onRegenerate: () {},
              isRefreshing: false,
            ),
          ),
        ),
        locale: const Locale('zh'),
      ),
    );

    final shape = tester.widget<PhysicalShape>(
      find.byKey(const Key('family-invite-ticket-physical-shape')),
    );
    expect(shape.elevation, greaterThan(0));
    expect(shape.clipper, isA<FamilyInviteTicketClipper>());
    expect(
      find.byKey(const Key('family-invite-ticket-border-painter')),
      findsOneWidget,
    );

    expect(
      tester.getSize(find.byKey(const Key('family-invite-ticket-copy'))).height,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('family-invite-ticket-regenerate')))
          .height,
      greaterThanOrEqualTo(44),
    );

    final surface = find.byKey(const Key('family-invite-ticket-surface'));
    final surfaceRect = tester.getRect(surface);
    expect(
      tester.getCenter(find.byKey(const Key('create-group-copy-code'))).dx,
      closeTo(surfaceRect.left + surfaceRect.width * 0.25, 0.5),
    );
    expect(
      tester
          .getCenter(find.byKey(const Key('create-group-regenerate-code')))
          .dx,
      closeTo(surfaceRect.left + surfaceRect.width * 0.75, 0.5),
    );

    final divider = find.byKey(
      const Key('family-invite-ticket-action-divider'),
    );
    expect(divider, findsOneWidget);
    final actionRegionCenterY =
        (tester.getRect(divider).bottom + surfaceRect.bottom) / 2;
    expect(
      tester.getCenter(find.byKey(const Key('create-group-copy-code'))).dy,
      closeTo(actionRegionCenterY, 0.5),
    );
    expect(
      tester
          .getCenter(find.byKey(const Key('create-group-regenerate-code')))
          .dy,
      closeTo(actionRegionCenterY, 0.5),
    );
  });
}
