import 'package:absensi_acara/models/user.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/attendance.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'attendance.db');
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE participants(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        event TEXT NOT NULL,
        email TEXT,
        phone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance(
        id TEXT PRIMARY KEY,
        participantId TEXT NOT NULL,
        participantName TEXT NOT NULL,
        event TEXT NOT NULL,
        attendanceTime TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  // Participant CRUD
  // Future<void> insertParticipant(Participant participant) async {
  //   final db = await database;
  //   await db.insert('participants', participant.toMap());
  // }

  Future<User?> getParticipant(String id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first, id);
    }
    return null;
  }

  // Attendance CRUD
  Future<void> insertAttendance(Attendance attendance) async {
    final db = await database;
    await db.insert('attendance', attendance.toMap());
  }

  Future<List<Attendance>> getAttendanceHistory() async {
    final db = await database;
    final maps = await db.query('attendance', orderBy: 'attendanceTime DESC');
    return maps.map((map) => Attendance.fromMap(map)).toList();
  }

  Future<bool> isAlreadyAttended(String participantId) async {
    final db = await database;
    final maps = await db.query(
      'attendance',
      where: 'participantId = ?',
      whereArgs: [participantId],
    );
    return maps.isNotEmpty;
  }
}
