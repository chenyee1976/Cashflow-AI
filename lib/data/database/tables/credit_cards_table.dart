import 'package:drift/drift.dart';
import 'users_table.dart';

// PRD Section 5.3 — AI extracts card info from credit card statements
class CreditCards extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get bankName => text()(); // extracted by AI
  TextColumn get cardName => text()(); // e.g. 'DBS Altitude Visa'
  TextColumn get cardType => text()(); // 'visa' | 'mastercard' | 'amex'
  TextColumn get rewardType => text()(); // 'miles' | 'cashback' | 'points'
  TextColumn get lastFour => text().nullable()(); // last 4 digits if visible
  TextColumn get sourceStatementId => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
