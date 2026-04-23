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

@DriftDatabase(tables: [OutboxEvents])
class OutboxDatabase extends _$OutboxDatabase {
  OutboxDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;
}









