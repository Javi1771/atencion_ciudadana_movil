// lib/screens/citizen_voice_registration_screen.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:app_atencion_ciudadana/controllers/citizen_voice_controller.dart';
import '../components/CurvedHeader.dart';

class CitizenVoiceRegistrationScreen extends StatefulWidget {
  const CitizenVoiceRegistrationScreen({super.key});

  @override
  State<CitizenVoiceRegistrationScreen> createState() => _CitizenVoiceRegistrationScreenState();
}

class _CitizenVoiceRegistrationScreenState extends State<CitizenVoiceRegistrationScreen>
    with TickerProviderStateMixin {
  late CitizenVoiceController _controller;

  //? Colores
  static const Color primaryGreen = Color(0xFF0D9488);
  static const Color darkGreen = Color(0xFF047857);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color backgroundGradient1 = Color(0xFFF0FDF4);

  //? Animaciones
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late final VoidCallback _controllerListener;
  bool _navigatedToReview = false;

  @override
  void initState() {
    super.initState();
    _controller = CitizenVoiceController();
    _initializeAnimations();

    _controller.setAnimationControllers(
      pulseController: _pulseController,
      waveController: _waveController,
      slideController: _slideController,
      fadeController: _fadeController,
    );

    _controller.initialize();

    _controllerListener = () {
      if (!mounted) return;

      if (_controller.isRegistrationComplete() && !_navigatedToReview) {
        _navigatedToReview = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _controller.navigateToReview(context);
        });
      } else {
        setState(() {});
      }
    };

    _controller.addListener(_controllerListener);
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
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

          return WillPopScope(
            onWillPop: () async {
              await _controller.silence();
              return true;
            },
            child: Stack(
              children: [
                //* Banner Curvo
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CurvedHeader(
                    title: 'Registro Ciudadano',
                    height: headerHeight,
                    fontSize: isSmallScreen ? 18 : 20,
                  ),
                ),

                //* Botones sobre el banner
                _buildHeaderButtons(),

                //* Contenedor principal
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
                        horizontal: isSmallScreen ? 16 : 20,
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          _buildProgressSection(),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          Expanded(child: _buildChatSection()),
                          _buildControlsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  //? === Header buttons ===
  Widget _buildHeaderButtons() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //* Back
          IconButton(
            onPressed: () async {
              await _controller.silence(); //* calla antes de salir
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/offlineForm');
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(6),
            ),
          ),
          IconButton(
            onPressed: () {
              _controller.speak(
                "Estás en el registro de ciudadanos por voz. Te haré preguntas para crear tu perfil. Responde claramente a cada pregunta. Si no conoces algún dato, puedes decir 'omitir' en las preguntas opcionales.",
              );
            },
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 22),
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

  //? === Barra de progreso ===
  Widget _buildProgressSection() {
    final totalValidQuestions = _controller.getTotalValidQuestions();
    final currentValidIndex = _controller.getCurrentValidQuestionIndex();
    final progress = _controller.getProgress();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.1), width: 1),
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
                      color: primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      color: primaryGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campo $currentValidIndex de $totalValidQuestions',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _controller.getFieldDescription(),
                        style: TextStyle(
                          fontSize: 11,
                          color: primaryGreen.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryGreen, accentGreen],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //? === Zona del mic y textos ===
  Widget _buildChatSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final microphoneSize = isSmallScreen ? 100.0 : 120.0;
        final iconSize = isSmallScreen ? 40.0 : 48.0;

        final hasQuestion =
            _controller.questions.isNotEmpty &&
            _controller.currentQuestion < _controller.questions.length;

        final questionText = hasQuestion
            ? _controller.questions[_controller.currentQuestion]['question']
            : '';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              //* Mic animado
              Expanded(
                flex: isSmallScreen ? 3 : 2,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _controller.isListening
                            ? _pulseAnimation.value
                            : 1.0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_controller.isListening)
                              AnimatedBuilder(
                                animation: _waveAnimation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: Size(
                                      isSmallScreen ? 180 : 200,
                                      isSmallScreen ? 180 : 200,
                                    ),
                                    painter: RegistrationSoundWavePainter(
                                      _waveAnimation.value,
                                    ),
                                  );
                                },
                              ),
                            Container(
                              width: microphoneSize + 30,
                              height: microphoneSize + 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _controller.isListening
                                    ? primaryGreen.withOpacity(0.04)
                                    : _controller.isSpeaking
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
                                  colors: _controller.isListening
                                      ? const [primaryGreen, accentGreen]
                                      : _controller.isSpeaking
                                      ? [Colors.blue, Colors.blueAccent]
                                      : [Colors.grey, Colors.grey],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (_controller.isListening
                                                ? primaryGreen
                                                : Colors.grey)
                                            .withOpacity(0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _controller.isListening
                                    ? Icons.mic_rounded
                                    : _controller.isSpeaking
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

              //* Pregunta + transcripción
              Expanded(
                flex: isSmallScreen ? 2 : 1,
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
                        if (hasQuestion)
                          SlideTransition(
                            position: _slideAnimation,
                            child: Text(
                              questionText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                                height: 1.4,
                              ),
                            ),
                          ),
                        if (_controller.transcribedText.isNotEmpty) ...[
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: primaryGreen.withOpacity(0.05),
                                border: Border.all(
                                  color: primaryGreen.withOpacity(0.1),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 16,
                                    color: primaryGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '"${_controller.transcribedText}"',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: darkGreen,
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
      },
    );
  }

  //? === Controles ===
  Widget _buildControlsSection() {
    final isSmall = MediaQuery.of(context).size.width < 600;

    final Widget repeatBtn = _buildActionButton(
      icon: Icons.replay,
      label: 'Repetir',
      onPressed: _controller.repeatQuestion,
      backgroundColor: Colors.grey[600]!,
      isSecondary: true,
    );

    final bool listening = _controller.isListening;
    final Widget rightBtn = listening
        ? _buildActionButton(
            icon: Icons.stop,
            label: 'Parar',
            onPressed: _controller.stopListening,
            backgroundColor: Color.fromARGB(255, 6, 118, 109),
          )
        : _buildActionButton(
            icon: Icons.mic,
            label: 'Responder',
            onPressed: _controller.startListening,
            backgroundColor: primaryGreen,
          );

    return Column(
      children: [
        if (listening)
          Container(
            margin: EdgeInsets.only(bottom: isSmall ? 12 : 16),
            child: LinearProgressIndicator(
              backgroundColor: primaryGreen.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    bool isSecondary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isSecondary ? 18 : 20),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isSecondary ? 13 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: isSecondary ? 1 : 2,
        padding: EdgeInsets.symmetric(
          horizontal: isSecondary ? 14 : 20,
          vertical: isSecondary ? 10 : 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSecondary ? 10 : 14),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_controllerListener);
    _controller.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

///* Painter de ondas para registro
class RegistrationSoundWavePainter extends CustomPainter {
  final double value;
  RegistrationSoundWavePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final radius = (size.width * 0.2) + (i * 18) * (0.6 + value);
      final opacity = (0.3 - (i * 0.1)) * (1.0 - (value * 0.7)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = const Color(0xFF059669).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RegistrationSoundWavePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}