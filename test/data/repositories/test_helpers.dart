import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:home_pocket/data/database/app_database.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'test_helpers.mocks.dart';

// Generate mocks for crypto services
@GenerateMocks([FieldEncryptionService, HashChainService])
void main() {}

/// Creates an in-memory test database
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

/// Sets up mock encryption service with default behavior
MockFieldEncryptionService setupMockEncryption() {
  final mock = MockFieldEncryptionService();

  // Mock encryptField: returns "enc_<value>"
  when(mock.encryptField(any)).thenAnswer((invocation) async {
    final value = invocation.positionalArguments[0] as String;
    return 'enc_$value';
  });

  // Mock decryptField: strips "enc_" prefix
  when(mock.decryptField(any)).thenAnswer((invocation) async {
    final encrypted = invocation.positionalArguments[0] as String;
    return encrypted.replaceFirst('enc_', '');
  });

  // Mock encryptAmount: returns "enc_<amount>"
  when(mock.encryptAmount(any)).thenAnswer((invocation) async {
    final amount = invocation.positionalArguments[0] as double;
    return 'enc_$amount';
  });

  // Mock decryptAmount: parses from "enc_<amount>"
  when(mock.decryptAmount(any)).thenAnswer((invocation) async {
    final encrypted = invocation.positionalArguments[0] as String;
    final amountStr = encrypted.replaceFirst('enc_', '');
    return double.parse(amountStr);
  });

  return mock;
}

/// Sets up mock hash chain service with default behavior
MockHashChainService setupMockHashChain() {
  final mock = MockHashChainService();

  // Mock calculateTransactionHash: returns "hash_<id>"
  when(
    mock.calculateTransactionHash(
      transactionId: anyNamed('transactionId'),
      amount: anyNamed('amount'),
      timestamp: anyNamed('timestamp'),
      previousHash: anyNamed('previousHash'),
    ),
  ).thenAnswer((invocation) async {
    final id = invocation.namedArguments[#transactionId] as String;
    return 'hash_$id';
  });

  // Mock verifyTransactionHash: always returns true by default
  when(
    mock.verifyTransactionHash(
      transactionId: anyNamed('transactionId'),
      amount: anyNamed('amount'),
      timestamp: anyNamed('timestamp'),
      previousHash: anyNamed('previousHash'),
      currentHash: anyNamed('currentHash'),
    ),
  ).thenAnswer((_) async => true);

  // Mock getLastHash: returns empty string by default
  when(mock.getLastHash()).thenAnswer((_) async => '');

  return mock;
}
