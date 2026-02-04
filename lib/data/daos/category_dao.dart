import 'package:drift/drift.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/tables/categories_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.attachedDatabase);

  // Placeholder - will be implemented in Task 2.3
}
