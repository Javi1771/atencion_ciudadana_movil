// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/services/auth_service.dart';
import '/utils/rfc_test_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '/widgets/alert_helper.dart';
import 'package:atencion_ciudadana/models/usuario_cus.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool obscureText = true;
  bool _isLoading = false;
  String? _loginError;

  // Nueva paleta de colores inspirada en Pinterest
  static const Color primaryColor = Color(0xFF71079C);
  static const Color backgroundLight = Color(0xFFF9F9F9);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF767676);

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _testRFCValidation();
      });
    }
  }

  void _testRFCValidation() {
    debugPrint('\n=== INICIO DE PRUEBAS DE VALIDACIÓN ===');

    // Prueba del RFC especial
    const specialRFC = 'ORG1213456789';
    final result = RFCTestHelper.analyzeRFC(specialRFC);
    debugPrint('RFC especial: $specialRFC');
    debugPrint('Válido: ${result['valid']}');
    debugPrint('Es excepción: ${result['isExcepcion']}');
    debugPrint('Tipo: ${result['type']}');

    // Ejecutar pruebas del helper
    RFCTestHelper.testRFCValidation();
  }

  String? _validateEmailCurpOrRfc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }

    final input = value.trim();
    final inputUpper = input.toUpperCase();

    if (kDebugMode) {
      debugPrint('\n🔍 Validando input: "$input" (${input.length} chars)');
    }

    // Validación de email
    if (input.contains('@')) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (emailRegex.hasMatch(input)) {
        if (kDebugMode) debugPrint('✅ Email válido detectado');
        return null;
      }
      return 'Formato de email incorrecto';
    }

    // Validación de CURP
    if (inputUpper.length == 18) {
      final curpRegex = RegExp(r'^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[A-Z0-9][0-9]$');
      if (curpRegex.hasMatch(inputUpper)) {
        if (kDebugMode) debugPrint('✅ CURP válido detectado');
        return null;
      }
      return 'Formato de CURP incorrecto';
    }

    // Validación especial para RFC de excepción (comparación exacta)
    if (inputUpper == 'ORG1213456789') {
      debugPrint('✅ RFC de excepción aceptado exactamente');
      return null;
    }

    // Validación estándar de RFC para otros casos
    if (inputUpper.length >= 9 && inputUpper.length <= 13) {
      final rfcAnalysis = RFCTestHelper.analyzeRFC(inputUpper);

      if (kDebugMode) {
        debugPrint('🔍 Análisis RFC:');
        debugPrint('- Válido: ${rfcAnalysis['valid']}');
        debugPrint('- Excepción: ${rfcAnalysis['isExcepcion']}');
        debugPrint('- Tipo: ${rfcAnalysis['type']}');
      }

      if (rfcAnalysis['valid'] == true) {
        if (kDebugMode) debugPrint('✅ RFC válido detectado');
        return null;
      }

      return 'Formato de RFC incorrecto\n'
          'Ejemplos válidos:\n'
          '- Persona Física: ABCD123456 o ABCD123456EFG\n'
          '- Persona Moral: ABC123456 o ABC123456789\n'
          '- Caso especial exacto: ORG1213456789';
    }

    if (kDebugMode) debugPrint('❌ Formato no reconocido');
    return 'Ingresa un correo, CURP (18 chars) o RFC (9-13 chars) válido';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    if (value.length < 3) {
      return 'La contraseña debe tener al menos 3 caracteres';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    final rawUser = userCtrl.text.trim();
    final user = rawUser.contains('@') ? rawUser : rawUser.toUpperCase();
    final pass = passCtrl.text;

    try {
      final authService = AuthService(user);
      final success = await authService.login(user, pass);
      if (!success) {
        _showError(_getSpecificErrorMessage(user));
        return;
      }

      // Obtener datos almacenados tras el login
      final userData = await authService.getUserData();
      if (userData == null) {
        _showError('Error al leer los datos de usuario. Intenta de nuevo.');
        return;
      }

      final usuario = UsuarioCUS.fromJson(userData);

      // 🚨 ALERTA: Usuario no admitido
      if (usuario.tipoPerfil != TipoPerfilCUS.trabajador) {
        // 1) Detenemos el loading
        if (mounted) setState(() => _isLoading = false);

        // 2) PostFrame para que ScaffoldMessenger tenga un contexto válido
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AlertHelper.showAlert(
            'Acceso restringido\n'
            'Tu cuenta no tiene permisos para acceder a esta aplicación. \n'
            'Solo personal autorizado puede ingresar.',
            type: AlertType.error,
            duration: const Duration(seconds: 5),
          );
        });
        return;
      }

      // ALERTA MEJORADA: Bienvenida personalizada
      AlertHelper.showAlert(
        '¡Bienvenido ${usuario.nombre.split(" ")[0]}!',
        type: AlertType.success,
        duration: const Duration(seconds: 3),
      );

      Future.delayed(const Duration(milliseconds: 1800), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } on SocketException {
      // ALERTA MEJORADA: Sin conexión
      AlertHelper.showAlert(
        '🔌 Sin conexión a internet\n'
        'Verifica tu conexión e intenta nuevamente',
        type: AlertType.warning,
      );
    } catch (e, st) {
      debugPrint('❌ Error en login: $e\n$st');

      // ALERTA MEJORADA: Error inesperado
      AlertHelper.showAlert(
        '⚠️ Error inesperado\n'
        'Por favor intenta nuevamente más tarde',
        type: AlertType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    setState(() {
      _loginError = message;
      _isLoading = false;
    });

    // ALERTA MEJORADA: Credenciales incorrectas
    AlertHelper.showAlert(
      '🔐 Credenciales incorrectas\n$message',
      type: AlertType.error,
    );
  }

  String _getSpecificErrorMessage(String user) {
    if (user.contains('@')) {
      return 'Verifica tu email y contraseña.';
    } else if (user.length == 18) {
      return 'Tu CURP o contraseña son incorrectos.';
    } else if (user == 'ORG1213456789') {
      return 'RFC o contraseña incorrectos.';
    } else if (user.length >= 9 && user.length <= 13) {
      return 'RFC o contraseña incorrectos.';
    } else {
      return 'Usuario o contraseña incorrectos.';
    }
  }

  Future<void> _launchPasswordRecovery() async {
    const urlString =
        'https://cus.sanjuandelrio.gob.mx/tramites-sjr/public/forgot-password.html';

    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // ALERTA MEJORADA: Error en enlace
      AlertHelper.showAlert(
        '❌ No se pudo abrir el enlace\n'
        'Verifica tu conexión a internet',
        type: AlertType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Stack(
        children: [
          // Fondo estilo Pinterest con mosaico de colores
          _buildPinterestBackground(),

          // Contenido principal
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80),

                // Logo y título
                _buildHeader(),

                const SizedBox(height: 40),

                // Formulario de login
                _buildLoginCard(),

                const SizedBox(height: 30),

                // Botón de sin conexión
                _buildOfflineButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinterestBackground() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      children: List.generate(40, (index) {
        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _getRandomColor(index),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }

  Color _getRandomColor(int index) {
    final colors = [
      primaryColor.withOpacity(0.1),
      primaryColor.withOpacity(0.15),
      primaryColor.withOpacity(0.2),
      Colors.grey[100]!,
      Colors.grey[200]!,
    ];
    return colors[index % colors.length];
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo Pinterest-style
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outlined, color: Colors.white, size: 36),
        ),

        const SizedBox(height: 20),

        const Text(
          'Bienvenido a Atención Ciudadana',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDark,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Registro y seguimiento de incidencias',
          style: TextStyle(fontSize: 16, color: textLight),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Campo de usuario
            _buildInputField(
              controller: userCtrl,
              label: 'Correo, CURP o RFC',
              hint: 'usuario@ejemplo.com / CURP / RFC',
              icon: Icons.person_outline,
              validator: _validateEmailCurpOrRfc,
            ),

            const SizedBox(height: 20),

            // Campo de contraseña
            _buildPasswordField(),

            const SizedBox(height: 10),

            // Enlace de recuperación de contraseña
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _launchPasswordRecovery,
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botón de inicio de sesión
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        )
                        : const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),

            // Mensaje de error mejorado
            if (_loginError != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _loginError!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: textDark,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: textLight),
            prefixIcon: Icon(icon, color: primaryColor),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contraseña',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textDark,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: passCtrl,
          obscureText: obscureText,
          style: const TextStyle(color: textDark),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: textLight),
            prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: textLight,
              ),
              onPressed: () => setState(() => obscureText = !obscureText),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: _validatePassword,
        ),
      ],
    );
  }

  Widget _buildOfflineButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 24),
          const Text(
            '¿Prefieres continuar sin iniciar sesión?',
            style: TextStyle(color: textLight, fontSize: 15),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/offlineForm'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white,
              ),
              child: Text(
                'Continuar sin conexión',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
