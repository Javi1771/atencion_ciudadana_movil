// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primary = Color(0xFF6D1F70);

  int _pendingCount = 0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'incidencias.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE incidencias (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            curp_solicitante TEXT,
            colonia TEXT,
            direccion TEXT,
            comentarios TEXT,
            tipo_solicitante TEXT,
            origen TEXT,
            motivo TEXT,
            secretaria TEXT,
            tipo_incidencia TEXT,
            uploaded INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> _loadPendingCount() async {
    final db = await _openDb();
    final rows = await db.query(
      'incidencias',
      where: 'uploaded = ?',
      whereArgs: [0],
    );
    setState(() => _pendingCount = rows.length);
  }

  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);

    // Aquí deberías poner tu lógica real de subida:
    // 1. Generar Excel con las filas pendientes
    // 2. Hacer POST al endpoint con FormData
    // 3. Esperar respuesta y, en éxito...

    await Future.delayed(const Duration(seconds: 2));

    // Marcar todos como subidos
    final db = await _openDb();
    await db.update(
      'incidencias',
      {'uploaded': 1},
      where: 'uploaded = ?',
      whereArgs: [0],
    );

    setState(() => _isUploading = false);
    await _loadPendingCount();

    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      const SnackBar(content: Text('Importación finalizada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atención Ciudadana'),
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_pendingCount > 0) ...[
              Card(
                elevation: 4,
                child: ListTile(
                  leading: Icon(Icons.cloud_upload, color: primary),
                  title: Text('Registros pendientes: $_pendingCount'),
                  trailing: _isUploading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : ElevatedButton(
                          onPressed: _handleUpload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                          ),
                          child: const Text('Subir ahora'),
                        ),
                ),
              ),
            ] else ...[
              Card(
                elevation: 4,
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('No hay registros pendientes'),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Botón para registrar nueva incidencia (ya con Internet)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/offlineForm'),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Registrar nueva incidencia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
