part of 'app_database.dart';

typedef _MigrationStep = Future<void> Function();

/// Executes schema upgrades one version at a time.
///
/// Keeping every rung separate makes ordering explicit and prevents a new
/// schema change from increasing the complexity of [AppDatabase.migration].
class _DatabaseMigrationRunner {
  _DatabaseMigrationRunner({
    required AppDatabase database,
    required this._migrator,
    required this._sourceVersion,
  }) : _db = database;

  final AppDatabase _db;
  final Migrator _migrator;
  final int _sourceVersion;

  Map<int, _MigrationStep> get _steps => {
    3: _toV3,
    4: _toV4,
    5: _toV5,
    6: _toV6,
    7: _toV7,
    8: _toV8,
    9: _toV9,
    10: _toV10,
    11: _toV11,
    12: _toV12,
    13: _toV13,
    14: _toV14,
    15: _toV15,
    17: _toV17,
    18: _toV18,
    19: _toV19,
    20: _toV20,
    21: _toV21,
    22: _toV22,
    23: _toV23,
    24: _toV24,
    25: _toV25,
    26: _toV26,
    27: _toV27,
    28: _toV28,
    29: _toV29,
    30: _toV30,
    31: _toV31,
    32: _toV32,
    33: _toV33,
    34: _toV34,
    35: _toV35,
    36: _toV36,
  };

  Future<void> run({required int from, required int to}) async {
    for (var version = from + 1; version <= to; version++) {
      await _steps[version]?.call();
    }
  }

  Future<void> _toV3() => _db.customStatement(
    'ALTER TABLE categories ADD COLUMN budget_amount INTEGER',
  );

  Future<void> _toV4() => _db.customStatement(
    'ALTER TABLE transactions ADD COLUMN soul_satisfaction '
    'INTEGER NOT NULL DEFAULT 2',
  );

  Future<void> _toV5() async {
    await _migrator.addColumn(_db.categories, _db.categories.isArchived);
    await _migrator.addColumn(_db.categories, _db.categories.updatedAt);
    await _migrator.createTable(_db.categoryLedgerConfigs);
    await _db.customStatement('''
      INSERT INTO category_ledger_configs (category_id, ledger_type, updated_at)
      SELECT id, 'daily', CAST(strftime('%s', 'now') * 1000 AS INTEGER)
      FROM categories WHERE level = 1 AND type IS NOT NULL
    ''');
    await _db.customStatement('''
      UPDATE categories SET parent_id = NULL
      WHERE level = 1 AND parent_id IS NOT NULL
    ''');
    await _db.customStatement('''
      UPDATE categories SET is_archived = 1
      WHERE level = 2 AND parent_id IS NULL
    ''');
  }

  Future<void> _toV6() =>
      _migrator.createTable(_db.merchantCategoryPreferences);

  Future<void> _toV7() async {
    await _migrator.createTable(_db.categoryKeywordPreferences);
    await _migrator.createTable(_db.syncQueue);
  }

  Future<void> _toV8() async {
    await _migrator.createTable(_db.groups);
    await _migrator.createTable(_db.groupMembers);
    if (_sourceVersion != 7) return;
    await _db.customStatement(
      'ALTER TABLE sync_queue RENAME TO sync_queue_old',
    );
    await _migrator.createTable(_db.syncQueue);
    await _db.customStatement('''
      INSERT INTO sync_queue (
        id, group_id, encrypted_payload, vector_clock,
        operation_count, retry_count, created_at
      )
      SELECT id, pair_id, encrypted_payload, vector_clock,
             operation_count, retry_count, created_at
      FROM sync_queue_old
    ''');
    await _db.customStatement('DROP TABLE sync_queue_old');
  }

  Future<void> _toV9() =>
      _db.customStatement('DROP TABLE IF EXISTS paired_devices');

  Future<void> _toV10() async {
    if (_sourceVersion < 8) return;
    await _db.customStatement('ALTER TABLE groups DROP COLUMN book_id');
    await _db.customStatement('DROP INDEX IF EXISTS idx_groups_book_id');
  }

  Future<void> _toV11() async {
    await _migrator.addColumn(_db.books, _db.books.isShadow);
    await _migrator.addColumn(_db.books, _db.books.groupId);
    await _migrator.addColumn(_db.books, _db.books.ownerDeviceId);
    await _migrator.addColumn(_db.books, _db.books.ownerDeviceName);
  }

  Future<void> _toV12() => _migrator.createTable(_db.userProfiles);

  Future<void> _toV13() async {
    if (_sourceVersion < 8) return;
    await _db.transaction(() async {
      await _migrator.addColumn(_db.groups, _db.groups.groupName);
      await _migrator.addColumn(_db.groupMembers, _db.groupMembers.displayName);
      await _migrator.addColumn(_db.groupMembers, _db.groupMembers.avatarEmoji);
      await _migrator.addColumn(
        _db.groupMembers,
        _db.groupMembers.avatarImagePath,
      );
      await _migrator.addColumn(
        _db.groupMembers,
        _db.groupMembers.avatarImageHash,
      );
      await _db.customStatement(
        'UPDATE group_members SET display_name = device_name '
        'WHERE display_name = \'\'',
      );
    });
  }

  Future<void> _toV14() async {
    await _rebuildV14LedgerConfigs();
    await _db.transaction(_migrateV14Taxonomy);
  }

  Future<void> _rebuildV14LedgerConfigs() async {
    await _db.customStatement(
      'DROP INDEX IF EXISTS idx_category_ledger_configs_ledger_type',
    );
    await _db.customStatement(
      'DROP INDEX IF EXISTS idx_category_ledger_configs_updated_at',
    );
    await _db.customStatement(
      'ALTER TABLE category_ledger_configs '
      'RENAME TO category_ledger_configs_pre14',
    );
    await _migrator.createTable(_db.categoryLedgerConfigs);
    await _createCategoryLedgerConfigIndexes();
    await _db.customStatement('''
      INSERT OR IGNORE INTO category_ledger_configs
        (category_id, ledger_type, updated_at)
      SELECT category_id,
             CASE ledger_type
               WHEN 'survival' THEN 'daily'
               WHEN 'soul' THEN 'joy'
               ELSE ledger_type
             END,
             updated_at
      FROM category_ledger_configs_pre14
    ''');
    await _db.customStatement('DROP TABLE category_ledger_configs_pre14');
  }

  Future<void> _migrateV14Taxonomy() async {
    const remaps = <String, String>{
      'cat_cash_card': 'cat_other_unclassified',
      'cat_uncategorized': 'cat_other_unclassified',
      'cat_daily_pets': 'cat_pet_other',
      'cat_other_allowance': 'cat_allowance_self',
      'cat_other_advances': 'cat_other_misc',
      'cat_other_business': 'cat_other_misc',
      'cat_other_debt': 'cat_other_misc',
      'cat_food_general': 'cat_food_other',
      'cat_food_breakfast': 'cat_food_dining_out',
      'cat_food_lunch': 'cat_food_dining_out',
      'cat_food_dinner': 'cat_food_dining_out',
      'cat_daily_general': 'cat_daily_other',
      'cat_transport_general': 'cat_transport_other',
      'cat_social_general': 'cat_social_other',
      'cat_utilities_general': 'cat_utilities_other',
      'cat_communication_info': 'cat_communication_other',
      'cat_insurance_general': 'cat_insurance_other',
      'cat_special_general': 'cat_special_other',
      'cat_special_furniture': 'cat_housing_furniture',
      'cat_special_housing': 'cat_housing_renovation',
    };
    for (final entry in remaps.entries) {
      await _db.customStatement(
        'UPDATE transactions SET category_id = ? WHERE category_id = ?',
        [entry.value, entry.key],
      );
    }
    await _deleteRemovedV14Categories();
    await _upsertV14Categories();
  }

  Future<void> _deleteRemovedV14Categories() async {
    for (final id in const ['cat_cash_card', 'cat_uncategorized']) {
      await _db.customStatement(
        'DELETE FROM category_ledger_configs WHERE category_id = ?',
        [id],
      );
      await _db.customStatement(
        'DELETE FROM categories WHERE id = ? AND is_system = 1',
        [id],
      );
    }
  }

  Future<void> _upsertV14Categories() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final category in DefaultCategories.all) {
      final parent = category.parentId == null
          ? 'NULL'
          : "'${category.parentId}'";
      await _db.customStatement('''
        INSERT OR REPLACE INTO categories
          (id, name, icon, color, parent_id, level,
           is_system, is_archived, sort_order, created_at)
        VALUES
          ('${category.id}', '${category.name}', '${category.icon}',
           '${category.color}', $parent, ${category.level},
           ${category.isSystem ? 1 : 0}, ${category.isArchived ? 1 : 0},
           ${category.sortOrder}, $nowMs)
      ''');
    }
    for (final config in DefaultCategories.defaultLedgerConfigs) {
      await _db.customStatement('''
        INSERT OR REPLACE INTO category_ledger_configs
          (category_id, ledger_type, updated_at)
        VALUES ('${config.categoryId}', '${config.ledgerType.name}', $nowMs)
      ''');
    }
  }

  Future<void> _toV15() async {
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_event '
      'ON audit_logs (event)',
    );
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_device_id '
      'ON audit_logs (device_id)',
    );
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp '
      'ON audit_logs (timestamp)',
    );
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at '
      'ON user_profiles (updated_at)',
    );
    await _createCategoryLedgerConfigIndexes();
  }

  Future<void> _createCategoryLedgerConfigIndexes() async {
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_ledger_type '
      'ON category_ledger_configs (ledger_type)',
    );
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_updated_at '
      'ON category_ledger_configs (updated_at)',
    );
  }

  Future<void> _toV17() => _db.customStatement(
    '''ALTER TABLE transactions ADD COLUMN entry_source TEXT NOT NULL '''
    '''DEFAULT 'manual' CHECK(entry_source IN ('manual', 'voice', 'ocr'))''',
  );

  Future<void> _toV18() => _db.transaction(() async {
    await _db.customStatement(
      'DROP INDEX IF EXISTS idx_category_ledger_configs_ledger_type',
    );
    await _db.customStatement(
      'DROP INDEX IF EXISTS idx_category_ledger_configs_updated_at',
    );
    await _db.customStatement(
      'ALTER TABLE category_ledger_configs '
      'RENAME TO category_ledger_configs_old',
    );
    await _migrator.createTable(_db.categoryLedgerConfigs);
    await _createCategoryLedgerConfigIndexes();
    await _db.customStatement('''
      INSERT INTO category_ledger_configs
        (category_id, ledger_type, updated_at)
      SELECT category_id,
             CASE ledger_type
               WHEN 'survival' THEN 'daily'
               WHEN 'soul' THEN 'joy'
               ELSE ledger_type
             END,
             updated_at
      FROM category_ledger_configs_old
    ''');
    await _db.customStatement('DROP TABLE category_ledger_configs_old');
    await _db.customStatement(
      "UPDATE transactions SET ledger_type = 'daily' "
      "WHERE ledger_type = 'survival'",
    );
    await _db.customStatement(
      "UPDATE transactions SET ledger_type = 'joy' "
      "WHERE ledger_type = 'soul'",
    );
    await _db.customStatement(
      'ALTER TABLE transactions '
      'RENAME COLUMN soul_satisfaction TO joy_fullness',
    );
  });

  Future<void> _toV19() async {
    await _db.customStatement(
      'UPDATE categories SET sort_order = 1 '
      'WHERE id = \'cat_food_dining_out\' AND is_system = 1',
    );
    await _db.customStatement(
      'UPDATE categories SET sort_order = 2 '
      'WHERE id = \'cat_food_groceries\' AND is_system = 1',
    );
  }

  Future<void> _toV20() async {
    await _migrator.createTable(_db.shoppingItems);
    await _db._createShoppingItemIndexes();
  }

  Future<void> _toV21() async {
    await _migrator.createTable(_db.exchangeRates);
    await _db._createExchangeRateIndexes();
    await _db.customStatement(
      'ALTER TABLE transactions ADD COLUMN original_currency TEXT',
    );
    await _db.customStatement(
      'ALTER TABLE transactions ADD COLUMN original_amount INTEGER',
    );
    await _db.customStatement(
      'ALTER TABLE transactions ADD COLUMN applied_rate TEXT',
    );
  }

  Future<void> _toV22() async {
    await _migrator.createTable(_db.merchants);
    await _migrator.createTable(_db.merchantMatchKeys);
    await _db._createMerchantIndexes();
  }

  Future<void> _toV23() =>
      _db._createAllDeclaredIndexes(includeSyncQueueRecoveryIndex: false);

  Future<void> _toV24() => _db.transaction(() async {
    if (!await _db._tableHasColumn('groups', 'key_epoch')) {
      await _migrator.addColumn(_db.groups, _db.groups.keyEpoch);
    }
    if (!await _db._tableHasColumn('sync_queue', 'key_epoch')) {
      await _migrator.addColumn(_db.syncQueue, _db.syncQueue.keyEpoch);
    }
  });

  Future<void> _toV25() => _db.transaction(() async {
    if (!await _db._tableHasColumn('transactions', 'sync_revision')) {
      await _migrator.addColumn(
        _db.transactions,
        _db.transactions.syncRevision,
      );
    }
    if (!await _db._tableHasColumn('transactions', 'sync_origin_device_id')) {
      await _migrator.addColumn(
        _db.transactions,
        _db.transactions.syncOriginDeviceId,
      );
    }
    final hasUpdatedAt = await _db._tableHasColumn(
      'transactions',
      'updated_at',
    );
    final revisionTime = hasUpdatedAt
        ? 'COALESCE(updated_at, created_at)'
        : 'created_at';
    await _db.customStatement('''
      UPDATE transactions
      SET sync_revision = $revisionTime * 1000000
      WHERE sync_revision = 0
    ''');
    await _db.customStatement('''
      UPDATE transactions
      SET sync_origin_device_id = device_id
      WHERE sync_origin_device_id = ''
    ''');
  });

  Future<void> _toV26() => _db.transaction(() async {
    await _addSyncQueueRecoveryColumns();
    await _db._createSyncQueueRecoveryIndex();
  });

  Future<void> _addSyncQueueRecoveryColumns() async {
    if (!await _db._tableHasColumn('sync_queue', 'state')) {
      await _migrator.addColumn(_db.syncQueue, _db.syncQueue.state);
    }
    if (!await _db._tableHasColumn('sync_queue', 'last_error_code')) {
      await _migrator.addColumn(_db.syncQueue, _db.syncQueue.lastErrorCode);
    }
    if (!await _db._tableHasColumn('sync_queue', 'next_retry_at')) {
      await _migrator.addColumn(_db.syncQueue, _db.syncQueue.nextRetryAt);
    }
    if (!await _db._tableHasColumn('sync_queue', 'failed_at')) {
      await _migrator.addColumn(_db.syncQueue, _db.syncQueue.failedAt);
    }
  }

  Future<void> _toV27() async {
    await _migrator.createTable(_db.inboundSyncOperations);
    await _db._createInboundSyncOperationIndexes();
  }

  Future<void> _toV28() => _db.transaction(() async {
    if (!await _db._tableHasColumn('categories', 'shared_revision')) {
      await _migrator.addColumn(_db.categories, _db.categories.sharedRevision);
    }
    if (!await _db._tableHasColumn('categories', 'shared_origin_device_id')) {
      await _migrator.addColumn(
        _db.categories,
        _db.categories.sharedOriginDeviceId,
      );
    }
    if (!await _db._tableHasColumn('categories', 'shared_is_deleted')) {
      await _migrator.addColumn(_db.categories, _db.categories.sharedIsDeleted);
    }
    await _db.customStatement('''
      UPDATE categories
      SET shared_revision = COALESCE(updated_at, created_at) * 1000000
      WHERE is_system = 0 AND shared_revision = 0
    ''');
  });

  Future<void> _toV29() => _db.transaction(() async {
    await _addGroupControlColumns();
    await _addMemberControlColumns();
    await _migrator.createTable(_db.controlEvents);
    await _db.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'idx_control_events_group_revision '
      'ON control_events (group_id, revision)',
    );
  });

  Future<void> _addGroupControlColumns() async {
    if (!await _db._tableHasColumn('groups', 'control_revision')) {
      await _migrator.addColumn(_db.groups, _db.groups.controlRevision);
    }
    if (!await _db._tableHasColumn('groups', 'control_updated_at')) {
      await _migrator.addColumn(_db.groups, _db.groups.controlUpdatedAt);
    }
    if (!await _db._tableHasColumn('groups', 'control_snapshot_digest')) {
      await _migrator.addColumn(_db.groups, _db.groups.controlSnapshotDigest);
    }
  }

  Future<void> _addMemberControlColumns() async {
    if (!await _db._tableHasColumn('group_members', 'joined_at')) {
      await _migrator.addColumn(_db.groupMembers, _db.groupMembers.joinedAt);
    }
    if (!await _db._tableHasColumn('group_members', 'confirmed_at')) {
      await _migrator.addColumn(_db.groupMembers, _db.groupMembers.confirmedAt);
    }
    if (!await _db._tableHasColumn('group_members', 'removed_at')) {
      await _migrator.addColumn(_db.groupMembers, _db.groupMembers.removedAt);
    }
    if (!await _db._tableHasColumn('group_members', 'removal_reason')) {
      await _migrator.addColumn(
        _db.groupMembers,
        _db.groupMembers.removalReason,
      );
    }
  }

  Future<void> _toV30() => _db.transaction(() async {
    await _addFamilyVisibilityColumns();
    final hasPrivate = await _db._tableHasColumn('transactions', 'is_private');
    final privateExpression = hasPrivate ? 'is_private' : '0';
    await _db.customStatement('''
      UPDATE transactions
      SET family_sync_visibility = CASE
            WHEN $privateExpression = 1 THEN 'localOnly'
            ELSE 'shared'
          END,
          family_shared_revision = CASE
            WHEN $privateExpression = 1 THEN 0
            ELSE sync_revision
          END
    ''');
  });

  Future<void> _addFamilyVisibilityColumns() async {
    if (!await _db._tableHasColumn('transactions', 'family_sync_visibility')) {
      await _migrator.addColumn(
        _db.transactions,
        _db.transactions.familySyncVisibility,
      );
    }
    if (!await _db._tableHasColumn('transactions', 'family_shared_revision')) {
      await _migrator.addColumn(
        _db.transactions,
        _db.transactions.familySharedRevision,
      );
    }
    if (!await _db._tableHasColumn('sync_queue', 'withdrawal_receipts')) {
      await _migrator.addColumn(
        _db.syncQueue,
        _db.syncQueue.withdrawalReceipts,
      );
    }
  }

  Future<void> _toV31() => _db._createMembershipRotationIntentsTable();

  Future<void> _toV32() async {
    await _migrator.createTable(_db.familySyncOutbox);
    await _db._createFamilySyncOutboxIndexes();
  }

  Future<void> _toV33() async {
    if (!await _db._tableExists('group_members')) return;
    await _db.transaction(() async {
      await _addMemberProfileColumns();
      await _backfillMemberProfileDigests();
    });
  }

  Future<void> _addMemberProfileColumns() async {
    final columns = <(String, GeneratedColumn<Object>)>[
      ('profile_revision', _db.groupMembers.profileRevision),
      ('profile_origin_device_id', _db.groupMembers.profileOriginDeviceId),
      ('profile_digest', _db.groupMembers.profileDigest),
      ('avatar_revision', _db.groupMembers.avatarRevision),
      ('avatar_origin_device_id', _db.groupMembers.avatarOriginDeviceId),
      ('avatar_content_hash', _db.groupMembers.avatarContentHash),
    ];
    for (final (name, column) in columns) {
      if (!await _db._tableHasColumn('group_members', name)) {
        await _migrator.addColumn(_db.groupMembers, column);
      }
    }
    if (await _db._tableHasColumn('group_members', 'avatar_image_hash')) {
      await _db.customStatement('''
        UPDATE group_members
        SET avatar_content_hash = COALESCE(avatar_image_hash, '')
        WHERE avatar_content_hash = ''
      ''');
    }
  }

  Future<void> _backfillMemberProfileDigests() async {
    if (!await _hasLegacyProfileColumns()) return;
    final members = await _db.customSelect('''
      SELECT group_id, device_id, display_name, avatar_emoji
      FROM group_members
      WHERE profile_digest = ''
    ''').get();
    for (final member in members) {
      await _backfillMemberProfileDigest(member);
    }
  }

  Future<bool> _hasLegacyProfileColumns() async =>
      await _db._tableHasColumn('group_members', 'display_name') &&
      await _db._tableHasColumn('group_members', 'avatar_emoji') &&
      await _db._tableHasColumn('group_members', 'device_id');

  Future<void> _backfillMemberProfileDigest(QueryRow member) async {
    final deviceId = member.read<String>('device_id');
    final digest = sha256
        .convert(
          utf8.encode(
            jsonEncode([
              member.read<String>('display_name'),
              member.read<String>('avatar_emoji'),
            ]),
          ),
        )
        .toString();
    await _db.customStatement(
      '''UPDATE group_members
         SET profile_origin_device_id = ?, profile_digest = ?,
             avatar_origin_device_id = CASE
               WHEN avatar_origin_device_id = '' THEN ?
               ELSE avatar_origin_device_id
             END
         WHERE group_id = ? AND device_id = ?''',
      [deviceId, digest, deviceId, member.read<String>('group_id'), deviceId],
    );
  }

  Future<void> _toV34() async {
    if (!await _db._tableExists('inbound_sync_operations')) return;
    await _db.transaction(() async {
      await _db.customStatement('''
        CREATE TABLE inbound_sync_operations_v34 (
          group_id TEXT NOT NULL,
          operation_id TEXT NOT NULL,
          message_id TEXT NOT NULL,
          state TEXT NOT NULL,
          operation_json TEXT,
          error_code TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          PRIMARY KEY (group_id, operation_id)
        )
      ''');
      await _db.customStatement('''
        INSERT INTO inbound_sync_operations_v34 (
          group_id, operation_id, message_id, state, operation_json,
          error_code, created_at, updated_at
        )
        SELECT group_id, operation_id, message_id, state,
               operation_json, error_code, created_at, updated_at
        FROM inbound_sync_operations
      ''');
      await _db.customStatement('DROP TABLE inbound_sync_operations');
      await _db.customStatement(
        'ALTER TABLE inbound_sync_operations_v34 '
        'RENAME TO inbound_sync_operations',
      );
      await _db._createInboundSyncOperationIndexes();
    });
  }

  Future<void> _toV35() async {
    if (!await _db._tableExists('inbound_sync_operations')) return;
    await _db.transaction(() async {
      if (!await _db._tableHasColumn('inbound_sync_operations', 'retryable')) {
        await _migrator.addColumn(
          _db.inboundSyncOperations,
          _db.inboundSyncOperations.retryable,
        );
      }
      if (!await _db._tableHasColumn(
        'inbound_sync_operations',
        'payload_bytes',
      )) {
        await _migrator.addColumn(
          _db.inboundSyncOperations,
          _db.inboundSyncOperations.payloadBytes,
        );
      }
      await _db.customStatement('''
        UPDATE inbound_sync_operations
        SET retryable = CASE
              WHEN state = 'quarantined' AND operation_json IS NULL THEN 0
              ELSE retryable
            END,
            payload_bytes = CASE
              WHEN operation_json IS NULL THEN 0
              ELSE length(CAST(operation_json AS BLOB))
            END
      ''');
    });
  }

  Future<void> _toV36() => _db.transaction(() async {
    await _upgradeShoppingSyncVersion();
    await _upgradeProfileSyncVersion();
  });

  Future<void> _upgradeShoppingSyncVersion() async {
    if (!await _db._tableExists('shopping_items')) return;
    if (!await _db._tableHasColumn('shopping_items', 'sync_revision')) {
      await _migrator.addColumn(
        _db.shoppingItems,
        _db.shoppingItems.syncRevision,
      );
    }
    if (!await _db._tableHasColumn('shopping_items', 'sync_origin_device_id')) {
      await _migrator.addColumn(
        _db.shoppingItems,
        _db.shoppingItems.syncOriginDeviceId,
      );
    }
    await _db.customStatement('''
      UPDATE shopping_items
      SET sync_revision = CASE
            WHEN list_type = 'public' THEN
              COALESCE(updated_at, created_at, 0) * 1000
            ELSE 0
          END,
          sync_origin_device_id = CASE
            WHEN list_type = 'public' THEN device_id
            ELSE ''
          END
      WHERE sync_revision = 0
    ''');
  }

  Future<void> _upgradeProfileSyncVersion() async {
    if (!await _db._tableExists('user_profiles')) return;
    if (!await _db._tableHasColumn('user_profiles', 'sync_revision')) {
      await _migrator.addColumn(
        _db.userProfiles,
        _db.userProfiles.syncRevision,
      );
    }
    if (!await _db._tableHasColumn('user_profiles', 'sync_origin_device_id')) {
      await _migrator.addColumn(
        _db.userProfiles,
        _db.userProfiles.syncOriginDeviceId,
      );
    }
    await _db.customStatement('''
      UPDATE user_profiles
      SET sync_revision = updated_at * 1000
      WHERE sync_revision = 0
    ''');
  }
}
