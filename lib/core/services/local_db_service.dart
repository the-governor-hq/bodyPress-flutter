import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/body_blog_entry.dart';

/// SQLite persistence layer for [BodyBlogEntry] records.
///
/// One row per calendar day (PK = ISO date string "yyyy-MM-dd").
/// Callers never interact with raw SQL — use the typed helpers below.
class LocalDbService {
  static const _dbName = 'bodypress.db';
  static const _tableEntries = 'entries';
  static const _schemaVersion = 1;

  Database? _db;

  // ── lifecycle ─────────────────────────────────────────────────────────────

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, _dbName);

    return openDatabase(
      fullPath,
      version: _schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableEntries (
        date       TEXT    PRIMARY KEY,
        headline   TEXT    NOT NULL,
        summary    TEXT    NOT NULL,
        full_body  TEXT    NOT NULL,
        mood       TEXT    NOT NULL,
        mood_emoji TEXT    NOT NULL,
        tags       TEXT    NOT NULL DEFAULT '[]',
        user_note  TEXT,
        snapshot   TEXT    NOT NULL DEFAULT '{}'
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here following ALTER TABLE / new table patterns.
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /// "yyyy-MM-dd" key used as primary key.
  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _toRow(BodyBlogEntry e) {
    final json = e.toJson();
    // toJson already encodes date as ISO string; convert to date-only key
    return {
      'date': _dateKey(e.date),
      'headline': json['headline'],
      'summary': json['summary'],
      'full_body': json['full_body'],
      'mood': json['mood'],
      'mood_emoji': json['mood_emoji'],
      'tags': json['tags'],
      'user_note': json['user_note'],
      'snapshot': json['snapshot'],
    };
  }

  static BodyBlogEntry _fromRow(Map<String, dynamic> row) {
    return BodyBlogEntry.fromJson({
      ...row,
      // fromJson expects ISO8601 date
      'date': '${row['date']}T00:00:00.000',
    });
  }

  // ── public API ────────────────────────────────────────────────────────────

  /// Insert or replace an entry (upsert by date).
  Future<void> saveEntry(BodyBlogEntry entry) async {
    final db = await _database;
    await db.insert(
      _tableEntries,
      _toRow(entry),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Load entry for a specific date, or `null` if not stored yet.
  Future<BodyBlogEntry?> loadEntry(DateTime date) async {
    final db = await _database;
    final rows = await db.query(
      _tableEntries,
      where: 'date = ?',
      whereArgs: [_dateKey(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  /// Load all stored entries between [from] and [to] (inclusive), newest first.
  Future<List<BodyBlogEntry>> loadEntriesInRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _database;
    final rows = await db.query(
      _tableEntries,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [_dateKey(from), _dateKey(to)],
      orderBy: 'date DESC',
    );
    return rows.map(_fromRow).toList();
  }

  /// Overwrite only the `user_note` column for a given date.
  /// Returns the updated entry, or `null` if the date does not exist.
  Future<BodyBlogEntry?> updateUserNote(DateTime date, String? note) async {
    final db = await _database;
    final count = await db.update(
      _tableEntries,
      {'user_note': note},
      where: 'date = ?',
      whereArgs: [_dateKey(date)],
    );
    if (count == 0) return null;
    return loadEntry(date);
  }

  /// Delete the persisted entry for [date] (no-op if absent).
  Future<void> deleteEntry(DateTime date) async {
    final db = await _database;
    await db.delete(
      _tableEntries,
      where: 'date = ?',
      whereArgs: [_dateKey(date)],
    );
  }

  /// Total number of stored entries.
  Future<int> count() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM $_tableEntries',
    );
    return (result.first['c'] as int?) ?? 0;
  }
}
