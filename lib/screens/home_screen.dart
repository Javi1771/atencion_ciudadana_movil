// lib/screens/home_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:app_atencion_ciudadana/controllers/home_controller.dart';
import 'package:app_atencion_ciudadana/controllers/citizen_home_controller.dart';
import 'package:app_atencion_ciudadana/widgets/incidences_tab.dart';
import 'package:app_atencion_ciudadana/widgets/citizens_tab.dart';
import '../components/CurvedHeader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  late HomeController _incidenceController;
  late CitizenHomeController _citizenController;
  late TabController _tabController;
  
  //* Colores del sistema
  static const Color primaryPurple = Color(0xFF6B46C1);
  static const Color primaryGreen = Color(0xFF059669);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color backgroundGradient1 = Color(0xFFF8FAFF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    //* Inicializar controladores
    _incidenceController = HomeController();
    _citizenController = CitizenHomeController();
    
    //* Configurar TabController
    _tabController = TabController(length: 2, vsync: this);
    
    //* Listeners
    _incidenceController.addListener(() => setState(() {}));
    _citizenController.addListener(() => setState(() {}));
    
    //* Cargar datos iniciales
    _incidenceController.loadPending();
    _citizenController.loadCitizens();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _incidenceController.dispose();
    _citizenController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _incidenceController.loadPending();
      _citizenController.loadCitizens();
    }
  }

  //* Obtener color dinámico según pestaña activa
  Color get _currentPrimaryColor {
    return _tabController.index == 0 ? primaryPurple : primaryGreen;
  }

  Color get _currentAccentColor {
    return _tabController.index == 0 ? accentPurple : accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGradient1,
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final headerHeight = isSmallScreen ? 180.0 : 200.0;
          final contentTop = headerHeight - 60;

          return AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              return Stack(
                children: [
                  //* Banner Curvo dinámico
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: CurvedHeader(
                        title: _tabController.index == 0 
                            ? 'Incidencias' 
                            : 'Ciudadanos',
                        height: headerHeight,
                        fontSize: isSmallScreen ? 18 : 20,
                        textColor: backgroundGradient1,
                      ),
                    ),
                  ),

                  //* Botones del header
                  _buildHeaderButtons(),

                  //* Pestañas deslizables
                  Positioned(
                    top: contentTop - 20,
                    left: 0,
                    right: 0,
                    child: _buildTabBar(),
                  ),

                  //* Contenido principal
                  Positioned(
                    top: contentTop + 20,
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
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          //* Pestaña de Incidencias
                          IncidencesTab(
                            controller: _incidenceController,
                            primaryColor: primaryPurple,
                            accentColor: accentPurple,
                          ),
                          
                          //* Pestaña de Ciudadanos
                          CitizensTab(
                            controller: _citizenController,
                            primaryColor: primaryGreen,
                            accentColor: accentGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderButtons() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //* Botón de actualizar
          IconButton(
            onPressed: () {
              if (_tabController.index == 0) {
                _incidenceController.loadPending();
              } else {
                _citizenController.loadCitizens();
              }
            },
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(6),
            ),
          ),
          
          //* Botón de logout
          IconButton(
            onPressed: () => _incidenceController.logout(context),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [_currentPrimaryColor, _currentAccentColor],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.report_problem_rounded, size: 18),
                const SizedBox(width: 8),
                const Text('Incidencias'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_rounded, size: 18),
                const SizedBox(width: 8),
                const Text('Ciudadanos'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}