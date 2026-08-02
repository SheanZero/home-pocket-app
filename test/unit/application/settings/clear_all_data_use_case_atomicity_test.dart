import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

Future<int> _count(AppDatabase db, String table) async {
  final result = await db
      .customSelect('SELECT COUNT(*) AS count FROM "$table"')
      .getSingle();
  return result.read<int>('count');
}

void main() {
  test('database wipe commits all core deletes together', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    await db.customStatement(
      'INSERT INTO books (id,name,currency,device_id,created_at) '
      'VALUES (\'book\',\'Book\',\'JPY\',\'device\',1)',
    );
    await db.customStatement(
      'INSERT INTO categories (id,name,icon,color,level,created_at) '
      'VALUES (\'category\',\'Category\',\'food\',\'#000000\',1,1)',
    );
    await db.customStatement(
      'INSERT INTO transactions '
      '(id,book_id,device_id,amount,type,category_id,ledger_type,timestamp,current_hash,created_at) '
      'VALUES (\'transaction\',\'book\',\'device\',100,\'expense\',\'category\',\'daily\',1,\'hash\',1)',
    );

    await db.wipeLocalUserData();

    expect(await _count(db, 'books'), 0);
    expect(await _count(db, 'categories'), 0);
    expect(await _count(db, 'transactions'), 0);
  });
}
