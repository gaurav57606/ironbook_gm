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
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();

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
  TextColumn get hmacSignature => text().withDefault(const Constant(''))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get photoPath => text().nullable()();

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
  TextColumn get planId => text().nullable()();
  TextColumn get planName => text().withDefault(const Constant(''))();
  IntColumn get durationMonths => integer().withDefault(const Constant(0))();
  TextColumn get invoiceNumber => text()();
  RealColumn get subtotal => real()();
  RealColumn get gstAmount => real()();
  RealColumn get gstRate => real().withDefault(const Constant(0))();
  TextColumn get componentsJson => text().nullable()();
  TextColumn get hmacSignature => text().withDefault(const Constant(''))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

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
  TextColumn get hmacSignature => text().withDefault(const Constant(''))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

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
  TextColumn get hmacSignature => text().withDefault(const Constant(''))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class PinAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get count => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get lockoutUntil => dateTime().nullable()();
}

class InvoiceSequences extends Table {
  TextColumn get prefix => text()();
  IntColumn get nextNumber => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {prefix};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  TextColumn get category => text()();
  IntColumn get iconCodePoint => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class OwnerProfiles extends Table {
  TextColumn get gymName => text()();
  TextColumn get ownerName => text()();
  TextColumn get phone => text()();
  TextColumn get address => text()();
  TextColumn get gstin => text().nullable()();
  TextColumn get bankName => text().nullable()();
  TextColumn get accountNumber => text().nullable()();
  TextColumn get ifsc => text().nullable()();
  TextColumn get upiId => text().nullable()();
  TextColumn get logoPath => text().nullable()();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get exp => integer().withDefault(const Constant(0))();
  RealColumn get strength => real().withDefault(const Constant(0.5))();
  RealColumn get endurance => real().withDefault(const Constant(0.5))();
  RealColumn get dexterity => real().withDefault(const Constant(0.5))();
  TextColumn get selectedCharacterId => text().withDefault(const Constant('warrior'))();
  TextColumn get hmacSignature => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get ownerPhotoPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {gymName};
}

class AppSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get gstRate => real().withDefault(const Constant(18.0))();
  IntColumn get expiryReminderDays => integer().withDefault(const Constant(3))();
  BoolColumn get whatsappReminders => boolean().withDefault(const Constant(true))();
  BoolColumn get biometricEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get useBiometrics => boolean().withDefault(const Constant(false))();
  TextColumn get businessType => text().withDefault(const Constant('Gym'))();
  DateTimeColumn get lastBackupAt => dateTime().nullable()();
  TextColumn get hmacSignature => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get category => text()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get payload => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}



@DriftDatabase(tables: [
  OutboxEvents,
  Members,
  Payments,
  Plans,
  Sales,
  PinAttempts,
  InvoiceSequences,
  Products,
  Preferences,
  OwnerProfiles,
  AppSettingsTable,
  Notifications,
])
class OutboxDatabase extends _$OutboxDatabase {
  OutboxDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 15;

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
      if (from < 3) {
        await m.createTable(pinAttempts);
        await m.alterTable(TableMigration(members));
        await m.alterTable(TableMigration(payments));
        await m.alterTable(TableMigration(plans));
        await m.alterTable(TableMigration(sales));
      }
      if (from < 4) {
        await m.createTable(invoiceSequences);
      }
      if (from < 5) {
        await m.createTable(products);
      }
      if (from < 6) {
        await m.createTable(preferences);
      }
      if (from < 7) {
        await m.createTable(ownerProfiles);
        await m.createTable(appSettingsTable);
      }
      if (from < 8) {
        await m.deleteTable('owner_profiles');
        await m.deleteTable('app_settings_table');
        await m.createTable(ownerProfiles);
        await m.createTable(appSettingsTable);
      }
      if (from < 9) {
        // Nutrition tables removed
      }
      if (from < 10) {
        await m.addColumn(ownerProfiles, ownerProfiles.hmacSignature);
        await m.addColumn(appSettingsTable, appSettingsTable.hmacSignature);
      }
      if (from < 12) {
        await m.addColumn(outboxEvents, outboxEvents.isVerified as GeneratedColumn<Object>);
      }
      if (from < 13) {
        await m.createTable(notifications);
      }
      if (from < 14) {
        await m.addColumn(members, members.isSynced as GeneratedColumn<Object>);
        await m.addColumn(payments, payments.isSynced as GeneratedColumn<Object>);
        await m.addColumn(plans, plans.isSynced as GeneratedColumn<Object>);
        await m.addColumn(sales, sales.isSynced as GeneratedColumn<Object>);
        await m.addColumn(ownerProfiles, ownerProfiles.isSynced as GeneratedColumn<Object>);
        await m.addColumn(appSettingsTable, appSettingsTable.isSynced as GeneratedColumn<Object>);
      }
      if (from < 15) {
        await m.addColumn(members, members.photoPath);
        await m.addColumn(ownerProfiles, ownerProfiles.ownerPhotoPath);
      }
    },
  );
}
