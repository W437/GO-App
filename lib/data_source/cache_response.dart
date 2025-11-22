import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
part 'cache_response.g.dart';

class CacheResponse extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get endPoint => text().unique()();
  TextColumn get header => text()();
  TextColumn get response => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  // New columns for Centralized Cache System
  TextColumn get cacheKey => text().nullable().unique()(); // Structured CacheKey.id
  TextColumn get metadata => text().nullable()(); // Additional metadata
  DateTimeColumn get expiresAt => dateTime().nullable()(); // TTL enforcement
  DateTimeColumn get lastAccessedAt => dateTime().nullable()(); // LRU tracking
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))(); // For size limit
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))(); // API version
}

@DriftDatabase(tables: [CacheResponse])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5; // Incremented from 4

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'cache_response_new_db');
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 5) {
          // Add new columns
          await m.addColumn(cacheResponse, cacheResponse.cacheKey);
          await m.addColumn(cacheResponse, cacheResponse.metadata);
          await m.addColumn(cacheResponse, cacheResponse.expiresAt);
          await m.addColumn(cacheResponse, cacheResponse.lastAccessedAt);
          await m.addColumn(cacheResponse, cacheResponse.sizeBytes);
          await m.addColumn(cacheResponse, cacheResponse.schemaVersion);
        }
      },
    );
  }

  Future<int> insertCacheResponse(CacheResponseCompanion entry) async {
    return await into(cacheResponse).insert(entry);
  }

  Future<List<CacheResponseData>> getAllCacheResponses() async {
    return await select(cacheResponse).get();
  }

  Future<CacheResponseData?> getCacheResponseById(String endPoint) async {
    return await (select(cacheResponse)..where((tbl) => tbl.endPoint.equals(endPoint))).getSingleOrNull();
  }

  Future<CacheResponseData?> getCacheResponseByKey(String key) async {
    return await (select(cacheResponse)..where((tbl) => tbl.cacheKey.equals(key))).getSingleOrNull();
  }

  Future<int> updateCacheResponse(String endPoint, CacheResponseCompanion entry) async {
    return await (update(cacheResponse)..where((tbl) => tbl.endPoint.equals(endPoint))).write(entry);
  }

  Future<int> updateCacheResponseByKey(String key, CacheResponseCompanion entry) async {
    return await (update(cacheResponse)..where((tbl) => tbl.cacheKey.equals(key))).write(entry);
  }

  Future<int> deleteCacheResponse(int id) async {
    return await (delete(cacheResponse)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> clearCacheResponses() async {
    return await delete(cacheResponse).go();
  }

}