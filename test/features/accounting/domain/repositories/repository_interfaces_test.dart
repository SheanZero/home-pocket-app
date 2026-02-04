import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';

void main() {
  group('Repository Interfaces', () {
    test('TransactionRepository interface should be defined', () {
      expect(TransactionRepository, isNotNull);
    });

    test('CategoryRepository interface should be defined', () {
      expect(CategoryRepository, isNotNull);
    });

    test('BookRepository interface should be defined', () {
      expect(BookRepository, isNotNull);
    });
  });
}
