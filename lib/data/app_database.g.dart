// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AuditLogsTable extends AuditLogs
    with TableInfo<$AuditLogsTable, AuditLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventMeta = const VerificationMeta('event');
  @override
  late final GeneratedColumn<String> event = GeneratedColumn<String>(
    'event',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    event,
    deviceId,
    bookId,
    transactionId,
    details,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event')) {
      context.handle(
        _eventMeta,
        event.isAcceptableOrUnknown(data['event']!, _eventMeta),
      );
    } else if (isInserting) {
      context.missing(_eventMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      event: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      ),
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      ),
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $AuditLogsTable createAlias(String alias) {
    return $AuditLogsTable(attachedDatabase, alias);
  }
}

class AuditLog extends DataClass implements Insertable<AuditLog> {
  /// ULID — time-sortable unique identifier.
  final String id;

  /// Event type (AuditEvent.name string).
  final String event;

  /// Device that produced this event.
  final String deviceId;

  /// Associated book ID (optional).
  final String? bookId;

  /// Associated transaction ID (optional).
  final String? transactionId;

  /// Extra JSON details (optional). MUST NOT contain sensitive data.
  final String? details;

  /// When the event occurred.
  final DateTime timestamp;
  const AuditLog({
    required this.id,
    required this.event,
    required this.deviceId,
    this.bookId,
    this.transactionId,
    this.details,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event'] = Variable<String>(event);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || bookId != null) {
      map['book_id'] = Variable<String>(bookId);
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  AuditLogsCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsCompanion(
      id: Value(id),
      event: Value(event),
      deviceId: Value(deviceId),
      bookId: bookId == null && nullToAbsent
          ? const Value.absent()
          : Value(bookId),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
      timestamp: Value(timestamp),
    );
  }

  factory AuditLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLog(
      id: serializer.fromJson<String>(json['id']),
      event: serializer.fromJson<String>(json['event']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      bookId: serializer.fromJson<String?>(json['bookId']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
      details: serializer.fromJson<String?>(json['details']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'event': serializer.toJson<String>(event),
      'deviceId': serializer.toJson<String>(deviceId),
      'bookId': serializer.toJson<String?>(bookId),
      'transactionId': serializer.toJson<String?>(transactionId),
      'details': serializer.toJson<String?>(details),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  AuditLog copyWith({
    String? id,
    String? event,
    String? deviceId,
    Value<String?> bookId = const Value.absent(),
    Value<String?> transactionId = const Value.absent(),
    Value<String?> details = const Value.absent(),
    DateTime? timestamp,
  }) => AuditLog(
    id: id ?? this.id,
    event: event ?? this.event,
    deviceId: deviceId ?? this.deviceId,
    bookId: bookId.present ? bookId.value : this.bookId,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
    details: details.present ? details.value : this.details,
    timestamp: timestamp ?? this.timestamp,
  );
  AuditLog copyWithCompanion(AuditLogsCompanion data) {
    return AuditLog(
      id: data.id.present ? data.id.value : this.id,
      event: data.event.present ? data.event.value : this.event,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      details: data.details.present ? data.details.value : this.details,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLog(')
          ..write('id: $id, ')
          ..write('event: $event, ')
          ..write('deviceId: $deviceId, ')
          ..write('bookId: $bookId, ')
          ..write('transactionId: $transactionId, ')
          ..write('details: $details, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    event,
    deviceId,
    bookId,
    transactionId,
    details,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLog &&
          other.id == this.id &&
          other.event == this.event &&
          other.deviceId == this.deviceId &&
          other.bookId == this.bookId &&
          other.transactionId == this.transactionId &&
          other.details == this.details &&
          other.timestamp == this.timestamp);
}

class AuditLogsCompanion extends UpdateCompanion<AuditLog> {
  final Value<String> id;
  final Value<String> event;
  final Value<String> deviceId;
  final Value<String?> bookId;
  final Value<String?> transactionId;
  final Value<String?> details;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const AuditLogsCompanion({
    this.id = const Value.absent(),
    this.event = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.details = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogsCompanion.insert({
    required String id,
    required String event,
    required String deviceId,
    this.bookId = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.details = const Value.absent(),
    required DateTime timestamp,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       event = Value(event),
       deviceId = Value(deviceId),
       timestamp = Value(timestamp);
  static Insertable<AuditLog> custom({
    Expression<String>? id,
    Expression<String>? event,
    Expression<String>? deviceId,
    Expression<String>? bookId,
    Expression<String>? transactionId,
    Expression<String>? details,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (event != null) 'event': event,
      if (deviceId != null) 'device_id': deviceId,
      if (bookId != null) 'book_id': bookId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (details != null) 'details': details,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? event,
    Value<String>? deviceId,
    Value<String?>? bookId,
    Value<String?>? transactionId,
    Value<String?>? details,
    Value<DateTime>? timestamp,
    Value<int>? rowid,
  }) {
    return AuditLogsCompanion(
      id: id ?? this.id,
      event: event ?? this.event,
      deviceId: deviceId ?? this.deviceId,
      bookId: bookId ?? this.bookId,
      transactionId: transactionId ?? this.transactionId,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (event.present) {
      map['event'] = Variable<String>(event.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsCompanion(')
          ..write('id: $id, ')
          ..write('event: $event, ')
          ..write('deviceId: $deviceId, ')
          ..write('bookId: $bookId, ')
          ..write('transactionId: $transactionId, ')
          ..write('details: $details, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BooksTable extends Books with TableInfo<$BooksTable, BookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isShadowMeta = const VerificationMeta(
    'isShadow',
  );
  @override
  late final GeneratedColumn<bool> isShadow = GeneratedColumn<bool>(
    'is_shadow',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_shadow" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerDeviceIdMeta = const VerificationMeta(
    'ownerDeviceId',
  );
  @override
  late final GeneratedColumn<String> ownerDeviceId = GeneratedColumn<String>(
    'owner_device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerDeviceNameMeta = const VerificationMeta(
    'ownerDeviceName',
  );
  @override
  late final GeneratedColumn<String> ownerDeviceName = GeneratedColumn<String>(
    'owner_device_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionCountMeta = const VerificationMeta(
    'transactionCount',
  );
  @override
  late final GeneratedColumn<int> transactionCount = GeneratedColumn<int>(
    'transaction_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _survivalBalanceMeta = const VerificationMeta(
    'survivalBalance',
  );
  @override
  late final GeneratedColumn<int> survivalBalance = GeneratedColumn<int>(
    'survival_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _soulBalanceMeta = const VerificationMeta(
    'soulBalance',
  );
  @override
  late final GeneratedColumn<int> soulBalance = GeneratedColumn<int>(
    'soul_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    currency,
    deviceId,
    createdAt,
    updatedAt,
    isArchived,
    isShadow,
    groupId,
    ownerDeviceId,
    ownerDeviceName,
    transactionCount,
    survivalBalance,
    soulBalance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_shadow')) {
      context.handle(
        _isShadowMeta,
        isShadow.isAcceptableOrUnknown(data['is_shadow']!, _isShadowMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('owner_device_id')) {
      context.handle(
        _ownerDeviceIdMeta,
        ownerDeviceId.isAcceptableOrUnknown(
          data['owner_device_id']!,
          _ownerDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('owner_device_name')) {
      context.handle(
        _ownerDeviceNameMeta,
        ownerDeviceName.isAcceptableOrUnknown(
          data['owner_device_name']!,
          _ownerDeviceNameMeta,
        ),
      );
    }
    if (data.containsKey('transaction_count')) {
      context.handle(
        _transactionCountMeta,
        transactionCount.isAcceptableOrUnknown(
          data['transaction_count']!,
          _transactionCountMeta,
        ),
      );
    }
    if (data.containsKey('survival_balance')) {
      context.handle(
        _survivalBalanceMeta,
        survivalBalance.isAcceptableOrUnknown(
          data['survival_balance']!,
          _survivalBalanceMeta,
        ),
      );
    }
    if (data.containsKey('soul_balance')) {
      context.handle(
        _soulBalanceMeta,
        soulBalance.isAcceptableOrUnknown(
          data['soul_balance']!,
          _soulBalanceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      isShadow: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_shadow'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      ownerDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_device_id'],
      ),
      ownerDeviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_device_name'],
      ),
      transactionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_count'],
      )!,
      survivalBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}survival_balance'],
      )!,
      soulBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}soul_balance'],
      )!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class BookRow extends DataClass implements Insertable<BookRow> {
  final String id;
  final String name;
  final String currency;
  final String deviceId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isArchived;
  final bool isShadow;
  final String? groupId;
  final String? ownerDeviceId;
  final String? ownerDeviceName;
  final int transactionCount;
  final int survivalBalance;
  final int soulBalance;
  const BookRow({
    required this.id,
    required this.name,
    required this.currency,
    required this.deviceId,
    required this.createdAt,
    this.updatedAt,
    required this.isArchived,
    required this.isShadow,
    this.groupId,
    this.ownerDeviceId,
    this.ownerDeviceName,
    required this.transactionCount,
    required this.survivalBalance,
    required this.soulBalance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['currency'] = Variable<String>(currency);
    map['device_id'] = Variable<String>(deviceId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_shadow'] = Variable<bool>(isShadow);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || ownerDeviceId != null) {
      map['owner_device_id'] = Variable<String>(ownerDeviceId);
    }
    if (!nullToAbsent || ownerDeviceName != null) {
      map['owner_device_name'] = Variable<String>(ownerDeviceName);
    }
    map['transaction_count'] = Variable<int>(transactionCount);
    map['survival_balance'] = Variable<int>(survivalBalance);
    map['soul_balance'] = Variable<int>(soulBalance);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      name: Value(name),
      currency: Value(currency),
      deviceId: Value(deviceId),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isArchived: Value(isArchived),
      isShadow: Value(isShadow),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      ownerDeviceId: ownerDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerDeviceId),
      ownerDeviceName: ownerDeviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerDeviceName),
      transactionCount: Value(transactionCount),
      survivalBalance: Value(survivalBalance),
      soulBalance: Value(soulBalance),
    );
  }

  factory BookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      currency: serializer.fromJson<String>(json['currency']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isShadow: serializer.fromJson<bool>(json['isShadow']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      ownerDeviceId: serializer.fromJson<String?>(json['ownerDeviceId']),
      ownerDeviceName: serializer.fromJson<String?>(json['ownerDeviceName']),
      transactionCount: serializer.fromJson<int>(json['transactionCount']),
      survivalBalance: serializer.fromJson<int>(json['survivalBalance']),
      soulBalance: serializer.fromJson<int>(json['soulBalance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'currency': serializer.toJson<String>(currency),
      'deviceId': serializer.toJson<String>(deviceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isShadow': serializer.toJson<bool>(isShadow),
      'groupId': serializer.toJson<String?>(groupId),
      'ownerDeviceId': serializer.toJson<String?>(ownerDeviceId),
      'ownerDeviceName': serializer.toJson<String?>(ownerDeviceName),
      'transactionCount': serializer.toJson<int>(transactionCount),
      'survivalBalance': serializer.toJson<int>(survivalBalance),
      'soulBalance': serializer.toJson<int>(soulBalance),
    };
  }

  BookRow copyWith({
    String? id,
    String? name,
    String? currency,
    String? deviceId,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isArchived,
    bool? isShadow,
    Value<String?> groupId = const Value.absent(),
    Value<String?> ownerDeviceId = const Value.absent(),
    Value<String?> ownerDeviceName = const Value.absent(),
    int? transactionCount,
    int? survivalBalance,
    int? soulBalance,
  }) => BookRow(
    id: id ?? this.id,
    name: name ?? this.name,
    currency: currency ?? this.currency,
    deviceId: deviceId ?? this.deviceId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isArchived: isArchived ?? this.isArchived,
    isShadow: isShadow ?? this.isShadow,
    groupId: groupId.present ? groupId.value : this.groupId,
    ownerDeviceId: ownerDeviceId.present
        ? ownerDeviceId.value
        : this.ownerDeviceId,
    ownerDeviceName: ownerDeviceName.present
        ? ownerDeviceName.value
        : this.ownerDeviceName,
    transactionCount: transactionCount ?? this.transactionCount,
    survivalBalance: survivalBalance ?? this.survivalBalance,
    soulBalance: soulBalance ?? this.soulBalance,
  );
  BookRow copyWithCompanion(BooksCompanion data) {
    return BookRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      currency: data.currency.present ? data.currency.value : this.currency,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isShadow: data.isShadow.present ? data.isShadow.value : this.isShadow,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      ownerDeviceId: data.ownerDeviceId.present
          ? data.ownerDeviceId.value
          : this.ownerDeviceId,
      ownerDeviceName: data.ownerDeviceName.present
          ? data.ownerDeviceName.value
          : this.ownerDeviceName,
      transactionCount: data.transactionCount.present
          ? data.transactionCount.value
          : this.transactionCount,
      survivalBalance: data.survivalBalance.present
          ? data.survivalBalance.value
          : this.survivalBalance,
      soulBalance: data.soulBalance.present
          ? data.soulBalance.value
          : this.soulBalance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('isShadow: $isShadow, ')
          ..write('groupId: $groupId, ')
          ..write('ownerDeviceId: $ownerDeviceId, ')
          ..write('ownerDeviceName: $ownerDeviceName, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('survivalBalance: $survivalBalance, ')
          ..write('soulBalance: $soulBalance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    currency,
    deviceId,
    createdAt,
    updatedAt,
    isArchived,
    isShadow,
    groupId,
    ownerDeviceId,
    ownerDeviceName,
    transactionCount,
    survivalBalance,
    soulBalance,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.currency == this.currency &&
          other.deviceId == this.deviceId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isArchived == this.isArchived &&
          other.isShadow == this.isShadow &&
          other.groupId == this.groupId &&
          other.ownerDeviceId == this.ownerDeviceId &&
          other.ownerDeviceName == this.ownerDeviceName &&
          other.transactionCount == this.transactionCount &&
          other.survivalBalance == this.survivalBalance &&
          other.soulBalance == this.soulBalance);
}

class BooksCompanion extends UpdateCompanion<BookRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> currency;
  final Value<String> deviceId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<bool> isArchived;
  final Value<bool> isShadow;
  final Value<String?> groupId;
  final Value<String?> ownerDeviceId;
  final Value<String?> ownerDeviceName;
  final Value<int> transactionCount;
  final Value<int> survivalBalance;
  final Value<int> soulBalance;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.currency = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isShadow = const Value.absent(),
    this.groupId = const Value.absent(),
    this.ownerDeviceId = const Value.absent(),
    this.ownerDeviceName = const Value.absent(),
    this.transactionCount = const Value.absent(),
    this.survivalBalance = const Value.absent(),
    this.soulBalance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    required String name,
    required String currency,
    required String deviceId,
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isShadow = const Value.absent(),
    this.groupId = const Value.absent(),
    this.ownerDeviceId = const Value.absent(),
    this.ownerDeviceName = const Value.absent(),
    this.transactionCount = const Value.absent(),
    this.survivalBalance = const Value.absent(),
    this.soulBalance = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       currency = Value(currency),
       deviceId = Value(deviceId),
       createdAt = Value(createdAt);
  static Insertable<BookRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? currency,
    Expression<String>? deviceId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isArchived,
    Expression<bool>? isShadow,
    Expression<String>? groupId,
    Expression<String>? ownerDeviceId,
    Expression<String>? ownerDeviceName,
    Expression<int>? transactionCount,
    Expression<int>? survivalBalance,
    Expression<int>? soulBalance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (currency != null) 'currency': currency,
      if (deviceId != null) 'device_id': deviceId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isArchived != null) 'is_archived': isArchived,
      if (isShadow != null) 'is_shadow': isShadow,
      if (groupId != null) 'group_id': groupId,
      if (ownerDeviceId != null) 'owner_device_id': ownerDeviceId,
      if (ownerDeviceName != null) 'owner_device_name': ownerDeviceName,
      if (transactionCount != null) 'transaction_count': transactionCount,
      if (survivalBalance != null) 'survival_balance': survivalBalance,
      if (soulBalance != null) 'soul_balance': soulBalance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? currency,
    Value<String>? deviceId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<bool>? isArchived,
    Value<bool>? isShadow,
    Value<String?>? groupId,
    Value<String?>? ownerDeviceId,
    Value<String?>? ownerDeviceName,
    Value<int>? transactionCount,
    Value<int>? survivalBalance,
    Value<int>? soulBalance,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      isShadow: isShadow ?? this.isShadow,
      groupId: groupId ?? this.groupId,
      ownerDeviceId: ownerDeviceId ?? this.ownerDeviceId,
      ownerDeviceName: ownerDeviceName ?? this.ownerDeviceName,
      transactionCount: transactionCount ?? this.transactionCount,
      survivalBalance: survivalBalance ?? this.survivalBalance,
      soulBalance: soulBalance ?? this.soulBalance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isShadow.present) {
      map['is_shadow'] = Variable<bool>(isShadow.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (ownerDeviceId.present) {
      map['owner_device_id'] = Variable<String>(ownerDeviceId.value);
    }
    if (ownerDeviceName.present) {
      map['owner_device_name'] = Variable<String>(ownerDeviceName.value);
    }
    if (transactionCount.present) {
      map['transaction_count'] = Variable<int>(transactionCount.value);
    }
    if (survivalBalance.present) {
      map['survival_balance'] = Variable<int>(survivalBalance.value);
    }
    if (soulBalance.present) {
      map['soul_balance'] = Variable<int>(soulBalance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('isShadow: $isShadow, ')
          ..write('groupId: $groupId, ')
          ..write('ownerDeviceId: $ownerDeviceId, ')
          ..write('ownerDeviceName: $ownerDeviceName, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('survivalBalance: $survivalBalance, ')
          ..write('soulBalance: $soulBalance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(level IN (1, 2))',
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    color,
    parentId,
    level,
    isSystem,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String? parentId;
  final int level;
  final bool isSystem;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.parentId,
    required this.level,
    required this.isSystem,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<String>(color);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['level'] = Variable<int>(level);
    map['is_system'] = Variable<bool>(isSystem);
    map['is_archived'] = Variable<bool>(isArchived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      color: Value(color),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      level: Value(level),
      isSystem: Value(isSystem),
      isArchived: Value(isArchived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<String>(json['color']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      level: serializer.fromJson<int>(json['level']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<String>(color),
      'parentId': serializer.toJson<String?>(parentId),
      'level': serializer.toJson<int>(level),
      'isSystem': serializer.toJson<bool>(isSystem),
      'isArchived': serializer.toJson<bool>(isArchived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    Value<String?> parentId = const Value.absent(),
    int? level,
    bool? isSystem,
    bool? isArchived,
    int? sortOrder,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    parentId: parentId.present ? parentId.value : this.parentId,
    level: level ?? this.level,
    isSystem: isSystem ?? this.isSystem,
    isArchived: isArchived ?? this.isArchived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      level: data.level.present ? data.level.value : this.level,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('parentId: $parentId, ')
          ..write('level: $level, ')
          ..write('isSystem: $isSystem, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    icon,
    color,
    parentId,
    level,
    isSystem,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.parentId == this.parentId &&
          other.level == this.level &&
          other.isSystem == this.isSystem &&
          other.isArchived == this.isArchived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<String> color;
  final Value<String?> parentId;
  final Value<int> level;
  final Value<bool> isSystem;
  final Value<bool> isArchived;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.parentId = const Value.absent(),
    this.level = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required String icon,
    required String color,
    this.parentId = const Value.absent(),
    required int level,
    this.isSystem = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       icon = Value(icon),
       color = Value(color),
       level = Value(level),
       createdAt = Value(createdAt);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<String>? parentId,
    Expression<int>? level,
    Expression<bool>? isSystem,
    Expression<bool>? isArchived,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (parentId != null) 'parent_id': parentId,
      if (level != null) 'level': level,
      if (isSystem != null) 'is_system': isSystem,
      if (isArchived != null) 'is_archived': isArchived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<String>? color,
    Value<String?>? parentId,
    Value<int>? level,
    Value<bool>? isSystem,
    Value<bool>? isArchived,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      isSystem: isSystem ?? this.isSystem,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('parentId: $parentId, ')
          ..write('level: $level, ')
          ..write('isSystem: $isSystem, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryKeywordPreferencesTable extends CategoryKeywordPreferences
    with
        TableInfo<
          $CategoryKeywordPreferencesTable,
          CategoryKeywordPreferenceRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryKeywordPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keywordMeta = const VerificationMeta(
    'keyword',
  );
  @override
  late final GeneratedColumn<String> keyword = GeneratedColumn<String>(
    'keyword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hitCountMeta = const VerificationMeta(
    'hitCount',
  );
  @override
  late final GeneratedColumn<int> hitCount = GeneratedColumn<int>(
    'hit_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastUsedMeta = const VerificationMeta(
    'lastUsed',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsed = GeneratedColumn<DateTime>(
    'last_used',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    keyword,
    categoryId,
    hitCount,
    lastUsed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_keyword_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryKeywordPreferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('keyword')) {
      context.handle(
        _keywordMeta,
        keyword.isAcceptableOrUnknown(data['keyword']!, _keywordMeta),
      );
    } else if (isInserting) {
      context.missing(_keywordMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('hit_count')) {
      context.handle(
        _hitCountMeta,
        hitCount.isAcceptableOrUnknown(data['hit_count']!, _hitCountMeta),
      );
    }
    if (data.containsKey('last_used')) {
      context.handle(
        _lastUsedMeta,
        lastUsed.isAcceptableOrUnknown(data['last_used']!, _lastUsedMeta),
      );
    } else if (isInserting) {
      context.missing(_lastUsedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {keyword, categoryId};
  @override
  CategoryKeywordPreferenceRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryKeywordPreferenceRow(
      keyword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keyword'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      hitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hit_count'],
      )!,
      lastUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used'],
      )!,
    );
  }

  @override
  $CategoryKeywordPreferencesTable createAlias(String alias) {
    return $CategoryKeywordPreferencesTable(attachedDatabase, alias);
  }
}

class CategoryKeywordPreferenceRow extends DataClass
    implements Insertable<CategoryKeywordPreferenceRow> {
  /// Normalized keyword extracted from voice input.
  final String keyword;

  /// The category ID the user corrected to.
  final String categoryId;

  /// Number of times the user selected this mapping.
  final int hitCount;

  /// When this mapping was last used/updated.
  final DateTime lastUsed;
  const CategoryKeywordPreferenceRow({
    required this.keyword,
    required this.categoryId,
    required this.hitCount,
    required this.lastUsed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['keyword'] = Variable<String>(keyword);
    map['category_id'] = Variable<String>(categoryId);
    map['hit_count'] = Variable<int>(hitCount);
    map['last_used'] = Variable<DateTime>(lastUsed);
    return map;
  }

  CategoryKeywordPreferencesCompanion toCompanion(bool nullToAbsent) {
    return CategoryKeywordPreferencesCompanion(
      keyword: Value(keyword),
      categoryId: Value(categoryId),
      hitCount: Value(hitCount),
      lastUsed: Value(lastUsed),
    );
  }

  factory CategoryKeywordPreferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryKeywordPreferenceRow(
      keyword: serializer.fromJson<String>(json['keyword']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      hitCount: serializer.fromJson<int>(json['hitCount']),
      lastUsed: serializer.fromJson<DateTime>(json['lastUsed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'keyword': serializer.toJson<String>(keyword),
      'categoryId': serializer.toJson<String>(categoryId),
      'hitCount': serializer.toJson<int>(hitCount),
      'lastUsed': serializer.toJson<DateTime>(lastUsed),
    };
  }

  CategoryKeywordPreferenceRow copyWith({
    String? keyword,
    String? categoryId,
    int? hitCount,
    DateTime? lastUsed,
  }) => CategoryKeywordPreferenceRow(
    keyword: keyword ?? this.keyword,
    categoryId: categoryId ?? this.categoryId,
    hitCount: hitCount ?? this.hitCount,
    lastUsed: lastUsed ?? this.lastUsed,
  );
  CategoryKeywordPreferenceRow copyWithCompanion(
    CategoryKeywordPreferencesCompanion data,
  ) {
    return CategoryKeywordPreferenceRow(
      keyword: data.keyword.present ? data.keyword.value : this.keyword,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      hitCount: data.hitCount.present ? data.hitCount.value : this.hitCount,
      lastUsed: data.lastUsed.present ? data.lastUsed.value : this.lastUsed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryKeywordPreferenceRow(')
          ..write('keyword: $keyword, ')
          ..write('categoryId: $categoryId, ')
          ..write('hitCount: $hitCount, ')
          ..write('lastUsed: $lastUsed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(keyword, categoryId, hitCount, lastUsed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryKeywordPreferenceRow &&
          other.keyword == this.keyword &&
          other.categoryId == this.categoryId &&
          other.hitCount == this.hitCount &&
          other.lastUsed == this.lastUsed);
}

class CategoryKeywordPreferencesCompanion
    extends UpdateCompanion<CategoryKeywordPreferenceRow> {
  final Value<String> keyword;
  final Value<String> categoryId;
  final Value<int> hitCount;
  final Value<DateTime> lastUsed;
  final Value<int> rowid;
  const CategoryKeywordPreferencesCompanion({
    this.keyword = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.hitCount = const Value.absent(),
    this.lastUsed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryKeywordPreferencesCompanion.insert({
    required String keyword,
    required String categoryId,
    this.hitCount = const Value.absent(),
    required DateTime lastUsed,
    this.rowid = const Value.absent(),
  }) : keyword = Value(keyword),
       categoryId = Value(categoryId),
       lastUsed = Value(lastUsed);
  static Insertable<CategoryKeywordPreferenceRow> custom({
    Expression<String>? keyword,
    Expression<String>? categoryId,
    Expression<int>? hitCount,
    Expression<DateTime>? lastUsed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (keyword != null) 'keyword': keyword,
      if (categoryId != null) 'category_id': categoryId,
      if (hitCount != null) 'hit_count': hitCount,
      if (lastUsed != null) 'last_used': lastUsed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryKeywordPreferencesCompanion copyWith({
    Value<String>? keyword,
    Value<String>? categoryId,
    Value<int>? hitCount,
    Value<DateTime>? lastUsed,
    Value<int>? rowid,
  }) {
    return CategoryKeywordPreferencesCompanion(
      keyword: keyword ?? this.keyword,
      categoryId: categoryId ?? this.categoryId,
      hitCount: hitCount ?? this.hitCount,
      lastUsed: lastUsed ?? this.lastUsed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (keyword.present) {
      map['keyword'] = Variable<String>(keyword.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (hitCount.present) {
      map['hit_count'] = Variable<int>(hitCount.value);
    }
    if (lastUsed.present) {
      map['last_used'] = Variable<DateTime>(lastUsed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryKeywordPreferencesCompanion(')
          ..write('keyword: $keyword, ')
          ..write('categoryId: $categoryId, ')
          ..write('hitCount: $hitCount, ')
          ..write('lastUsed: $lastUsed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryLedgerConfigsTable extends CategoryLedgerConfigs
    with TableInfo<$CategoryLedgerConfigsTable, CategoryLedgerConfigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryLedgerConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _ledgerTypeMeta = const VerificationMeta(
    'ledgerType',
  );
  @override
  late final GeneratedColumn<String> ledgerType = GeneratedColumn<String>(
    'ledger_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK(ledger_type IN (\'survival\', \'soul\'))',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [categoryId, ledgerType, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_ledger_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryLedgerConfigRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('ledger_type')) {
      context.handle(
        _ledgerTypeMeta,
        ledgerType.isAcceptableOrUnknown(data['ledger_type']!, _ledgerTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_ledgerTypeMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {categoryId};
  @override
  CategoryLedgerConfigRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryLedgerConfigRow(
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      ledgerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ledger_type'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoryLedgerConfigsTable createAlias(String alias) {
    return $CategoryLedgerConfigsTable(attachedDatabase, alias);
  }
}

class CategoryLedgerConfigRow extends DataClass
    implements Insertable<CategoryLedgerConfigRow> {
  final String categoryId;
  final String ledgerType;
  final DateTime updatedAt;
  const CategoryLedgerConfigRow({
    required this.categoryId,
    required this.ledgerType,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category_id'] = Variable<String>(categoryId);
    map['ledger_type'] = Variable<String>(ledgerType);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoryLedgerConfigsCompanion toCompanion(bool nullToAbsent) {
    return CategoryLedgerConfigsCompanion(
      categoryId: Value(categoryId),
      ledgerType: Value(ledgerType),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryLedgerConfigRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryLedgerConfigRow(
      categoryId: serializer.fromJson<String>(json['categoryId']),
      ledgerType: serializer.fromJson<String>(json['ledgerType']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'categoryId': serializer.toJson<String>(categoryId),
      'ledgerType': serializer.toJson<String>(ledgerType),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CategoryLedgerConfigRow copyWith({
    String? categoryId,
    String? ledgerType,
    DateTime? updatedAt,
  }) => CategoryLedgerConfigRow(
    categoryId: categoryId ?? this.categoryId,
    ledgerType: ledgerType ?? this.ledgerType,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoryLedgerConfigRow copyWithCompanion(
    CategoryLedgerConfigsCompanion data,
  ) {
    return CategoryLedgerConfigRow(
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      ledgerType: data.ledgerType.present
          ? data.ledgerType.value
          : this.ledgerType,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryLedgerConfigRow(')
          ..write('categoryId: $categoryId, ')
          ..write('ledgerType: $ledgerType, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(categoryId, ledgerType, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryLedgerConfigRow &&
          other.categoryId == this.categoryId &&
          other.ledgerType == this.ledgerType &&
          other.updatedAt == this.updatedAt);
}

class CategoryLedgerConfigsCompanion
    extends UpdateCompanion<CategoryLedgerConfigRow> {
  final Value<String> categoryId;
  final Value<String> ledgerType;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CategoryLedgerConfigsCompanion({
    this.categoryId = const Value.absent(),
    this.ledgerType = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryLedgerConfigsCompanion.insert({
    required String categoryId,
    required String ledgerType,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : categoryId = Value(categoryId),
       ledgerType = Value(ledgerType),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryLedgerConfigRow> custom({
    Expression<String>? categoryId,
    Expression<String>? ledgerType,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (categoryId != null) 'category_id': categoryId,
      if (ledgerType != null) 'ledger_type': ledgerType,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryLedgerConfigsCompanion copyWith({
    Value<String>? categoryId,
    Value<String>? ledgerType,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoryLedgerConfigsCompanion(
      categoryId: categoryId ?? this.categoryId,
      ledgerType: ledgerType ?? this.ledgerType,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (ledgerType.present) {
      map['ledger_type'] = Variable<String>(ledgerType.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryLedgerConfigsCompanion(')
          ..write('categoryId: $categoryId, ')
          ..write('ledgerType: $ledgerType, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTable extends GroupMembers
    with TableInfo<$GroupMembersTable, GroupMemberData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _avatarEmojiMeta = const VerificationMeta(
    'avatarEmoji',
  );
  @override
  late final GeneratedColumn<String> avatarEmoji = GeneratedColumn<String>(
    'avatar_emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('🏠'),
  );
  static const VerificationMeta _avatarImagePathMeta = const VerificationMeta(
    'avatarImagePath',
  );
  @override
  late final GeneratedColumn<String> avatarImagePath = GeneratedColumn<String>(
    'avatar_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarImageHashMeta = const VerificationMeta(
    'avatarImageHash',
  );
  @override
  late final GeneratedColumn<String> avatarImageHash = GeneratedColumn<String>(
    'avatar_image_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    deviceId,
    publicKey,
    deviceName,
    role,
    status,
    displayName,
    avatarEmoji,
    avatarImagePath,
    avatarImageHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupMemberData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('avatar_emoji')) {
      context.handle(
        _avatarEmojiMeta,
        avatarEmoji.isAcceptableOrUnknown(
          data['avatar_emoji']!,
          _avatarEmojiMeta,
        ),
      );
    }
    if (data.containsKey('avatar_image_path')) {
      context.handle(
        _avatarImagePathMeta,
        avatarImagePath.isAcceptableOrUnknown(
          data['avatar_image_path']!,
          _avatarImagePathMeta,
        ),
      );
    }
    if (data.containsKey('avatar_image_hash')) {
      context.handle(
        _avatarImageHashMeta,
        avatarImageHash.isAcceptableOrUnknown(
          data['avatar_image_hash']!,
          _avatarImageHashMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, deviceId};
  @override
  GroupMemberData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMemberData(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      avatarEmoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_emoji'],
      )!,
      avatarImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_image_path'],
      ),
      avatarImageHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_image_hash'],
      ),
    );
  }

  @override
  $GroupMembersTable createAlias(String alias) {
    return $GroupMembersTable(attachedDatabase, alias);
  }
}

class GroupMemberData extends DataClass implements Insertable<GroupMemberData> {
  final String groupId;
  final String deviceId;
  final String publicKey;
  final String deviceName;
  final String role;
  final String status;
  final String displayName;
  final String avatarEmoji;
  final String? avatarImagePath;
  final String? avatarImageHash;
  const GroupMemberData({
    required this.groupId,
    required this.deviceId,
    required this.publicKey,
    required this.deviceName,
    required this.role,
    required this.status,
    required this.displayName,
    required this.avatarEmoji,
    this.avatarImagePath,
    this.avatarImageHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['device_id'] = Variable<String>(deviceId);
    map['public_key'] = Variable<String>(publicKey);
    map['device_name'] = Variable<String>(deviceName);
    map['role'] = Variable<String>(role);
    map['status'] = Variable<String>(status);
    map['display_name'] = Variable<String>(displayName);
    map['avatar_emoji'] = Variable<String>(avatarEmoji);
    if (!nullToAbsent || avatarImagePath != null) {
      map['avatar_image_path'] = Variable<String>(avatarImagePath);
    }
    if (!nullToAbsent || avatarImageHash != null) {
      map['avatar_image_hash'] = Variable<String>(avatarImageHash);
    }
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      groupId: Value(groupId),
      deviceId: Value(deviceId),
      publicKey: Value(publicKey),
      deviceName: Value(deviceName),
      role: Value(role),
      status: Value(status),
      displayName: Value(displayName),
      avatarEmoji: Value(avatarEmoji),
      avatarImagePath: avatarImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarImagePath),
      avatarImageHash: avatarImageHash == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarImageHash),
    );
  }

  factory GroupMemberData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMemberData(
      groupId: serializer.fromJson<String>(json['groupId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      publicKey: serializer.fromJson<String>(json['publicKey']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      role: serializer.fromJson<String>(json['role']),
      status: serializer.fromJson<String>(json['status']),
      displayName: serializer.fromJson<String>(json['displayName']),
      avatarEmoji: serializer.fromJson<String>(json['avatarEmoji']),
      avatarImagePath: serializer.fromJson<String?>(json['avatarImagePath']),
      avatarImageHash: serializer.fromJson<String?>(json['avatarImageHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'deviceId': serializer.toJson<String>(deviceId),
      'publicKey': serializer.toJson<String>(publicKey),
      'deviceName': serializer.toJson<String>(deviceName),
      'role': serializer.toJson<String>(role),
      'status': serializer.toJson<String>(status),
      'displayName': serializer.toJson<String>(displayName),
      'avatarEmoji': serializer.toJson<String>(avatarEmoji),
      'avatarImagePath': serializer.toJson<String?>(avatarImagePath),
      'avatarImageHash': serializer.toJson<String?>(avatarImageHash),
    };
  }

  GroupMemberData copyWith({
    String? groupId,
    String? deviceId,
    String? publicKey,
    String? deviceName,
    String? role,
    String? status,
    String? displayName,
    String? avatarEmoji,
    Value<String?> avatarImagePath = const Value.absent(),
    Value<String?> avatarImageHash = const Value.absent(),
  }) => GroupMemberData(
    groupId: groupId ?? this.groupId,
    deviceId: deviceId ?? this.deviceId,
    publicKey: publicKey ?? this.publicKey,
    deviceName: deviceName ?? this.deviceName,
    role: role ?? this.role,
    status: status ?? this.status,
    displayName: displayName ?? this.displayName,
    avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    avatarImagePath: avatarImagePath.present
        ? avatarImagePath.value
        : this.avatarImagePath,
    avatarImageHash: avatarImageHash.present
        ? avatarImageHash.value
        : this.avatarImageHash,
  );
  GroupMemberData copyWithCompanion(GroupMembersCompanion data) {
    return GroupMemberData(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      role: data.role.present ? data.role.value : this.role,
      status: data.status.present ? data.status.value : this.status,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarEmoji: data.avatarEmoji.present
          ? data.avatarEmoji.value
          : this.avatarEmoji,
      avatarImagePath: data.avatarImagePath.present
          ? data.avatarImagePath.value
          : this.avatarImagePath,
      avatarImageHash: data.avatarImageHash.present
          ? data.avatarImageHash.value
          : this.avatarImageHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMemberData(')
          ..write('groupId: $groupId, ')
          ..write('deviceId: $deviceId, ')
          ..write('publicKey: $publicKey, ')
          ..write('deviceName: $deviceName, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('displayName: $displayName, ')
          ..write('avatarEmoji: $avatarEmoji, ')
          ..write('avatarImagePath: $avatarImagePath, ')
          ..write('avatarImageHash: $avatarImageHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    groupId,
    deviceId,
    publicKey,
    deviceName,
    role,
    status,
    displayName,
    avatarEmoji,
    avatarImagePath,
    avatarImageHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMemberData &&
          other.groupId == this.groupId &&
          other.deviceId == this.deviceId &&
          other.publicKey == this.publicKey &&
          other.deviceName == this.deviceName &&
          other.role == this.role &&
          other.status == this.status &&
          other.displayName == this.displayName &&
          other.avatarEmoji == this.avatarEmoji &&
          other.avatarImagePath == this.avatarImagePath &&
          other.avatarImageHash == this.avatarImageHash);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMemberData> {
  final Value<String> groupId;
  final Value<String> deviceId;
  final Value<String> publicKey;
  final Value<String> deviceName;
  final Value<String> role;
  final Value<String> status;
  final Value<String> displayName;
  final Value<String> avatarEmoji;
  final Value<String?> avatarImagePath;
  final Value<String?> avatarImageHash;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.groupId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.role = const Value.absent(),
    this.status = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarEmoji = const Value.absent(),
    this.avatarImagePath = const Value.absent(),
    this.avatarImageHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required String groupId,
    required String deviceId,
    required String publicKey,
    required String deviceName,
    required String role,
    required String status,
    this.displayName = const Value.absent(),
    this.avatarEmoji = const Value.absent(),
    this.avatarImagePath = const Value.absent(),
    this.avatarImageHash = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       deviceId = Value(deviceId),
       publicKey = Value(publicKey),
       deviceName = Value(deviceName),
       role = Value(role),
       status = Value(status);
  static Insertable<GroupMemberData> custom({
    Expression<String>? groupId,
    Expression<String>? deviceId,
    Expression<String>? publicKey,
    Expression<String>? deviceName,
    Expression<String>? role,
    Expression<String>? status,
    Expression<String>? displayName,
    Expression<String>? avatarEmoji,
    Expression<String>? avatarImagePath,
    Expression<String>? avatarImageHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (deviceId != null) 'device_id': deviceId,
      if (publicKey != null) 'public_key': publicKey,
      if (deviceName != null) 'device_name': deviceName,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
      if (displayName != null) 'display_name': displayName,
      if (avatarEmoji != null) 'avatar_emoji': avatarEmoji,
      if (avatarImagePath != null) 'avatar_image_path': avatarImagePath,
      if (avatarImageHash != null) 'avatar_image_hash': avatarImageHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith({
    Value<String>? groupId,
    Value<String>? deviceId,
    Value<String>? publicKey,
    Value<String>? deviceName,
    Value<String>? role,
    Value<String>? status,
    Value<String>? displayName,
    Value<String>? avatarEmoji,
    Value<String?>? avatarImagePath,
    Value<String?>? avatarImageHash,
    Value<int>? rowid,
  }) {
    return GroupMembersCompanion(
      groupId: groupId ?? this.groupId,
      deviceId: deviceId ?? this.deviceId,
      publicKey: publicKey ?? this.publicKey,
      deviceName: deviceName ?? this.deviceName,
      role: role ?? this.role,
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarImagePath: avatarImagePath ?? this.avatarImagePath,
      avatarImageHash: avatarImageHash ?? this.avatarImageHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarEmoji.present) {
      map['avatar_emoji'] = Variable<String>(avatarEmoji.value);
    }
    if (avatarImagePath.present) {
      map['avatar_image_path'] = Variable<String>(avatarImagePath.value);
    }
    if (avatarImageHash.present) {
      map['avatar_image_hash'] = Variable<String>(avatarImageHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('groupId: $groupId, ')
          ..write('deviceId: $deviceId, ')
          ..write('publicKey: $publicKey, ')
          ..write('deviceName: $deviceName, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('displayName: $displayName, ')
          ..write('avatarEmoji: $avatarEmoji, ')
          ..write('avatarImagePath: $avatarImagePath, ')
          ..write('avatarImageHash: $avatarImageHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, GroupData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _inviteCodeMeta = const VerificationMeta(
    'inviteCode',
  );
  @override
  late final GeneratedColumn<String> inviteCode = GeneratedColumn<String>(
    'invite_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inviteExpiresAtMeta = const VerificationMeta(
    'inviteExpiresAt',
  );
  @override
  late final GeneratedColumn<int> inviteExpiresAt = GeneratedColumn<int>(
    'invite_expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupKeyMeta = const VerificationMeta(
    'groupKey',
  );
  @override
  late final GeneratedColumn<String> groupKey = GeneratedColumn<String>(
    'group_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<int> confirmedAt = GeneratedColumn<int>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncAt = GeneratedColumn<int>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    status,
    role,
    groupName,
    inviteCode,
    inviteExpiresAt,
    groupKey,
    createdAt,
    confirmedAt,
    lastSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    if (data.containsKey('invite_code')) {
      context.handle(
        _inviteCodeMeta,
        inviteCode.isAcceptableOrUnknown(data['invite_code']!, _inviteCodeMeta),
      );
    }
    if (data.containsKey('invite_expires_at')) {
      context.handle(
        _inviteExpiresAtMeta,
        inviteExpiresAt.isAcceptableOrUnknown(
          data['invite_expires_at']!,
          _inviteExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('group_key')) {
      context.handle(
        _groupKeyMeta,
        groupKey.isAcceptableOrUnknown(data['group_key']!, _groupKeyMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  GroupData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupData(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      )!,
      inviteCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invite_code'],
      ),
      inviteExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}invite_expires_at'],
      ),
      groupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_key'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}confirmed_at'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync_at'],
      ),
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class GroupData extends DataClass implements Insertable<GroupData> {
  final String groupId;
  final String status;
  final String role;
  final String groupName;
  final String? inviteCode;
  final int? inviteExpiresAt;
  final String? groupKey;
  final int createdAt;
  final int? confirmedAt;
  final int? lastSyncAt;
  const GroupData({
    required this.groupId,
    required this.status,
    required this.role,
    required this.groupName,
    this.inviteCode,
    this.inviteExpiresAt,
    this.groupKey,
    required this.createdAt,
    this.confirmedAt,
    this.lastSyncAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['status'] = Variable<String>(status);
    map['role'] = Variable<String>(role);
    map['group_name'] = Variable<String>(groupName);
    if (!nullToAbsent || inviteCode != null) {
      map['invite_code'] = Variable<String>(inviteCode);
    }
    if (!nullToAbsent || inviteExpiresAt != null) {
      map['invite_expires_at'] = Variable<int>(inviteExpiresAt);
    }
    if (!nullToAbsent || groupKey != null) {
      map['group_key'] = Variable<String>(groupKey);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<int>(confirmedAt);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<int>(lastSyncAt);
    }
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      groupId: Value(groupId),
      status: Value(status),
      role: Value(role),
      groupName: Value(groupName),
      inviteCode: inviteCode == null && nullToAbsent
          ? const Value.absent()
          : Value(inviteCode),
      inviteExpiresAt: inviteExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(inviteExpiresAt),
      groupKey: groupKey == null && nullToAbsent
          ? const Value.absent()
          : Value(groupKey),
      createdAt: Value(createdAt),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory GroupData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupData(
      groupId: serializer.fromJson<String>(json['groupId']),
      status: serializer.fromJson<String>(json['status']),
      role: serializer.fromJson<String>(json['role']),
      groupName: serializer.fromJson<String>(json['groupName']),
      inviteCode: serializer.fromJson<String?>(json['inviteCode']),
      inviteExpiresAt: serializer.fromJson<int?>(json['inviteExpiresAt']),
      groupKey: serializer.fromJson<String?>(json['groupKey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      confirmedAt: serializer.fromJson<int?>(json['confirmedAt']),
      lastSyncAt: serializer.fromJson<int?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'status': serializer.toJson<String>(status),
      'role': serializer.toJson<String>(role),
      'groupName': serializer.toJson<String>(groupName),
      'inviteCode': serializer.toJson<String?>(inviteCode),
      'inviteExpiresAt': serializer.toJson<int?>(inviteExpiresAt),
      'groupKey': serializer.toJson<String?>(groupKey),
      'createdAt': serializer.toJson<int>(createdAt),
      'confirmedAt': serializer.toJson<int?>(confirmedAt),
      'lastSyncAt': serializer.toJson<int?>(lastSyncAt),
    };
  }

  GroupData copyWith({
    String? groupId,
    String? status,
    String? role,
    String? groupName,
    Value<String?> inviteCode = const Value.absent(),
    Value<int?> inviteExpiresAt = const Value.absent(),
    Value<String?> groupKey = const Value.absent(),
    int? createdAt,
    Value<int?> confirmedAt = const Value.absent(),
    Value<int?> lastSyncAt = const Value.absent(),
  }) => GroupData(
    groupId: groupId ?? this.groupId,
    status: status ?? this.status,
    role: role ?? this.role,
    groupName: groupName ?? this.groupName,
    inviteCode: inviteCode.present ? inviteCode.value : this.inviteCode,
    inviteExpiresAt: inviteExpiresAt.present
        ? inviteExpiresAt.value
        : this.inviteExpiresAt,
    groupKey: groupKey.present ? groupKey.value : this.groupKey,
    createdAt: createdAt ?? this.createdAt,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
  );
  GroupData copyWithCompanion(GroupsCompanion data) {
    return GroupData(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      status: data.status.present ? data.status.value : this.status,
      role: data.role.present ? data.role.value : this.role,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      inviteCode: data.inviteCode.present
          ? data.inviteCode.value
          : this.inviteCode,
      inviteExpiresAt: data.inviteExpiresAt.present
          ? data.inviteExpiresAt.value
          : this.inviteExpiresAt,
      groupKey: data.groupKey.present ? data.groupKey.value : this.groupKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupData(')
          ..write('groupId: $groupId, ')
          ..write('status: $status, ')
          ..write('role: $role, ')
          ..write('groupName: $groupName, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('inviteExpiresAt: $inviteExpiresAt, ')
          ..write('groupKey: $groupKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    groupId,
    status,
    role,
    groupName,
    inviteCode,
    inviteExpiresAt,
    groupKey,
    createdAt,
    confirmedAt,
    lastSyncAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupData &&
          other.groupId == this.groupId &&
          other.status == this.status &&
          other.role == this.role &&
          other.groupName == this.groupName &&
          other.inviteCode == this.inviteCode &&
          other.inviteExpiresAt == this.inviteExpiresAt &&
          other.groupKey == this.groupKey &&
          other.createdAt == this.createdAt &&
          other.confirmedAt == this.confirmedAt &&
          other.lastSyncAt == this.lastSyncAt);
}

class GroupsCompanion extends UpdateCompanion<GroupData> {
  final Value<String> groupId;
  final Value<String> status;
  final Value<String> role;
  final Value<String> groupName;
  final Value<String?> inviteCode;
  final Value<int?> inviteExpiresAt;
  final Value<String?> groupKey;
  final Value<int> createdAt;
  final Value<int?> confirmedAt;
  final Value<int?> lastSyncAt;
  final Value<int> rowid;
  const GroupsCompanion({
    this.groupId = const Value.absent(),
    this.status = const Value.absent(),
    this.role = const Value.absent(),
    this.groupName = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.inviteExpiresAt = const Value.absent(),
    this.groupKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String groupId,
    required String status,
    required String role,
    this.groupName = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.inviteExpiresAt = const Value.absent(),
    this.groupKey = const Value.absent(),
    required int createdAt,
    this.confirmedAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       status = Value(status),
       role = Value(role),
       createdAt = Value(createdAt);
  static Insertable<GroupData> custom({
    Expression<String>? groupId,
    Expression<String>? status,
    Expression<String>? role,
    Expression<String>? groupName,
    Expression<String>? inviteCode,
    Expression<int>? inviteExpiresAt,
    Expression<String>? groupKey,
    Expression<int>? createdAt,
    Expression<int>? confirmedAt,
    Expression<int>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (status != null) 'status': status,
      if (role != null) 'role': role,
      if (groupName != null) 'group_name': groupName,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (inviteExpiresAt != null) 'invite_expires_at': inviteExpiresAt,
      if (groupKey != null) 'group_key': groupKey,
      if (createdAt != null) 'created_at': createdAt,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith({
    Value<String>? groupId,
    Value<String>? status,
    Value<String>? role,
    Value<String>? groupName,
    Value<String?>? inviteCode,
    Value<int?>? inviteExpiresAt,
    Value<String?>? groupKey,
    Value<int>? createdAt,
    Value<int?>? confirmedAt,
    Value<int?>? lastSyncAt,
    Value<int>? rowid,
  }) {
    return GroupsCompanion(
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      role: role ?? this.role,
      groupName: groupName ?? this.groupName,
      inviteCode: inviteCode ?? this.inviteCode,
      inviteExpiresAt: inviteExpiresAt ?? this.inviteExpiresAt,
      groupKey: groupKey ?? this.groupKey,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (inviteCode.present) {
      map['invite_code'] = Variable<String>(inviteCode.value);
    }
    if (inviteExpiresAt.present) {
      map['invite_expires_at'] = Variable<int>(inviteExpiresAt.value);
    }
    if (groupKey.present) {
      map['group_key'] = Variable<String>(groupKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<int>(confirmedAt.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<int>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('status: $status, ')
          ..write('role: $role, ')
          ..write('groupName: $groupName, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('inviteExpiresAt: $inviteExpiresAt, ')
          ..write('groupKey: $groupKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MerchantCategoryPreferencesTable extends MerchantCategoryPreferences
    with
        TableInfo<
          $MerchantCategoryPreferencesTable,
          MerchantCategoryPreferenceRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MerchantCategoryPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _merchantKeyMeta = const VerificationMeta(
    'merchantKey',
  );
  @override
  late final GeneratedColumn<String> merchantKey = GeneratedColumn<String>(
    'merchant_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preferredCategoryIdMeta =
      const VerificationMeta('preferredCategoryId');
  @override
  late final GeneratedColumn<String> preferredCategoryId =
      GeneratedColumn<String>(
        'preferred_category_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastOverrideCategoryIdMeta =
      const VerificationMeta('lastOverrideCategoryId');
  @override
  late final GeneratedColumn<String> lastOverrideCategoryId =
      GeneratedColumn<String>(
        'last_override_category_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _overrideStreakMeta = const VerificationMeta(
    'overrideStreak',
  );
  @override
  late final GeneratedColumn<int> overrideStreak = GeneratedColumn<int>(
    'override_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    merchantKey,
    preferredCategoryId,
    lastOverrideCategoryId,
    overrideStreak,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merchant_category_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<MerchantCategoryPreferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('merchant_key')) {
      context.handle(
        _merchantKeyMeta,
        merchantKey.isAcceptableOrUnknown(
          data['merchant_key']!,
          _merchantKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantKeyMeta);
    }
    if (data.containsKey('preferred_category_id')) {
      context.handle(
        _preferredCategoryIdMeta,
        preferredCategoryId.isAcceptableOrUnknown(
          data['preferred_category_id']!,
          _preferredCategoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_preferredCategoryIdMeta);
    }
    if (data.containsKey('last_override_category_id')) {
      context.handle(
        _lastOverrideCategoryIdMeta,
        lastOverrideCategoryId.isAcceptableOrUnknown(
          data['last_override_category_id']!,
          _lastOverrideCategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('override_streak')) {
      context.handle(
        _overrideStreakMeta,
        overrideStreak.isAcceptableOrUnknown(
          data['override_streak']!,
          _overrideStreakMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {merchantKey};
  @override
  MerchantCategoryPreferenceRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MerchantCategoryPreferenceRow(
      merchantKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_key'],
      )!,
      preferredCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_category_id'],
      )!,
      lastOverrideCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_override_category_id'],
      ),
      overrideStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}override_streak'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MerchantCategoryPreferencesTable createAlias(String alias) {
    return $MerchantCategoryPreferencesTable(attachedDatabase, alias);
  }
}

class MerchantCategoryPreferenceRow extends DataClass
    implements Insertable<MerchantCategoryPreferenceRow> {
  final String merchantKey;
  final String preferredCategoryId;
  final String? lastOverrideCategoryId;
  final int overrideStreak;
  final DateTime updatedAt;
  const MerchantCategoryPreferenceRow({
    required this.merchantKey,
    required this.preferredCategoryId,
    this.lastOverrideCategoryId,
    required this.overrideStreak,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['merchant_key'] = Variable<String>(merchantKey);
    map['preferred_category_id'] = Variable<String>(preferredCategoryId);
    if (!nullToAbsent || lastOverrideCategoryId != null) {
      map['last_override_category_id'] = Variable<String>(
        lastOverrideCategoryId,
      );
    }
    map['override_streak'] = Variable<int>(overrideStreak);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MerchantCategoryPreferencesCompanion toCompanion(bool nullToAbsent) {
    return MerchantCategoryPreferencesCompanion(
      merchantKey: Value(merchantKey),
      preferredCategoryId: Value(preferredCategoryId),
      lastOverrideCategoryId: lastOverrideCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOverrideCategoryId),
      overrideStreak: Value(overrideStreak),
      updatedAt: Value(updatedAt),
    );
  }

  factory MerchantCategoryPreferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MerchantCategoryPreferenceRow(
      merchantKey: serializer.fromJson<String>(json['merchantKey']),
      preferredCategoryId: serializer.fromJson<String>(
        json['preferredCategoryId'],
      ),
      lastOverrideCategoryId: serializer.fromJson<String?>(
        json['lastOverrideCategoryId'],
      ),
      overrideStreak: serializer.fromJson<int>(json['overrideStreak']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'merchantKey': serializer.toJson<String>(merchantKey),
      'preferredCategoryId': serializer.toJson<String>(preferredCategoryId),
      'lastOverrideCategoryId': serializer.toJson<String?>(
        lastOverrideCategoryId,
      ),
      'overrideStreak': serializer.toJson<int>(overrideStreak),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MerchantCategoryPreferenceRow copyWith({
    String? merchantKey,
    String? preferredCategoryId,
    Value<String?> lastOverrideCategoryId = const Value.absent(),
    int? overrideStreak,
    DateTime? updatedAt,
  }) => MerchantCategoryPreferenceRow(
    merchantKey: merchantKey ?? this.merchantKey,
    preferredCategoryId: preferredCategoryId ?? this.preferredCategoryId,
    lastOverrideCategoryId: lastOverrideCategoryId.present
        ? lastOverrideCategoryId.value
        : this.lastOverrideCategoryId,
    overrideStreak: overrideStreak ?? this.overrideStreak,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MerchantCategoryPreferenceRow copyWithCompanion(
    MerchantCategoryPreferencesCompanion data,
  ) {
    return MerchantCategoryPreferenceRow(
      merchantKey: data.merchantKey.present
          ? data.merchantKey.value
          : this.merchantKey,
      preferredCategoryId: data.preferredCategoryId.present
          ? data.preferredCategoryId.value
          : this.preferredCategoryId,
      lastOverrideCategoryId: data.lastOverrideCategoryId.present
          ? data.lastOverrideCategoryId.value
          : this.lastOverrideCategoryId,
      overrideStreak: data.overrideStreak.present
          ? data.overrideStreak.value
          : this.overrideStreak,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MerchantCategoryPreferenceRow(')
          ..write('merchantKey: $merchantKey, ')
          ..write('preferredCategoryId: $preferredCategoryId, ')
          ..write('lastOverrideCategoryId: $lastOverrideCategoryId, ')
          ..write('overrideStreak: $overrideStreak, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    merchantKey,
    preferredCategoryId,
    lastOverrideCategoryId,
    overrideStreak,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MerchantCategoryPreferenceRow &&
          other.merchantKey == this.merchantKey &&
          other.preferredCategoryId == this.preferredCategoryId &&
          other.lastOverrideCategoryId == this.lastOverrideCategoryId &&
          other.overrideStreak == this.overrideStreak &&
          other.updatedAt == this.updatedAt);
}

class MerchantCategoryPreferencesCompanion
    extends UpdateCompanion<MerchantCategoryPreferenceRow> {
  final Value<String> merchantKey;
  final Value<String> preferredCategoryId;
  final Value<String?> lastOverrideCategoryId;
  final Value<int> overrideStreak;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MerchantCategoryPreferencesCompanion({
    this.merchantKey = const Value.absent(),
    this.preferredCategoryId = const Value.absent(),
    this.lastOverrideCategoryId = const Value.absent(),
    this.overrideStreak = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MerchantCategoryPreferencesCompanion.insert({
    required String merchantKey,
    required String preferredCategoryId,
    this.lastOverrideCategoryId = const Value.absent(),
    this.overrideStreak = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : merchantKey = Value(merchantKey),
       preferredCategoryId = Value(preferredCategoryId),
       updatedAt = Value(updatedAt);
  static Insertable<MerchantCategoryPreferenceRow> custom({
    Expression<String>? merchantKey,
    Expression<String>? preferredCategoryId,
    Expression<String>? lastOverrideCategoryId,
    Expression<int>? overrideStreak,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (merchantKey != null) 'merchant_key': merchantKey,
      if (preferredCategoryId != null)
        'preferred_category_id': preferredCategoryId,
      if (lastOverrideCategoryId != null)
        'last_override_category_id': lastOverrideCategoryId,
      if (overrideStreak != null) 'override_streak': overrideStreak,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MerchantCategoryPreferencesCompanion copyWith({
    Value<String>? merchantKey,
    Value<String>? preferredCategoryId,
    Value<String?>? lastOverrideCategoryId,
    Value<int>? overrideStreak,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MerchantCategoryPreferencesCompanion(
      merchantKey: merchantKey ?? this.merchantKey,
      preferredCategoryId: preferredCategoryId ?? this.preferredCategoryId,
      lastOverrideCategoryId:
          lastOverrideCategoryId ?? this.lastOverrideCategoryId,
      overrideStreak: overrideStreak ?? this.overrideStreak,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (merchantKey.present) {
      map['merchant_key'] = Variable<String>(merchantKey.value);
    }
    if (preferredCategoryId.present) {
      map['preferred_category_id'] = Variable<String>(
        preferredCategoryId.value,
      );
    }
    if (lastOverrideCategoryId.present) {
      map['last_override_category_id'] = Variable<String>(
        lastOverrideCategoryId.value,
      );
    }
    if (overrideStreak.present) {
      map['override_streak'] = Variable<int>(overrideStreak.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MerchantCategoryPreferencesCompanion(')
          ..write('merchantKey: $merchantKey, ')
          ..write('preferredCategoryId: $preferredCategoryId, ')
          ..write('lastOverrideCategoryId: $lastOverrideCategoryId, ')
          ..write('overrideStreak: $overrideStreak, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedPayloadMeta = const VerificationMeta(
    'encryptedPayload',
  );
  @override
  late final GeneratedColumn<String> encryptedPayload = GeneratedColumn<String>(
    'encrypted_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vectorClockMeta = const VerificationMeta(
    'vectorClock',
  );
  @override
  late final GeneratedColumn<String> vectorClock = GeneratedColumn<String>(
    'vector_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationCountMeta = const VerificationMeta(
    'operationCount',
  );
  @override
  late final GeneratedColumn<int> operationCount = GeneratedColumn<int>(
    'operation_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    encryptedPayload,
    vectorClock,
    operationCount,
    retryCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('encrypted_payload')) {
      context.handle(
        _encryptedPayloadMeta,
        encryptedPayload.isAcceptableOrUnknown(
          data['encrypted_payload']!,
          _encryptedPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedPayloadMeta);
    }
    if (data.containsKey('vector_clock')) {
      context.handle(
        _vectorClockMeta,
        vectorClock.isAcceptableOrUnknown(
          data['vector_clock']!,
          _vectorClockMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vectorClockMeta);
    }
    if (data.containsKey('operation_count')) {
      context.handle(
        _operationCountMeta,
        operationCount.isAcceptableOrUnknown(
          data['operation_count']!,
          _operationCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationCountMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      encryptedPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_payload'],
      )!,
      vectorClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vector_clock'],
      )!,
      operationCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}operation_count'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;
  final String groupId;
  final String encryptedPayload;
  final String vectorClock;
  final int operationCount;
  final int retryCount;
  final int createdAt;
  const SyncQueueData({
    required this.id,
    required this.groupId,
    required this.encryptedPayload,
    required this.vectorClock,
    required this.operationCount,
    required this.retryCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['encrypted_payload'] = Variable<String>(encryptedPayload);
    map['vector_clock'] = Variable<String>(vectorClock);
    map['operation_count'] = Variable<int>(operationCount);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      groupId: Value(groupId),
      encryptedPayload: Value(encryptedPayload),
      vectorClock: Value(vectorClock),
      operationCount: Value(operationCount),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      encryptedPayload: serializer.fromJson<String>(json['encryptedPayload']),
      vectorClock: serializer.fromJson<String>(json['vectorClock']),
      operationCount: serializer.fromJson<int>(json['operationCount']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'encryptedPayload': serializer.toJson<String>(encryptedPayload),
      'vectorClock': serializer.toJson<String>(vectorClock),
      'operationCount': serializer.toJson<int>(operationCount),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SyncQueueData copyWith({
    String? id,
    String? groupId,
    String? encryptedPayload,
    String? vectorClock,
    int? operationCount,
    int? retryCount,
    int? createdAt,
  }) => SyncQueueData(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    encryptedPayload: encryptedPayload ?? this.encryptedPayload,
    vectorClock: vectorClock ?? this.vectorClock,
    operationCount: operationCount ?? this.operationCount,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      encryptedPayload: data.encryptedPayload.present
          ? data.encryptedPayload.value
          : this.encryptedPayload,
      vectorClock: data.vectorClock.present
          ? data.vectorClock.value
          : this.vectorClock,
      operationCount: data.operationCount.present
          ? data.operationCount.value
          : this.operationCount,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('vectorClock: $vectorClock, ')
          ..write('operationCount: $operationCount, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    encryptedPayload,
    vectorClock,
    operationCount,
    retryCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.encryptedPayload == this.encryptedPayload &&
          other.vectorClock == this.vectorClock &&
          other.operationCount == this.operationCount &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> encryptedPayload;
  final Value<String> vectorClock;
  final Value<int> operationCount;
  final Value<int> retryCount;
  final Value<int> createdAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.encryptedPayload = const Value.absent(),
    this.vectorClock = const Value.absent(),
    this.operationCount = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String groupId,
    required String encryptedPayload,
    required String vectorClock,
    required int operationCount,
    this.retryCount = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       encryptedPayload = Value(encryptedPayload),
       vectorClock = Value(vectorClock),
       operationCount = Value(operationCount),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? encryptedPayload,
    Expression<String>? vectorClock,
    Expression<int>? operationCount,
    Expression<int>? retryCount,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (encryptedPayload != null) 'encrypted_payload': encryptedPayload,
      if (vectorClock != null) 'vector_clock': vectorClock,
      if (operationCount != null) 'operation_count': operationCount,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? encryptedPayload,
    Value<String>? vectorClock,
    Value<int>? operationCount,
    Value<int>? retryCount,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      vectorClock: vectorClock ?? this.vectorClock,
      operationCount: operationCount ?? this.operationCount,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (encryptedPayload.present) {
      map['encrypted_payload'] = Variable<String>(encryptedPayload.value);
    }
    if (vectorClock.present) {
      map['vector_clock'] = Variable<String>(vectorClock.value);
    }
    if (operationCount.present) {
      map['operation_count'] = Variable<int>(operationCount.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('vectorClock: $vectorClock, ')
          ..write('operationCount: $operationCount, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ledgerTypeMeta = const VerificationMeta(
    'ledgerType',
  );
  @override
  late final GeneratedColumn<String> ledgerType = GeneratedColumn<String>(
    'ledger_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoHashMeta = const VerificationMeta(
    'photoHash',
  );
  @override
  late final GeneratedColumn<String> photoHash = GeneratedColumn<String>(
    'photo_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prevHashMeta = const VerificationMeta(
    'prevHash',
  );
  @override
  late final GeneratedColumn<String> prevHash = GeneratedColumn<String>(
    'prev_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentHashMeta = const VerificationMeta(
    'currentHash',
  );
  @override
  late final GeneratedColumn<String> currentHash = GeneratedColumn<String>(
    'current_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrivateMeta = const VerificationMeta(
    'isPrivate',
  );
  @override
  late final GeneratedColumn<bool> isPrivate = GeneratedColumn<bool>(
    'is_private',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_private" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _soulSatisfactionMeta = const VerificationMeta(
    'soulSatisfaction',
  );
  @override
  late final GeneratedColumn<int> soulSatisfaction = GeneratedColumn<int>(
    'soul_satisfaction',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    deviceId,
    amount,
    type,
    categoryId,
    ledgerType,
    timestamp,
    note,
    photoHash,
    merchant,
    metadata,
    prevHash,
    currentHash,
    createdAt,
    updatedAt,
    isPrivate,
    isSynced,
    isDeleted,
    soulSatisfaction,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('ledger_type')) {
      context.handle(
        _ledgerTypeMeta,
        ledgerType.isAcceptableOrUnknown(data['ledger_type']!, _ledgerTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_ledgerTypeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('photo_hash')) {
      context.handle(
        _photoHashMeta,
        photoHash.isAcceptableOrUnknown(data['photo_hash']!, _photoHashMeta),
      );
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('prev_hash')) {
      context.handle(
        _prevHashMeta,
        prevHash.isAcceptableOrUnknown(data['prev_hash']!, _prevHashMeta),
      );
    }
    if (data.containsKey('current_hash')) {
      context.handle(
        _currentHashMeta,
        currentHash.isAcceptableOrUnknown(
          data['current_hash']!,
          _currentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentHashMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_private')) {
      context.handle(
        _isPrivateMeta,
        isPrivate.isAcceptableOrUnknown(data['is_private']!, _isPrivateMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('soul_satisfaction')) {
      context.handle(
        _soulSatisfactionMeta,
        soulSatisfaction.isAcceptableOrUnknown(
          data['soul_satisfaction']!,
          _soulSatisfactionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      ledgerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ledger_type'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      photoHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_hash'],
      ),
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      prevHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prev_hash'],
      ),
      currentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_hash'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isPrivate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_private'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      soulSatisfaction: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}soul_satisfaction'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final String id;
  final String bookId;
  final String deviceId;
  final int amount;
  final String type;
  final String categoryId;
  final String ledgerType;
  final DateTime timestamp;
  final String? note;
  final String? photoHash;
  final String? merchant;
  final String? metadata;
  final String? prevHash;
  final String currentHash;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPrivate;
  final bool isSynced;
  final bool isDeleted;
  final int soulSatisfaction;
  const TransactionRow({
    required this.id,
    required this.bookId,
    required this.deviceId,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.ledgerType,
    required this.timestamp,
    this.note,
    this.photoHash,
    this.merchant,
    this.metadata,
    this.prevHash,
    required this.currentHash,
    required this.createdAt,
    this.updatedAt,
    required this.isPrivate,
    required this.isSynced,
    required this.isDeleted,
    required this.soulSatisfaction,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['device_id'] = Variable<String>(deviceId);
    map['amount'] = Variable<int>(amount);
    map['type'] = Variable<String>(type);
    map['category_id'] = Variable<String>(categoryId);
    map['ledger_type'] = Variable<String>(ledgerType);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || photoHash != null) {
      map['photo_hash'] = Variable<String>(photoHash);
    }
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    if (!nullToAbsent || prevHash != null) {
      map['prev_hash'] = Variable<String>(prevHash);
    }
    map['current_hash'] = Variable<String>(currentHash);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_private'] = Variable<bool>(isPrivate);
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['soul_satisfaction'] = Variable<int>(soulSatisfaction);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      deviceId: Value(deviceId),
      amount: Value(amount),
      type: Value(type),
      categoryId: Value(categoryId),
      ledgerType: Value(ledgerType),
      timestamp: Value(timestamp),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      photoHash: photoHash == null && nullToAbsent
          ? const Value.absent()
          : Value(photoHash),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      prevHash: prevHash == null && nullToAbsent
          ? const Value.absent()
          : Value(prevHash),
      currentHash: Value(currentHash),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isPrivate: Value(isPrivate),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
      soulSatisfaction: Value(soulSatisfaction),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      amount: serializer.fromJson<int>(json['amount']),
      type: serializer.fromJson<String>(json['type']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      ledgerType: serializer.fromJson<String>(json['ledgerType']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      note: serializer.fromJson<String?>(json['note']),
      photoHash: serializer.fromJson<String?>(json['photoHash']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      prevHash: serializer.fromJson<String?>(json['prevHash']),
      currentHash: serializer.fromJson<String>(json['currentHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isPrivate: serializer.fromJson<bool>(json['isPrivate']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      soulSatisfaction: serializer.fromJson<int>(json['soulSatisfaction']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'deviceId': serializer.toJson<String>(deviceId),
      'amount': serializer.toJson<int>(amount),
      'type': serializer.toJson<String>(type),
      'categoryId': serializer.toJson<String>(categoryId),
      'ledgerType': serializer.toJson<String>(ledgerType),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'note': serializer.toJson<String?>(note),
      'photoHash': serializer.toJson<String?>(photoHash),
      'merchant': serializer.toJson<String?>(merchant),
      'metadata': serializer.toJson<String?>(metadata),
      'prevHash': serializer.toJson<String?>(prevHash),
      'currentHash': serializer.toJson<String>(currentHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isPrivate': serializer.toJson<bool>(isPrivate),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'soulSatisfaction': serializer.toJson<int>(soulSatisfaction),
    };
  }

  TransactionRow copyWith({
    String? id,
    String? bookId,
    String? deviceId,
    int? amount,
    String? type,
    String? categoryId,
    String? ledgerType,
    DateTime? timestamp,
    Value<String?> note = const Value.absent(),
    Value<String?> photoHash = const Value.absent(),
    Value<String?> merchant = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    Value<String?> prevHash = const Value.absent(),
    String? currentHash,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isPrivate,
    bool? isSynced,
    bool? isDeleted,
    int? soulSatisfaction,
  }) => TransactionRow(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    deviceId: deviceId ?? this.deviceId,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    categoryId: categoryId ?? this.categoryId,
    ledgerType: ledgerType ?? this.ledgerType,
    timestamp: timestamp ?? this.timestamp,
    note: note.present ? note.value : this.note,
    photoHash: photoHash.present ? photoHash.value : this.photoHash,
    merchant: merchant.present ? merchant.value : this.merchant,
    metadata: metadata.present ? metadata.value : this.metadata,
    prevHash: prevHash.present ? prevHash.value : this.prevHash,
    currentHash: currentHash ?? this.currentHash,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isPrivate: isPrivate ?? this.isPrivate,
    isSynced: isSynced ?? this.isSynced,
    isDeleted: isDeleted ?? this.isDeleted,
    soulSatisfaction: soulSatisfaction ?? this.soulSatisfaction,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      ledgerType: data.ledgerType.present
          ? data.ledgerType.value
          : this.ledgerType,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      note: data.note.present ? data.note.value : this.note,
      photoHash: data.photoHash.present ? data.photoHash.value : this.photoHash,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      prevHash: data.prevHash.present ? data.prevHash.value : this.prevHash,
      currentHash: data.currentHash.present
          ? data.currentHash.value
          : this.currentHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isPrivate: data.isPrivate.present ? data.isPrivate.value : this.isPrivate,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      soulSatisfaction: data.soulSatisfaction.present
          ? data.soulSatisfaction.value
          : this.soulSatisfaction,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('deviceId: $deviceId, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('categoryId: $categoryId, ')
          ..write('ledgerType: $ledgerType, ')
          ..write('timestamp: $timestamp, ')
          ..write('note: $note, ')
          ..write('photoHash: $photoHash, ')
          ..write('merchant: $merchant, ')
          ..write('metadata: $metadata, ')
          ..write('prevHash: $prevHash, ')
          ..write('currentHash: $currentHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('soulSatisfaction: $soulSatisfaction')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    deviceId,
    amount,
    type,
    categoryId,
    ledgerType,
    timestamp,
    note,
    photoHash,
    merchant,
    metadata,
    prevHash,
    currentHash,
    createdAt,
    updatedAt,
    isPrivate,
    isSynced,
    isDeleted,
    soulSatisfaction,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.deviceId == this.deviceId &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.categoryId == this.categoryId &&
          other.ledgerType == this.ledgerType &&
          other.timestamp == this.timestamp &&
          other.note == this.note &&
          other.photoHash == this.photoHash &&
          other.merchant == this.merchant &&
          other.metadata == this.metadata &&
          other.prevHash == this.prevHash &&
          other.currentHash == this.currentHash &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isPrivate == this.isPrivate &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted &&
          other.soulSatisfaction == this.soulSatisfaction);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> deviceId;
  final Value<int> amount;
  final Value<String> type;
  final Value<String> categoryId;
  final Value<String> ledgerType;
  final Value<DateTime> timestamp;
  final Value<String?> note;
  final Value<String?> photoHash;
  final Value<String?> merchant;
  final Value<String?> metadata;
  final Value<String?> prevHash;
  final Value<String> currentHash;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<bool> isPrivate;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  final Value<int> soulSatisfaction;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.ledgerType = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.note = const Value.absent(),
    this.photoHash = const Value.absent(),
    this.merchant = const Value.absent(),
    this.metadata = const Value.absent(),
    this.prevHash = const Value.absent(),
    this.currentHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.soulSatisfaction = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String bookId,
    required String deviceId,
    required int amount,
    required String type,
    required String categoryId,
    required String ledgerType,
    required DateTime timestamp,
    this.note = const Value.absent(),
    this.photoHash = const Value.absent(),
    this.merchant = const Value.absent(),
    this.metadata = const Value.absent(),
    this.prevHash = const Value.absent(),
    required String currentHash,
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.soulSatisfaction = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       deviceId = Value(deviceId),
       amount = Value(amount),
       type = Value(type),
       categoryId = Value(categoryId),
       ledgerType = Value(ledgerType),
       timestamp = Value(timestamp),
       currentHash = Value(currentHash),
       createdAt = Value(createdAt);
  static Insertable<TransactionRow> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? deviceId,
    Expression<int>? amount,
    Expression<String>? type,
    Expression<String>? categoryId,
    Expression<String>? ledgerType,
    Expression<DateTime>? timestamp,
    Expression<String>? note,
    Expression<String>? photoHash,
    Expression<String>? merchant,
    Expression<String>? metadata,
    Expression<String>? prevHash,
    Expression<String>? currentHash,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isPrivate,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
    Expression<int>? soulSatisfaction,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (deviceId != null) 'device_id': deviceId,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (categoryId != null) 'category_id': categoryId,
      if (ledgerType != null) 'ledger_type': ledgerType,
      if (timestamp != null) 'timestamp': timestamp,
      if (note != null) 'note': note,
      if (photoHash != null) 'photo_hash': photoHash,
      if (merchant != null) 'merchant': merchant,
      if (metadata != null) 'metadata': metadata,
      if (prevHash != null) 'prev_hash': prevHash,
      if (currentHash != null) 'current_hash': currentHash,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isPrivate != null) 'is_private': isPrivate,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (soulSatisfaction != null) 'soul_satisfaction': soulSatisfaction,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<String>? deviceId,
    Value<int>? amount,
    Value<String>? type,
    Value<String>? categoryId,
    Value<String>? ledgerType,
    Value<DateTime>? timestamp,
    Value<String?>? note,
    Value<String?>? photoHash,
    Value<String?>? merchant,
    Value<String?>? metadata,
    Value<String?>? prevHash,
    Value<String>? currentHash,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<bool>? isPrivate,
    Value<bool>? isSynced,
    Value<bool>? isDeleted,
    Value<int>? soulSatisfaction,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      deviceId: deviceId ?? this.deviceId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      ledgerType: ledgerType ?? this.ledgerType,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      photoHash: photoHash ?? this.photoHash,
      merchant: merchant ?? this.merchant,
      metadata: metadata ?? this.metadata,
      prevHash: prevHash ?? this.prevHash,
      currentHash: currentHash ?? this.currentHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrivate: isPrivate ?? this.isPrivate,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      soulSatisfaction: soulSatisfaction ?? this.soulSatisfaction,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (ledgerType.present) {
      map['ledger_type'] = Variable<String>(ledgerType.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (photoHash.present) {
      map['photo_hash'] = Variable<String>(photoHash.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (prevHash.present) {
      map['prev_hash'] = Variable<String>(prevHash.value);
    }
    if (currentHash.present) {
      map['current_hash'] = Variable<String>(currentHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isPrivate.present) {
      map['is_private'] = Variable<bool>(isPrivate.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (soulSatisfaction.present) {
      map['soul_satisfaction'] = Variable<int>(soulSatisfaction.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('deviceId: $deviceId, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('categoryId: $categoryId, ')
          ..write('ledgerType: $ledgerType, ')
          ..write('timestamp: $timestamp, ')
          ..write('note: $note, ')
          ..write('photoHash: $photoHash, ')
          ..write('merchant: $merchant, ')
          ..write('metadata: $metadata, ')
          ..write('prevHash: $prevHash, ')
          ..write('currentHash: $currentHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('soulSatisfaction: $soulSatisfaction, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarEmojiMeta = const VerificationMeta(
    'avatarEmoji',
  );
  @override
  late final GeneratedColumn<String> avatarEmoji = GeneratedColumn<String>(
    'avatar_emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarImagePathMeta = const VerificationMeta(
    'avatarImagePath',
  );
  @override
  late final GeneratedColumn<String> avatarImagePath = GeneratedColumn<String>(
    'avatar_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    avatarEmoji,
    avatarImagePath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('avatar_emoji')) {
      context.handle(
        _avatarEmojiMeta,
        avatarEmoji.isAcceptableOrUnknown(
          data['avatar_emoji']!,
          _avatarEmojiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avatarEmojiMeta);
    }
    if (data.containsKey('avatar_image_path')) {
      context.handle(
        _avatarImagePathMeta,
        avatarImagePath.isAcceptableOrUnknown(
          data['avatar_image_path']!,
          _avatarImagePathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      avatarEmoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_emoji'],
      )!,
      avatarImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_image_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  final String id;
  final String displayName;
  final String avatarEmoji;
  final String? avatarImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserProfileRow({
    required this.id,
    required this.displayName,
    required this.avatarEmoji,
    this.avatarImagePath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['avatar_emoji'] = Variable<String>(avatarEmoji);
    if (!nullToAbsent || avatarImagePath != null) {
      map['avatar_image_path'] = Variable<String>(avatarImagePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      displayName: Value(displayName),
      avatarEmoji: Value(avatarEmoji),
      avatarImagePath: avatarImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarImagePath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      avatarEmoji: serializer.fromJson<String>(json['avatarEmoji']),
      avatarImagePath: serializer.fromJson<String?>(json['avatarImagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'avatarEmoji': serializer.toJson<String>(avatarEmoji),
      'avatarImagePath': serializer.toJson<String?>(avatarImagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfileRow copyWith({
    String? id,
    String? displayName,
    String? avatarEmoji,
    Value<String?> avatarImagePath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfileRow(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    avatarImagePath: avatarImagePath.present
        ? avatarImagePath.value
        : this.avatarImagePath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserProfileRow copyWithCompanion(UserProfilesCompanion data) {
    return UserProfileRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarEmoji: data.avatarEmoji.present
          ? data.avatarEmoji.value
          : this.avatarEmoji,
      avatarImagePath: data.avatarImagePath.present
          ? data.avatarImagePath.value
          : this.avatarImagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('avatarEmoji: $avatarEmoji, ')
          ..write('avatarImagePath: $avatarImagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    avatarEmoji,
    avatarImagePath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.avatarEmoji == this.avatarEmoji &&
          other.avatarImagePath == this.avatarImagePath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> avatarEmoji;
  final Value<String?> avatarImagePath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarEmoji = const Value.absent(),
    this.avatarImagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    required String id,
    required String displayName,
    required String avatarEmoji,
    this.avatarImagePath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       avatarEmoji = Value(avatarEmoji),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserProfileRow> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? avatarEmoji,
    Expression<String>? avatarImagePath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (avatarEmoji != null) 'avatar_emoji': avatarEmoji,
      if (avatarImagePath != null) 'avatar_image_path': avatarImagePath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? avatarEmoji,
    Value<String?>? avatarImagePath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarImagePath: avatarImagePath ?? this.avatarImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarEmoji.present) {
      map['avatar_emoji'] = Variable<String>(avatarEmoji.value);
    }
    if (avatarImagePath.present) {
      map['avatar_image_path'] = Variable<String>(avatarImagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('avatarEmoji: $avatarEmoji, ')
          ..write('avatarImagePath: $avatarImagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AuditLogsTable auditLogs = $AuditLogsTable(this);
  late final $BooksTable books = $BooksTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $CategoryKeywordPreferencesTable categoryKeywordPreferences =
      $CategoryKeywordPreferencesTable(this);
  late final $CategoryLedgerConfigsTable categoryLedgerConfigs =
      $CategoryLedgerConfigsTable(this);
  late final $GroupMembersTable groupMembers = $GroupMembersTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $MerchantCategoryPreferencesTable merchantCategoryPreferences =
      $MerchantCategoryPreferencesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    auditLogs,
    books,
    categories,
    categoryKeywordPreferences,
    categoryLedgerConfigs,
    groupMembers,
    groups,
    merchantCategoryPreferences,
    syncQueue,
    transactions,
    userProfiles,
  ];
}

typedef $$AuditLogsTableCreateCompanionBuilder =
    AuditLogsCompanion Function({
      required String id,
      required String event,
      required String deviceId,
      Value<String?> bookId,
      Value<String?> transactionId,
      Value<String?> details,
      required DateTime timestamp,
      Value<int> rowid,
    });
typedef $$AuditLogsTableUpdateCompanionBuilder =
    AuditLogsCompanion Function({
      Value<String> id,
      Value<String> event,
      Value<String> deviceId,
      Value<String?> bookId,
      Value<String?> transactionId,
      Value<String?> details,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });

class $$AuditLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get event => $composableBuilder(
    column: $table.event,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get event => $composableBuilder(
    column: $table.event,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get event =>
      $composableBuilder(column: $table.event, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$AuditLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogsTable,
          AuditLog,
          $$AuditLogsTableFilterComposer,
          $$AuditLogsTableOrderingComposer,
          $$AuditLogsTableAnnotationComposer,
          $$AuditLogsTableCreateCompanionBuilder,
          $$AuditLogsTableUpdateCompanionBuilder,
          (AuditLog, BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLog>),
          AuditLog,
          PrefetchHooks Function()
        > {
  $$AuditLogsTableTableManager(_$AppDatabase db, $AuditLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> event = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String?> bookId = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogsCompanion(
                id: id,
                event: event,
                deviceId: deviceId,
                bookId: bookId,
                transactionId: transactionId,
                details: details,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String event,
                required String deviceId,
                Value<String?> bookId = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                Value<String?> details = const Value.absent(),
                required DateTime timestamp,
                Value<int> rowid = const Value.absent(),
              }) => AuditLogsCompanion.insert(
                id: id,
                event: event,
                deviceId: deviceId,
                bookId: bookId,
                transactionId: transactionId,
                details: details,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogsTable,
      AuditLog,
      $$AuditLogsTableFilterComposer,
      $$AuditLogsTableOrderingComposer,
      $$AuditLogsTableAnnotationComposer,
      $$AuditLogsTableCreateCompanionBuilder,
      $$AuditLogsTableUpdateCompanionBuilder,
      (AuditLog, BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLog>),
      AuditLog,
      PrefetchHooks Function()
    >;
typedef $$BooksTableCreateCompanionBuilder =
    BooksCompanion Function({
      required String id,
      required String name,
      required String currency,
      required String deviceId,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isArchived,
      Value<bool> isShadow,
      Value<String?> groupId,
      Value<String?> ownerDeviceId,
      Value<String?> ownerDeviceName,
      Value<int> transactionCount,
      Value<int> survivalBalance,
      Value<int> soulBalance,
      Value<int> rowid,
    });
typedef $$BooksTableUpdateCompanionBuilder =
    BooksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> currency,
      Value<String> deviceId,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isArchived,
      Value<bool> isShadow,
      Value<String?> groupId,
      Value<String?> ownerDeviceId,
      Value<String?> ownerDeviceName,
      Value<int> transactionCount,
      Value<int> survivalBalance,
      Value<int> soulBalance,
      Value<int> rowid,
    });

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isShadow => $composableBuilder(
    column: $table.isShadow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerDeviceId => $composableBuilder(
    column: $table.ownerDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerDeviceName => $composableBuilder(
    column: $table.ownerDeviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get survivalBalance => $composableBuilder(
    column: $table.survivalBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get soulBalance => $composableBuilder(
    column: $table.soulBalance,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isShadow => $composableBuilder(
    column: $table.isShadow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerDeviceId => $composableBuilder(
    column: $table.ownerDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerDeviceName => $composableBuilder(
    column: $table.ownerDeviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get survivalBalance => $composableBuilder(
    column: $table.survivalBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get soulBalance => $composableBuilder(
    column: $table.soulBalance,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isShadow =>
      $composableBuilder(column: $table.isShadow, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get ownerDeviceId => $composableBuilder(
    column: $table.ownerDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerDeviceName => $composableBuilder(
    column: $table.ownerDeviceName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get survivalBalance => $composableBuilder(
    column: $table.survivalBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get soulBalance => $composableBuilder(
    column: $table.soulBalance,
    builder: (column) => column,
  );
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          BookRow,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (BookRow, BaseReferences<_$AppDatabase, $BooksTable, BookRow>),
          BookRow,
          PrefetchHooks Function()
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isShadow = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> ownerDeviceId = const Value.absent(),
                Value<String?> ownerDeviceName = const Value.absent(),
                Value<int> transactionCount = const Value.absent(),
                Value<int> survivalBalance = const Value.absent(),
                Value<int> soulBalance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                name: name,
                currency: currency,
                deviceId: deviceId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isArchived: isArchived,
                isShadow: isShadow,
                groupId: groupId,
                ownerDeviceId: ownerDeviceId,
                ownerDeviceName: ownerDeviceName,
                transactionCount: transactionCount,
                survivalBalance: survivalBalance,
                soulBalance: soulBalance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String currency,
                required String deviceId,
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isShadow = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> ownerDeviceId = const Value.absent(),
                Value<String?> ownerDeviceName = const Value.absent(),
                Value<int> transactionCount = const Value.absent(),
                Value<int> survivalBalance = const Value.absent(),
                Value<int> soulBalance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                name: name,
                currency: currency,
                deviceId: deviceId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isArchived: isArchived,
                isShadow: isShadow,
                groupId: groupId,
                ownerDeviceId: ownerDeviceId,
                ownerDeviceName: ownerDeviceName,
                transactionCount: transactionCount,
                survivalBalance: survivalBalance,
                soulBalance: soulBalance,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      BookRow,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (BookRow, BaseReferences<_$AppDatabase, $BooksTable, BookRow>),
      BookRow,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String name,
      required String icon,
      required String color,
      Value<String?> parentId,
      required int level,
      Value<bool> isSystem,
      Value<bool> isArchived,
      Value<int> sortOrder,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> icon,
      Value<String> color,
      Value<String?> parentId,
      Value<int> level,
      Value<bool> isSystem,
      Value<bool> isArchived,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _parentIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.categories.parentId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $CategoryLedgerConfigsTable,
    List<CategoryLedgerConfigRow>
  >
  _categoryLedgerConfigsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.categoryLedgerConfigs,
        aliasName: $_aliasNameGenerator(
          db.categories.id,
          db.categoryLedgerConfigs.categoryId,
        ),
      );

  $$CategoryLedgerConfigsTableProcessedTableManager
  get categoryLedgerConfigsRefs {
    final manager = $$CategoryLedgerConfigsTableTableManager(
      $_db,
      $_db.categoryLedgerConfigs,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _categoryLedgerConfigsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> categoryLedgerConfigsRefs(
    Expression<bool> Function($$CategoryLedgerConfigsTableFilterComposer f) f,
  ) {
    final $$CategoryLedgerConfigsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.categoryLedgerConfigs,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CategoryLedgerConfigsTableFilterComposer(
                $db: $db,
                $table: $db.categoryLedgerConfigs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get parentId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> categoryLedgerConfigsRefs<T extends Object>(
    Expression<T> Function($$CategoryLedgerConfigsTableAnnotationComposer a) f,
  ) {
    final $$CategoryLedgerConfigsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.categoryLedgerConfigs,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CategoryLedgerConfigsTableAnnotationComposer(
                $db: $db,
                $table: $db.categoryLedgerConfigs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({
            bool parentId,
            bool categoryLedgerConfigsRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                icon: icon,
                color: color,
                parentId: parentId,
                level: level,
                isSystem: isSystem,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String icon,
                required String color,
                Value<String?> parentId = const Value.absent(),
                required int level,
                Value<bool> isSystem = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                color: color,
                parentId: parentId,
                level: level,
                isSystem: isSystem,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({parentId = false, categoryLedgerConfigsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (categoryLedgerConfigsRefs) db.categoryLedgerConfigs,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable: $$CategoriesTableReferences
                                        ._parentIdTable(db),
                                    referencedColumn:
                                        $$CategoriesTableReferences
                                            ._parentIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (categoryLedgerConfigsRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          CategoryLedgerConfigRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._categoryLedgerConfigsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).categoryLedgerConfigsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({bool parentId, bool categoryLedgerConfigsRefs})
    >;
typedef $$CategoryKeywordPreferencesTableCreateCompanionBuilder =
    CategoryKeywordPreferencesCompanion Function({
      required String keyword,
      required String categoryId,
      Value<int> hitCount,
      required DateTime lastUsed,
      Value<int> rowid,
    });
typedef $$CategoryKeywordPreferencesTableUpdateCompanionBuilder =
    CategoryKeywordPreferencesCompanion Function({
      Value<String> keyword,
      Value<String> categoryId,
      Value<int> hitCount,
      Value<DateTime> lastUsed,
      Value<int> rowid,
    });

class $$CategoryKeywordPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryKeywordPreferencesTable> {
  $$CategoryKeywordPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get keyword => $composableBuilder(
    column: $table.keyword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hitCount => $composableBuilder(
    column: $table.hitCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsed => $composableBuilder(
    column: $table.lastUsed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryKeywordPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryKeywordPreferencesTable> {
  $$CategoryKeywordPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get keyword => $composableBuilder(
    column: $table.keyword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hitCount => $composableBuilder(
    column: $table.hitCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsed => $composableBuilder(
    column: $table.lastUsed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryKeywordPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryKeywordPreferencesTable> {
  $$CategoryKeywordPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get keyword =>
      $composableBuilder(column: $table.keyword, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hitCount =>
      $composableBuilder(column: $table.hitCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsed =>
      $composableBuilder(column: $table.lastUsed, builder: (column) => column);
}

class $$CategoryKeywordPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryKeywordPreferencesTable,
          CategoryKeywordPreferenceRow,
          $$CategoryKeywordPreferencesTableFilterComposer,
          $$CategoryKeywordPreferencesTableOrderingComposer,
          $$CategoryKeywordPreferencesTableAnnotationComposer,
          $$CategoryKeywordPreferencesTableCreateCompanionBuilder,
          $$CategoryKeywordPreferencesTableUpdateCompanionBuilder,
          (
            CategoryKeywordPreferenceRow,
            BaseReferences<
              _$AppDatabase,
              $CategoryKeywordPreferencesTable,
              CategoryKeywordPreferenceRow
            >,
          ),
          CategoryKeywordPreferenceRow,
          PrefetchHooks Function()
        > {
  $$CategoryKeywordPreferencesTableTableManager(
    _$AppDatabase db,
    $CategoryKeywordPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryKeywordPreferencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CategoryKeywordPreferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CategoryKeywordPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> keyword = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> hitCount = const Value.absent(),
                Value<DateTime> lastUsed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryKeywordPreferencesCompanion(
                keyword: keyword,
                categoryId: categoryId,
                hitCount: hitCount,
                lastUsed: lastUsed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String keyword,
                required String categoryId,
                Value<int> hitCount = const Value.absent(),
                required DateTime lastUsed,
                Value<int> rowid = const Value.absent(),
              }) => CategoryKeywordPreferencesCompanion.insert(
                keyword: keyword,
                categoryId: categoryId,
                hitCount: hitCount,
                lastUsed: lastUsed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryKeywordPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryKeywordPreferencesTable,
      CategoryKeywordPreferenceRow,
      $$CategoryKeywordPreferencesTableFilterComposer,
      $$CategoryKeywordPreferencesTableOrderingComposer,
      $$CategoryKeywordPreferencesTableAnnotationComposer,
      $$CategoryKeywordPreferencesTableCreateCompanionBuilder,
      $$CategoryKeywordPreferencesTableUpdateCompanionBuilder,
      (
        CategoryKeywordPreferenceRow,
        BaseReferences<
          _$AppDatabase,
          $CategoryKeywordPreferencesTable,
          CategoryKeywordPreferenceRow
        >,
      ),
      CategoryKeywordPreferenceRow,
      PrefetchHooks Function()
    >;
typedef $$CategoryLedgerConfigsTableCreateCompanionBuilder =
    CategoryLedgerConfigsCompanion Function({
      required String categoryId,
      required String ledgerType,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CategoryLedgerConfigsTableUpdateCompanionBuilder =
    CategoryLedgerConfigsCompanion Function({
      Value<String> categoryId,
      Value<String> ledgerType,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CategoryLedgerConfigsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CategoryLedgerConfigsTable,
          CategoryLedgerConfigRow
        > {
  $$CategoryLedgerConfigsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(
          db.categoryLedgerConfigs.categoryId,
          db.categories.id,
        ),
      );

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CategoryLedgerConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryLedgerConfigsTable> {
  $$CategoryLedgerConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ledgerType => $composableBuilder(
    column: $table.ledgerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoryLedgerConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryLedgerConfigsTable> {
  $$CategoryLedgerConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ledgerType => $composableBuilder(
    column: $table.ledgerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoryLedgerConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryLedgerConfigsTable> {
  $$CategoryLedgerConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ledgerType => $composableBuilder(
    column: $table.ledgerType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoryLedgerConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryLedgerConfigsTable,
          CategoryLedgerConfigRow,
          $$CategoryLedgerConfigsTableFilterComposer,
          $$CategoryLedgerConfigsTableOrderingComposer,
          $$CategoryLedgerConfigsTableAnnotationComposer,
          $$CategoryLedgerConfigsTableCreateCompanionBuilder,
          $$CategoryLedgerConfigsTableUpdateCompanionBuilder,
          (CategoryLedgerConfigRow, $$CategoryLedgerConfigsTableReferences),
          CategoryLedgerConfigRow,
          PrefetchHooks Function({bool categoryId})
        > {
  $$CategoryLedgerConfigsTableTableManager(
    _$AppDatabase db,
    $CategoryLedgerConfigsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryLedgerConfigsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CategoryLedgerConfigsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CategoryLedgerConfigsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> categoryId = const Value.absent(),
                Value<String> ledgerType = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryLedgerConfigsCompanion(
                categoryId: categoryId,
                ledgerType: ledgerType,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String categoryId,
                required String ledgerType,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoryLedgerConfigsCompanion.insert(
                categoryId: categoryId,
                ledgerType: ledgerType,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoryLedgerConfigsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable:
                                    $$CategoryLedgerConfigsTableReferences
                                        ._categoryIdTable(db),
                                referencedColumn:
                                    $$CategoryLedgerConfigsTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CategoryLedgerConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryLedgerConfigsTable,
      CategoryLedgerConfigRow,
      $$CategoryLedgerConfigsTableFilterComposer,
      $$CategoryLedgerConfigsTableOrderingComposer,
      $$CategoryLedgerConfigsTableAnnotationComposer,
      $$CategoryLedgerConfigsTableCreateCompanionBuilder,
      $$CategoryLedgerConfigsTableUpdateCompanionBuilder,
      (CategoryLedgerConfigRow, $$CategoryLedgerConfigsTableReferences),
      CategoryLedgerConfigRow,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$GroupMembersTableCreateCompanionBuilder =
    GroupMembersCompanion Function({
      required String groupId,
      required String deviceId,
      required String publicKey,
      required String deviceName,
      required String role,
      required String status,
      Value<String> displayName,
      Value<String> avatarEmoji,
      Value<String?> avatarImagePath,
      Value<String?> avatarImageHash,
      Value<int> rowid,
    });
typedef $$GroupMembersTableUpdateCompanionBuilder =
    GroupMembersCompanion Function({
      Value<String> groupId,
      Value<String> deviceId,
      Value<String> publicKey,
      Value<String> deviceName,
      Value<String> role,
      Value<String> status,
      Value<String> displayName,
      Value<String> avatarEmoji,
      Value<String?> avatarImagePath,
      Value<String?> avatarImageHash,
      Value<int> rowid,
    });

class $$GroupMembersTableFilterComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarImagePath => $composableBuilder(
    column: $table.avatarImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarImageHash => $composableBuilder(
    column: $table.avatarImageHash,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarImagePath => $composableBuilder(
    column: $table.avatarImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarImageHash => $composableBuilder(
    column: $table.avatarImageHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarImagePath => $composableBuilder(
    column: $table.avatarImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarImageHash => $composableBuilder(
    column: $table.avatarImageHash,
    builder: (column) => column,
  );
}

class $$GroupMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupMembersTable,
          GroupMemberData,
          $$GroupMembersTableFilterComposer,
          $$GroupMembersTableOrderingComposer,
          $$GroupMembersTableAnnotationComposer,
          $$GroupMembersTableCreateCompanionBuilder,
          $$GroupMembersTableUpdateCompanionBuilder,
          (
            GroupMemberData,
            BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMemberData>,
          ),
          GroupMemberData,
          PrefetchHooks Function()
        > {
  $$GroupMembersTableTableManager(_$AppDatabase db, $GroupMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> publicKey = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> avatarEmoji = const Value.absent(),
                Value<String?> avatarImagePath = const Value.absent(),
                Value<String?> avatarImageHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupMembersCompanion(
                groupId: groupId,
                deviceId: deviceId,
                publicKey: publicKey,
                deviceName: deviceName,
                role: role,
                status: status,
                displayName: displayName,
                avatarEmoji: avatarEmoji,
                avatarImagePath: avatarImagePath,
                avatarImageHash: avatarImageHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String deviceId,
                required String publicKey,
                required String deviceName,
                required String role,
                required String status,
                Value<String> displayName = const Value.absent(),
                Value<String> avatarEmoji = const Value.absent(),
                Value<String?> avatarImagePath = const Value.absent(),
                Value<String?> avatarImageHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupMembersCompanion.insert(
                groupId: groupId,
                deviceId: deviceId,
                publicKey: publicKey,
                deviceName: deviceName,
                role: role,
                status: status,
                displayName: displayName,
                avatarEmoji: avatarEmoji,
                avatarImagePath: avatarImagePath,
                avatarImageHash: avatarImageHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupMembersTable,
      GroupMemberData,
      $$GroupMembersTableFilterComposer,
      $$GroupMembersTableOrderingComposer,
      $$GroupMembersTableAnnotationComposer,
      $$GroupMembersTableCreateCompanionBuilder,
      $$GroupMembersTableUpdateCompanionBuilder,
      (
        GroupMemberData,
        BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMemberData>,
      ),
      GroupMemberData,
      PrefetchHooks Function()
    >;
typedef $$GroupsTableCreateCompanionBuilder =
    GroupsCompanion Function({
      required String groupId,
      required String status,
      required String role,
      Value<String> groupName,
      Value<String?> inviteCode,
      Value<int?> inviteExpiresAt,
      Value<String?> groupKey,
      required int createdAt,
      Value<int?> confirmedAt,
      Value<int?> lastSyncAt,
      Value<int> rowid,
    });
typedef $$GroupsTableUpdateCompanionBuilder =
    GroupsCompanion Function({
      Value<String> groupId,
      Value<String> status,
      Value<String> role,
      Value<String> groupName,
      Value<String?> inviteCode,
      Value<int?> inviteExpiresAt,
      Value<String?> groupKey,
      Value<int> createdAt,
      Value<int?> confirmedAt,
      Value<int?> lastSyncAt,
      Value<int> rowid,
    });

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inviteExpiresAt => $composableBuilder(
    column: $table.inviteExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inviteExpiresAt => $composableBuilder(
    column: $table.inviteExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get inviteExpiresAt => $composableBuilder(
    column: $table.inviteExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupKey =>
      $composableBuilder(column: $table.groupKey, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTable,
          GroupData,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (GroupData, BaseReferences<_$AppDatabase, $GroupsTable, GroupData>),
          GroupData,
          PrefetchHooks Function()
        > {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> groupName = const Value.absent(),
                Value<String?> inviteCode = const Value.absent(),
                Value<int?> inviteExpiresAt = const Value.absent(),
                Value<String?> groupKey = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> confirmedAt = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion(
                groupId: groupId,
                status: status,
                role: role,
                groupName: groupName,
                inviteCode: inviteCode,
                inviteExpiresAt: inviteExpiresAt,
                groupKey: groupKey,
                createdAt: createdAt,
                confirmedAt: confirmedAt,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String status,
                required String role,
                Value<String> groupName = const Value.absent(),
                Value<String?> inviteCode = const Value.absent(),
                Value<int?> inviteExpiresAt = const Value.absent(),
                Value<String?> groupKey = const Value.absent(),
                required int createdAt,
                Value<int?> confirmedAt = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion.insert(
                groupId: groupId,
                status: status,
                role: role,
                groupName: groupName,
                inviteCode: inviteCode,
                inviteExpiresAt: inviteExpiresAt,
                groupKey: groupKey,
                createdAt: createdAt,
                confirmedAt: confirmedAt,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTable,
      GroupData,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (GroupData, BaseReferences<_$AppDatabase, $GroupsTable, GroupData>),
      GroupData,
      PrefetchHooks Function()
    >;
typedef $$MerchantCategoryPreferencesTableCreateCompanionBuilder =
    MerchantCategoryPreferencesCompanion Function({
      required String merchantKey,
      required String preferredCategoryId,
      Value<String?> lastOverrideCategoryId,
      Value<int> overrideStreak,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MerchantCategoryPreferencesTableUpdateCompanionBuilder =
    MerchantCategoryPreferencesCompanion Function({
      Value<String> merchantKey,
      Value<String> preferredCategoryId,
      Value<String?> lastOverrideCategoryId,
      Value<int> overrideStreak,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MerchantCategoryPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $MerchantCategoryPreferencesTable> {
  $$MerchantCategoryPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get merchantKey => $composableBuilder(
    column: $table.merchantKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredCategoryId => $composableBuilder(
    column: $table.preferredCategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastOverrideCategoryId => $composableBuilder(
    column: $table.lastOverrideCategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overrideStreak => $composableBuilder(
    column: $table.overrideStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MerchantCategoryPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $MerchantCategoryPreferencesTable> {
  $$MerchantCategoryPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get merchantKey => $composableBuilder(
    column: $table.merchantKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredCategoryId => $composableBuilder(
    column: $table.preferredCategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastOverrideCategoryId => $composableBuilder(
    column: $table.lastOverrideCategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overrideStreak => $composableBuilder(
    column: $table.overrideStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MerchantCategoryPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MerchantCategoryPreferencesTable> {
  $$MerchantCategoryPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get merchantKey => $composableBuilder(
    column: $table.merchantKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredCategoryId => $composableBuilder(
    column: $table.preferredCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastOverrideCategoryId => $composableBuilder(
    column: $table.lastOverrideCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overrideStreak => $composableBuilder(
    column: $table.overrideStreak,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MerchantCategoryPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MerchantCategoryPreferencesTable,
          MerchantCategoryPreferenceRow,
          $$MerchantCategoryPreferencesTableFilterComposer,
          $$MerchantCategoryPreferencesTableOrderingComposer,
          $$MerchantCategoryPreferencesTableAnnotationComposer,
          $$MerchantCategoryPreferencesTableCreateCompanionBuilder,
          $$MerchantCategoryPreferencesTableUpdateCompanionBuilder,
          (
            MerchantCategoryPreferenceRow,
            BaseReferences<
              _$AppDatabase,
              $MerchantCategoryPreferencesTable,
              MerchantCategoryPreferenceRow
            >,
          ),
          MerchantCategoryPreferenceRow,
          PrefetchHooks Function()
        > {
  $$MerchantCategoryPreferencesTableTableManager(
    _$AppDatabase db,
    $MerchantCategoryPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MerchantCategoryPreferencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MerchantCategoryPreferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MerchantCategoryPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> merchantKey = const Value.absent(),
                Value<String> preferredCategoryId = const Value.absent(),
                Value<String?> lastOverrideCategoryId = const Value.absent(),
                Value<int> overrideStreak = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MerchantCategoryPreferencesCompanion(
                merchantKey: merchantKey,
                preferredCategoryId: preferredCategoryId,
                lastOverrideCategoryId: lastOverrideCategoryId,
                overrideStreak: overrideStreak,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String merchantKey,
                required String preferredCategoryId,
                Value<String?> lastOverrideCategoryId = const Value.absent(),
                Value<int> overrideStreak = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MerchantCategoryPreferencesCompanion.insert(
                merchantKey: merchantKey,
                preferredCategoryId: preferredCategoryId,
                lastOverrideCategoryId: lastOverrideCategoryId,
                overrideStreak: overrideStreak,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MerchantCategoryPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MerchantCategoryPreferencesTable,
      MerchantCategoryPreferenceRow,
      $$MerchantCategoryPreferencesTableFilterComposer,
      $$MerchantCategoryPreferencesTableOrderingComposer,
      $$MerchantCategoryPreferencesTableAnnotationComposer,
      $$MerchantCategoryPreferencesTableCreateCompanionBuilder,
      $$MerchantCategoryPreferencesTableUpdateCompanionBuilder,
      (
        MerchantCategoryPreferenceRow,
        BaseReferences<
          _$AppDatabase,
          $MerchantCategoryPreferencesTable,
          MerchantCategoryPreferenceRow
        >,
      ),
      MerchantCategoryPreferenceRow,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      required String id,
      required String groupId,
      required String encryptedPayload,
      required String vectorClock,
      required int operationCount,
      Value<int> retryCount,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> encryptedPayload,
      Value<String> vectorClock,
      Value<int> operationCount,
      Value<int> retryCount,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get operationCount => $composableBuilder(
    column: $table.operationCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get operationCount => $composableBuilder(
    column: $table.operationCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => column,
  );

  GeneratedColumn<int> get operationCount => $composableBuilder(
    column: $table.operationCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> encryptedPayload = const Value.absent(),
                Value<String> vectorClock = const Value.absent(),
                Value<int> operationCount = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                groupId: groupId,
                encryptedPayload: encryptedPayload,
                vectorClock: vectorClock,
                operationCount: operationCount,
                retryCount: retryCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String encryptedPayload,
                required String vectorClock,
                required int operationCount,
                Value<int> retryCount = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                groupId: groupId,
                encryptedPayload: encryptedPayload,
                vectorClock: vectorClock,
                operationCount: operationCount,
                retryCount: retryCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String bookId,
      required String deviceId,
      required int amount,
      required String type,
      required String categoryId,
      required String ledgerType,
      required DateTime timestamp,
      Value<String?> note,
      Value<String?> photoHash,
      Value<String?> merchant,
      Value<String?> metadata,
      Value<String?> prevHash,
      required String currentHash,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isPrivate,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<int> soulSatisfaction,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> bookId,
      Value<String> deviceId,
      Value<int> amount,
      Value<String> type,
      Value<String> categoryId,
      Value<String> ledgerType,
      Value<DateTime> timestamp,
      Value<String?> note,
      Value<String?> photoHash,
      Value<String?> merchant,
      Value<String?> metadata,
      Value<String?> prevHash,
      Value<String> currentHash,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isPrivate,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<int> soulSatisfaction,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ledgerType => $composableBuilder(
    column: $table.ledgerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoHash => $composableBuilder(
    column: $table.photoHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prevHash => $composableBuilder(
    column: $table.prevHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentHash => $composableBuilder(
    column: $table.currentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get soulSatisfaction => $composableBuilder(
    column: $table.soulSatisfaction,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ledgerType => $composableBuilder(
    column: $table.ledgerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoHash => $composableBuilder(
    column: $table.photoHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prevHash => $composableBuilder(
    column: $table.prevHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentHash => $composableBuilder(
    column: $table.currentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get soulSatisfaction => $composableBuilder(
    column: $table.soulSatisfaction,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ledgerType => $composableBuilder(
    column: $table.ledgerType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get photoHash =>
      $composableBuilder(column: $table.photoHash, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get prevHash =>
      $composableBuilder(column: $table.prevHash, builder: (column) => column);

  GeneratedColumn<String> get currentHash => $composableBuilder(
    column: $table.currentHash,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isPrivate =>
      $composableBuilder(column: $table.isPrivate, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get soulSatisfaction => $composableBuilder(
    column: $table.soulSatisfaction,
    builder: (column) => column,
  );
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            TransactionRow,
            BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>,
          ),
          TransactionRow,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> ledgerType = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> photoHash = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<String?> prevHash = const Value.absent(),
                Value<String> currentHash = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> soulSatisfaction = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                bookId: bookId,
                deviceId: deviceId,
                amount: amount,
                type: type,
                categoryId: categoryId,
                ledgerType: ledgerType,
                timestamp: timestamp,
                note: note,
                photoHash: photoHash,
                merchant: merchant,
                metadata: metadata,
                prevHash: prevHash,
                currentHash: currentHash,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isPrivate: isPrivate,
                isSynced: isSynced,
                isDeleted: isDeleted,
                soulSatisfaction: soulSatisfaction,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                required String deviceId,
                required int amount,
                required String type,
                required String categoryId,
                required String ledgerType,
                required DateTime timestamp,
                Value<String?> note = const Value.absent(),
                Value<String?> photoHash = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<String?> prevHash = const Value.absent(),
                required String currentHash,
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> soulSatisfaction = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                bookId: bookId,
                deviceId: deviceId,
                amount: amount,
                type: type,
                categoryId: categoryId,
                ledgerType: ledgerType,
                timestamp: timestamp,
                note: note,
                photoHash: photoHash,
                merchant: merchant,
                metadata: metadata,
                prevHash: prevHash,
                currentHash: currentHash,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isPrivate: isPrivate,
                isSynced: isSynced,
                isDeleted: isDeleted,
                soulSatisfaction: soulSatisfaction,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        TransactionRow,
        BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>,
      ),
      TransactionRow,
      PrefetchHooks Function()
    >;
typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      required String id,
      required String displayName,
      required String avatarEmoji,
      Value<String?> avatarImagePath,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> avatarEmoji,
      Value<String?> avatarImagePath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarImagePath => $composableBuilder(
    column: $table.avatarImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarImagePath => $composableBuilder(
    column: $table.avatarImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarImagePath => $composableBuilder(
    column: $table.avatarImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTable,
          UserProfileRow,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (
            UserProfileRow,
            BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow>,
          ),
          UserProfileRow,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> avatarEmoji = const Value.absent(),
                Value<String?> avatarImagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                displayName: displayName,
                avatarEmoji: avatarEmoji,
                avatarImagePath: avatarImagePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String avatarEmoji,
                Value<String?> avatarImagePath = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                displayName: displayName,
                avatarEmoji: avatarEmoji,
                avatarImagePath: avatarImagePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTable,
      UserProfileRow,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (
        UserProfileRow,
        BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow>,
      ),
      UserProfileRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db, _db.auditLogs);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$CategoryKeywordPreferencesTableTableManager
  get categoryKeywordPreferences =>
      $$CategoryKeywordPreferencesTableTableManager(
        _db,
        _db.categoryKeywordPreferences,
      );
  $$CategoryLedgerConfigsTableTableManager get categoryLedgerConfigs =>
      $$CategoryLedgerConfigsTableTableManager(_db, _db.categoryLedgerConfigs);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db, _db.groupMembers);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$MerchantCategoryPreferencesTableTableManager
  get merchantCategoryPreferences =>
      $$MerchantCategoryPreferencesTableTableManager(
        _db,
        _db.merchantCategoryPreferences,
      );
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
}
