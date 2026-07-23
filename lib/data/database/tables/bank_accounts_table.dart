import 'package:drift/drift.dart';
import 'users_table.dart';

// PRD Section 5.2 — populated by AI from statements, not manual entry
class BankAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get bankName => text()(); // e.g. 'DBS', extracted by AI
  TextColumn get accountType => text()(); // 'savings' | 'current' | 'fixed_deposit'
  TextColumn get accountNumber => text().nullable()(); // last 4 digits if extracted
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();
  RealColumn get currentBalance => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('SGD'))();
  TextColumn get sourceStatementId => text().nullable()(); // which statement populated this
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
