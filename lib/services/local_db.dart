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
    //? print('[LocalDb] Abriendo base de datos en: $path');

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) async {
        //? print('[LocalDb] onCreate v$_dbVersion');
        await _createIncidencias(db);
        await _createCiudadanos(db);
      },
      onUpgrade: (db, oldV, newV) async {
        //? print('[LocalDb] onUpgrade $oldV -> $newV');

        //* v1 -> v2: crear tabla ciudadanos (por compatibilidad)
        if (oldV < 2) {
          await _createCiudadanos(db);
        }
      },
      onOpen: (_) => print('[LocalDb] Base abierta correctamente'),
    );
    return _db!;
  }

  //? --- Tabla incidencias (ya existente) ---
  static Future<void> _createIncidencias(Database db) async {
    //? print('[LocalDb] Creando tabla "incidencias" (si no existe)');
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

  //* --- NUEVA tabla ciudadanos ---
  static Future<void> _createCiudadanos(Database db) async {
    //? print('[LocalDb] Creando tabla "ciudadanos" (si no existe)');
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

    //* Índices útiles
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
  ///* Guarda un nuevo registro en la tabla 'incidencias'
  static Future<int> save(Map<String, dynamic> data) async {
    final db = await LocalDb.instance;
    final id = await db.insert('incidencias', data);
    //? print('[IncidenceLocalRepo] Guardada incidencia id=$id → $data');
    return id;
  }

  ///* Devuelve todos los registros
  static Future<List<Map<String, dynamic>>> pending() async {
    final db = await LocalDb.instance;
    final rows = await db.query('incidencias', orderBy: 'id DESC');
    //? print('[IncidenceLocalRepo] Pendientes: ${rows.length}');
    return rows;
  }

  ///* Buscar una incidencia por ID
  static Future<Map<String, dynamic>?> findById(int id) async {
    final db = await LocalDb.instance;
    final res =
        await db.query('incidencias', where: 'id = ?', whereArgs: [id], limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  ///* Editar (update parcial) una incidencia por ID
  static Future<int> update(int id, Map<String, dynamic> data) async {
    final db = await LocalDb.instance;
    final count =
        await db.update('incidencias', data, where: 'id = ?', whereArgs: [id]);
    //? print('[IncidenceLocalRepo] Actualizados $count para id=$id → $data');
    return count;
  }

  ///? Actualiza el campo CURP de un registro específico (compatibilidad)
  static Future<int> updateCurp(int id, String newCurp) async {
    return update(id, {'curp': newCurp});
  }

  ///! Elimina una incidencia por ID
  static Future<int> delete(int id) async {
    final db = await LocalDb.instance;
    final count =
        await db.delete('incidencias', where: 'id = ?', whereArgs: [id]);
    //? print('[IncidenceLocalRepo] Eliminados: $count (id=$id)');
    return count;
  }
}

///* =====================================
///*  Repositorio LOCAL para *ciudadanos*
///*  (nueva tabla con CRUD completo)
///* =====================================
class CitizenLocalRepo {
  static const _table = 'ciudadanos';

  ///* Inserta un ciudadano. Si `nombre_completo` viene vacío, se compone.
  static Future<int> insert(Map<String, dynamic> data) async {
    final db = await LocalDb.instance;

    final nombre = (data['nombre'] ?? '').toString().trim();
    final pApe = (data['primer_apellido'] ?? '').toString().trim();
    final sApe = (data['segundo_apellido'] ?? '').toString().trim();

    data['nombre_completo'] =
        (data['nombre_completo'] ?? '').toString().trim().isNotEmpty
            ? data['nombre_completo']
            : [nombre, pApe, sApe].where((e) => e.isNotEmpty).join(' ').trim();

    final id = await db.insert(
      _table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    //? print('[CitizenLocalRepo] Insertado id=$id → $data');
    return id; //* devuelve id insertado
  }

  ///* Listar todos
  static Future<List<Map<String, dynamic>>> all() async {
    final db = await LocalDb.instance;
    final rows = await db.query(_table, orderBy: 'id_ciudadano DESC');
    //? print('[CitizenLocalRepo] Registros: ${rows.length}');
    return rows;
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

  ///* Buscar por CURP
  static Future<Map<String, dynamic>?> findByCurp(String curp) async {
    final db = await LocalDb.instance;
    final res = await db.query(
      _table,
      where: 'curp_ciudadano = ?',
      whereArgs: [curp],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  ///? Actualizar por id_ciudadano
  static Future<int> update(int idCiudadano, Map<String, dynamic> data) async {
    final db = await LocalDb.instance;
    final count = await db.update(
      _table,
      data,
      where: 'id_ciudadano = ?',
      whereArgs: [idCiudadano],
    );
    //? print('[CitizenLocalRepo] Actualizados $count para id=$idCiudadano → $data');
    return count;
  }

  ///! Eliminar por id_ciudadano
  static Future<int> delete(int idCiudadano) async {
    final db = await LocalDb.instance;
    final count = await db.delete(
      _table,
      where: 'id_ciudadano = ?',
      whereArgs: [idCiudadano],
    );
    //? print('[CitizenLocalRepo] Eliminados: $count (id=$idCiudadano)');
    return count;
  }

  ///* Upsert usando curp_ciudadano (si viene)
  static Future<int> upsertByCurp(Map<String, dynamic> data) async {
    final curp = (data['curp_ciudadano'] ?? '').toString().trim();
    if (curp.isEmpty) return insert(data);
    final existing = await findByCurp(curp);
    if (existing == null) return insert(data);
    return update(existing['id_ciudadano'] as int, data);
  }
}
