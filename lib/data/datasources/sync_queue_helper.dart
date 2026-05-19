import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SyncQueueHelper {
  static SyncQueueHelper? _instance;
  static Database? _database;

  factory SyncQueueHelper() {
    _instance ??= SyncQueueHelper._internal();
    return _instance!;
  }

  SyncQueueHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final String dbPath = join(dir.path, 'finance_app_sync.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        collection TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        retry_count INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> enqueue(String operation, String collection, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert('sync_queue', {
      'operation': operation,
      'collection': collection,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingItems() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'synced = 0 AND retry_count < 5',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markSynced(int id) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> deleteSyncedItems() async {
    final db = await database;
    await db.delete('sync_queue', where: 'synced = 1');
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('sync_queue');
  }

  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getPendingCountForCollection(String collection) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE synced = 0 AND collection = ?',
      [collection],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
