// lib/screens/citizen_review_screen.dart
// ignore_for_file: avoid_print, deprecated_member_use

import 'package:app_atencion_ciudadana/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:app_atencion_ciudadana/services/local_db.dart';
import 'package:app_atencion_ciudadana/widgets/alert_helper.dart';
import 'package:app_atencion_ciudadana/data/citizen_questions.dart';
import '../components/CurvedHeader.dart';

class CitizenReviewScreen extends StatefulWidget {
  final Map<String, dynamic> formData;
  final VoidCallback onReturnToVoice;

  const CitizenReviewScreen({
    super.key,
    required this.formData,
    required this.onReturnToVoice,
  });

  @override
  State<CitizenReviewScreen> createState() => _CitizenReviewScreenState();
}

class _CitizenReviewScreenState extends State<CitizenReviewScreen> {
  final FlutterTts _tts = FlutterTts();
  final Map<String, TextEditingController> _reviewControllers = {};
  bool _isSaving = false;

  ///* Control de visibilidad de contraseña
  final Map<String, bool> _passwordVisibility = {
    'password': false,
  };

  //* Colores
  static const Color primaryGreen = Color(0xFF0D9488);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color lightGreen = Color(0xFFECFDF5);

  //* Campos válidos (los únicos que mostraremos/guardaremos)
  late final Set<String> _allowedFields;

  //* Lista ordenada de campos a mostrar
  late final List<String> _visibleFields;

  @override
  void initState() {
    super.initState();
    _allowedFields = CitizenQuestions.getFieldLabels().keys.toSet();

    //* filtra llaves raras como "__skipped__" u otras
    _visibleFields = widget.formData.keys
        .where((k) => _allowedFields.contains(k))
        .toList(growable: false);

    _initializeTts();
    _initializeControllers();

    //* Mensaje inicial
    Future.delayed(const Duration(milliseconds: 500), () {
      _speak(
        'Ha terminado su registro. Ahora puede revisar y editar su información antes de crear su cuenta.',
      );
    });
  }

  void _initializeTts() async {
    await _tts.setLanguage("es_MX");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  ///* Mapea valores omitidos/extraños a "OMITIDO" sólo para mostrar
  String _valueForDisplay(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return 'OMITIDO';
    final upper = s.toUpperCase();

    //* marcadores comunes de omitido o payload raro
    if (upper == 'OMITIR' ||
        s.contains('__skipped__') ||
        s.startsWith('{') && s.endsWith('}')) {
      return 'OMITIDO';
    }
    return s;
  }

  void _initializeControllers() {
    for (final field in _visibleFields) {
      final showValue = _valueForDisplay(widget.formData[field]);
      _reviewControllers[field] = TextEditingController(text: showValue);

      if (field == 'password' && !_passwordVisibility.containsKey(field)) {
        _passwordVisibility[field] = false;
      }
    }
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _tts.speak(text);
    }
  }

  Future<void> _saveCitizen() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      //? 1) Tomar datos editados en Review, filtrando omitidos y llaves no permitidas
      final Map<String, dynamic> updatedFormData = {};
      for (final field in _visibleFields) {
        final controller = _reviewControllers[field];
        if (controller == null) continue;

        final value = controller.text.trim();

        //! Si en pantalla sigue "OMITIDO" o está vacío -> NO guardar ese campo
        if (value.isEmpty || value.toUpperCase() == 'OMITIDO') {
          continue;
        }
        updatedFormData[field] = value;
      }

      //? 2) Preparar datos para BD (normalización mayúsculas, emails, números, etc.)
      final preparedData =
          CitizenQuestions.prepareDataForDatabase(updatedFormData);

      //? 3) Validar requeridos
      final validationError =
          CitizenQuestions.validateRequiredFields(preparedData);
      if (validationError != null) {
        await _speak(validationError);
        AlertHelper.showAlert(validationError, type: AlertType.error);
        return;
      }

      //? 4) Guardar en BD
      await CitizenLocalRepo.insert(preparedData);

      //? 5) Feedback
      await _speak(
        '¡Excelente! Su registro de ciudadano ha sido completado correctamente. Ya puede usar sus credenciales para acceder a la Clave Única.',
      );

      AlertHelper.showAlert(
        'Registro de ciudadano completado exitosamente.',
        type: AlertType.success,
      );

      //? 6) Limpiar
      for (final c in _reviewControllers.values) {
        c.clear();
      }

      //? 7) Ir a Home
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.offlineCitizen,
          (route) => false,
        );
      }
    } catch (e) {
      //? print('Error al guardar ciudadano: $e');
      await _speak(
        'Ha ocurrido un error al crear su registro. Por favor, intente nuevamente.',
      );
      AlertHelper.showAlert(
        'Error al crear el registro. Por favor, intente nuevamente.',
        type: AlertType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  //* Iconos
  final Map<String, IconData> _fieldIcons = const {
    'nombre': Icons.person,
    'primer_apellido': Icons.person_outline,
    'segundo_apellido': Icons.person_outline,
    'curp_ciudadano': Icons.badge,
    'fecha_nacimiento': Icons.calendar_today,
    'password': Icons.lock,
    'sexo': Icons.wc,
    'estado': Icons.location_on,
    'telefono': Icons.phone,
    'email': Icons.email,
    'asentamiento': Icons.home_work,
    'calle': Icons.home,
    'numero_exterior': Icons.numbers,
    'numero_interior': Icons.apartment,
    'codigo_postal': Icons.local_post_office,
  };

  IconData _getIconForField(String field) => _fieldIcons[field] ?? Icons.edit;

  bool _isPasswordField(String field) => field == 'password';

  @override
  Widget build(BuildContext context) {
    final fieldLabels = CitizenQuestions.getFieldLabels();

    return Scaffold(
      backgroundColor: lightGreen,
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final headerHeight = isSmallScreen ? 160.0 : 200.0;

          return Stack(
            children: [
              // Header curvo
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CurvedHeader(
                  title: 'Revisar Registro',
                  height: headerHeight,
                  fontSize: isSmallScreen ? 18 : 20,
                  textColor: lightGreen,
                ),
              ),

              // Back
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

              // Help
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
                        'Está en la pantalla de revisión de su registro. Puede editar cualquier campo y luego crear su cuenta de ciudadano o volver a grabar con el asistente de voz.',
                      );
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

                        //* Banner estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                primaryGreen.withOpacity(0.8),
                                accentGreen
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_add_alt_1,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Registro completado. Revise los datos antes de crear la cuenta.',
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

                        //* Título
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.edit_note,
                                  color: primaryGreen, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Revise y edite su información:',
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

                        //* Lista de campos
                        Expanded(
                          child: ListView.builder(
                            itemCount: _visibleFields.length,
                            itemBuilder: (context, index) {
                              final field = _visibleFields[index];
                              final isPassword = _isPasswordField(field);

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
                                          Icon(
                                            _getIconForField(field),
                                            size: 16,
                                            color: primaryGreen,
                                          ),
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
                                          if (field == 'password')
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(left: 8),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange[100],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Privado',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.orange[800],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    TextFormField(
                                      controller: _reviewControllers[field],
                                      obscureText: isPassword &&
                                          !(_passwordVisibility[field] ?? false),
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
                                            color: primaryGreen,
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
                                              primaryGreen.withOpacity(0.7),
                                          size: 20,
                                        ),
                                        //* Ojito para password, altavoz para otros
                                        suffixIcon: isPassword
                                            ? IconButton(
                                                icon: Icon(
                                                  (_passwordVisibility[field] ??
                                                          false)
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                  size: 20,
                                                  color: primaryGreen
                                                      .withOpacity(0.7),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _passwordVisibility[field] =
                                                        !(_passwordVisibility[
                                                                field] ??
                                                            false);
                                                  });
                                                },
                                              )
                                            : IconButton(
                                                icon: Icon(
                                                  Icons.volume_up_outlined,
                                                  color: primaryGreen
                                                      .withOpacity(0.7),
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  _speak(_reviewControllers[
                                                              field]!
                                                          .text
                                                          .trim()
                                                          .isEmpty
                                                      ? 'OMITIDO'
                                                      : _reviewControllers[field]!
                                                          .text);
                                                },
                                              ),
                                      ),
                                      style: TextStyle(
                                        fontSize:
                                            isSmallScreen ? 14 : 16,
                                        color: Colors.black87,
                                      ),
                                      textCapitalization:
                                          field == 'curp_ciudadano'
                                              ? TextCapitalization.characters
                                              : field == 'email'
                                                  ? TextCapitalization.none
                                                  : TextCapitalization.words,
                                      maxLines: field == 'asentamiento' ||
                                              field == 'calle'
                                          ? 2
                                          : 1,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        //* Botones
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                        Navigator.of(context).pop();
                                        widget.onReturnToVoice();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[700],
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.grey[400],
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  elevation: 3,
                                  shadowColor:
                                      Colors.grey.withOpacity(0.5),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.mic_none, size: 20),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Volver a Grabar',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
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
                                onPressed:
                                    _isSaving ? null : _saveCitizen,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      primaryGreen.withOpacity(0.6),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  shadowColor:
                                      primaryGreen.withOpacity(0.5),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    if (_isSaving)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    else
                                      const Icon(Icons.person_add, size: 20),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _isSaving
                                            ? 'Creando...'
                                            : 'Crear Cuenta',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
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

                        if (!_isSaving) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryGreen.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: primaryGreen, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Una vez creada su cuenta, podrá acceder con su CURP o nombre y la contraseña establecida.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryGreen.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
