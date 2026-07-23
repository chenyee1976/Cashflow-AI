import 'package:drift/drift.dart';
import 'users_table.dart';

// PRD Section 5.6
class Statements extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get fileName => text()();
  TextColumn get filePath => text()(); // local device path
  TextColumn get fileType => text()(); // 'pdf' | 'csv' | 'excel' | 'image'
  IntColumn get fileSizeBytes => integer()();
  TextColumn get fileHash => text().nullable()(); // MD5 for duplicate detection
  TextColumn get bankOrCard => text().nullable()(); // institution parsed by AI
  TextColumn get accountType => text().nullable()(); // 'bank' | 'credit_card'
  IntColumn get periodStart => integer().nullable()();
  IntColumn get periodEnd => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  // 'pending' | 'processing' | 'processed' | 'failed'
  TextColumn get aiModelUsed => text().nullable()();
  IntColumn get transactionCount => integer().withDefault(const Constant(0))();
  IntColumn get uploadedAt => integer()();
  IntColumn get processedAt => integer().nullable()();
}
