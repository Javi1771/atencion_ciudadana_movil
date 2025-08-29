// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

///* =======================
///*  Conexión / Esquema BD
///* =======================
class LocalDb {
  static Database? _db;
  static const int _dbVersion = 3; //* subimos a 3 para aplicar migración

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'atencion_ciudadana.db');

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) async {
        await _createIncidencias(db);
        await _createCiudadanos(db);
      },
      onUpgrade: (db, oldV, newV) async {
        //* v1 -> v2: crear tabla ciudadanos
        if (oldV < 2) {
          await _createCiudadanos(db);
        }
        //* v2 -> v3: normalizar curp_ciudadano ('' -> NULL, TRIM/UPPER) y asegurar índice único
        if (oldV < 3) {
          //* Curp a UPPER/trim donde no es null
          await db.execute('''
            UPDATE ciudadanos
               SET curp_ciudadano = UPPER(TRIM(curp_ciudadano))
             WHERE curp_ciudadano IS NOT NULL
          ''');

          //* Vacías -> NULL (permiten múltiples NULL bajo UNIQUE)
          await db.execute('''
            UPDATE ciudadanos
               SET curp_ciudadano = NULL
             WHERE curp_ciudadano IS NULL OR curp_ciudadano = ''
          ''');

          //* Asegurar índices
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_ciud_curp ON ciudadanos(curp_ciudadano)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_ciud_email ON ciudadanos(email)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_ciud_nombre ON ciudadanos(nombre, primer_apellido, segundo_apellido)',
          );
        }
      },
      onOpen: (_) => print('[LocalDb] Base abierta correctamente'),
    );
    return _db!;
  }

  //? --- Tabla incidencias (ya existente) ---
  static Future<void> _createIncidencias(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS incidencias (
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
  }

  //* --- Tabla ciudadanos ---
  static Future<void> _createCiudadanos(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ciudadanos (
        id_ciudadano     INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre           TEXT,
        primer_apellido  TEXT,
        segundo_apellido TEXT,
        nombre_completo  TEXT,
        curp_ciudadano   TEXT,
        fecha_nacimiento TEXT,
        password         TEXT,
        sexo             TEXT,
        estado           TEXT,
        telefono         TEXT,
        email            TEXT,
        asentamiento     TEXT,
        calle            TEXT,
        numero_exterior  TEXT,
        numero_interior  TEXT,
        codigo_postal    TEXT
      )
    ''');

    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_ciud_curp ON ciudadanos(curp_ciudadano)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ciud_email ON ciudadanos(email)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ciud_nombre ON ciudadanos(nombre, primer_apellido, segundo_apellido)');
  }
}

///* ======================================
///*  Repositorio LOCAL para *incidencias*
///* ======================================
class IncidenceLocalRepo {
  static Future<int> save(Map<String, dynamic> data) async {
    final db = await LocalDb.instance;
    return db.insert('incidencias', data);
  }

  static Future<List<Map<String, dynamic>>> pending() async {
    final db = await LocalDb.instance;
    return db.query('incidencias', orderBy: 'id DESC');
  }

  static Future<Map<String, dynamic>?> findById(int id) async {
    final db = await LocalDb.instance;
    final res = await db.query('incidencias', where: 'id = ?', whereArgs: [id], limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  static Future<int> update(int id, Map<String, dynamic> data) async {
    final db = await LocalDb.instance;
    return db.update('incidencias', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> updateCurp(int id, String newCurp) async {
    return update(id, {'curp': newCurp});
  }

  static Future<int> delete(int id) async {
    final db = await LocalDb.instance;
    return db.delete('incidencias', where: 'id = ?', whereArgs: [id]);
  }
}

///* =====================================
///*  Repositorio LOCAL para *ciudadanos*
///* =====================================
class CitizenLocalRepo {
  static const _table = 'ciudadanos';

  ///* Normaliza payloads para proteger el índice UNIQUE y calidad de datos.
  static Map<String, dynamic> _normalizeCitizen(Map<String, dynamic> data) {
    final out = Map<String, dynamic>.from(data);
    String s(dynamic v) => (v ?? '').toString();

    //* CURP: UPPER/TRIM y '' -> NULL
    if (out.containsKey('curp_ciudadano')) {
      final curp = s(out['curp_ciudadano']).trim().toUpperCase();
      out['curp_ciudadano'] = curp.isEmpty ? null : curp;
    }

    //* Password: sin espacios
    if (out.containsKey('password')) {
      out['password'] = s(out['password']).replaceAll(' ', '');
    }

    //* Teléfono / CP: solo dígitos
    if (out.containsKey('telefono')) {
      out['telefono'] = s(out['telefono']).replaceAll(RegExp(r'\D'), '');
    }
    if (out.containsKey('codigo_postal')) {
      out['codigo_postal'] = s(out['codigo_postal']).replaceAll(RegExp(r'\D'), '');
    }

    return out;
  }

  ///* Inserta un ciudadano. Si `nombre_completo` viene vacío, se compone.
  static Future<int> insert(Map<String, dynamic> data) async {
    final db = await LocalDb.instance;

    //* Componer nombre_completo si no viene
    final nombre = (data['nombre'] ?? '').toString().trim();
    final pApe = (data['primer_apellido'] ?? '').toString().trim();
    final sApe = (data['segundo_apellido'] ?? '').toString().trim();
    data['nombre_completo'] =
        (data['nombre_completo'] ?? '').toString().trim().isNotEmpty
            ? data['nombre_completo']
            : [nombre, pApe, sApe].where((e) => e.isNotEmpty).join(' ').trim();

    final normalized = _normalizeCitizen(data);

    try {
      return await db.insert(
        _table,
        normalized,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      final msg = e.toString();
      if (msg.contains('UNIQUE constraint failed') &&
          msg.contains('ciudadanos.curp_ciudadano')) {
        throw 'La CURP ya existe en otro ciudadano.';
      }
      rethrow;
    }
  }

  ///* Listar todos
  static Future<List<Map<String, dynamic>>> all() async {
    final db = await LocalDb.instance;
    return db.query(_table, orderBy: 'id_ciudadano DESC');
  }

  ///* Buscar por id_ciudadano
  static Future<Map<String, dynamic>?> findById(int idCiudadano) async {
    final db = await LocalDb.instance;
    final res = await db.query(
      _table,
      where: 'id_ciudadano = ?',
      whereArgs: [idCiudadano],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  ///* Buscar por CURP (normalizada)
  static Future<Map<String, dynamic>?> findByCurp(String curp) async {
    final db = await LocalDb.instance;
    final cc = curp.trim().toUpperCase();
    final res = await db.query(
      _table,
      where: 'curp_ciudadano = ?',
      whereArgs: [cc],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  ///* Actualizar por id_ciudadano
  static Future<int> update(int idCiudadano, Map<String, dynamic> data) async {
    final db = await LocalDb.instance;
    final normalized = _normalizeCitizen(data);

    try {
      return await db.update(
        _table,
        normalized,
        where: 'id_ciudadano = ?',
        whereArgs: [idCiudadano],
      );
    } on DatabaseException catch (e) {
      final msg = e.toString();
      if (msg.contains('UNIQUE constraint failed') &&
          msg.contains('ciudadanos.curp_ciudadano')) {
        throw 'La CURP que intentas guardar ya existe en otro registro.';
      }
      rethrow;
    }
  }

  ///! Eliminar por id_ciudadano
  static Future<int> delete(int idCiudadano) async {
    final db = await LocalDb.instance;
    return db.delete(_table, where: 'id_ciudadano = ?', whereArgs: [idCiudadano]);
  }

  ///* Upsert usando curp_ciudadano (si viene)
  static Future<int> upsertByCurp(Map<String, dynamic> data) async {
    final normalized = _normalizeCitizen(data);
    final curp = (normalized['curp_ciudadano'] ?? '').toString();

    if (curp.isEmpty) return insert(normalized); //* sin CURP -> insert directo

    final existing = await findByCurp(curp);
    if (existing == null) return insert(normalized);
    return update(existing['id_ciudadano'] as int, normalized);
  }
}
