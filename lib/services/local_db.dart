// ignore_for_file: depend_on_referenced_packages

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDb {
  static Database? _db;
  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'atencion_ciudadana.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, _) {
      return db.execute('''
        CREATE TABLE incidencias (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          curp TEXT,
          colonia TEXT,
          direccion TEXT,
          comentarios TEXT,
          tipo_solicitante TEXT,
          origen TEXT,
          motivo TEXT,
          secretaria TEXT,
          tipo_incidencia TEXT
        )
      ''');
    });
    return _db!;
  }
}

class IncidenceLocalRepo {
  static Future<void> save(Map<String, dynamic> data) async {
    final db = await LocalDb.instance;
    await db.insert('incidencias', data);
  }
  static Future<List<Map<String, dynamic>>> pending() async {
    final db = await LocalDb.instance;
    return db.query('incidencias');
  }
  static Future<void> clearAll() async {
    final db = await LocalDb.instance;
    await db.delete('incidencias');
  }
}
