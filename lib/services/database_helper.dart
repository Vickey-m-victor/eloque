import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/practice_result.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('eloque.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE practice_results (
        id TEXT PRIMARY KEY,
        lessonId TEXT NOT NULL,
        audioFilePath TEXT NOT NULL,
        transcript TEXT NOT NULL,
        completedAt TEXT NOT NULL,
        sessionDurationMs INTEGER NOT NULL,
        targetWpm INTEGER NOT NULL,
        actualWpm INTEGER NOT NULL,
        accuracyScore REAL NOT NULL,
        fillerWordCount INTEGER NOT NULL,
        fluencyScore REAL NOT NULL
      )
    ''');
  }

  Future<int> insertResult(PracticeResult result) async {
    final db = await instance.database;
    return await db.insert(
      'practice_results',
      result.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PracticeResult>> fetchAllResults() async {
    final db = await instance.database;
    final maps = await db.query(
      'practice_results',
      orderBy: 'completedAt DESC',
    );

    return maps.map((map) => PracticeResult.fromJson(map)).toList();
  }

  Future<int> deleteResult(String id) async {
    final db = await instance.database;
    return await db.delete(
      'practice_results',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllResults() async {
    final db = await instance.database;
    return await db.delete('practice_results');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
