// lib/widgets/citizens_tab.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:app_atencion_ciudadana/controllers/citizen_home_controller.dart';
import 'package:app_atencion_ciudadana/widgets/citizen_detail_edit_sheet.dart';

class CitizensTab extends StatefulWidget {
  final CitizenHomeController controller;
  final Color primaryColor;
  final Color accentColor;

  const CitizensTab({
    super.key,
    required this.controller,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<CitizensTab> createState() => _CitizensTabState();
}

class _CitizensTabState extends State<CitizensTab> {
  final TextEditingController _searchController = TextEditingController();

  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

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
                _buildNewCitizenButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (widget.controller.filteredCitizens.isNotEmpty)
            _buildCitizensList()
          else if (widget.controller.hasCitizens)
            _buildNoResultsWidget()
          else if (widget.controller.isLoading)
            _buildLoadingWidget()
          else
            _buildEmptyStateWidget(),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    final canUpload = widget.controller.citizensWithCurp > 0 && !widget.controller.isUploading;

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
          onTap: canUpload ? widget.controller.uploadCitizensJson : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Subir ${widget.controller.citizensWithCurp}',
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

  Widget _buildStatsCard() {
    final genderStats = widget.controller.getGenderStats();

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
                    child: Icon(Icons.people_rounded, color: widget.primaryColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Ciudadanos Registrados',
                    style: TextStyle(
                      fontSize: 16,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (widget.controller.citizensWithCurp > 0)
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
              _buildStatItem('Total', widget.controller.totalCitizens.toString(),
                  widget.primaryColor, Icons.person_rounded),
              Container(width: 1, height: 40, color: borderColor),
              _buildStatItem('Con CURP', widget.controller.citizensWithCurp.toString(),
                  const Color(0xFF10B981), Icons.verified_user_rounded),
              Container(width: 1, height: 40, color: borderColor),
              _buildStatItem('Hombres', genderStats['masculino'].toString(),
                  const Color(0xFF3B82F6), Icons.male_rounded),
              Container(width: 1, height: 40, color: borderColor),
              _buildStatItem('Mujeres', genderStats['femenino'].toString(),
                  const Color(0xFFEC4899), Icons.female_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
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
          hintText: 'Buscar por CURP, nombre, teléfono, email...',
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
            margin: EdgeInsets.only(right: 8, left: index == 0 ? 0 : 0),
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

  Widget _buildNewCitizenButton() {
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
          onTap: () => Navigator.pushNamed(context, '/offlineForm/citizen'),
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
                  child: const Icon(Icons.spatial_audio_off, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nuevo Ciudadano',
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

  Widget _buildCitizensList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final citizen = widget.controller.filteredCitizens[index];
          return _buildCitizenCard(citizen);
        },
        childCount: widget.controller.filteredCitizens.length,
      ),
    );
  }

  Widget _buildCitizenCard(Map<String, dynamic> citizen) {
    final status = widget.controller.getCitizenStatus(citizen);
    final statusColor = widget.controller.getCitizenStatusColor(citizen);
    final curp = citizen['curp_ciudadano']?.toString() ?? '';
    final nombreCompleto = citizen['nombre_completo']?.toString() ?? '';
    final telefono = citizen['telefono']?.toString() ?? '';
    final email = citizen['email']?.toString() ?? '';
    final asentamiento = citizen['asentamiento']?.toString() ?? '';

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
                    curp.isNotEmpty && curp.length == 18
                        ? Icons.verified_user_rounded
                        : Icons.person_rounded,
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
                        nombreCompleto.isNotEmpty ? nombreCompleto : 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
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
                          if (curp.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                curp,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: widget.primaryColor, size: 18),
                  onSelected: (value) => _handleMenuAction(value, citizen),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'view_edit',
                      child: Row(
                        children: [
                          Icon(Icons.drive_file_rename_outline, size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (telefono.isNotEmpty || email.isNotEmpty || asentamiento.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (telefono.isNotEmpty)
                    _buildInfoRow('Teléfono', telefono, Icons.phone),
                  if (telefono.isNotEmpty && (email.isNotEmpty || asentamiento.isNotEmpty))
                    const SizedBox(height: 8),
                  if (email.isNotEmpty)
                    _buildInfoRow('Email', email, Icons.email),
                  if (email.isNotEmpty && asentamiento.isNotEmpty)
                    const SizedBox(height: 8),
                  if (asentamiento.isNotEmpty)
                    _buildInfoRow('Asentamiento', asentamiento, Icons.location_on),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: widget.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: widget.primaryColor, size: 12),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.primaryColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              'No se encontraron ciudadanos',
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
                color: widget.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.people_rounded, size: 48, color: widget.primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay ciudadanos registrados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comienza registrando el primer ciudadano',
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

  Widget _buildLoadingWidget() {
    return SliverFillRemaining(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cargando ciudadanos...',
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Map<String, dynamic> citizen) async {
    if (action == 'view_edit') {
      final result = await CitizenDetailEditSheet.showSheet(
        context: context,
        citizen: citizen,
        primaryColor: widget.primaryColor,
        accentColor: widget.accentColor,
        controller: widget.controller,
      );
      
      if (mounted && result == 'updated') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ciudadano actualizado correctamente'),
          backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    }
  }
}