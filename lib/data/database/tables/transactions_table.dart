import 'package:drift/drift.dart';
import 'users_table.dart';
import 'statements_table.dart';

// PRD Section 5.4
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get accountId => text()(); // bank_account.id OR credit_card.id
  TextColumn get accountType => text()(); // 'bank' | 'credit_card'
  IntColumn get date => integer()(); // Unix timestamp
  TextColumn get merchant => text()();
  TextColumn get description => text()();
  RealColumn get amount => real()(); // positive = inflow, negative = outflow
  TextColumn get currency => text().withDefault(const Constant('SGD'))();
  TextColumn get category => text()(); // TransactionCategory.value
  TextColumn get mccCode => text().nullable()();
  RealColumn get milesEarned => real().withDefault(const Constant(0.0))();
  RealColumn get cashbackEarned => real().withDefault(const Constant(0.0))();
  TextColumn get statementId => text().nullable().references(Statements, #id)();
  RealColumn get aiConfidence => real().nullable()(); // 0.0–1.0
  IntColumn get userCorrected => integer().withDefault(const Constant(0))(); // 1 if user edited
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
