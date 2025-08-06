// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDb {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'atencion_ciudadana.db');
    print('[LocalDb] Abriendo base de datos en: $path');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        print('[LocalDb] Creando tabla "incidencias"');
        await db.execute('''
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
      },
      onOpen: (db) {
        print('[LocalDb] Base de datos abierta correctamente');
      },
    );
    return _db!;
  }
}

class IncidenceLocalRepo {
  //? Guarda un nuevo registro en la tabla 'incidencias'
  static Future<void> save(Map<String, dynamic> data) async {
    final db = await LocalDb.instance;
    final id = await db.insert('incidencias', data);
    print('[IncidenceLocalRepo] Guardada incidencia id=$id → $data');
  }

  //? Devuelve todos los registros de la tabla 'incidencias'
  static Future<List<Map<String, dynamic>>> pending() async {
    final db = await LocalDb.instance;
    final rows = await db.query('incidencias');
    print(
      '[IncidenceLocalRepo] Registros pendientes encontrados: ${rows.length}',
    );
    for (var row in rows) {
      print('  → $row');
    }
    return rows;
  }

  //! Elimina todos los registros de la tabla 'incidencias'
  static Future<void> delete(int id) async {
    final db = await LocalDb.instance;
    final count = await db.delete(
      'incidencias',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count > 0) {
      print('[IncidenceLocalRepo] Registro eliminado id=$id');
    } else {
      print('[IncidenceLocalRepo] No se encontró registro con id=$id');
    }
  }

  //? Actualiza el campo CURP de un registro específico
  static Future<void> updateCurp(int id, String newCurp) async {
    final db = await LocalDb.instance;
    final count = await db.update(
      'incidencias',
      {'curp': newCurp},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count > 0) {
      print('[IncidenceLocalRepo] CURP actualizada para id=$id → $newCurp');
    } else {
      print('[IncidenceLocalRepo] No se encontró registro con id=$id');
    }
  }
}
