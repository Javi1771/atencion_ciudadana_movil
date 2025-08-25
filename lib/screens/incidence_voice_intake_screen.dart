// lib/screens/voice_incidence_screen.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:app_atencion_ciudadana/controllers/voice_incidence_controller.dart';
import '../components/CurvedHeader.dart';

class VoiceIncidenceScreen extends StatefulWidget {
  const VoiceIncidenceScreen({super.key});

  @override
  State<VoiceIncidenceScreen> createState() => _VoiceIncidenceScreenState();
}

class _VoiceIncidenceScreenState extends State<VoiceIncidenceScreen>
    with TickerProviderStateMixin {
  late VoiceIncidenceController _controller;

  // Colores
  static const Color primaryPurple = Color(0xFF6B46C1);
  static const Color darkPurple = Color(0xFF553C9A);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color backgroundGradient1 = Color(0xFFF8FAFF);

  // Animaciones
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = VoiceIncidenceController();
    _initializeAnimations();

    // Pasar controladores de animación al controlador
    _controller.setAnimationControllers(
      pulseController: _pulseController,
      waveController: _waveController,
      slideController: _slideController,
      fadeController: _fadeController,
    );

    // Inicializar lógica voz/tts
    _controller.initialize();

    // Escuchar cambios
    _controller.addListener(() {
      if (!mounted) return;
      setState(() {});
      if (_controller.isInterviewComplete()) {
        _controller.navigateToReview(context);
      }
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _waveAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
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
              // Banner Curvo
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CurvedHeader(
                  title: 'Asistente de Voz',
                  height: headerHeight,
                  fontSize: isSmallScreen ? 18 : 20,
                ),
              ),

              // Botones sobre el banner
              _buildHeaderButtons(),

              // Contenedor principal
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
                        _buildEnhancedProgressSection(),
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        Expanded(child: _buildEnhancedChatSection()),
                        _buildEnhancedControlsSection(),
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

  // === Header buttons ===
  Widget _buildHeaderButtons() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/offlineForm'),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(6),
            ),
          ),
          // Help
          IconButton(
            onPressed: () {
              _controller.speak(
                "Estás en el asistente de voz para reportar incidencias. Si conoces tu CURP, dímela; si no, la puedes omitir y usaremos tu nombre para identificarte. Responde a las preguntas que te haré para completar tu reporte.",
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

  // === Barra de progreso ===
  Widget _buildEnhancedProgressSection() {
    final totalValidQuestions = _controller.getTotalValidQuestions();
    final currentValidIndex = _controller.getCurrentValidQuestionIndex();
    final progress = _controller.getProgress();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                    child: Icon(Icons.quiz_rounded,
                        color: primaryPurple, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pregunta $currentValidIndex de $totalValidQuestions',
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
                          color: primaryPurple.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryPurple,
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
                  gradient:
                      const LinearGradient(colors: [primaryPurple, accentPurple]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === Zona del mic y textos ===
  Widget _buildEnhancedChatSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final microphoneSize = isSmallScreen ? 100.0 : 120.0;
        final iconSize = isSmallScreen ? 40.0 : 48.0;

        final hasQuestion = _controller.questions.isNotEmpty &&
            _controller.currentQuestion < _controller.questions.length;

        final questionText =
            hasQuestion ? _controller.questions[_controller.currentQuestion]['question'] : '';

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
              // Mic animado
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
                                    painter: EnhancedSoundWavePainter(
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
                                    ? primaryPurple.withOpacity(0.04)
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
                                      ? const [primaryPurple, accentPurple]
                                      : _controller.isSpeaking
                                          ? [Colors.blue[400]!, Colors.blue[600]!]
                                          : [Colors.grey[300]!, Colors.grey[400]!],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_controller.isListening
                                                ? primaryPurple
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

              // Pregunta + transcripción
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
                                color: primaryPurple.withOpacity(0.05),
                                border: Border.all(
                                  color: primaryPurple.withOpacity(0.1),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 16, color: primaryPurple),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '"${_controller.transcribedText}"',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: darkPurple,
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

  // === Controles ===
  Widget _buildEnhancedControlsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;

        final mainButton = !_controller.isListening && !_controller.isSpeaking
            ? _buildActionButton(
                icon: Icons.mic,
                label: 'Responder',
                onPressed: _controller.startListening,
                backgroundColor: primaryPurple,
              )
            : _controller.isListening
                ? _buildActionButton(
                    icon: Icons.stop,
                    label: 'Parar',
                    onPressed: _controller.stopListening,
                    backgroundColor: Colors.red,
                  )
                : const SizedBox.shrink();

        return Column(
          children: [
            if (_controller.isListening)
              Container(
                margin: EdgeInsets.only(bottom: isSmall ? 12 : 16),
                child: LinearProgressIndicator(
                  backgroundColor: primaryPurple.withOpacity(0.15),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(primaryPurple),
                  minHeight: 3,
                ),
              ),
            isSmall
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: _buildActionButton(
                          icon: Icons.replay,
                          label: 'Repetir Pregunta',
                          onPressed: _controller.repeatQuestion,
                          backgroundColor: Colors.grey[600]!,
                          isSecondary: true,
                          isFullWidth: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: mainButton),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.replay,
                        label: 'Repetir',
                        onPressed: _controller.repeatQuestion,
                        backgroundColor: Colors.grey[600]!,
                        isSecondary: true,
                      ),
                      mainButton,
                    ],
                  ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    bool isSecondary = false,
    bool isFullWidth = false,
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
        minimumSize: isFullWidth ? const Size(double.infinity, 46) : null,
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

/// Painter de ondas (estado escuchando)
class EnhancedSoundWavePainter extends CustomPainter {
  final double value;
  EnhancedSoundWavePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final radius = (size.width * 0.2) + (i * 18) * (0.6 + value);
      final opacity =
          (0.3 - (i * 0.1)) * (1.0 - (value * 0.7)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = const Color(0xFF6B46C1).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant EnhancedSoundWavePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}