import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final pathToDatabase = path.join(databasesPath, 'my_database.db');

    return await openDatabase(
      pathToDatabase,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE my_table (
            id INTEGER PRIMARY KEY,
            latitude REAL,
            longitude REAL,
            timestamp INTEGER
          )
        ''');
      },
    );
  }

  Future closeDatabase() async {
    final db = await database;
    db.close();
  }

  // Add your CRUD operations here:
  // 1) Insert
  Future<int> insertData(double latitude, double longitude, int timestamp) async {
    final db = await database;
    final data = {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
    return await db.insert('my_table', data);
  }

  // 2) Delete
  Future<int> deleteData(int id) async {
    final db = await database;
    return await db.delete('my_table', where: 'id = ?', whereArgs: [id]);
  }

  // 3) Update
  Future<int> updateData(int id, double latitude, double longitude, int timestamp) async {
    final db = await database;
    final data = {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
    return await db.update('my_table', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getData() async {
    final db = await database;
    return await db.query('my_table');
  }

// Add other necessary functions for querying data if needed.
}
