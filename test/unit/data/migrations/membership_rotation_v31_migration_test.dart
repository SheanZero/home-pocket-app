import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

void main() {
  test(
    'fresh v31 has the encrypted membership rotation intent ledger',
    () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);

      expect(db.schemaVersion, greaterThanOrEqualTo(31));
      final columns = await db
          .customSelect('PRAGMA table_info(membership_rotation_intents)')
          .get();
      expect(
        columns.map((row) => row.read<String>('name')).toSet(),
        containsAll({
          'group_id',
          'request_id',
          'operation',
          'target_device_id',
          'expected_key_epoch',
          'new_key_epoch',
          'group_key',
          'envelopes_json',
          'created_at',
        }),
      );
    },
  );
}
