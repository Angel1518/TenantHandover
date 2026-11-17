import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/tenant_models.dart';

class TenantRepository {
  TenantRepository({Database? testDb}) : _db = testDb;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'tenant_handover.db'),
      version: 1,
      onCreate: createSchema,
    );
    return _db!;
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expedientes (
        id TEXT PRIMARY KEY,
        property_name TEXT NOT NULL,
        tenant_name TEXT NOT NULL DEFAULT '',
        landlord_name TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE puntos (
        id TEXT PRIMARY KEY,
        case_id TEXT NOT NULL,
        room_name TEXT NOT NULL,
        element_name TEXT NOT NULL,
        entry_state TEXT NOT NULL DEFAULT 'bueno',
        entry_note TEXT NOT NULL DEFAULT '',
        exit_state TEXT,
        exit_note TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<List<Expediente>> listCases() async {
    final db = await database;
    final rows = await db.query('expedientes', orderBy: 'created_at DESC');
    return rows.map(Expediente.fromMap).toList();
  }

  Future<List<PuntoInspeccion>> listPoints() async {
    final db = await database;
    final rows = await db.query('puntos');
    return rows.map(PuntoInspeccion.fromMap).toList();
  }

  Future<void> saveCaseWithPoints({
    required Expediente expediente,
    required List<PuntoInspeccion> points,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('expedientes', expediente.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      for (final pt in points) {
        await txn.insert('puntos', pt.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> upsertPoint(PuntoInspeccion point) async {
    final db = await database;
    await db.insert('puntos', point.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

