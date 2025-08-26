// lib/screens/citizen_voice_screen.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/CurvedHeader.dart';

class CitizenVoiceScreen extends StatefulWidget {
  const CitizenVoiceScreen({super.key});

  @override
  State<CitizenVoiceScreen> createState() => _CitizenVoiceScreenState();
}

class _CitizenVoiceScreenState extends State<CitizenVoiceScreen>
    with TickerProviderStateMixin {
  // Colores
  static const Color primaryPurple = Color(0xFF6B46C1);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color background = Color(0xFFF8FAFF);

  // Animaciones (ya listas para conectar al controlador)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Estado mínimo para que compile sin lógica de voz todavía
  bool _isListening = false;
  final bool _isSpeaking = false;
  final String _questionText = 'Diga el CURP del ciudadano o diga “OMITIR”.';
  String _transcribedText = '';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Aquí, en el siguiente paso, conectaremos CitizenVoiceController.initialize()
  }

  void _initAnimations() {
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _waveAnimation =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _slideController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideController.forward();
  }

  Future<bool> _hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ??
        prefs.getString('access_token') ??
        prefs.getString('token');
    final logged = prefs.getBool('logged_in') ?? false;
    return (token != null && token.isNotEmpty) || logged;
  }

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
    return Scaffold(
      backgroundColor: background,
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;
          final headerHeight = isSmall ? 160.0 : 180.0;
          final contentTop = headerHeight - 40;

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: const CurvedHeader(
                  title: 'Registro de Ciudadano (Voz)',
                  height: 180,
                  fontSize: 20,
                ),
              ),
              // back
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: IconButton(
                  onPressed: () => _smartBack(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ),

              // contenido
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 16 : 20,
                      vertical: isSmall ? 12 : 16,
                    ),
                    child: Column(
                      children: [
                        // “barra de progreso” básica — luego se conectará al controlador
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryPurple.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Pregunta 1', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('0%', style: TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // mic + pregunta + transcripción (mismo layout que incidencias)
                        Expanded(child: _micCard(isSmall)),
                        _controlsRow(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _micCard(bool isSmall) {
    final microphoneSize = isSmall ? 100.0 : 120.0;
    final iconSize = isSmall ? 40.0 : 48.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: isSmall ? 3 : 2,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isListening)
                          AnimatedBuilder(
                            animation: _waveAnimation,
                            builder: (_, __) {
                              return CustomPaint(
                                size: Size(isSmall ? 180 : 200, isSmall ? 180 : 200),
                                painter: _SoundWavePainter(_waveAnimation.value),
                              );
                            },
                          ),
                        Container(
                          width: microphoneSize + 30,
                          height: microphoneSize + 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? primaryPurple.withOpacity(0.04)
                                : _isSpeaking
                                    ? Colors.blue.withOpacity(0.04)
                                    : Colors.grey.withOpacity(0.04),
                          ),
                        ),
                        Container(
                          width: microphoneSize,
                          height: microphoneSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isListening
                                  ? const [primaryPurple, accentPurple]
                                  : _isSpeaking
                                      ? [Colors.blue, Colors.blueAccent]
                                      : [Colors.grey, Colors.grey],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isListening
                                ? Icons.mic_rounded
                                : _isSpeaking
                                    ? Icons.volume_up_rounded
                                    : Icons.mic_none_rounded,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: isSmall ? 2 : 1,
            child: Container(
              padding: EdgeInsets.all(isSmall ? 16 : 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SlideTransition(
                      position: _slideAnimation,
                      child: Text(
                        _questionText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmall ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (_transcribedText.isNotEmpty) ...[
                      SizedBox(height: isSmall ? 12 : 16),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isSmall ? 12 : 16),
                          decoration: BoxDecoration(
                            color: primaryPurple.withOpacity(0.05),
                            border: Border.all(color: primaryPurple.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.chat_bubble_outline, size: 16, color: primaryPurple),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '"$_transcribedText"',
                                  style: TextStyle(
                                    fontSize: isSmall ? 12 : 14,
                                    color: const Color(0xFF553C9A),
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlsRow() {
    final isSmall = MediaQuery.of(context).size.width < 600;

    final repeatBtn = _actionBtn(
      icon: Icons.replay,
      label: 'Repetir',
      backgroundColor: Colors.grey[600]!,
      onPressed: () {
        // TODO: conectar con TTS (repetir pregunta)
      },
      secondary: true,
    );

    final rightBtn = _isListening
        ? _actionBtn(
            icon: Icons.stop,
            label: 'Parar',
            backgroundColor: const Color.fromARGB(255, 105, 28, 126),
            onPressed: () {
              setState(() => _isListening = false);
              // TODO: stop STT y procesar respuesta
            },
          )
        : _actionBtn(
            icon: Icons.mic,
            label: 'Responder',
            backgroundColor: primaryPurple,
            onPressed: () {
              setState(() {
                _isListening = true;
                _transcribedText = '...'; // demo
              });
              _pulseController.repeat(reverse: true);
              _waveController.repeat();
              _fadeController.forward();
              // TODO: start STT real
            },
          );

    return Column(
      children: [
        if (_isListening)
          Container(
            margin: EdgeInsets.only(bottom: isSmall ? 12 : 16),
            child: LinearProgressIndicator(
              backgroundColor: primaryPurple.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryPurple),
              minHeight: 3,
            ),
          ),
        Row(
          children: [
            Expanded(child: repeatBtn),
            const SizedBox(width: 12),
            Expanded(child: rightBtn),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
    bool secondary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: secondary ? 18 : 20),
      label: Text(
        label,
        style: TextStyle(fontSize: secondary ? 13 : 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: secondary ? 1 : 2,
        padding: EdgeInsets.symmetric(
          horizontal: secondary ? 14 : 20,
          vertical: secondary ? 10 : 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

class _SoundWavePainter extends CustomPainter {
  final double value;
  _SoundWavePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 3; i++) {
      final radius = (size.width * 0.2) + (i * 18) * (0.6 + value);
      final opacity = (0.3 - (i * 0.1)) * (1.0 - (value * 0.7)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = const Color(0xFF6B46C1).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoundWavePainter oldDelegate) =>
      oldDelegate.value != value;
}
