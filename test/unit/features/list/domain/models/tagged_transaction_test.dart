import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/list/domain/models/tagged_transaction.dart';

// Helper: a minimal Transaction with all required fields.
Transaction _makeTransaction({String id = 'tx-1'}) => Transaction(
      id: id,
      bookId: 'book-1',
      deviceId: 'device-1',
      amount: 1000,
      type: TransactionType.expense,
      categoryId: 'food',
      ledgerType: LedgerType.survival,
      timestamp: DateTime(2026, 5, 1),
      currentHash: 'hash-abc',
      createdAt: DateTime(2026, 5, 1),
    );

void main() {
  group('MemberTag (Freezed value semantics)', () {
    test('two MemberTags with the same emoji and name are equal', () {
      const a = MemberTag(emoji: '🐱', name: 'Alice');
      const b = MemberTag(emoji: '🐱', name: 'Alice');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('MemberTags with different fields are not equal', () {
      const a = MemberTag(emoji: '🐱', name: 'Alice');
      const b = MemberTag(emoji: '🐶', name: 'Alice');

      expect(a, isNot(equals(b)));
    });

    test('MemberTag.copyWith returns new object with updated field', () {
      const original = MemberTag(emoji: '🐱', name: 'Alice');
      final copied = original.copyWith(name: 'Bob');

      expect(copied.name, equals('Bob'));
      expect(copied.emoji, equals('🐱'));
      // Original is unchanged (Freezed immutability contract)
      expect(original.name, equals('Alice'));
    });
  });

  group('TaggedTransaction (Freezed value semantics)', () {
    test('copyWith creates new object; original memberTag remains null', () {
      final tx = _makeTransaction();
      final original = TaggedTransaction(transaction: tx);
      expect(original.memberTag, isNull);

      final tagged = original.copyWith(
        memberTag: const MemberTag(emoji: '🐱', name: 'Alice'),
      );

      // Original is unchanged
      expect(original.memberTag, isNull);
      // Copied has the new memberTag
      expect(tagged.memberTag, equals(const MemberTag(emoji: '🐱', name: 'Alice')));
    });

    test('two TaggedTransactions with same transaction and null memberTag are equal', () {
      final tx = _makeTransaction();
      final a = TaggedTransaction(transaction: tx);
      final b = TaggedTransaction(transaction: tx);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('two TaggedTransactions with different memberTags are not equal', () {
      final tx = _makeTransaction();
      final a = TaggedTransaction(
        transaction: tx,
        memberTag: const MemberTag(emoji: '🐱', name: 'Alice'),
      );
      final b = TaggedTransaction(
        transaction: tx,
        memberTag: const MemberTag(emoji: '🐶', name: 'Bob'),
      );

      expect(a, isNot(equals(b)));
    });

    test('TaggedTransaction with memberTag:null is valid (own-book path)', () {
      final tx = _makeTransaction();
      final tagged = TaggedTransaction(transaction: tx);

      expect(tagged.memberTag, isNull);
      expect(tagged.transaction.id, equals('tx-1'));
    });

    test('TaggedTransactions wrapping different Transaction instances are not equal', () {
      final tx1 = _makeTransaction(id: 'tx-1');
      final tx2 = _makeTransaction(id: 'tx-2');
      final a = TaggedTransaction(transaction: tx1);
      final b = TaggedTransaction(transaction: tx2);

      expect(a, isNot(equals(b)));
    });
  });
}
