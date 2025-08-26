// lib/screens/voice_review_screen.dart
// ignore_for_file: avoid_print, deprecated_member_use

import 'package:app_atencion_ciudadana/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:app_atencion_ciudadana/services/local_db.dart';
import 'package:app_atencion_ciudadana/widgets/alert_helper.dart';
import 'package:app_atencion_ciudadana/data/voice_questions.dart';
import '../components/CurvedHeader.dart';

class VoiceReviewScreen extends StatefulWidget {
  final Map<String, dynamic> formData;
  final VoidCallback onReturnToVoice;

  const VoiceReviewScreen({
    super.key,
    required this.formData,
    required this.onReturnToVoice,
  });

  @override
  State<VoiceReviewScreen> createState() => _VoiceReviewScreenState();
}

class _VoiceReviewScreenState extends State<VoiceReviewScreen> {
  final FlutterTts _tts = FlutterTts();
  final Map<String, TextEditingController> _reviewControllers = {};
  static const Color primaryPurple = Color(0xFF6B46C1);
  static const Color accentColor = Color(0xFF8B5FEB);

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeControllers();

    //* Mensaje inicial
    Future.delayed(const Duration(milliseconds: 500), () {
      _speak(
        'Ha terminado la entrevista. Ahora puede revisar y editar sus respuestas antes de guardar.',
      );
    });
  }

  void _initializeTts() async {
    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true); //* espera a que termine de hablar
  }

  void _initializeControllers() {
    for (var field in widget.formData.keys) {
      _reviewControllers[field] = TextEditingController(
        text: widget.formData[field]?.toString() ?? '',
      );
    }
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _tts.speak(text);
      //* con awaitSpeakCompletion(true), esta línea esperará a que termine el TTS
    }
  }

  Future<void> _saveForm() async {
    try {
      //? 1) Tomar lo editado en la pantalla de review
      final Map<String, dynamic> updatedFormData = {};
      for (var field in _reviewControllers.keys) {
        updatedFormData[field] =
            _reviewControllers[field]!.text.toUpperCase().trim();
      }

      //? 2) Asegurar identificador mínimo (CURP o nombre)
      if ((updatedFormData['curp'] ?? '').toString().isEmpty) {
        updatedFormData['curp'] =
            (updatedFormData['nombre'] ?? 'SIN_IDENTIFICADOR')
                .toString()
                .toUpperCase()
                .trim();
      }
      if (updatedFormData['curp'] == updatedFormData['nombre']) {
        updatedFormData.remove('nombre');
      }

      //? 3) NO guardar fecha (si viniera en el mapa)
      updatedFormData.remove('fecha_registro');

      //? 4) Guardar en DB
      await IncidenceLocalRepo.save(updatedFormData);

      //? 5) Feedback por voz y visual
      await _speak(
          '¡Perfecto! Su incidencia ha sido registrada correctamente. Iniciaremos una nueva entrevista.');
      AlertHelper.showAlert(
        'Incidencia registrada correctamente.',
        type: AlertType.success,
      );

      //? 6) Limpiar los campos del review (opcional)
      for (final c in _reviewControllers.values) {
        c.text = '';
      }

      //? 7) Navegar a la pantalla de voz definida en rutas,
      //?    limpiando el stack para empezar de cero
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.offlineFormIncidenceVoice,
          (route) => false,
        );
      }
    } catch (e) {
      print('Error al guardar: $e');
      await _speak(
          'Ha ocurrido un error al guardar su incidencia. Por favor, intente nuevamente.');
      AlertHelper.showAlert(
        'Error al guardar la incidencia. Por favor, intente nuevamente.',
        type: AlertType.error,
      );
    }
  }

  //* Mapa de iconos (opcional)
  final Map<String, IconData> _fieldIcons = {
    'nombre': Icons.person,
    'curp': Icons.badge,
    'direccion': Icons.home,
    'telefono': Icons.phone,
    'comentarios': Icons.description,
    'email': Icons.email,
    'fecha_nacimiento': Icons.calendar_today,
  };

  IconData _getIconForField(String field) {
    return _fieldIcons[field] ?? Icons.edit;
  }

  @override
  Widget build(BuildContext context) {
    final fieldLabels = VoiceQuestions.getFieldLabels();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final headerHeight = isSmallScreen ? 160.0 : 200.0;

          return Stack(
            children: [
              //* Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CurvedHeader(
                  title: 'Revisar Información',
                  height: headerHeight,
                  fontSize: isSmallScreen ? 18 : 20,
                ),
              ),

              //* Back
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),

              //* Help
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      _speak(
                          'Está en la pantalla de revisión. Puede editar cualquier campo y luego guardar su incidencia o volver a grabar con el asistente de voz.');
                    },
                    icon: const Icon(Icons.help_outline_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),

              //* Contenido
              Positioned(
                top: headerHeight - 40,
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
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      children: [
                        SizedBox(height: isSmallScreen ? 16 : 20),

                        //* Banner de estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                primaryPurple.withOpacity(0.8),
                                accentColor
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryPurple.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Entrevista completada. Revise los datos antes de guardar.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        //* Título de sección
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.edit_note,
                                  color: primaryPurple, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Revise y edite la información:',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        //* Formulario de revisión
                        Expanded(
                          child: ListView(
                            children: widget.formData.keys.map((field) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0, bottom: 6),
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit,
                                              size: 16,
                                              color: primaryPurple),
                                          const SizedBox(width: 8),
                                          Text(
                                            fieldLabels[field] ?? field,
                                            style: TextStyle(
                                              fontSize:
                                                  isSmallScreen ? 12 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextFormField(
                                      controller: _reviewControllers[field],
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: primaryPurple,
                                            width: 2,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                        ),
                                        prefixIcon: Icon(
                                          _getIconForField(field),
                                          color:
                                              primaryPurple.withOpacity(0.7),
                                          size: 20,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            Icons.volume_up_outlined,
                                            color:
                                                primaryPurple.withOpacity(0.7),
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            _speak(
                                                _reviewControllers[field]!.text);
                                          },
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        color: Colors.black87,
                                      ),
                                      textCapitalization: field == 'curp'
                                          ? TextCapitalization.characters
                                          : TextCapitalization.words,
                                      maxLines: field == 'comentarios' ||
                                              field == 'direccion'
                                          ? 3
                                          : 1,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        //* Botones
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.onReturnToVoice();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 3,
                                  shadowColor:
                                      Colors.grey.withOpacity(0.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.mic_none, size: 20),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Volver a Grabar',
                                        style: TextStyle(
                                          fontSize:
                                              isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  shadowColor:
                                      primaryPurple.withOpacity(0.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.save_outlined, size: 20),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Guardar Incidencia',
                                        style: TextStyle(
                                          fontSize:
                                              isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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

  @override
  void dispose() {
    _tts.stop();
    for (var controller in _reviewControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
