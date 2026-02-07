import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/domain/models/backup_data.dart';

void main() {
  group('BackupMetadata', () {
    test('creates with required fields', () {
      final metadata = BackupMetadata(
        version: '1.0',
        createdAt: 1700000000000,
        deviceId: 'device-123',
        appVersion: '0.1.0',
      );

      expect(metadata.version, '1.0');
      expect(metadata.createdAt, 1700000000000);
      expect(metadata.deviceId, 'device-123');
      expect(metadata.appVersion, '0.1.0');
    });

    test('serializes to JSON and back', () {
      final metadata = BackupMetadata(
        version: '1.0',
        createdAt: 1700000000000,
        deviceId: 'device-123',
        appVersion: '0.1.0',
      );

      final json = metadata.toJson();
      final restored = BackupMetadata.fromJson(json);

      expect(restored, metadata);
    });

    test('equality works correctly', () {
      final a = BackupMetadata(
        version: '1.0',
        createdAt: 1700000000000,
        deviceId: 'device-123',
        appVersion: '0.1.0',
      );
      final b = BackupMetadata(
        version: '1.0',
        createdAt: 1700000000000,
        deviceId: 'device-123',
        appVersion: '0.1.0',
      );

      expect(a, b);
    });
  });

  group('BackupData', () {
    final sampleMetadata = BackupMetadata(
      version: '1.0',
      createdAt: 1700000000000,
      deviceId: 'device-123',
      appVersion: '0.1.0',
    );

    test('creates with empty data', () {
      final backup = BackupData(
        metadata: sampleMetadata,
        transactions: [],
        categories: [],
        books: [],
        settings: {},
      );

      expect(backup.metadata, sampleMetadata);
      expect(backup.transactions, isEmpty);
      expect(backup.categories, isEmpty);
      expect(backup.books, isEmpty);
      expect(backup.settings, isEmpty);
    });

    test('creates with sample data', () {
      final backup = BackupData(
        metadata: sampleMetadata,
        transactions: [
          {'id': 'tx-1', 'amount': 1000},
          {'id': 'tx-2', 'amount': 2000},
        ],
        categories: [
          {'id': 'cat-1', 'name': 'Food'},
        ],
        books: [
          {'id': 'book-1', 'name': 'Default'},
        ],
        settings: {'language': 'ja', 'themeMode': 'system'},
      );

      expect(backup.transactions, hasLength(2));
      expect(backup.categories, hasLength(1));
      expect(backup.books, hasLength(1));
      expect(backup.settings['language'], 'ja');
    });

    test('serializes to JSON and back', () {
      final backup = BackupData(
        metadata: sampleMetadata,
        transactions: [
          {'id': 'tx-1', 'amount': 1000},
        ],
        categories: [
          {'id': 'cat-1', 'name': 'Food'},
        ],
        books: [
          {'id': 'book-1', 'name': 'Default'},
        ],
        settings: {'language': 'ja'},
      );

      final json = backup.toJson();
      final restored = BackupData.fromJson(json);

      expect(restored.metadata, backup.metadata);
      expect(restored.transactions, backup.transactions);
      expect(restored.categories, backup.categories);
      expect(restored.books, backup.books);
      expect(restored.settings, backup.settings);
    });
  });
}
