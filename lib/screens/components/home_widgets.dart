// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class HomePalette {
  static const Color primary = Color(0xFF6B46C1);
  static const Color primaryLight = Color(0xFF9F7AEA);
  static const Color primaryDark = Color(0xFF553C9A);
  static const Color background = Color(0xFFF8FAFF);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFD32F2F);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF6B7280);
}

// ---------- CONTENEDOR PRINCIPAL SCROLLEABLE ----------
Widget buildMainContainer({
  required BuildContext context,
  required Future<void> Function() onRefresh,
  required List<Widget> children,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, -6),
        ),
      ],
    ),
    child: RefreshIndicator(
      onRefresh: onRefresh,
      color: HomePalette.primary,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(
          16, 18, 16, 24 + MediaQuery.of(context).padding.bottom,
        ),
        children: children,
      ),
    ),
  );
}

// ---------- HEADER BUTTONS ----------
Widget buildHeaderButtons({
  required BuildContext context,
  required VoidCallback onRefresh,
  required VoidCallback onInfo,
  required VoidCallback onLogout,
}) {
  final top = MediaQuery.of(context).padding.top + 10;
  return Positioned(
    top: top, left: 16, right: 16,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _glassIcon(icon: Icons.refresh, onTap: onRefresh),
        Row(
          children: [
            _glassIcon(icon: Icons.info_outline, onTap: onInfo),
            const SizedBox(width: 10),
            _glassIcon(icon: Icons.logout, onTap: onLogout),
          ],
        ),
      ],
    ),
  );
}

Widget _glassIcon({required IconData icon, required VoidCallback onTap}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    ),
  );
}

// ---------- BUSCADOR ----------
Widget buildGlobalSearchBar({
  required TextEditingController controller,
  required bool isSearching,
  required String query,
  required VoidCallback onClear,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: HomePalette.primary.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(
      children: [
        const SizedBox(width: 4),
        Icon(Icons.search, color: HomePalette.primary.withOpacity(0.9), size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Buscar por CURP (18) o NOMBRE (mín. 3)',
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 15, letterSpacing: 0.5),
          ),
        ),
        if (isSearching)
          const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (query.isNotEmpty)
          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClear),
      ],
    ),
  );
}

// ---------- ESTADO + SUBIR ----------
Widget buildStatusCard({
  required bool hasPending,
  required int pendingCount,
  required int invalidCurps,
  required bool isUploading,
  required bool canUpload,
  required VoidCallback onUpload,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: hasPending
            ? [Colors.white, HomePalette.primaryLight.withOpacity(0.08)]
            : [Colors.white, HomePalette.success.withOpacity(0.08)],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
      border: Border.all(color: Colors.grey.shade200),
    ),
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasPending
                ? HomePalette.primaryLight.withOpacity(0.15)
                : HomePalette.success.withOpacity(0.15),
          ),
          child: Icon(
            hasPending ? Icons.info : Icons.check_circle,
            color: hasPending ? HomePalette.primary : HomePalette.success,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasPending ? 'Registros pendientes' : 'Todo sincronizado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: hasPending ? HomePalette.primary : HomePalette.success,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasPending
                    ? '$pendingCount ${pendingCount == 1 ? "incidencia pendiente" : "incidencias pendientes"}'
                    : 'Todos los registros están sincronizados',
                style: const TextStyle(color: HomePalette.textSecondary, fontSize: 13.5),
              ),
              if (hasPending && invalidCurps > 0)
                const SizedBox(height: 6),
              if (hasPending && invalidCurps > 0)
                Text(
                  'Faltan ${invalidCurps == 1 ? "1 CURP" : "$invalidCurps CURP"} por corregir.',
                  style: const TextStyle(
                    color: HomePalette.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
            ],
          ),
        ),
        if (hasPending)
          ElevatedButton.icon(
            onPressed: (canUpload && !isUploading) ? onUpload : null,
            icon: isUploading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_upload, size: 18),
            label: const Text('Subir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HomePalette.primary,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.white70,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
      ],
    ),
  );
}

// ---------- CTA ----------
Widget buildMainActionButton({
  required BuildContext context,
  required VoidCallback onTap,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: HomePalette.primaryDark.withOpacity(0.22),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
      gradient: const LinearGradient(
        colors: [HomePalette.primary, HomePalette.primaryLight],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    ),
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
          SizedBox(width: 10),
          Text(
            'Registrar nueva incidencia',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------- RESULTADOS GLOBALES ----------
Widget buildGlobalResultsSection({
  required List<Map<String, dynamic>> results,
  required bool isSearching,
  required String query,
}) {
  final noResults = results.isEmpty && !isSearching;

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HomePalette.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search, color: HomePalette.primary, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Resultados Globales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: HomePalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (noResults)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_off, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No se encontraron coincidencias para "$query".',
                      style: const TextStyle(color: HomePalette.textSecondary, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          ...results.map(_buildGlobalResultCard),
        ],
      ),
    ),
  );
}

Widget _buildGlobalResultCard(Map<String, dynamic> row) {
  final curp = (row['curp'] ?? row['curp_solicitante'] ?? '').toString();
  final nombre = (row['nombre'] ?? row['nombre_solicitante'] ?? '').toString();
  final motivo = (row['motivo'] ?? '').toString();
  final colonia = (row['colonia'] ?? '').toString();
  final tipo = (row['tipo_incidencia'] ?? '').toString();
  final secretaria = (row['secretaria'] ?? '').toString();

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: HomePalette.primary.withOpacity(0.08),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_open, color: HomePalette.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  curp.isNotEmpty ? curp : (nombre.isNotEmpty ? nombre : 'Registro'),
                  style: const TextStyle(
                    color: HomePalette.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              _dataRow('Nombre', nombre, Icons.person),
              const SizedBox(height: 12),
              _dataRow('CURP', curp, Icons.badge),
              const SizedBox(height: 12),
              _dataRow('Motivo', motivo, Icons.library_books),
              const SizedBox(height: 12),
              _dataRow('Tipo', tipo, Icons.report_problem_outlined),
              const SizedBox(height: 12),
              _dataRow('Colonia', colonia, Icons.pin_drop_outlined),
              const SizedBox(height: 12),
              _dataRow('Secretaría', secretaria, Icons.account_balance),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------- DATOS LOCALES ----------
Widget buildLocalDataSection({
  required List<Map<String, dynamic>> rows,
  required bool Function(String) isValidCurp,
  required Future<void> Function(Map<String, dynamic> row) onEditCurp,
}) {
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
                  color: HomePalette.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fact_check, color: HomePalette.primary, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Datos Locales (${rows.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: HomePalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HomePalette.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: HomePalette.warning, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Solo se puede editar el campo CURP. Los registros sin CURP válida no se subirán.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: HomePalette.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...rows.map((row) {
            final curp = (row['curp']?.toString() ?? '').toUpperCase().trim();
            final hasValidCurp = isValidCurp(curp);
            final motivo = row['motivo']?.toString() ?? '';
            final colonia = row['colonia']?.toString() ?? '';
            final comentarios = row['comentarios']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // header
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: hasValidCurp ? HomePalette.primary : HomePalette.warning,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_copy, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hasValidCurp ? curp : (curp.isEmpty ? 'CURP no registrada' : curp),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _smallGlassAction(
                          icon: Icons.edit,
                          onTap: () => onEditCurp(row),
                        ),
                      ],
                    ),
                  ),
                  // body
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _chipStatus(hasValidCurp),
                        const SizedBox(height: 12),
                        _dataRow('Motivo', motivo, Icons.library_books),
                        const SizedBox(height: 12),
                        _dataRow('Colonia', colonia, Icons.pin_drop),
                        const SizedBox(height: 12),
                        _dataRow('Comentarios', comentarios, Icons.comment),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ),
  );
}

// ---------- Dialogo editar CURP ----------
Future<String?> showEditCurpDialog({
  required BuildContext context,
  required String initialCurp,
}) async {
  final controller = TextEditingController(text: initialCurp);
  String? errorText;

  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                // header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: HomePalette.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.badge, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Editar CURP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                // body
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Nueva CURP',
                          labelStyle: const TextStyle(color: HomePalette.textSecondary),
                          prefixIcon: const Icon(Icons.badge, color: HomePalette.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: HomePalette.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          errorText: errorText,
                        ),
                        maxLength: 18,
                        style: const TextStyle(fontSize: 16, letterSpacing: 1.2),
                        onChanged: (value) {
                          if (value.length == 18) setState(() => errorText = null);
                        },
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'La CURP debe tener 18 caracteres alfanuméricos',
                        style: TextStyle(
                          fontSize: 12,
                          color: HomePalette.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: HomePalette.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: HomePalette.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HomePalette.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: () {
                                final value = controller.text.trim().toUpperCase();
                                if (value.length != 18 ||
                                    !RegExp(r'^[A-Z0-9]{18}$').hasMatch(value)) {
                                  setState(() => errorText = 'CURP inválida');
                                } else {
                                  Navigator.pop(context, value);
                                }
                              },
                              child: const Text(
                                'Guardar',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
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
      });
    },
  );
}

// ---------- helpers visuales ----------
Widget _smallGlassAction({required IconData icon, required VoidCallback onTap}) {
  return Material(
    color: Colors.white.withOpacity(0.22),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    ),
  );
}

Widget _chipStatus(bool hasCurp) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasCurp ? HomePalette.success.withOpacity(0.1) : HomePalette.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasCurp ? HomePalette.success.withOpacity(0.4) : HomePalette.warning.withOpacity(0.4),
        ),
      ),
      child: Text(
        hasCurp ? 'LISTO PARA SUBIR' : 'FALTA CURP VÁLIDA',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: hasCurp ? HomePalette.success : HomePalette.warning,
        ),
      ),
    ),
  );
}

Widget _dataRow(String label, String value, IconData icon) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: HomePalette.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: HomePalette.primary),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              (value).isNotEmpty ? value : 'No especificado',
              style: const TextStyle(
                fontSize: 15,
                color: HomePalette.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
