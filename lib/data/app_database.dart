import 'package:drift/drift.dart';
import 'package:home_pocket/data/tables/books_table.dart';
import 'package:home_pocket/data/tables/categories_table.dart';
import 'package:home_pocket/data/tables/transactions_table.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/daos/book_dao.dart';

part 'app_database.g.dart';

/// Main database class for accounting feature
///
/// Uses Drift code generation with Dart table classes.
///
/// Includes:
/// - Transactions, Categories, Books tables
/// - DAOs for data access
/// - Schema version management
@DriftDatabase(
  tables: [Transactions, Categories, Books],
  daos: [TransactionDao, CategoryDao, BookDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle schema migrations here in future versions
      },
    );
  }
}
