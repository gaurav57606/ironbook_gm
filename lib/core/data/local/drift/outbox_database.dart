import 'package:drift/drift.dart';
import 'connection/native.dart' if (dart.library.html) 'connection/web.dart';

part 'outbox_database.g.dart';

class OutboxEvents extends Table {
  TextColumn get id => text()();
  TextColumn get entityId => text()();
  TextColumn get eventType => text()();
  TextColumn get payloadJson => text()();
  IntColumn get deviceTimestamp => integer()();
  IntColumn get isSynced => integer().withDefault(const Constant(0))();
  TextColumn get hmacSignature => text().withDefault(const Constant(''))();
  TextColumn get deviceId => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

class Members extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get joinDate => dateTime()();
  TextColumn get planId => text().nullable()();
  TextColumn get planName => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  IntColumn get totalPaid => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get gender => text().nullable()();
  IntColumn get age => integer().nullable()();
  TextColumn get checkInPin => text().nullable()();
  DateTimeColumn get lastCheckIn => dateTime().nullable()();
  TextColumn get hmacSignature => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get amount => real()();
  TextColumn get method => text()();
  TextColumn get reference => text().nullable()();
  TextColumn get invoiceNumber => text()();
  RealColumn get subtotal => real()();
  RealColumn get gstAmount => real()();
  TextColumn get hmacSignature => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Plans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get durationMonths => integer()();
  RealColumn get price => real()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get componentsJson => text().nullable()();
  TextColumn get hmacSignature => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text().nullable()();
  DateTimeColumn get date => dateTime()();
  RealColumn get totalAmount => real()();
  TextColumn get paymentMethod => text()();
  TextColumn get invoiceNumber => text()();
  TextColumn get itemsJson => text()();
  TextColumn get hmacSignature => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [OutboxEvents, Members, Payments, Plans, Sales])
class OutboxDatabase extends _$OutboxDatabase {
  OutboxDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(members);
        await m.createTable(payments);
        await m.createTable(plans);
        await m.createTable(sales);
      }
    },
  );
}









