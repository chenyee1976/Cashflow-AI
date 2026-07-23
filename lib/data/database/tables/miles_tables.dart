import 'package:drift/drift.dart';
import 'users_table.dart';

// PRD Section 5.7
class MilesWallet extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get programName => text()(); // e.g. 'KrisFlyer'
  TextColumn get programType => text()(); // 'airline' | 'bank_points'
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  IntColumn get expiryDate => integer().nullable()();
  IntColumn get lastUpdated => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// PRD Section 5.8
class TravelGoals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get destination => text()();
  TextColumn get airline => text()();
  TextColumn get cabinClass => text()(); // 'economy'|'premium_economy'|'business'|'first'
  RealColumn get milesRequired => real()();
  RealColumn get milesCurrent => real().withDefault(const Constant(0.0))();
  IntColumn get targetDate => integer().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
