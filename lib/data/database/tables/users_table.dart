import 'package:drift/drift.dart';

// PRD Section 5.1
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get firstName => text().withLength(min: 1, max: 100)();
  TextColumn get lastName => text().withLength(min: 1, max: 100)();
  TextColumn get email => text()(); // Google email
  TextColumn get googleId => text()(); // Google sub/id
  TextColumn get displayName => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get rewardFocus => text().nullable()(); // 'miles' | 'cashback' | 'both'
  TextColumn get currencyPref => text().withDefault(const Constant('SGD'))();
  IntColumn get createdAt => integer()();
  IntColumn get lastLoginAt => integer().nullable()();
  IntColumn get sessionExpires => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
