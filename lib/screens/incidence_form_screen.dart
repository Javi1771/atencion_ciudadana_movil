// lib/screens/incidence_form_screen.dart
// ignore_for_file: deprecated_member_use, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/CurvedHeader.dart';

class IncidenceFormScreen extends StatelessWidget {
  const IncidenceFormScreen({super.key});

  ///* Revisa si hay sesión activa.
  Future<bool> _hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ??
        prefs.getString('access_token') ??
        prefs.getString('token');
    final logged = prefs.getBool('logged_in') ?? false;
    return (token != null && token.isNotEmpty) || logged;
  }

  ///* Back inteligente: pop si hay stack; si no, Home/Auth
  Future<void> _smartBack(BuildContext context) async {
    final didPop = await Navigator.of(context).maybePop();
    if (!didPop) {
      final isLogged = await _hasActiveSession();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        isLogged ? '/home' : '/auth',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) return true;
        final isLogged = await _hasActiveSession();
        if (!context.mounted) return false;
        Navigator.of(context).pushNamedAndRemoveUntil(
          isLogged ? '/home' : '/auth',
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            //* Header
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CurvedHeader(
                title: 'Menú de Registro',
                height: 200,
                fontSize: 22,
              ),
            ),

            //* Botón back
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: IconButton(
                onPressed: () async => _smartBack(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            //* Contenido
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¿Qué deseas registrar?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elige una opción para continuar',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                      const SizedBox(height: 10),

                      Expanded(
                        child: ListView(
                          children: [
                            _ModernOptionCard(
                              icon: Icons.edit_document,
                              title: 'Registro Manual',
                              description:
                                  'Completa el formulario paso a paso para registrar tu incidencia.',
                              actionText: 'Continuar',
                              primaryColor: theme.primaryColor,
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/offlineForm/incidence',
                              ),
                            ),
                            const SizedBox(height: 20),
                            const _ModernOptionCard(
                              icon: Icons.mic_rounded,
                              title: 'Registro por Voz (Incidencia)',
                              description:
                                  'Graba tu incidencia usando comandos de voz.',
                              actionText: 'Grabar',
                              primaryColor: Color.fromARGB(255, 105, 28, 126),
                              onPressedRoute: '/offlineForm/incidence/voice',
                            ),
                            const SizedBox(height: 20),

                            ///* NUEVO ACCESO
                            const _ModernOptionCard(
                              icon: Icons.record_voice_over_rounded,
                              title: 'Registro de Ciudadano (Voz)',
                              description:
                                  'Crea un registro de ciudadano dictando sus datos (solo voz).',
                              actionText: 'Registrar ciudadano',
                              primaryColor: Color(0xFF0D9488), 
                              onPressedRoute: '/offlineForm/citizen',
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _ModernOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionText;
  final Color primaryColor;
  final VoidCallback? onPressed;
  final String? onPressedRoute;

  const _ModernOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionText,
    required this.primaryColor,
    this.onPressed,
    this.onPressedRoute,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = onPressed ??
        () {
          if (onPressedRoute != null) {
            Navigator.pushNamed(context, onPressedRoute!);
          }
        };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: primaryColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: effectiveOnPressed,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(actionText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
