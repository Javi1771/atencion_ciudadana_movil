// lib/widgets/incidences_tab.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:app_atencion_ciudadana/controllers/home_controller.dart';

class IncidencesTab extends StatefulWidget {
  final HomeController controller;
  final Color primaryColor;
  final Color accentColor;

  const IncidencesTab({
    super.key,
    required this.controller,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<IncidencesTab> createState() => _IncidencesTabState();
}

class _IncidencesTabState extends State<IncidencesTab> {
  final TextEditingController _searchController = TextEditingController();

  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 12 : 16,
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: isSmallScreen ? 8 : 12),
                
                _buildStatsCard(),
                const SizedBox(height: 16),

                _buildSearchField(),
                const SizedBox(height: 12),

                _buildFilterChips(),
                const SizedBox(height: 16),

                _buildNewIncidenceButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          if (widget.controller.filteredRows.isNotEmpty)
            _buildIncidencesList()
          else if (widget.controller.hasPending)
            _buildNoResultsWidget()
          else
            _buildEmptyStateWidget(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.primaryColor.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.poll, color: widget.primaryColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Incidencias Registradas',
                    style: TextStyle(
                      fontSize: 16,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (widget.controller.hasValidRows)
                widget.controller.isUploading
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                          ),
                        ),
                      )
                    : _buildUploadButton(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', widget.controller.totalRows.toString(), 
                  widget.primaryColor, Icons.folder_rounded),
              Container(width: 1, height: 40, color: borderColor),
              _buildStatItem('Válidas', widget.controller.validRows.toString(), 
                  successGreen, Icons.check_circle_rounded),
              Container(width: 1, height: 40, color: borderColor),
              _buildStatItem('Inválidas', widget.controller.invalidRows.toString(), 
                  errorRed, Icons.error_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [widget.primaryColor, widget.accentColor]),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.controller.uploadJson,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Subir ${widget.controller.validRows}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: widget.controller.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Buscar por CURP, nombre, colonia...',
          hintStyle: TextStyle(color: textSecondary.withOpacity(0.7), fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: widget.primaryColor),
          suffixIcon: widget.controller.searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, size: 18, color: textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    widget.controller.setSearchQuery('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: false,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.controller.getFilterOptions().length,
        itemBuilder: (context, index) {
          final filter = widget.controller.getFilterOptions()[index];
          final isSelected = filter == widget.controller.selectedFilter;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.controller.setFilter(filter),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? LinearGradient(colors: [widget.primaryColor, widget.accentColor])
                        : null,
                    color: isSelected ? null : cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : borderColor,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: widget.primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Text(
                    widget.controller.getFilterLabel(filter),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewIncidenceButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.primaryColor, widget.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/offlineForm'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.interpreter_mode, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nueva Incidencia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncidencesList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final row = widget.controller.filteredRows[index];
          return _buildIncidenceCard(row);
        },
        childCount: widget.controller.filteredRows.length,
      ),
    );
  }

  Widget _buildIncidenceCard(Map<String, dynamic> row) {
    final status = widget.controller.getRecordStatus(row);
    final statusColor = widget.controller.getRecordStatusColor(row);
    final curp = row['curp']?.toString() ?? '';
    final nombre = row['nombre']?.toString() ?? '';
    final colonia = row['colonia']?.toString() ?? '';
    final comentarios = row['comentarios']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    curp.isNotEmpty && curp.length == 18 ? Icons.verified_user_rounded : 
                    nombre.isNotEmpty ? Icons.person_rounded : Icons.warning_rounded,
                    color: widget.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curp.isNotEmpty ? curp : (nombre.isNotEmpty ? nombre : 'Sin identificación'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit_rounded, size: 18, color: widget.primaryColor),
                    onPressed: () => _showEditCurpDialog(row),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ),

          if (colonia.isNotEmpty || comentarios.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (colonia.isNotEmpty)
                    _buildInfoRow('Colonia', colonia, Icons.location_on_rounded),
                  if (colonia.isNotEmpty && comentarios.isNotEmpty) 
                    const SizedBox(height: 12),
                  if (comentarios.isNotEmpty)
                    _buildInfoRow('Comentarios', comentarios, Icons.comment_rounded),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: widget.primaryColor, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'No especificado',
                style: const TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsWidget() {
    return SliverFillRemaining(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.search_off_rounded, size: 48, color: widget.primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'No se encontraron resultados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta cambiar los filtros o el término de búsqueda',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return SliverFillRemaining(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF6B46C1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF6B46C1)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Todo sincronizado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay registros pendientes por subir',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.edit_rounded, size: 20, color: widget.primaryColor),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Editar CURP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: curpController,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (v) {
                          final val = v.trim().toUpperCase();
                          if (val.length == 18 && RegExp(r'^[A-Z0-9]{18}$').hasMatch(val)) {
                            setState(() => errorText = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Nueva CURP (18 caracteres)',
                          labelStyle: TextStyle(color: widget.primaryColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          counterStyle: TextStyle(color: textSecondary),
                          errorText: errorText,
                        ),
                        maxLength: 18,
                        style: const TextStyle(fontSize: 14, letterSpacing: 1.2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: textSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [widget.primaryColor, widget.accentColor]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextButton(
                              onPressed: () async {
                                final newCurp = curpController.text.trim().toUpperCase();

                                if (newCurp.isEmpty) {
                                  setState(() => errorText = 'La CURP no puede estar vacía');
                                  return;
                                }
                                if (newCurp.length != 18 || !RegExp(r'^[A-Z0-9]{18}$').hasMatch(newCurp)) {
                                  setState(() => errorText = 'Formato inválido. Debe ser A-Z/0-9 y 18 caracteres');
                                  return;
                                }

                                await widget.controller.updateCurp(row['id'] as int, newCurp);
                                await widget.controller.loadPending();

                                if (context.mounted) Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Guardar'),
                            ),
                          ),
                        ),
                      ],
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