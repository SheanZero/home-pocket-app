import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/user_profile_dao.dart';

void main() {
  late AppDatabase db;
  late UserProfileDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = UserProfileDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UserProfileDao', () {
    test('insert and find returns the profile', () async {
      final now = DateTime(2026, 4, 3, 10, 0);

      await dao.upsert(
        id: 'test-id',
        displayName: 'たけし',
        avatarEmoji: '🐱',
        avatarImagePath: null,
        createdAt: now,
        updatedAt: now,
      );

      final row = await dao.find();
      expect(row, isNotNull);
      expect(row!.displayName, 'たけし');
      expect(row.avatarEmoji, '🐱');
      expect(row.avatarImagePath, isNull);
    });

    test('find returns null when no profile exists', () async {
      final row = await dao.find();
      expect(row, isNull);
    });

    test('upsert updates existing profile', () async {
      final now = DateTime(2026, 4, 3, 10, 0);

      await dao.upsert(
        id: 'test-id',
        displayName: 'たけし',
        avatarEmoji: '🐱',
        avatarImagePath: null,
        createdAt: now,
        updatedAt: now,
      );

      await dao.upsert(
        id: 'test-id',
        displayName: 'はなこ',
        avatarEmoji: '🌸',
        avatarImagePath: '/path/to/img.jpg',
        createdAt: now,
        updatedAt: DateTime(2026, 4, 3, 10, 30),
      );

      final row = await dao.find();
      expect(row, isNotNull);
      expect(row!.displayName, 'はなこ');
      expect(row.avatarEmoji, '🌸');
      expect(row.avatarImagePath, '/path/to/img.jpg');
    });

    test('delete removes the profile', () async {
      final now = DateTime(2026, 4, 3, 10, 0);

      await dao.upsert(
        id: 'test-id',
        displayName: 'たけし',
        avatarEmoji: '🐱',
        avatarImagePath: null,
        createdAt: now,
        updatedAt: now,
      );

      await dao.delete('test-id');

      final row = await dao.find();
      expect(row, isNull);
    });
  });
}
