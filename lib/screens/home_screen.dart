// lib/screens/home_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:app_atencion_ciudadana/controllers/home_controller.dart';
import '../components/CurvedHeader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late HomeController _controller;
  final TextEditingController _searchController = TextEditingController();

  // Sistema de colores actualizado - matching voice_incidence_screen
  static const Color primaryPurple = Color(0xFF6B46C1);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color backgroundGradient1 = Color(0xFFF8FAFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = HomeController();
    _controller.addListener(() {
      setState(() {});
    });
    _controller.loadPending();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.loadPending();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGradient1,
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final headerHeight = isSmallScreen ? 160.0 : 180.0;
          final contentTop = headerHeight - 40;

          return Stack(
            children: [
              // Banner Curvo - Similar al voice_incidence_screen
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CurvedHeader(
                  title: 'Atención Ciudadana',
                  height: headerHeight,
                  fontSize: isSmallScreen ? 18 : 20,
                ),
              ),

              // Botones sobre el banner
              _buildHeaderButtons(),

              // Contenedor principal con el nuevo estilo
              Positioned(
                top: contentTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 12 : 16,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              
                              // Tarjeta de estadísticas mejorada
                              _buildEnhancedStatsCard(),
                              const SizedBox(height: 16),

                              // Buscador mejorado
                              _buildEnhancedSearchField(),
                              const SizedBox(height: 12),

                              // Filtros mejorados
                              _buildEnhancedFilterChips(),
                              const SizedBox(height: 16),

                              // Botón de nueva incidencia mejorado
                              _buildEnhancedNewIncidenceButton(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      // Lista de registros o estados vacíos
                      if (_controller.filteredRows.isNotEmpty)
                        _buildEnhancedRecordsList()
                      else if (_controller.hasPending)
                        _buildEnhancedNoResultsWidget()
                      else
                        _buildEnhancedEmptyStateWidget(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // === Header buttons ===
  Widget _buildHeaderButtons() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón de actualizar
          IconButton(
            onPressed: _controller.loadPending,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(6),
            ),
          ),
          
          // Solo botón de logout
          IconButton(
            onPressed: () => _controller.logout(context),
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsUploadButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryPurple, accentPurple]),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _controller.uploadJson,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Subir ${_controller.validRows}',
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

  // === Tarjeta de estadísticas mejorada ===
  Widget _buildEnhancedStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryPurple.withOpacity(0.1), width: 1),
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
                      color: primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.analytics_rounded, color: primaryPurple, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Resumen de Registros',
                    style: TextStyle(
                      fontSize: 16,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Botón de subir en la tarjeta de estadísticas
              if (_controller.hasValidRows)
                _controller.isUploading
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryPurple),
                          ),
                        ),
                      )
                    : _buildStatsUploadButton(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEnhancedStatItem('Total', _controller.totalRows.toString(), primaryPurple, Icons.folder_rounded),
              Container(width: 1, height: 40, color: borderColor),
              _buildEnhancedStatItem('Válidas', _controller.validRows.toString(), successGreen, Icons.check_circle_rounded),
              Container(width: 1, height: 40, color: borderColor),
              _buildEnhancedStatItem('Inválidas', _controller.invalidRows.toString(), errorRed, Icons.error_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatItem(String label, String value, Color color, IconData icon) {
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

  // === Buscador mejorado ===
  Widget _buildEnhancedSearchField() {
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
        onChanged: _controller.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Buscar por CURP, nombre, colonia...',
          hintStyle: TextStyle(color: textSecondary.withOpacity(0.7), fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: primaryPurple),
          suffixIcon: _controller.searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, size: 18, color: textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _controller.setSearchQuery('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  // === Filtros mejorados ===
  Widget _buildEnhancedFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _controller.getFilterOptions().length,
        itemBuilder: (context, index) {
          final filter = _controller.getFilterOptions()[index];
          final isSelected = filter == _controller.selectedFilter;
          
          return Container(
            margin: EdgeInsets.only(right: 8, left: index == 0 ? 0 : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _controller.setFilter(filter),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? const LinearGradient(colors: [primaryPurple, accentPurple])
                        : null,
                    color: isSelected ? null : cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : borderColor,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: primaryPurple.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Text(
                    _controller.getFilterLabel(filter),
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

  // === Botón de nueva incidencia mejorado ===
  Widget _buildEnhancedNewIncidenceButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryPurple, accentPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.3),
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
                  child: const Icon(Icons.mic_rounded, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nuevo registro',
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

  // === Lista de registros mejorada ===
  Widget _buildEnhancedRecordsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final row = _controller.filteredRows[index];
          return _buildEnhancedRecordCard(row);
        },
        childCount: _controller.filteredRows.length,
      ),
    );
  }

  Widget _buildEnhancedRecordCard(Map<String, dynamic> row) {
    final status = _controller.getRecordStatus(row);
    final statusColor = _controller.getRecordStatusColor(row);
    final curp = row['curp']?.toString() ?? '';
    final nombre = row['nombre']?.toString() ?? '';
    final colonia = row['colonia']?.toString() ?? '';
    final comentarios = row['comentarios']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryPurple.withOpacity(0.1)),
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
          // Header del registro mejorado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.05),
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
                    color: primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    curp.isNotEmpty && curp.length == 18 ? Icons.verified_user_rounded : 
                    nombre.isNotEmpty ? Icons.person_rounded : Icons.warning_rounded,
                    color: primaryPurple,
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
                    color: primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit_rounded, size: 18, color: primaryPurple),
                    onPressed: () => _showEnhancedEditCurpDialog(row),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ),

          // Contenido del registro mejorado
          if (colonia.isNotEmpty || comentarios.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (colonia.isNotEmpty)
                    _buildEnhancedInfoRow('Colonia', colonia, Icons.location_on_rounded),
                  if (colonia.isNotEmpty && comentarios.isNotEmpty) 
                    const SizedBox(height: 12),
                  if (comentarios.isNotEmpty)
                    _buildEnhancedInfoRow('Comentarios', comentarios, Icons.comment_rounded),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: primaryPurple, size: 14),
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
                  color: primaryPurple,
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

  // === Estados vacíos mejorados ===
  Widget _buildEnhancedNoResultsWidget() {
    return SliverFillRemaining(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.search_off_rounded, size: 48, color: primaryPurple),
            ),
            const SizedBox(height: 20),
            const Text(
              'No se encontraron resultados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta cambiar los filtros o el término de búsqueda',
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

  Widget _buildEnhancedEmptyStateWidget() {
    return SliverFillRemaining(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.check_circle_rounded, size: 48, color: successGreen),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Todo sincronizado!',
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

  // === Diálogo de edición mejorado ===
  void _showEnhancedEditCurpDialog(Map<String, dynamic> row) {
    final TextEditingController curpController = TextEditingController(
      text: row['curp']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
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
                        color: primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_rounded, size: 20, color: primaryPurple),
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
                    decoration: InputDecoration(
                      labelText: 'Nueva CURP (18 caracteres)',
                      labelStyle: TextStyle(color: primaryPurple),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: TextStyle(color: textSecondary),
                    ),
                    maxLength: 18,
                    style: const TextStyle(fontSize: 14),
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
                          gradient: const LinearGradient(colors: [primaryPurple, accentPurple]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextButton(
                          onPressed: () {
                            // Aquí iría la lógica para guardar la CURP editada
                            Navigator.pop(context);
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
  }
}