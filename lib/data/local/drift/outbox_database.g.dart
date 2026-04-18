// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_database.dart';

// ignore_for_file: type=lint
class $OutboxEventsTable extends OutboxEvents
    with TableInfo<$OutboxEventsTable, OutboxEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceTimestampMeta =
      const VerificationMeta('deviceTimestamp');
  @override
  late final GeneratedColumn<int> deviceTimestamp = GeneratedColumn<int>(
      'device_timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<int> isSynced = GeneratedColumn<int>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _hmacSignatureMeta =
      const VerificationMeta('hmacSignature');
  @override
  late final GeneratedColumn<String> hmacSignature = GeneratedColumn<String>(
      'hmac_signature', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityId,
        eventType,
        payloadJson,
        deviceTimestamp,
        isSynced,
        hmacSignature,
        deviceId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_events';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('device_timestamp')) {
      context.handle(
          _deviceTimestampMeta,
          deviceTimestamp.isAcceptableOrUnknown(
              data['device_timestamp']!, _deviceTimestampMeta));
    } else if (isInserting) {
      context.missing(_deviceTimestampMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('hmac_signature')) {
      context.handle(
          _hmacSignatureMeta,
          hmacSignature.isAcceptableOrUnknown(
              data['hmac_signature']!, _hmacSignatureMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      deviceTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}device_timestamp'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_synced'])!,
      hmacSignature: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hmac_signature'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
    );
  }

  @override
  $OutboxEventsTable createAlias(String alias) {
    return $OutboxEventsTable(attachedDatabase, alias);
  }
}

class OutboxEvent extends DataClass implements Insertable<OutboxEvent> {
  final String id;
  final String entityId;
  final String eventType;
  final String payloadJson;
  final int deviceTimestamp;
  final int isSynced;
  final String hmacSignature;
  final String deviceId;
  const OutboxEvent(
      {required this.id,
      required this.entityId,
      required this.eventType,
      required this.payloadJson,
      required this.deviceTimestamp,
      required this.isSynced,
      required this.hmacSignature,
      required this.deviceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_id'] = Variable<String>(entityId);
    map['event_type'] = Variable<String>(eventType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['device_timestamp'] = Variable<int>(deviceTimestamp);
    map['is_synced'] = Variable<int>(isSynced);
    map['hmac_signature'] = Variable<String>(hmacSignature);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  OutboxEventsCompanion toCompanion(bool nullToAbsent) {
    return OutboxEventsCompanion(
      id: Value(id),
      entityId: Value(entityId),
      eventType: Value(eventType),
      payloadJson: Value(payloadJson),
      deviceTimestamp: Value(deviceTimestamp),
      isSynced: Value(isSynced),
      hmacSignature: Value(hmacSignature),
      deviceId: Value(deviceId),
    );
  }

  factory OutboxEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEvent(
      id: serializer.fromJson<String>(json['id']),
      entityId: serializer.fromJson<String>(json['entityId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      deviceTimestamp: serializer.fromJson<int>(json['deviceTimestamp']),
      isSynced: serializer.fromJson<int>(json['isSynced']),
      hmacSignature: serializer.fromJson<String>(json['hmacSignature']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityId': serializer.toJson<String>(entityId),
      'eventType': serializer.toJson<String>(eventType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'deviceTimestamp': serializer.toJson<int>(deviceTimestamp),
      'isSynced': serializer.toJson<int>(isSynced),
      'hmacSignature': serializer.toJson<String>(hmacSignature),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  OutboxEvent copyWith(
          {String? id,
          String? entityId,
          String? eventType,
          String? payloadJson,
          int? deviceTimestamp,
          int? isSynced,
          String? hmacSignature,
          String? deviceId}) =>
      OutboxEvent(
        id: id ?? this.id,
        entityId: entityId ?? this.entityId,
        eventType: eventType ?? this.eventType,
        payloadJson: payloadJson ?? this.payloadJson,
        deviceTimestamp: deviceTimestamp ?? this.deviceTimestamp,
        isSynced: isSynced ?? this.isSynced,
        hmacSignature: hmacSignature ?? this.hmacSignature,
        deviceId: deviceId ?? this.deviceId,
      );
  OutboxEvent copyWithCompanion(OutboxEventsCompanion data) {
    return OutboxEvent(
      id: data.id.present ? data.id.value : this.id,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      deviceTimestamp: data.deviceTimestamp.present
          ? data.deviceTimestamp.value
          : this.deviceTimestamp,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      hmacSignature: data.hmacSignature.present
          ? data.hmacSignature.value
          : this.hmacSignature,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEvent(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('eventType: $eventType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('deviceTimestamp: $deviceTimestamp, ')
          ..write('isSynced: $isSynced, ')
          ..write('hmacSignature: $hmacSignature, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityId, eventType, payloadJson,
      deviceTimestamp, isSynced, hmacSignature, deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEvent &&
          other.id == this.id &&
          other.entityId == this.entityId &&
          other.eventType == this.eventType &&
          other.payloadJson == this.payloadJson &&
          other.deviceTimestamp == this.deviceTimestamp &&
          other.isSynced == this.isSynced &&
          other.hmacSignature == this.hmacSignature &&
          other.deviceId == this.deviceId);
}

class OutboxEventsCompanion extends UpdateCompanion<OutboxEvent> {
  final Value<String> id;
  final Value<String> entityId;
  final Value<String> eventType;
  final Value<String> payloadJson;
  final Value<int> deviceTimestamp;
  final Value<int> isSynced;
  final Value<String> hmacSignature;
  final Value<String> deviceId;
  final Value<int> rowid;
  const OutboxEventsCompanion({
    this.id = const Value.absent(),
    this.entityId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.deviceTimestamp = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.hmacSignature = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxEventsCompanion.insert({
    required String id,
    required String entityId,
    required String eventType,
    required String payloadJson,
    required int deviceTimestamp,
    this.isSynced = const Value.absent(),
    this.hmacSignature = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        entityId = Value(entityId),
        eventType = Value(eventType),
        payloadJson = Value(payloadJson),
        deviceTimestamp = Value(deviceTimestamp);
  static Insertable<OutboxEvent> custom({
    Expression<String>? id,
    Expression<String>? entityId,
    Expression<String>? eventType,
    Expression<String>? payloadJson,
    Expression<int>? deviceTimestamp,
    Expression<int>? isSynced,
    Expression<String>? hmacSignature,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityId != null) 'entity_id': entityId,
      if (eventType != null) 'event_type': eventType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (deviceTimestamp != null) 'device_timestamp': deviceTimestamp,
      if (isSynced != null) 'is_synced': isSynced,
      if (hmacSignature != null) 'hmac_signature': hmacSignature,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? entityId,
      Value<String>? eventType,
      Value<String>? payloadJson,
      Value<int>? deviceTimestamp,
      Value<int>? isSynced,
      Value<String>? hmacSignature,
      Value<String>? deviceId,
      Value<int>? rowid}) {
    return OutboxEventsCompanion(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      eventType: eventType ?? this.eventType,
      payloadJson: payloadJson ?? this.payloadJson,
      deviceTimestamp: deviceTimestamp ?? this.deviceTimestamp,
      isSynced: isSynced ?? this.isSynced,
      hmacSignature: hmacSignature ?? this.hmacSignature,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (deviceTimestamp.present) {
      map['device_timestamp'] = Variable<int>(deviceTimestamp.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<int>(isSynced.value);
    }
    if (hmacSignature.present) {
      map['hmac_signature'] = Variable<String>(hmacSignature.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEventsCompanion(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('eventType: $eventType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('deviceTimestamp: $deviceTimestamp, ')
          ..write('isSynced: $isSynced, ')
          ..write('hmacSignature: $hmacSignature, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$OutboxDatabase extends GeneratedDatabase {
  _$OutboxDatabase(QueryExecutor e) : super(e);
  $OutboxDatabaseManager get managers => $OutboxDatabaseManager(this);
  late final $OutboxEventsTable outboxEvents = $OutboxEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [outboxEvents];
}

typedef $$OutboxEventsTableCreateCompanionBuilder = OutboxEventsCompanion
    Function({
  required String id,
  required String entityId,
  required String eventType,
  required String payloadJson,
  required int deviceTimestamp,
  Value<int> isSynced,
  Value<String> hmacSignature,
  Value<String> deviceId,
  Value<int> rowid,
});
typedef $$OutboxEventsTableUpdateCompanionBuilder = OutboxEventsCompanion
    Function({
  Value<String> id,
  Value<String> entityId,
  Value<String> eventType,
  Value<String> payloadJson,
  Value<int> deviceTimestamp,
  Value<int> isSynced,
  Value<String> hmacSignature,
  Value<String> deviceId,
  Value<int> rowid,
});

class $$OutboxEventsTableFilterComposer
    extends Composer<_$OutboxDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deviceTimestamp => $composableBuilder(
      column: $table.deviceTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));
}

class $$OutboxEventsTableOrderingComposer
    extends Composer<_$OutboxDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deviceTimestamp => $composableBuilder(
      column: $table.deviceTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));
}

class $$OutboxEventsTableAnnotationComposer
    extends Composer<_$OutboxDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<int> get deviceTimestamp => $composableBuilder(
      column: $table.deviceTimestamp, builder: (column) => column);

  GeneratedColumn<int> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$OutboxEventsTableTableManager extends RootTableManager<
    _$OutboxDatabase,
    $OutboxEventsTable,
    OutboxEvent,
    $$OutboxEventsTableFilterComposer,
    $$OutboxEventsTableOrderingComposer,
    $$OutboxEventsTableAnnotationComposer,
    $$OutboxEventsTableCreateCompanionBuilder,
    $$OutboxEventsTableUpdateCompanionBuilder,
    (
      OutboxEvent,
      BaseReferences<_$OutboxDatabase, $OutboxEventsTable, OutboxEvent>
    ),
    OutboxEvent,
    PrefetchHooks Function()> {
  $$OutboxEventsTableTableManager(_$OutboxDatabase db, $OutboxEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<int> deviceTimestamp = const Value.absent(),
            Value<int> isSynced = const Value.absent(),
            Value<String> hmacSignature = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxEventsCompanion(
            id: id,
            entityId: entityId,
            eventType: eventType,
            payloadJson: payloadJson,
            deviceTimestamp: deviceTimestamp,
            isSynced: isSynced,
            hmacSignature: hmacSignature,
            deviceId: deviceId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String entityId,
            required String eventType,
            required String payloadJson,
            required int deviceTimestamp,
            Value<int> isSynced = const Value.absent(),
            Value<String> hmacSignature = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxEventsCompanion.insert(
            id: id,
            entityId: entityId,
            eventType: eventType,
            payloadJson: payloadJson,
            deviceTimestamp: deviceTimestamp,
            isSynced: isSynced,
            hmacSignature: hmacSignature,
            deviceId: deviceId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OutboxEventsTableProcessedTableManager = ProcessedTableManager<
    _$OutboxDatabase,
    $OutboxEventsTable,
    OutboxEvent,
    $$OutboxEventsTableFilterComposer,
    $$OutboxEventsTableOrderingComposer,
    $$OutboxEventsTableAnnotationComposer,
    $$OutboxEventsTableCreateCompanionBuilder,
    $$OutboxEventsTableUpdateCompanionBuilder,
    (
      OutboxEvent,
      BaseReferences<_$OutboxDatabase, $OutboxEventsTable, OutboxEvent>
    ),
    OutboxEvent,
    PrefetchHooks Function()>;

class $OutboxDatabaseManager {
  final _$OutboxDatabase _db;
  $OutboxDatabaseManager(this._db);
  $$OutboxEventsTableTableManager get outboxEvents =>
      $$OutboxEventsTableTableManager(_db, _db.outboxEvents);
}
