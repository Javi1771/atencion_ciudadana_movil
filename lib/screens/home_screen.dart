// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atencion_ciudadana/services/local_db.dart';
import 'package:atencion_ciudadana/widgets/alert_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const Color primary = Color(0xFF6D1F70);
  static const Color primaryLight = Color(0xFF8E24AA);
  static const Color primaryDark = Color(0xFF4A0072);
  static const Color background = Color(0xFFF8F9FA);
  static const Color warning = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);

  List<Map<String, dynamic>> _pendingRows = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPending();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPending();
    }
  }

  Future<void> _loadPending() async {
    final rows = await IncidenceLocalRepo.pending();
    setState(() => _pendingRows = rows);
  }

  Future<void> _uploadJson() async {
    //? Filtrar solo registros con CURP válida
    final validRows =
        _pendingRows.where((row) {
          final curp = row['curp']?.toString() ?? '';
          return curp.isNotEmpty;
        }).toList();

    if (validRows.isEmpty) {
      AlertHelper.showAlert(
        'No hay registros con CURP válida para subir',
        type: AlertType.warning,
      );
      setState(() => _isUploading = false);
      return;
    }

    setState(() => _isUploading = true);

    final payload =
        validRows.map((row) {
          return {
            'curp_solicitante': row['curp']?.toString() ?? '',
            'colonia': row['colonia']?.toString() ?? '',
            'direccion': row['direccion']?.toString() ?? '',
            'comentarios': row['comentarios']?.toString() ?? '',
            'tipo_solicitante': row['tipo_solicitante']?.toString() ?? '',
            'origen': row['origen']?.toString() ?? '',
            'motivo': row['motivo']?.toString() ?? '',
            'secretaria': row['secretaria']?.toString() ?? '',
            'tipo_incidencia': row['tipo_incidencia']?.toString() ?? '',
          };
        }).toList();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isEmpty) {
      AlertHelper.showAlert(
        'Token no encontrado. Inicia sesión.',
        type: AlertType.error,
      );
      setState(() => _isUploading = false);
      return;
    }

    final uri = Uri.parse(
      'https://sanjuandelrio.gob.mx/tramites-sjr/Api/principal/cargar_indicadores_app',
    );

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('🌐 Status: ${response.statusCode}');
      debugPrint('📦 Body: ${response.body.trim()}');

      bool ok = false;
      String msg = 'Error en servidor';
      try {
        final json = jsonDecode(response.body);
        ok = json['success'] == true;
        msg = json['message']?.toString() ?? msg;
      } catch (_) {
        msg = response.body.trim();
      }

      if (ok) {
        //! Eliminar solo los registros válidos que se subieron
        for (var row in validRows) {
          await IncidenceLocalRepo.delete(row['id'] as int);
        }
        await _loadPending();

        AlertHelper.showAlert(msg, type: AlertType.success);

        //! Mostrar advertencia si quedan registros sin CURP
        if (_pendingRows.isNotEmpty) {
          AlertHelper.showAlert(
            'Algunos registros no se subieron porque falta CURP',
            type: AlertType.warning,
          );
        }
      } else {
        AlertHelper.showAlert(msg, type: AlertType.error);
      }
    } catch (e) {
      AlertHelper.showAlert('Error de red: $e', type: AlertType.error);
      debugPrint('🚨 Upload error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _updateCurp(int id, String newCurp) async {
    if (newCurp.isEmpty) {
      AlertHelper.showAlert(
        'La CURP no puede estar vacía',
        type: AlertType.error,
      );
      return;
    }

    //? Validar formato de CURP
    if (!_isValidCurp(newCurp)) {
      AlertHelper.showAlert(
        'Formato de CURP inválido. Debe tener 18 caracteres alfanuméricos',
        type: AlertType.error,
      );
      return;
    }

    try {
      await IncidenceLocalRepo.updateCurp(id, newCurp);
      await _loadPending();
      AlertHelper.showAlert(
        'CURP actualizada correctamente',
        type: AlertType.success,
      );
    } catch (e) {
      AlertHelper.showAlert('Error al actualizar: $e', type: AlertType.error);
    }
  }

  bool _isValidCurp(String curp) {
    //? Validación básica de CURP: 18 caracteres alfanuméricos
    return curp.length == 18 && RegExp(r'^[A-Z0-9]{18}$').hasMatch(curp);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    Navigator.pushReplacementNamed(context, '/auth');
    AlertHelper.showAlert(
      'Sesión cerrada correctamente',
      type: AlertType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _pendingRows.isNotEmpty;
    final hasValidRows = _pendingRows.any(
      (row) => (row['curp']?.toString() ?? '').isNotEmpty,
    );

    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [background, Colors.white],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadPending,
          color: primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              //? Tarjeta de estado
              _buildStatusCard(hasPending, hasValidRows),

              const SizedBox(height: 24),

              //? Botón de acción principal
              _buildMainActionButton(),

              const SizedBox(height: 24),

              //? Sección de datos locales
              if (_pendingRows.isNotEmpty) _buildLocalDataSection(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.diversity_3, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 12),
          const Text(
            'Atención Ciudadana',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: primary,
      elevation: 4,
      shadowColor: primaryDark,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadPending,
          tooltip: 'Actualizar',
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: () {
            AlertHelper.showAlert(
              'Solo se subirán los registros con CURP válida',
              type: AlertType.error,
            );
          },
          tooltip: 'Información',
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _logout,
          tooltip: 'Cerrar sesión',
        ),
      ],
    );
  }

  Widget _buildStatusCard(bool hasPending, bool hasValidRows) {
    final hasInvalidRows = hasPending && !hasValidRows;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black26,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                hasPending
                    ? [Colors.white, primaryLight.withOpacity(0.05)]
                    : [Colors.white, success.withOpacity(0.05)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      hasPending
                          ? primaryLight.withOpacity(0.1)
                          : success.withOpacity(0.1),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      hasPending ? Icons.info : Icons.check_circle,
                      color: hasPending ? primary : success,
                      size: 32,
                    ),
                    if (hasInvalidRows)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: warning,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPending ? 'Registros pendientes' : 'Todo sincronizado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: hasPending ? primary : success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPending
                          ? '${_pendingRows.length} ${_pendingRows.length == 1 ? "incidencia pendiente" : "incidencias pendientes"}'
                          : 'Todos los registros están sincronizados',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 78, 78, 78),
                        fontSize: 14,
                      ),
                    ),
                    if (hasInvalidRows)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Falta CURP en todos los registros',
                          style: TextStyle(
                            color: warning,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (hasPending && hasValidRows)
                _isUploading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                    : FloatingActionButton(
                      mini: true,
                      backgroundColor: primary,
                      onPressed: _uploadJson,
                      child: const Icon(
                        Icons.cloud_upload,
                        color: Colors.white,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          colors: [primary, primaryLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/offlineForm'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Registrar nueva incidencia',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalDataSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.fact_check, color: primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Datos Locales (${_pendingRows.length})',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color.fromARGB(255, 55, 53, 53),
                          fontStyle: FontStyle.italic,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Solo se puede editar el campo CURP. ',
                          ),
                          TextSpan(
                            text: 'Los registros sin CURP no se subirán.',
                            style: TextStyle(
                              color: warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            //* Lista de registros pendientes
            ..._pendingRows.map((row) => _buildPendingRowCard(row)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRowCard(Map<String, dynamic> row) {
    final hasCurp = (row['curp'] as String?)?.isNotEmpty ?? false;
    final motivo = row['motivo']?.toString() ?? '';
    final colonia = row['colonia']?.toString() ?? '';
    final comentarios = row['comentarios']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          //* Header con CURP section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasCurp ? primary : warning,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_copy,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          hasCurp
                              ? row['curp']?.toString() ?? 'No especificada'
                              : 'CURP no registrada',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => _showEditCurpDialog(row),
                ),
              ],
            ),
          ),

          //* Data content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //* status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            hasCurp
                                ? success.withOpacity(0.1)
                                : warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hasCurp ? 'LISTO PARA SUBIR' : 'FALTA REGISTRAR CURP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: hasCurp ? success : warning,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                //* Data rows
                _buildDataRow('Motivo', motivo, Icons.library_books),
                const SizedBox(height: 16),
                _buildDataRow('Colonia', colonia, Icons.pin_drop),
                const SizedBox(height: 16),
                _buildDataRow('Comentarios', comentarios, Icons.comment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, //* título en negro
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'No especificado',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color.fromARGB(255, 143, 143, 143), //* contenido en gris
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditCurpDialog(Map<String, dynamic> row) {
    final TextEditingController curpController = TextEditingController(
      text: row['curp']?.toString() ?? '',
    );

    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //* Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Editar CURP',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    //* Form
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          TextField(
                            controller: curpController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'Nueva CURP',
                              labelStyle: const TextStyle(color: textSecondary),
                              prefixIcon: Icon(Icons.badge, color: primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              errorText: errorText,
                            ),
                            maxLength: 18,
                            style: const TextStyle(
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                            onChanged: (value) {
                              if (value.length == 18) {
                                setState(() => errorText = null);
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'La CURP debe tener 18 caracteres alfanuméricos',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: BorderSide(color: primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: () {
                                    final newCurp = curpController.text.trim();
                                    if (newCurp.length != 18) {
                                      setState(
                                        () =>
                                            errorText =
                                                'CURP debe tener 18 caracteres',
                                      );
                                    } else if (!_isValidCurp(newCurp)) {
                                      setState(
                                        () =>
                                            errorText =
                                                'Formato de CURP inválido',
                                      );
                                    } else {
                                      _updateCurp(row['id'] as int, newCurp);
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text(
                                    'Guardar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
