import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../utils/constants.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    await _ensureDefaultUser();
    return _database!;
  }

  Future<void> _ensureDefaultUser() async {
    final db = _database!;
    final result = await db.query(
      tableNameUsers,
      where: 'username = ?',
      whereArgs: ['admin'],
    );
    if (result.isEmpty) {
      await db.insert(tableNameUsers, {
        'username': 'admin',
        'password_hash': 'admin123',
        'role': 'director',
        'employee_id': 1,
      });
    }
  }

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableNameEmployees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matricule TEXT UNIQUE,
        name TEXT NOT NULL,
        first_name TEXT,
        rank TEXT,
        department TEXT,
        position TEXT,
        salary REAL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableNamePrograms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT,
        week_date TEXT,
        month_year TEXT,
        created_by INTEGER,
        created_at TEXT,
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableNameAssignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_id INTEGER,
        employee_id INTEGER,
        location TEXT,
        start_date TEXT,
        end_date TEXT,
        status TEXT DEFAULT 'pending',
        FOREIGN KEY (program_id) REFERENCES programs(id),
        FOREIGN KEY (employee_id) REFERENCES employees(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableNameAttendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER,
        date TEXT NOT NULL,
        check_in_time TEXT,
        check_out_time TEXT,
        check_in_location TEXT,
        check_out_location TEXT,
        is_checked_out INTEGER DEFAULT 0,
        photo TEXT,
        FOREIGN KEY (employee_id) REFERENCES employees(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableNameAbsences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER,
        date TEXT NOT NULL,
        type TEXT,
        reason TEXT,
        verified_by INTEGER,
        deduction_decision_id INTEGER,
        FOREIGN KEY (employee_id) REFERENCES employees(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableNameDeductions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER,
        date TEXT,
        amount REAL,
        reason TEXT,
        approved_by INTEGER,
        status TEXT DEFAULT 'pending',
        executed_by INTEGER,
        FOREIGN KEY (employee_id) REFERENCES employees(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableNameUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password_hash TEXT,
        role TEXT,
        employee_id INTEGER,
        FOREIGN KEY (employee_id) REFERENCES employees(id)
      )
    ''');

    await db.insert(tableNameUsers, {
      'username': 'admin',
      'password_hash': 'admin123',
      'role': 'director',
      'employee_id': 1,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < dbVersion) {
      await db.execute('DROP TABLE IF EXISTS $tableNameEmployees');
      await db.execute('DROP TABLE IF EXISTS $tableNamePrograms');
      await db.execute('DROP TABLE IF EXISTS $tableNameAssignments');
      await db.execute('DROP TABLE IF EXISTS $tableNameAttendance');
      await db.execute('DROP TABLE IF EXISTS $tableNameAbsences');
      await db.execute('DROP TABLE IF EXISTS $tableNameDeductions');
      await db.execute('DROP TABLE IF EXISTS $tableNameUsers');
      await _onCreate(db, dbVersion);
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
