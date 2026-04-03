import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('creates with required fields', () {
      final now = DateTime(2026, 4, 3, 10, 0);
      final profile = UserProfile(
        id: 'profile_001',
        displayName: 'Takashi',
        avatarEmoji: '🐱',
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.id, 'profile_001');
      expect(profile.displayName, 'Takashi');
      expect(profile.avatarEmoji, '🐱');
      expect(profile.avatarImagePath, isNull);
      expect(profile.createdAt, now);
      expect(profile.updatedAt, now);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime(2026, 4, 3, 10, 0);
      final profile = UserProfile(
        id: 'profile_001',
        displayName: 'Takashi',
        avatarEmoji: '🐱',
        avatarImagePath: '/tmp/avatar.png',
        createdAt: now,
        updatedAt: now,
      );

      final restored = UserProfile.fromJson(profile.toJson());

      expect(restored, profile);
    });

    test('copyWith updates selected fields', () {
      final now = DateTime(2026, 4, 3, 10, 0);
      final profile = UserProfile(
        id: 'profile_001',
        displayName: 'Takashi',
        avatarEmoji: '🐱',
        createdAt: now,
        updatedAt: now,
      );

      final updated = profile.copyWith(
        displayName: 'Yukiko',
        avatarEmoji: '🌸',
      );

      expect(updated.displayName, 'Yukiko');
      expect(updated.avatarEmoji, '🌸');
      expect(updated.id, 'profile_001');
    });
  });
}
