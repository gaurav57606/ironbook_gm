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

class $MembersTable extends Members with TableInfo<$MembersTable, Member> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _joinDateMeta =
      const VerificationMeta('joinDate');
  @override
  late final GeneratedColumn<DateTime> joinDate = GeneratedColumn<DateTime>(
      'join_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
      'plan_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _planNameMeta =
      const VerificationMeta('planName');
  @override
  late final GeneratedColumn<String> planName = GeneratedColumn<String>(
      'plan_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expiryDateMeta =
      const VerificationMeta('expiryDate');
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
      'expiry_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _totalPaidMeta =
      const VerificationMeta('totalPaid');
  @override
  late final GeneratedColumn<int> totalPaid = GeneratedColumn<int>(
      'total_paid', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
      'age', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _checkInPinMeta =
      const VerificationMeta('checkInPin');
  @override
  late final GeneratedColumn<String> checkInPin = GeneratedColumn<String>(
      'check_in_pin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastCheckInMeta =
      const VerificationMeta('lastCheckIn');
  @override
  late final GeneratedColumn<DateTime> lastCheckIn = GeneratedColumn<DateTime>(
      'last_check_in', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _hmacSignatureMeta =
      const VerificationMeta('hmacSignature');
  @override
  late final GeneratedColumn<String> hmacSignature = GeneratedColumn<String>(
      'hmac_signature', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        phone,
        joinDate,
        planId,
        planName,
        expiryDate,
        totalPaid,
        archived,
        gender,
        age,
        checkInPin,
        lastCheckIn,
        hmacSignature
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(Insertable<Member> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('join_date')) {
      context.handle(_joinDateMeta,
          joinDate.isAcceptableOrUnknown(data['join_date']!, _joinDateMeta));
    } else if (isInserting) {
      context.missing(_joinDateMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    }
    if (data.containsKey('plan_name')) {
      context.handle(_planNameMeta,
          planName.isAcceptableOrUnknown(data['plan_name']!, _planNameMeta));
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
          _expiryDateMeta,
          expiryDate.isAcceptableOrUnknown(
              data['expiry_date']!, _expiryDateMeta));
    }
    if (data.containsKey('total_paid')) {
      context.handle(_totalPaidMeta,
          totalPaid.isAcceptableOrUnknown(data['total_paid']!, _totalPaidMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    }
    if (data.containsKey('age')) {
      context.handle(
          _ageMeta, age.isAcceptableOrUnknown(data['age']!, _ageMeta));
    }
    if (data.containsKey('check_in_pin')) {
      context.handle(
          _checkInPinMeta,
          checkInPin.isAcceptableOrUnknown(
              data['check_in_pin']!, _checkInPinMeta));
    }
    if (data.containsKey('last_check_in')) {
      context.handle(
          _lastCheckInMeta,
          lastCheckIn.isAcceptableOrUnknown(
              data['last_check_in']!, _lastCheckInMeta));
    }
    if (data.containsKey('hmac_signature')) {
      context.handle(
          _hmacSignatureMeta,
          hmacSignature.isAcceptableOrUnknown(
              data['hmac_signature']!, _hmacSignatureMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Member map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Member(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      joinDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}join_date'])!,
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_id']),
      planName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_name']),
      expiryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expiry_date']),
      totalPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_paid'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender']),
      age: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}age']),
      checkInPin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}check_in_pin']),
      lastCheckIn: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_check_in']),
      hmacSignature: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hmac_signature']),
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class Member extends DataClass implements Insertable<Member> {
  final String id;
  final String name;
  final String? phone;
  final DateTime joinDate;
  final String? planId;
  final String? planName;
  final DateTime? expiryDate;
  final int totalPaid;
  final bool archived;
  final String? gender;
  final int? age;
  final String? checkInPin;
  final DateTime? lastCheckIn;
  final String? hmacSignature;
  const Member(
      {required this.id,
      required this.name,
      this.phone,
      required this.joinDate,
      this.planId,
      this.planName,
      this.expiryDate,
      required this.totalPaid,
      required this.archived,
      this.gender,
      this.age,
      this.checkInPin,
      this.lastCheckIn,
      this.hmacSignature});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['join_date'] = Variable<DateTime>(joinDate);
    if (!nullToAbsent || planId != null) {
      map['plan_id'] = Variable<String>(planId);
    }
    if (!nullToAbsent || planName != null) {
      map['plan_name'] = Variable<String>(planName);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    map['total_paid'] = Variable<int>(totalPaid);
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<int>(age);
    }
    if (!nullToAbsent || checkInPin != null) {
      map['check_in_pin'] = Variable<String>(checkInPin);
    }
    if (!nullToAbsent || lastCheckIn != null) {
      map['last_check_in'] = Variable<DateTime>(lastCheckIn);
    }
    if (!nullToAbsent || hmacSignature != null) {
      map['hmac_signature'] = Variable<String>(hmacSignature);
    }
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      name: Value(name),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      joinDate: Value(joinDate),
      planId:
          planId == null && nullToAbsent ? const Value.absent() : Value(planId),
      planName: planName == null && nullToAbsent
          ? const Value.absent()
          : Value(planName),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      totalPaid: Value(totalPaid),
      archived: Value(archived),
      gender:
          gender == null && nullToAbsent ? const Value.absent() : Value(gender),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      checkInPin: checkInPin == null && nullToAbsent
          ? const Value.absent()
          : Value(checkInPin),
      lastCheckIn: lastCheckIn == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckIn),
      hmacSignature: hmacSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(hmacSignature),
    );
  }

  factory Member.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Member(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      joinDate: serializer.fromJson<DateTime>(json['joinDate']),
      planId: serializer.fromJson<String?>(json['planId']),
      planName: serializer.fromJson<String?>(json['planName']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      totalPaid: serializer.fromJson<int>(json['totalPaid']),
      archived: serializer.fromJson<bool>(json['archived']),
      gender: serializer.fromJson<String?>(json['gender']),
      age: serializer.fromJson<int?>(json['age']),
      checkInPin: serializer.fromJson<String?>(json['checkInPin']),
      lastCheckIn: serializer.fromJson<DateTime?>(json['lastCheckIn']),
      hmacSignature: serializer.fromJson<String?>(json['hmacSignature']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'joinDate': serializer.toJson<DateTime>(joinDate),
      'planId': serializer.toJson<String?>(planId),
      'planName': serializer.toJson<String?>(planName),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'totalPaid': serializer.toJson<int>(totalPaid),
      'archived': serializer.toJson<bool>(archived),
      'gender': serializer.toJson<String?>(gender),
      'age': serializer.toJson<int?>(age),
      'checkInPin': serializer.toJson<String?>(checkInPin),
      'lastCheckIn': serializer.toJson<DateTime?>(lastCheckIn),
      'hmacSignature': serializer.toJson<String?>(hmacSignature),
    };
  }

  Member copyWith(
          {String? id,
          String? name,
          Value<String?> phone = const Value.absent(),
          DateTime? joinDate,
          Value<String?> planId = const Value.absent(),
          Value<String?> planName = const Value.absent(),
          Value<DateTime?> expiryDate = const Value.absent(),
          int? totalPaid,
          bool? archived,
          Value<String?> gender = const Value.absent(),
          Value<int?> age = const Value.absent(),
          Value<String?> checkInPin = const Value.absent(),
          Value<DateTime?> lastCheckIn = const Value.absent(),
          Value<String?> hmacSignature = const Value.absent()}) =>
      Member(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone.present ? phone.value : this.phone,
        joinDate: joinDate ?? this.joinDate,
        planId: planId.present ? planId.value : this.planId,
        planName: planName.present ? planName.value : this.planName,
        expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
        totalPaid: totalPaid ?? this.totalPaid,
        archived: archived ?? this.archived,
        gender: gender.present ? gender.value : this.gender,
        age: age.present ? age.value : this.age,
        checkInPin: checkInPin.present ? checkInPin.value : this.checkInPin,
        lastCheckIn: lastCheckIn.present ? lastCheckIn.value : this.lastCheckIn,
        hmacSignature:
            hmacSignature.present ? hmacSignature.value : this.hmacSignature,
      );
  Member copyWithCompanion(MembersCompanion data) {
    return Member(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      joinDate: data.joinDate.present ? data.joinDate.value : this.joinDate,
      planId: data.planId.present ? data.planId.value : this.planId,
      planName: data.planName.present ? data.planName.value : this.planName,
      expiryDate:
          data.expiryDate.present ? data.expiryDate.value : this.expiryDate,
      totalPaid: data.totalPaid.present ? data.totalPaid.value : this.totalPaid,
      archived: data.archived.present ? data.archived.value : this.archived,
      gender: data.gender.present ? data.gender.value : this.gender,
      age: data.age.present ? data.age.value : this.age,
      checkInPin:
          data.checkInPin.present ? data.checkInPin.value : this.checkInPin,
      lastCheckIn:
          data.lastCheckIn.present ? data.lastCheckIn.value : this.lastCheckIn,
      hmacSignature: data.hmacSignature.present
          ? data.hmacSignature.value
          : this.hmacSignature,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Member(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('joinDate: $joinDate, ')
          ..write('planId: $planId, ')
          ..write('planName: $planName, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('totalPaid: $totalPaid, ')
          ..write('archived: $archived, ')
          ..write('gender: $gender, ')
          ..write('age: $age, ')
          ..write('checkInPin: $checkInPin, ')
          ..write('lastCheckIn: $lastCheckIn, ')
          ..write('hmacSignature: $hmacSignature')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      phone,
      joinDate,
      planId,
      planName,
      expiryDate,
      totalPaid,
      archived,
      gender,
      age,
      checkInPin,
      lastCheckIn,
      hmacSignature);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Member &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.joinDate == this.joinDate &&
          other.planId == this.planId &&
          other.planName == this.planName &&
          other.expiryDate == this.expiryDate &&
          other.totalPaid == this.totalPaid &&
          other.archived == this.archived &&
          other.gender == this.gender &&
          other.age == this.age &&
          other.checkInPin == this.checkInPin &&
          other.lastCheckIn == this.lastCheckIn &&
          other.hmacSignature == this.hmacSignature);
}

class MembersCompanion extends UpdateCompanion<Member> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<DateTime> joinDate;
  final Value<String?> planId;
  final Value<String?> planName;
  final Value<DateTime?> expiryDate;
  final Value<int> totalPaid;
  final Value<bool> archived;
  final Value<String?> gender;
  final Value<int?> age;
  final Value<String?> checkInPin;
  final Value<DateTime?> lastCheckIn;
  final Value<String?> hmacSignature;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.joinDate = const Value.absent(),
    this.planId = const Value.absent(),
    this.planName = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.totalPaid = const Value.absent(),
    this.archived = const Value.absent(),
    this.gender = const Value.absent(),
    this.age = const Value.absent(),
    this.checkInPin = const Value.absent(),
    this.lastCheckIn = const Value.absent(),
    this.hmacSignature = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    required DateTime joinDate,
    this.planId = const Value.absent(),
    this.planName = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.totalPaid = const Value.absent(),
    this.archived = const Value.absent(),
    this.gender = const Value.absent(),
    this.age = const Value.absent(),
    this.checkInPin = const Value.absent(),
    this.lastCheckIn = const Value.absent(),
    this.hmacSignature = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        joinDate = Value(joinDate);
  static Insertable<Member> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<DateTime>? joinDate,
    Expression<String>? planId,
    Expression<String>? planName,
    Expression<DateTime>? expiryDate,
    Expression<int>? totalPaid,
    Expression<bool>? archived,
    Expression<String>? gender,
    Expression<int>? age,
    Expression<String>? checkInPin,
    Expression<DateTime>? lastCheckIn,
    Expression<String>? hmacSignature,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (joinDate != null) 'join_date': joinDate,
      if (planId != null) 'plan_id': planId,
      if (planName != null) 'plan_name': planName,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (totalPaid != null) 'total_paid': totalPaid,
      if (archived != null) 'archived': archived,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (checkInPin != null) 'check_in_pin': checkInPin,
      if (lastCheckIn != null) 'last_check_in': lastCheckIn,
      if (hmacSignature != null) 'hmac_signature': hmacSignature,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? phone,
      Value<DateTime>? joinDate,
      Value<String?>? planId,
      Value<String?>? planName,
      Value<DateTime?>? expiryDate,
      Value<int>? totalPaid,
      Value<bool>? archived,
      Value<String?>? gender,
      Value<int?>? age,
      Value<String?>? checkInPin,
      Value<DateTime?>? lastCheckIn,
      Value<String?>? hmacSignature,
      Value<int>? rowid}) {
    return MembersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      joinDate: joinDate ?? this.joinDate,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      expiryDate: expiryDate ?? this.expiryDate,
      totalPaid: totalPaid ?? this.totalPaid,
      archived: archived ?? this.archived,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      checkInPin: checkInPin ?? this.checkInPin,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      hmacSignature: hmacSignature ?? this.hmacSignature,
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
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (joinDate.present) {
      map['join_date'] = Variable<DateTime>(joinDate.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (planName.present) {
      map['plan_name'] = Variable<String>(planName.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (totalPaid.present) {
      map['total_paid'] = Variable<int>(totalPaid.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (checkInPin.present) {
      map['check_in_pin'] = Variable<String>(checkInPin.value);
    }
    if (lastCheckIn.present) {
      map['last_check_in'] = Variable<DateTime>(lastCheckIn.value);
    }
    if (hmacSignature.present) {
      map['hmac_signature'] = Variable<String>(hmacSignature.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('joinDate: $joinDate, ')
          ..write('planId: $planId, ')
          ..write('planName: $planName, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('totalPaid: $totalPaid, ')
          ..write('archived: $archived, ')
          ..write('gender: $gender, ')
          ..write('age: $age, ')
          ..write('checkInPin: $checkInPin, ')
          ..write('lastCheckIn: $lastCheckIn, ')
          ..write('hmacSignature: $hmacSignature, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberIdMeta =
      const VerificationMeta('memberId');
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
      'member_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _referenceMeta =
      const VerificationMeta('reference');
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
      'reference', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
      'plan_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _planNameMeta =
      const VerificationMeta('planName');
  @override
  late final GeneratedColumn<String> planName = GeneratedColumn<String>(
      'plan_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _durationMonthsMeta =
      const VerificationMeta('durationMonths');
  @override
  late final GeneratedColumn<int> durationMonths = GeneratedColumn<int>(
      'duration_months', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _invoiceNumberMeta =
      const VerificationMeta('invoiceNumber');
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
      'invoice_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _gstAmountMeta =
      const VerificationMeta('gstAmount');
  @override
  late final GeneratedColumn<double> gstAmount = GeneratedColumn<double>(
      'gst_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _gstRateMeta =
      const VerificationMeta('gstRate');
  @override
  late final GeneratedColumn<double> gstRate = GeneratedColumn<double>(
      'gst_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _componentsJsonMeta =
      const VerificationMeta('componentsJson');
  @override
  late final GeneratedColumn<String> componentsJson = GeneratedColumn<String>(
      'components_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hmacSignatureMeta =
      const VerificationMeta('hmacSignature');
  @override
  late final GeneratedColumn<String> hmacSignature = GeneratedColumn<String>(
      'hmac_signature', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        memberId,
        date,
        amount,
        method,
        reference,
        planId,
        planName,
        durationMonths,
        invoiceNumber,
        subtotal,
        gstAmount,
        gstRate,
        componentsJson,
        hmacSignature
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(Insertable<Payment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(_memberIdMeta,
          memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta));
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(_referenceMeta,
          reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    }
    if (data.containsKey('plan_name')) {
      context.handle(_planNameMeta,
          planName.isAcceptableOrUnknown(data['plan_name']!, _planNameMeta));
    }
    if (data.containsKey('duration_months')) {
      context.handle(
          _durationMonthsMeta,
          durationMonths.isAcceptableOrUnknown(
              data['duration_months']!, _durationMonthsMeta));
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
          _invoiceNumberMeta,
          invoiceNumber.isAcceptableOrUnknown(
              data['invoice_number']!, _invoiceNumberMeta));
    } else if (isInserting) {
      context.missing(_invoiceNumberMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('gst_amount')) {
      context.handle(_gstAmountMeta,
          gstAmount.isAcceptableOrUnknown(data['gst_amount']!, _gstAmountMeta));
    } else if (isInserting) {
      context.missing(_gstAmountMeta);
    }
    if (data.containsKey('gst_rate')) {
      context.handle(_gstRateMeta,
          gstRate.isAcceptableOrUnknown(data['gst_rate']!, _gstRateMeta));
    }
    if (data.containsKey('components_json')) {
      context.handle(
          _componentsJsonMeta,
          componentsJson.isAcceptableOrUnknown(
              data['components_json']!, _componentsJsonMeta));
    }
    if (data.containsKey('hmac_signature')) {
      context.handle(
          _hmacSignatureMeta,
          hmacSignature.isAcceptableOrUnknown(
              data['hmac_signature']!, _hmacSignatureMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      memberId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      reference: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reference']),
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_id']),
      planName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_name'])!,
      durationMonths: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_months'])!,
      invoiceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_number'])!,
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
      gstAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}gst_amount'])!,
      gstRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}gst_rate'])!,
      componentsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}components_json']),
      hmacSignature: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hmac_signature']),
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class Payment extends DataClass implements Insertable<Payment> {
  final String id;
  final String memberId;
  final DateTime date;
  final double amount;
  final String method;
  final String? reference;
  final String? planId;
  final String planName;
  final int durationMonths;
  final String invoiceNumber;
  final double subtotal;
  final double gstAmount;
  final double gstRate;
  final String? componentsJson;
  final String? hmacSignature;
  const Payment(
      {required this.id,
      required this.memberId,
      required this.date,
      required this.amount,
      required this.method,
      this.reference,
      this.planId,
      required this.planName,
      required this.durationMonths,
      required this.invoiceNumber,
      required this.subtotal,
      required this.gstAmount,
      required this.gstRate,
      this.componentsJson,
      this.hmacSignature});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['date'] = Variable<DateTime>(date);
    map['amount'] = Variable<double>(amount);
    map['method'] = Variable<String>(method);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || planId != null) {
      map['plan_id'] = Variable<String>(planId);
    }
    map['plan_name'] = Variable<String>(planName);
    map['duration_months'] = Variable<int>(durationMonths);
    map['invoice_number'] = Variable<String>(invoiceNumber);
    map['subtotal'] = Variable<double>(subtotal);
    map['gst_amount'] = Variable<double>(gstAmount);
    map['gst_rate'] = Variable<double>(gstRate);
    if (!nullToAbsent || componentsJson != null) {
      map['components_json'] = Variable<String>(componentsJson);
    }
    if (!nullToAbsent || hmacSignature != null) {
      map['hmac_signature'] = Variable<String>(hmacSignature);
    }
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      date: Value(date),
      amount: Value(amount),
      method: Value(method),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      planId:
          planId == null && nullToAbsent ? const Value.absent() : Value(planId),
      planName: Value(planName),
      durationMonths: Value(durationMonths),
      invoiceNumber: Value(invoiceNumber),
      subtotal: Value(subtotal),
      gstAmount: Value(gstAmount),
      gstRate: Value(gstRate),
      componentsJson: componentsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(componentsJson),
      hmacSignature: hmacSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(hmacSignature),
    );
  }

  factory Payment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      date: serializer.fromJson<DateTime>(json['date']),
      amount: serializer.fromJson<double>(json['amount']),
      method: serializer.fromJson<String>(json['method']),
      reference: serializer.fromJson<String?>(json['reference']),
      planId: serializer.fromJson<String?>(json['planId']),
      planName: serializer.fromJson<String>(json['planName']),
      durationMonths: serializer.fromJson<int>(json['durationMonths']),
      invoiceNumber: serializer.fromJson<String>(json['invoiceNumber']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      gstAmount: serializer.fromJson<double>(json['gstAmount']),
      gstRate: serializer.fromJson<double>(json['gstRate']),
      componentsJson: serializer.fromJson<String?>(json['componentsJson']),
      hmacSignature: serializer.fromJson<String?>(json['hmacSignature']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'date': serializer.toJson<DateTime>(date),
      'amount': serializer.toJson<double>(amount),
      'method': serializer.toJson<String>(method),
      'reference': serializer.toJson<String?>(reference),
      'planId': serializer.toJson<String?>(planId),
      'planName': serializer.toJson<String>(planName),
      'durationMonths': serializer.toJson<int>(durationMonths),
      'invoiceNumber': serializer.toJson<String>(invoiceNumber),
      'subtotal': serializer.toJson<double>(subtotal),
      'gstAmount': serializer.toJson<double>(gstAmount),
      'gstRate': serializer.toJson<double>(gstRate),
      'componentsJson': serializer.toJson<String?>(componentsJson),
      'hmacSignature': serializer.toJson<String?>(hmacSignature),
    };
  }

  Payment copyWith(
          {String? id,
          String? memberId,
          DateTime? date,
          double? amount,
          String? method,
          Value<String?> reference = const Value.absent(),
          Value<String?> planId = const Value.absent(),
          String? planName,
          int? durationMonths,
          String? invoiceNumber,
          double? subtotal,
          double? gstAmount,
          double? gstRate,
          Value<String?> componentsJson = const Value.absent(),
          Value<String?> hmacSignature = const Value.absent()}) =>
      Payment(
        id: id ?? this.id,
        memberId: memberId ?? this.memberId,
        date: date ?? this.date,
        amount: amount ?? this.amount,
        method: method ?? this.method,
        reference: reference.present ? reference.value : this.reference,
        planId: planId.present ? planId.value : this.planId,
        planName: planName ?? this.planName,
        durationMonths: durationMonths ?? this.durationMonths,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        subtotal: subtotal ?? this.subtotal,
        gstAmount: gstAmount ?? this.gstAmount,
        gstRate: gstRate ?? this.gstRate,
        componentsJson:
            componentsJson.present ? componentsJson.value : this.componentsJson,
        hmacSignature:
            hmacSignature.present ? hmacSignature.value : this.hmacSignature,
      );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      method: data.method.present ? data.method.value : this.method,
      reference: data.reference.present ? data.reference.value : this.reference,
      planId: data.planId.present ? data.planId.value : this.planId,
      planName: data.planName.present ? data.planName.value : this.planName,
      durationMonths: data.durationMonths.present
          ? data.durationMonths.value
          : this.durationMonths,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      gstAmount: data.gstAmount.present ? data.gstAmount.value : this.gstAmount,
      gstRate: data.gstRate.present ? data.gstRate.value : this.gstRate,
      componentsJson: data.componentsJson.present
          ? data.componentsJson.value
          : this.componentsJson,
      hmacSignature: data.hmacSignature.present
          ? data.hmacSignature.value
          : this.hmacSignature,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('reference: $reference, ')
          ..write('planId: $planId, ')
          ..write('planName: $planName, ')
          ..write('durationMonths: $durationMonths, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('subtotal: $subtotal, ')
          ..write('gstAmount: $gstAmount, ')
          ..write('gstRate: $gstRate, ')
          ..write('componentsJson: $componentsJson, ')
          ..write('hmacSignature: $hmacSignature')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      memberId,
      date,
      amount,
      method,
      reference,
      planId,
      planName,
      durationMonths,
      invoiceNumber,
      subtotal,
      gstAmount,
      gstRate,
      componentsJson,
      hmacSignature);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.method == this.method &&
          other.reference == this.reference &&
          other.planId == this.planId &&
          other.planName == this.planName &&
          other.durationMonths == this.durationMonths &&
          other.invoiceNumber == this.invoiceNumber &&
          other.subtotal == this.subtotal &&
          other.gstAmount == this.gstAmount &&
          other.gstRate == this.gstRate &&
          other.componentsJson == this.componentsJson &&
          other.hmacSignature == this.hmacSignature);
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<DateTime> date;
  final Value<double> amount;
  final Value<String> method;
  final Value<String?> reference;
  final Value<String?> planId;
  final Value<String> planName;
  final Value<int> durationMonths;
  final Value<String> invoiceNumber;
  final Value<double> subtotal;
  final Value<double> gstAmount;
  final Value<double> gstRate;
  final Value<String?> componentsJson;
  final Value<String?> hmacSignature;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.method = const Value.absent(),
    this.reference = const Value.absent(),
    this.planId = const Value.absent(),
    this.planName = const Value.absent(),
    this.durationMonths = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.gstAmount = const Value.absent(),
    this.gstRate = const Value.absent(),
    this.componentsJson = const Value.absent(),
    this.hmacSignature = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    required String id,
    required String memberId,
    required DateTime date,
    required double amount,
    required String method,
    this.reference = const Value.absent(),
    this.planId = const Value.absent(),
    this.planName = const Value.absent(),
    this.durationMonths = const Value.absent(),
    required String invoiceNumber,
    required double subtotal,
    required double gstAmount,
    this.gstRate = const Value.absent(),
    this.componentsJson = const Value.absent(),
    this.hmacSignature = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        memberId = Value(memberId),
        date = Value(date),
        amount = Value(amount),
        method = Value(method),
        invoiceNumber = Value(invoiceNumber),
        subtotal = Value(subtotal),
        gstAmount = Value(gstAmount);
  static Insertable<Payment> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<DateTime>? date,
    Expression<double>? amount,
    Expression<String>? method,
    Expression<String>? reference,
    Expression<String>? planId,
    Expression<String>? planName,
    Expression<int>? durationMonths,
    Expression<String>? invoiceNumber,
    Expression<double>? subtotal,
    Expression<double>? gstAmount,
    Expression<double>? gstRate,
    Expression<String>? componentsJson,
    Expression<String>? hmacSignature,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (method != null) 'method': method,
      if (reference != null) 'reference': reference,
      if (planId != null) 'plan_id': planId,
      if (planName != null) 'plan_name': planName,
      if (durationMonths != null) 'duration_months': durationMonths,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (subtotal != null) 'subtotal': subtotal,
      if (gstAmount != null) 'gst_amount': gstAmount,
      if (gstRate != null) 'gst_rate': gstRate,
      if (componentsJson != null) 'components_json': componentsJson,
      if (hmacSignature != null) 'hmac_signature': hmacSignature,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? memberId,
      Value<DateTime>? date,
      Value<double>? amount,
      Value<String>? method,
      Value<String?>? reference,
      Value<String?>? planId,
      Value<String>? planName,
      Value<int>? durationMonths,
      Value<String>? invoiceNumber,
      Value<double>? subtotal,
      Value<double>? gstAmount,
      Value<double>? gstRate,
      Value<String?>? componentsJson,
      Value<String?>? hmacSignature,
      Value<int>? rowid}) {
    return PaymentsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      durationMonths: durationMonths ?? this.durationMonths,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      subtotal: subtotal ?? this.subtotal,
      gstAmount: gstAmount ?? this.gstAmount,
      gstRate: gstRate ?? this.gstRate,
      componentsJson: componentsJson ?? this.componentsJson,
      hmacSignature: hmacSignature ?? this.hmacSignature,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (planName.present) {
      map['plan_name'] = Variable<String>(planName.value);
    }
    if (durationMonths.present) {
      map['duration_months'] = Variable<int>(durationMonths.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (gstAmount.present) {
      map['gst_amount'] = Variable<double>(gstAmount.value);
    }
    if (gstRate.present) {
      map['gst_rate'] = Variable<double>(gstRate.value);
    }
    if (componentsJson.present) {
      map['components_json'] = Variable<String>(componentsJson.value);
    }
    if (hmacSignature.present) {
      map['hmac_signature'] = Variable<String>(hmacSignature.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('reference: $reference, ')
          ..write('planId: $planId, ')
          ..write('planName: $planName, ')
          ..write('durationMonths: $durationMonths, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('subtotal: $subtotal, ')
          ..write('gstAmount: $gstAmount, ')
          ..write('gstRate: $gstRate, ')
          ..write('componentsJson: $componentsJson, ')
          ..write('hmacSignature: $hmacSignature, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlansTable extends Plans with TableInfo<$PlansTable, Plan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationMonthsMeta =
      const VerificationMeta('durationMonths');
  @override
  late final GeneratedColumn<int> durationMonths = GeneratedColumn<int>(
      'duration_months', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _componentsJsonMeta =
      const VerificationMeta('componentsJson');
  @override
  late final GeneratedColumn<String> componentsJson = GeneratedColumn<String>(
      'components_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hmacSignatureMeta =
      const VerificationMeta('hmacSignature');
  @override
  late final GeneratedColumn<String> hmacSignature = GeneratedColumn<String>(
      'hmac_signature', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, durationMonths, price, active, componentsJson, hmacSignature];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(Insertable<Plan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('duration_months')) {
      context.handle(
          _durationMonthsMeta,
          durationMonths.isAcceptableOrUnknown(
              data['duration_months']!, _durationMonthsMeta));
    } else if (isInserting) {
      context.missing(_durationMonthsMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('components_json')) {
      context.handle(
          _componentsJsonMeta,
          componentsJson.isAcceptableOrUnknown(
              data['components_json']!, _componentsJsonMeta));
    }
    if (data.containsKey('hmac_signature')) {
      context.handle(
          _hmacSignatureMeta,
          hmacSignature.isAcceptableOrUnknown(
              data['hmac_signature']!, _hmacSignatureMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Plan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      durationMonths: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_months'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      componentsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}components_json']),
      hmacSignature: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hmac_signature']),
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class Plan extends DataClass implements Insertable<Plan> {
  final String id;
  final String name;
  final int durationMonths;
  final double price;
  final bool active;
  final String? componentsJson;
  final String? hmacSignature;
  const Plan(
      {required this.id,
      required this.name,
      required this.durationMonths,
      required this.price,
      required this.active,
      this.componentsJson,
      this.hmacSignature});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['duration_months'] = Variable<int>(durationMonths);
    map['price'] = Variable<double>(price);
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || componentsJson != null) {
      map['components_json'] = Variable<String>(componentsJson);
    }
    if (!nullToAbsent || hmacSignature != null) {
      map['hmac_signature'] = Variable<String>(hmacSignature);
    }
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      name: Value(name),
      durationMonths: Value(durationMonths),
      price: Value(price),
      active: Value(active),
      componentsJson: componentsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(componentsJson),
      hmacSignature: hmacSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(hmacSignature),
    );
  }

  factory Plan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plan(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      durationMonths: serializer.fromJson<int>(json['durationMonths']),
      price: serializer.fromJson<double>(json['price']),
      active: serializer.fromJson<bool>(json['active']),
      componentsJson: serializer.fromJson<String?>(json['componentsJson']),
      hmacSignature: serializer.fromJson<String?>(json['hmacSignature']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'durationMonths': serializer.toJson<int>(durationMonths),
      'price': serializer.toJson<double>(price),
      'active': serializer.toJson<bool>(active),
      'componentsJson': serializer.toJson<String?>(componentsJson),
      'hmacSignature': serializer.toJson<String?>(hmacSignature),
    };
  }

  Plan copyWith(
          {String? id,
          String? name,
          int? durationMonths,
          double? price,
          bool? active,
          Value<String?> componentsJson = const Value.absent(),
          Value<String?> hmacSignature = const Value.absent()}) =>
      Plan(
        id: id ?? this.id,
        name: name ?? this.name,
        durationMonths: durationMonths ?? this.durationMonths,
        price: price ?? this.price,
        active: active ?? this.active,
        componentsJson:
            componentsJson.present ? componentsJson.value : this.componentsJson,
        hmacSignature:
            hmacSignature.present ? hmacSignature.value : this.hmacSignature,
      );
  Plan copyWithCompanion(PlansCompanion data) {
    return Plan(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      durationMonths: data.durationMonths.present
          ? data.durationMonths.value
          : this.durationMonths,
      price: data.price.present ? data.price.value : this.price,
      active: data.active.present ? data.active.value : this.active,
      componentsJson: data.componentsJson.present
          ? data.componentsJson.value
          : this.componentsJson,
      hmacSignature: data.hmacSignature.present
          ? data.hmacSignature.value
          : this.hmacSignature,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plan(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('durationMonths: $durationMonths, ')
          ..write('price: $price, ')
          ..write('active: $active, ')
          ..write('componentsJson: $componentsJson, ')
          ..write('hmacSignature: $hmacSignature')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, durationMonths, price, active, componentsJson, hmacSignature);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plan &&
          other.id == this.id &&
          other.name == this.name &&
          other.durationMonths == this.durationMonths &&
          other.price == this.price &&
          other.active == this.active &&
          other.componentsJson == this.componentsJson &&
          other.hmacSignature == this.hmacSignature);
}

class PlansCompanion extends UpdateCompanion<Plan> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> durationMonths;
  final Value<double> price;
  final Value<bool> active;
  final Value<String?> componentsJson;
  final Value<String?> hmacSignature;
  final Value<int> rowid;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.durationMonths = const Value.absent(),
    this.price = const Value.absent(),
    this.active = const Value.absent(),
    this.componentsJson = const Value.absent(),
    this.hmacSignature = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlansCompanion.insert({
    required String id,
    required String name,
    required int durationMonths,
    required double price,
    this.active = const Value.absent(),
    this.componentsJson = const Value.absent(),
    this.hmacSignature = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        durationMonths = Value(durationMonths),
        price = Value(price);
  static Insertable<Plan> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? durationMonths,
    Expression<double>? price,
    Expression<bool>? active,
    Expression<String>? componentsJson,
    Expression<String>? hmacSignature,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (durationMonths != null) 'duration_months': durationMonths,
      if (price != null) 'price': price,
      if (active != null) 'active': active,
      if (componentsJson != null) 'components_json': componentsJson,
      if (hmacSignature != null) 'hmac_signature': hmacSignature,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlansCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? durationMonths,
      Value<double>? price,
      Value<bool>? active,
      Value<String?>? componentsJson,
      Value<String?>? hmacSignature,
      Value<int>? rowid}) {
    return PlansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMonths: durationMonths ?? this.durationMonths,
      price: price ?? this.price,
      active: active ?? this.active,
      componentsJson: componentsJson ?? this.componentsJson,
      hmacSignature: hmacSignature ?? this.hmacSignature,
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
    if (durationMonths.present) {
      map['duration_months'] = Variable<int>(durationMonths.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (componentsJson.present) {
      map['components_json'] = Variable<String>(componentsJson.value);
    }
    if (hmacSignature.present) {
      map['hmac_signature'] = Variable<String>(hmacSignature.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('durationMonths: $durationMonths, ')
          ..write('price: $price, ')
          ..write('active: $active, ')
          ..write('componentsJson: $componentsJson, ')
          ..write('hmacSignature: $hmacSignature, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberIdMeta =
      const VerificationMeta('memberId');
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
      'member_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _invoiceNumberMeta =
      const VerificationMeta('invoiceNumber');
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
      'invoice_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemsJsonMeta =
      const VerificationMeta('itemsJson');
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
      'items_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hmacSignatureMeta =
      const VerificationMeta('hmacSignature');
  @override
  late final GeneratedColumn<String> hmacSignature = GeneratedColumn<String>(
      'hmac_signature', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        memberId,
        date,
        totalAmount,
        paymentMethod,
        invoiceNumber,
        itemsJson,
        hmacSignature
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(Insertable<Sale> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(_memberIdMeta,
          memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
          _invoiceNumberMeta,
          invoiceNumber.isAcceptableOrUnknown(
              data['invoice_number']!, _invoiceNumberMeta));
    } else if (isInserting) {
      context.missing(_invoiceNumberMeta);
    }
    if (data.containsKey('items_json')) {
      context.handle(_itemsJsonMeta,
          itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta));
    } else if (isInserting) {
      context.missing(_itemsJsonMeta);
    }
    if (data.containsKey('hmac_signature')) {
      context.handle(
          _hmacSignatureMeta,
          hmacSignature.isAcceptableOrUnknown(
              data['hmac_signature']!, _hmacSignatureMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      memberId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_id']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      invoiceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_number'])!,
      itemsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}items_json'])!,
      hmacSignature: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hmac_signature']),
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class Sale extends DataClass implements Insertable<Sale> {
  final String id;
  final String? memberId;
  final DateTime date;
  final double totalAmount;
  final String paymentMethod;
  final String invoiceNumber;
  final String itemsJson;
  final String? hmacSignature;
  const Sale(
      {required this.id,
      this.memberId,
      required this.date,
      required this.totalAmount,
      required this.paymentMethod,
      required this.invoiceNumber,
      required this.itemsJson,
      this.hmacSignature});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || memberId != null) {
      map['member_id'] = Variable<String>(memberId);
    }
    map['date'] = Variable<DateTime>(date);
    map['total_amount'] = Variable<double>(totalAmount);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['invoice_number'] = Variable<String>(invoiceNumber);
    map['items_json'] = Variable<String>(itemsJson);
    if (!nullToAbsent || hmacSignature != null) {
      map['hmac_signature'] = Variable<String>(hmacSignature);
    }
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      date: Value(date),
      totalAmount: Value(totalAmount),
      paymentMethod: Value(paymentMethod),
      invoiceNumber: Value(invoiceNumber),
      itemsJson: Value(itemsJson),
      hmacSignature: hmacSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(hmacSignature),
    );
  }

  factory Sale.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String?>(json['memberId']),
      date: serializer.fromJson<DateTime>(json['date']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      invoiceNumber: serializer.fromJson<String>(json['invoiceNumber']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      hmacSignature: serializer.fromJson<String?>(json['hmacSignature']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String?>(memberId),
      'date': serializer.toJson<DateTime>(date),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'invoiceNumber': serializer.toJson<String>(invoiceNumber),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'hmacSignature': serializer.toJson<String?>(hmacSignature),
    };
  }

  Sale copyWith(
          {String? id,
          Value<String?> memberId = const Value.absent(),
          DateTime? date,
          double? totalAmount,
          String? paymentMethod,
          String? invoiceNumber,
          String? itemsJson,
          Value<String?> hmacSignature = const Value.absent()}) =>
      Sale(
        id: id ?? this.id,
        memberId: memberId.present ? memberId.value : this.memberId,
        date: date ?? this.date,
        totalAmount: totalAmount ?? this.totalAmount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        itemsJson: itemsJson ?? this.itemsJson,
        hmacSignature:
            hmacSignature.present ? hmacSignature.value : this.hmacSignature,
      );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      date: data.date.present ? data.date.value : this.date,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      hmacSignature: data.hmacSignature.present
          ? data.hmacSignature.value
          : this.hmacSignature,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('date: $date, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('hmacSignature: $hmacSignature')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, memberId, date, totalAmount,
      paymentMethod, invoiceNumber, itemsJson, hmacSignature);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.date == this.date &&
          other.totalAmount == this.totalAmount &&
          other.paymentMethod == this.paymentMethod &&
          other.invoiceNumber == this.invoiceNumber &&
          other.itemsJson == this.itemsJson &&
          other.hmacSignature == this.hmacSignature);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<String> id;
  final Value<String?> memberId;
  final Value<DateTime> date;
  final Value<double> totalAmount;
  final Value<String> paymentMethod;
  final Value<String> invoiceNumber;
  final Value<String> itemsJson;
  final Value<String?> hmacSignature;
  final Value<int> rowid;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.date = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.hmacSignature = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesCompanion.insert({
    required String id,
    this.memberId = const Value.absent(),
    required DateTime date,
    required double totalAmount,
    required String paymentMethod,
    required String invoiceNumber,
    required String itemsJson,
    this.hmacSignature = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        date = Value(date),
        totalAmount = Value(totalAmount),
        paymentMethod = Value(paymentMethod),
        invoiceNumber = Value(invoiceNumber),
        itemsJson = Value(itemsJson);
  static Insertable<Sale> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<DateTime>? date,
    Expression<double>? totalAmount,
    Expression<String>? paymentMethod,
    Expression<String>? invoiceNumber,
    Expression<String>? itemsJson,
    Expression<String>? hmacSignature,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (date != null) 'date': date,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (itemsJson != null) 'items_json': itemsJson,
      if (hmacSignature != null) 'hmac_signature': hmacSignature,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? memberId,
      Value<DateTime>? date,
      Value<double>? totalAmount,
      Value<String>? paymentMethod,
      Value<String>? invoiceNumber,
      Value<String>? itemsJson,
      Value<String?>? hmacSignature,
      Value<int>? rowid}) {
    return SalesCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      itemsJson: itemsJson ?? this.itemsJson,
      hmacSignature: hmacSignature ?? this.hmacSignature,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (hmacSignature.present) {
      map['hmac_signature'] = Variable<String>(hmacSignature.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('date: $date, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('hmacSignature: $hmacSignature, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$OutboxDatabase extends GeneratedDatabase {
  _$OutboxDatabase(QueryExecutor e) : super(e);
  $OutboxDatabaseManager get managers => $OutboxDatabaseManager(this);
  late final $OutboxEventsTable outboxEvents = $OutboxEventsTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $SalesTable sales = $SalesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [outboxEvents, members, payments, plans, sales];
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
typedef $$MembersTableCreateCompanionBuilder = MembersCompanion Function({
  required String id,
  required String name,
  Value<String?> phone,
  required DateTime joinDate,
  Value<String?> planId,
  Value<String?> planName,
  Value<DateTime?> expiryDate,
  Value<int> totalPaid,
  Value<bool> archived,
  Value<String?> gender,
  Value<int?> age,
  Value<String?> checkInPin,
  Value<DateTime?> lastCheckIn,
  Value<String?> hmacSignature,
  Value<int> rowid,
});
typedef $$MembersTableUpdateCompanionBuilder = MembersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> phone,
  Value<DateTime> joinDate,
  Value<String?> planId,
  Value<String?> planName,
  Value<DateTime?> expiryDate,
  Value<int> totalPaid,
  Value<bool> archived,
  Value<String?> gender,
  Value<int?> age,
  Value<String?> checkInPin,
  Value<DateTime?> lastCheckIn,
  Value<String?> hmacSignature,
  Value<int> rowid,
});

class $$MembersTableFilterComposer
    extends Composer<_$OutboxDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get joinDate => $composableBuilder(
      column: $table.joinDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planName => $composableBuilder(
      column: $table.planName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalPaid => $composableBuilder(
      column: $table.totalPaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkInPin => $composableBuilder(
      column: $table.checkInPin, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastCheckIn => $composableBuilder(
      column: $table.lastCheckIn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature, builder: (column) => ColumnFilters(column));
}

class $$MembersTableOrderingComposer
    extends Composer<_$OutboxDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get joinDate => $composableBuilder(
      column: $table.joinDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planName => $composableBuilder(
      column: $table.planName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalPaid => $composableBuilder(
      column: $table.totalPaid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkInPin => $composableBuilder(
      column: $table.checkInPin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastCheckIn => $composableBuilder(
      column: $table.lastCheckIn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature,
      builder: (column) => ColumnOrderings(column));
}

class $$MembersTableAnnotationComposer
    extends Composer<_$OutboxDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
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

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<DateTime> get joinDate =>
      $composableBuilder(column: $table.joinDate, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get planName =>
      $composableBuilder(column: $table.planName, builder: (column) => column);

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => column);

  GeneratedColumn<int> get totalPaid =>
      $composableBuilder(column: $table.totalPaid, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<String> get checkInPin => $composableBuilder(
      column: $table.checkInPin, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCheckIn => $composableBuilder(
      column: $table.lastCheckIn, builder: (column) => column);

  GeneratedColumn<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature, builder: (column) => column);
}

class $$MembersTableTableManager extends RootTableManager<
    _$OutboxDatabase,
    $MembersTable,
    Member,
    $$MembersTableFilterComposer,
    $$MembersTableOrderingComposer,
    $$MembersTableAnnotationComposer,
    $$MembersTableCreateCompanionBuilder,
    $$MembersTableUpdateCompanionBuilder,
    (Member, BaseReferences<_$OutboxDatabase, $MembersTable, Member>),
    Member,
    PrefetchHooks Function()> {
  $$MembersTableTableManager(_$OutboxDatabase db, $MembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<DateTime> joinDate = const Value.absent(),
            Value<String?> planId = const Value.absent(),
            Value<String?> planName = const Value.absent(),
            Value<DateTime?> expiryDate = const Value.absent(),
            Value<int> totalPaid = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<int?> age = const Value.absent(),
            Value<String?> checkInPin = const Value.absent(),
            Value<DateTime?> lastCheckIn = const Value.absent(),
            Value<String?> hmacSignature = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MembersCompanion(
            id: id,
            name: name,
            phone: phone,
            joinDate: joinDate,
            planId: planId,
            planName: planName,
            expiryDate: expiryDate,
            totalPaid: totalPaid,
            archived: archived,
            gender: gender,
            age: age,
            checkInPin: checkInPin,
            lastCheckIn: lastCheckIn,
            hmacSignature: hmacSignature,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> phone = const Value.absent(),
            required DateTime joinDate,
            Value<String?> planId = const Value.absent(),
            Value<String?> planName = const Value.absent(),
            Value<DateTime?> expiryDate = const Value.absent(),
            Value<int> totalPaid = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<int?> age = const Value.absent(),
            Value<String?> checkInPin = const Value.absent(),
            Value<DateTime?> lastCheckIn = const Value.absent(),
            Value<String?> hmacSignature = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MembersCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            joinDate: joinDate,
            planId: planId,
            planName: planName,
            expiryDate: expiryDate,
            totalPaid: totalPaid,
            archived: archived,
            gender: gender,
            age: age,
            checkInPin: checkInPin,
            lastCheckIn: lastCheckIn,
            hmacSignature: hmacSignature,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MembersTableProcessedTableManager = ProcessedTableManager<
    _$OutboxDatabase,
    $MembersTable,
    Member,
    $$MembersTableFilterComposer,
    $$MembersTableOrderingComposer,
    $$MembersTableAnnotationComposer,
    $$MembersTableCreateCompanionBuilder,
    $$MembersTableUpdateCompanionBuilder,
    (Member, BaseReferences<_$OutboxDatabase, $MembersTable, Member>),
    Member,
    PrefetchHooks Function()>;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  required String id,
  required String memberId,
  required DateTime date,
  required double amount,
  required String method,
  Value<String?> reference,
  Value<String?> planId,
  Value<String> planName,
  Value<int> durationMonths,
  required String invoiceNumber,
  required double subtotal,
  required double gstAmount,
  Value<double> gstRate,
  Value<String?> componentsJson,
  Value<String?> hmacSignature,
  Value<int> rowid,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<String> id,
  Value<String> memberId,
  Value<DateTime> date,
  Value<double> amount,
  Value<String> method,
  Value<String?> reference,
  Value<String?> planId,
  Value<String> planName,
  Value<int> durationMonths,
  Value<String> invoiceNumber,
  Value<double> subtotal,
  Value<double> gstAmount,
  Value<double> gstRate,
  Value<String?> componentsJson,
  Value<String?> hmacSignature,
  Value<int> rowid,
});

class $$PaymentsTableFilterComposer
    extends Composer<_$OutboxDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reference => $composableBuilder(
      column: $table.reference, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planName => $composableBuilder(
      column: $table.planName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMonths => $composableBuilder(
      column: $table.durationMonths,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get gstAmount => $composableBuilder(
      column: $table.gstAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get gstRate => $composableBuilder(
      column: $table.gstRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get componentsJson => $composableBuilder(
      column: $table.componentsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature, builder: (column) => ColumnFilters(column));
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$OutboxDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reference => $composableBuilder(
      column: $table.reference, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planName => $composableBuilder(
      column: $table.planName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMonths => $composableBuilder(
      column: $table.durationMonths,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get gstAmount => $composableBuilder(
      column: $table.gstAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get gstRate => $composableBuilder(
      column: $table.gstRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get componentsJson => $composableBuilder(
      column: $table.componentsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature,
      builder: (column) => ColumnOrderings(column));
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$OutboxDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get planName =>
      $composableBuilder(column: $table.planName, builder: (column) => column);

  GeneratedColumn<int> get durationMonths => $composableBuilder(
      column: $table.durationMonths, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get gstAmount =>
      $composableBuilder(column: $table.gstAmount, builder: (column) => column);

  GeneratedColumn<double> get gstRate =>
      $composableBuilder(column: $table.gstRate, builder: (column) => column);

  GeneratedColumn<String> get componentsJson => $composableBuilder(
      column: $table.componentsJson, builder: (column) => column);

  GeneratedColumn<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature, builder: (column) => column);
}

class $$PaymentsTableTableManager extends RootTableManager<
    _$OutboxDatabase,
    $PaymentsTable,
    Payment,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (Payment, BaseReferences<_$OutboxDatabase, $PaymentsTable, Payment>),
    Payment,
    PrefetchHooks Function()> {
  $$PaymentsTableTableManager(_$OutboxDatabase db, $PaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> memberId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<String?> reference = const Value.absent(),
            Value<String?> planId = const Value.absent(),
            Value<String> planName = const Value.absent(),
            Value<int> durationMonths = const Value.absent(),
            Value<String> invoiceNumber = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> gstAmount = const Value.absent(),
            Value<double> gstRate = const Value.absent(),
            Value<String?> componentsJson = const Value.absent(),
            Value<String?> hmacSignature = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PaymentsCompanion(
            id: id,
            memberId: memberId,
            date: date,
            amount: amount,
            method: method,
            reference: reference,
            planId: planId,
            planName: planName,
            durationMonths: durationMonths,
            invoiceNumber: invoiceNumber,
            subtotal: subtotal,
            gstAmount: gstAmount,
            gstRate: gstRate,
            componentsJson: componentsJson,
            hmacSignature: hmacSignature,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String memberId,
            required DateTime date,
            required double amount,
            required String method,
            Value<String?> reference = const Value.absent(),
            Value<String?> planId = const Value.absent(),
            Value<String> planName = const Value.absent(),
            Value<int> durationMonths = const Value.absent(),
            required String invoiceNumber,
            required double subtotal,
            required double gstAmount,
            Value<double> gstRate = const Value.absent(),
            Value<String?> componentsJson = const Value.absent(),
            Value<String?> hmacSignature = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PaymentsCompanion.insert(
            id: id,
            memberId: memberId,
            date: date,
            amount: amount,
            method: method,
            reference: reference,
            planId: planId,
            planName: planName,
            durationMonths: durationMonths,
            invoiceNumber: invoiceNumber,
            subtotal: subtotal,
            gstAmount: gstAmount,
            gstRate: gstRate,
            componentsJson: componentsJson,
            hmacSignature: hmacSignature,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PaymentsTableProcessedTableManager = ProcessedTableManager<
    _$OutboxDatabase,
    $PaymentsTable,
    Payment,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (Payment, BaseReferences<_$OutboxDatabase, $PaymentsTable, Payment>),
    Payment,
    PrefetchHooks Function()>;
typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  required String id,
  required String name,
  required int durationMonths,
  required double price,
  Value<bool> active,
  Value<String?> componentsJson,
  Value<String?> hmacSignature,
  Value<int> rowid,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> durationMonths,
  Value<double> price,
  Value<bool> active,
  Value<String?> componentsJson,
  Value<String?> hmacSignature,
  Value<int> rowid,
});

class $$PlansTableFilterComposer
    extends Composer<_$OutboxDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMonths => $composableBuilder(
      column: $table.durationMonths,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get componentsJson => $composableBuilder(
      column: $table.componentsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature, builder: (column) => ColumnFilters(column));
}

class $$PlansTableOrderingComposer
    extends Composer<_$OutboxDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMonths => $composableBuilder(
      column: $table.durationMonths,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get componentsJson => $composableBuilder(
      column: $table.componentsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature,
      builder: (column) => ColumnOrderings(column));
}

class $$PlansTableAnnotationComposer
    extends Composer<_$OutboxDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
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

  GeneratedColumn<int> get durationMonths => $composableBuilder(
      column: $table.durationMonths, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get componentsJson => $composableBuilder(
      column: $table.componentsJson, builder: (column) => column);

  GeneratedColumn<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature, builder: (column) => column);
}

class $$PlansTableTableManager extends RootTableManager<
    _$OutboxDatabase,
    $PlansTable,
    Plan,
    $$PlansTableFilterComposer,
    $$PlansTableOrderingComposer,
    $$PlansTableAnnotationComposer,
    $$PlansTableCreateCompanionBuilder,
    $$PlansTableUpdateCompanionBuilder,
    (Plan, BaseReferences<_$OutboxDatabase, $PlansTable, Plan>),
    Plan,
    PrefetchHooks Function()> {
  $$PlansTableTableManager(_$OutboxDatabase db, $PlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> durationMonths = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<String?> componentsJson = const Value.absent(),
            Value<String?> hmacSignature = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlansCompanion(
            id: id,
            name: name,
            durationMonths: durationMonths,
            price: price,
            active: active,
            componentsJson: componentsJson,
            hmacSignature: hmacSignature,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required int durationMonths,
            required double price,
            Value<bool> active = const Value.absent(),
            Value<String?> componentsJson = const Value.absent(),
            Value<String?> hmacSignature = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlansCompanion.insert(
            id: id,
            name: name,
            durationMonths: durationMonths,
            price: price,
            active: active,
            componentsJson: componentsJson,
            hmacSignature: hmacSignature,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlansTableProcessedTableManager = ProcessedTableManager<
    _$OutboxDatabase,
    $PlansTable,
    Plan,
    $$PlansTableFilterComposer,
    $$PlansTableOrderingComposer,
    $$PlansTableAnnotationComposer,
    $$PlansTableCreateCompanionBuilder,
    $$PlansTableUpdateCompanionBuilder,
    (Plan, BaseReferences<_$OutboxDatabase, $PlansTable, Plan>),
    Plan,
    PrefetchHooks Function()>;
typedef $$SalesTableCreateCompanionBuilder = SalesCompanion Function({
  required String id,
  Value<String?> memberId,
  required DateTime date,
  required double totalAmount,
  required String paymentMethod,
  required String invoiceNumber,
  required String itemsJson,
  Value<String?> hmacSignature,
  Value<int> rowid,
});
typedef $$SalesTableUpdateCompanionBuilder = SalesCompanion Function({
  Value<String> id,
  Value<String?> memberId,
  Value<DateTime> date,
  Value<double> totalAmount,
  Value<String> paymentMethod,
  Value<String> invoiceNumber,
  Value<String> itemsJson,
  Value<String?> hmacSignature,
  Value<int> rowid,
});

class $$SalesTableFilterComposer
    extends Composer<_$OutboxDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemsJson => $composableBuilder(
      column: $table.itemsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature, builder: (column) => ColumnFilters(column));
}

class $$SalesTableOrderingComposer
    extends Composer<_$OutboxDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemsJson => $composableBuilder(
      column: $table.itemsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature,
      builder: (column) => ColumnOrderings(column));
}

class $$SalesTableAnnotationComposer
    extends Composer<_$OutboxDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => column);

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<String> get hmacSignature => $composableBuilder(
      column: $table.hmacSignature, builder: (column) => column);
}

class $$SalesTableTableManager extends RootTableManager<
    _$OutboxDatabase,
    $SalesTable,
    Sale,
    $$SalesTableFilterComposer,
    $$SalesTableOrderingComposer,
    $$SalesTableAnnotationComposer,
    $$SalesTableCreateCompanionBuilder,
    $$SalesTableUpdateCompanionBuilder,
    (Sale, BaseReferences<_$OutboxDatabase, $SalesTable, Sale>),
    Sale,
    PrefetchHooks Function()> {
  $$SalesTableTableManager(_$OutboxDatabase db, $SalesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> memberId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<String> invoiceNumber = const Value.absent(),
            Value<String> itemsJson = const Value.absent(),
            Value<String?> hmacSignature = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesCompanion(
            id: id,
            memberId: memberId,
            date: date,
            totalAmount: totalAmount,
            paymentMethod: paymentMethod,
            invoiceNumber: invoiceNumber,
            itemsJson: itemsJson,
            hmacSignature: hmacSignature,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> memberId = const Value.absent(),
            required DateTime date,
            required double totalAmount,
            required String paymentMethod,
            required String invoiceNumber,
            required String itemsJson,
            Value<String?> hmacSignature = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesCompanion.insert(
            id: id,
            memberId: memberId,
            date: date,
            totalAmount: totalAmount,
            paymentMethod: paymentMethod,
            invoiceNumber: invoiceNumber,
            itemsJson: itemsJson,
            hmacSignature: hmacSignature,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SalesTableProcessedTableManager = ProcessedTableManager<
    _$OutboxDatabase,
    $SalesTable,
    Sale,
    $$SalesTableFilterComposer,
    $$SalesTableOrderingComposer,
    $$SalesTableAnnotationComposer,
    $$SalesTableCreateCompanionBuilder,
    $$SalesTableUpdateCompanionBuilder,
    (Sale, BaseReferences<_$OutboxDatabase, $SalesTable, Sale>),
    Sale,
    PrefetchHooks Function()>;

class $OutboxDatabaseManager {
  final _$OutboxDatabase _db;
  $OutboxDatabaseManager(this._db);
  $$OutboxEventsTableTableManager get outboxEvents =>
      $$OutboxEventsTableTableManager(_db, _db.outboxEvents);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
}
