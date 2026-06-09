import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../daos/shopping_item_dao.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/shopping_list/domain/models/shopping_item.dart';
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import '../../infrastructure/crypto/services/field_encryption_service.dart';

/// Concrete implementation of [ShoppingItemRepository].
///
/// Security boundary: encrypts [ShoppingItem.note] via [FieldEncryptionService]
/// before persisting to the database, and decrypts on read. Tags are
/// JSON-encoded ([jsonEncode]) on write and decoded on read at this boundary.
///
/// Decryption failures are caught silently — the note is returned as null.
/// Ciphertext and exception messages are NEVER logged (T-36-13).
class ShoppingItemRepositoryImpl implements ShoppingItemRepository {
  ShoppingItemRepositoryImpl({
    required ShoppingItemDao dao,
    required FieldEncryptionService encryptionService,
  })  : _dao = dao,
        _encryptionService = encryptionService;

  final ShoppingItemDao _dao;
  final FieldEncryptionService _encryptionService;

  @override
  Future<void> insert(ShoppingItem item) async {
    final encryptedNote = await _encryptNote(item.note);
    final encodedTags = _encodeTags(item.tags);

    await _dao.insert(
      ShoppingItemsCompanion(
        id: Value(item.id),
        deviceId: Value(item.deviceId),
        listType: Value(item.listType),
        name: Value(item.name),
        ledgerType: Value(item.ledgerType?.name),
        categoryId: Value(item.categoryId),
        tags: Value(encodedTags),
        note: Value(encryptedNote),
        quantity: Value(item.quantity),
        estimatedPrice: Value(item.estimatedPrice),
        completedAt: Value(item.completedAt),
        isCompleted: Value(item.isCompleted),
        sortOrder: Value(item.sortOrder),
        isSynced: Value(item.isSynced),
        isDeleted: Value(item.isDeleted),
        addedByBookId: Value(item.addedByBookId),
        createdAt: Value(item.createdAt),
        updatedAt: Value(item.updatedAt),
      ),
    );
  }

  @override
  Future<void> update(ShoppingItem item) async {
    final encryptedNote = await _encryptNote(item.note);
    final encodedTags = _encodeTags(item.tags);

    await _dao.update(
      ShoppingItemsCompanion(
        id: Value(item.id),
        deviceId: Value(item.deviceId),
        listType: Value(item.listType),
        name: Value(item.name),
        ledgerType: Value(item.ledgerType?.name),
        categoryId: Value(item.categoryId),
        tags: Value(encodedTags),
        note: Value(encryptedNote),
        quantity: Value(item.quantity),
        estimatedPrice: Value(item.estimatedPrice),
        completedAt: Value(item.completedAt),
        isCompleted: Value(item.isCompleted),
        sortOrder: Value(item.sortOrder),
        isSynced: Value(item.isSynced),
        isDeleted: Value(item.isDeleted),
        addedByBookId: Value(item.addedByBookId),
        createdAt: Value(item.createdAt),
        updatedAt: Value(item.updatedAt),
      ),
    );
  }

  @override
  Future<void> softDelete(String id) async {
    await _dao.softDelete(id);
  }

  @override
  Future<void> softDeleteAllCompleted(String listType) async {
    await _dao.softDeleteAllCompleted(listType);
  }

  @override
  Future<ShoppingItem?> findById(String id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Stream<List<ShoppingItem>> watchByListType(String listType) {
    return _dao
        .watchByListType(listType)
        .asyncMap((rows) => Future.wait(rows.map(_toModel)));
  }

  @override
  Stream<List<ShoppingItem>> watchAll() {
    return _dao
        .watchAll()
        .asyncMap((rows) => Future.wait(rows.map(_toModel)));
  }

  @override
  Future<void> upsert(ShoppingItem item) async {
    final encryptedNote = await _encryptNote(item.note);
    final encodedTags = _encodeTags(item.tags);

    await _dao.upsert(
      ShoppingItemsCompanion(
        id: Value(item.id),
        deviceId: Value(item.deviceId),
        listType: Value(item.listType),
        name: Value(item.name),
        ledgerType: Value(item.ledgerType?.name),
        categoryId: Value(item.categoryId),
        tags: Value(encodedTags),
        note: Value(encryptedNote),
        quantity: Value(item.quantity),
        estimatedPrice: Value(item.estimatedPrice),
        completedAt: Value(item.completedAt),
        isCompleted: Value(item.isCompleted),
        sortOrder: Value(item.sortOrder),
        isSynced: Value(item.isSynced),
        isDeleted: Value(item.isDeleted),
        addedByBookId: Value(item.addedByBookId),
        createdAt: Value(item.createdAt),
        updatedAt: Value(item.updatedAt),
      ),
    );
  }

  @override
  Future<void> reorder(String id, int newSortOrder) async {
    await _dao.reorder(id, newSortOrder);
  }

  /// Encrypt [note] if non-null and non-empty; returns null otherwise.
  Future<String?> _encryptNote(String? note) async {
    if (note != null && note.isNotEmpty) {
      return _encryptionService.encryptField(note);
    }
    return null;
  }

  /// JSON-encode [tags] if non-empty; returns null for empty lists.
  String? _encodeTags(List<String> tags) {
    if (tags.isNotEmpty) {
      return jsonEncode(tags);
    }
    return null;
  }

  /// Map a [ShoppingItemRow] to a [ShoppingItem] domain model.
  ///
  /// Decrypts [note] silently — on failure returns null without logging
  /// ciphertext or the exception message (T-36-13 security rule).
  Future<ShoppingItem> _toModel(ShoppingItemRow row) async {
    // Decrypt note — silent failure on wrong-device-key scenario
    String? decryptedNote;
    if (row.note != null && row.note!.isNotEmpty) {
      try {
        decryptedNote = await _encryptionService.decryptField(row.note!);
      } catch (_) {
        // DO NOT log row.note or the exception — may contain ciphertext.
        decryptedNote = null;
      }
    }

    // Decode tags — wrap in try/catch for malformed JSON safety
    List<String> tags = [];
    if (row.tags != null) {
      try {
        tags = (jsonDecode(row.tags!) as List).cast<String>();
      } catch (_) {
        tags = [];
      }
    }

    // Convert ledger_type string to LedgerType? safely
    final ledgerType = row.ledgerType != null
        ? LedgerType.values
            .where((e) => e.name == row.ledgerType)
            .firstOrNull
        : null;

    return ShoppingItem(
      id: row.id,
      deviceId: row.deviceId,
      listType: row.listType,
      name: row.name,
      ledgerType: ledgerType,
      categoryId: row.categoryId,
      tags: tags,
      note: decryptedNote,
      quantity: row.quantity,
      estimatedPrice: row.estimatedPrice,
      completedAt: row.completedAt,
      isCompleted: row.isCompleted,
      sortOrder: row.sortOrder,
      isSynced: row.isSynced,
      isDeleted: row.isDeleted,
      addedByBookId: row.addedByBookId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
