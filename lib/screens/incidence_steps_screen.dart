// lib/screens/incidence_steps_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:app_atencion_ciudadana/services/local_db.dart';
import 'package:app_atencion_ciudadana/widgets/alert_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_atencion_ciudadana/services/connectivity_service.dart';
import './components/step2_form.dart';
import './components/step3_form.dart';

// 👇 Para validar que los argumentos de voz existan en los catálogos de dropdowns
import 'package:app_atencion_ciudadana/data/menu_options.dart';

class IncidenceStepsScreen extends StatefulWidget {
  const IncidenceStepsScreen({super.key});
  @override
  State<IncidenceStepsScreen> createState() => _IncidenceStepsScreenState();
}

class _IncidenceStepsScreenState extends State<IncidenceStepsScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;

  //* Controladores
  final _curpCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _comentariosCtrl = TextEditingController();
  final _tipoIncidenciaCtrl = TextEditingController();

  //* Variables de estado
  String? _colonia;
  String? _tipoSolicitante;
  String? _origen;
  String? _motivo;
  String? _secretaria;
  bool _isLoading = false;

  //* Animaciones
  late AnimationController _animationController;
  late AnimationController _stepAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  //* Prefill sólo una vez (si viene de flujo por voz)
  bool _prefilledFromArgs = false;

  @override
  void initState() {
    super.initState();
    //? ↓ Aquí empieza la inicialización de animaciones ↓

    //? 1) Init Controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _stepAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    //? 2) Init Tweens/Animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _stepAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _stepAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    //? 3) Arranca las animaciones
    _animationController.forward();
    _stepAnimationController.forward();
    _pulseController.repeat(reverse: true);

    //? ↑ Aquí termina la inicialización de animaciones ↑
  }

  /// Prefill desde arguments (por ejemplo, si vienes del intake por voz).
  /// Acepta claves en snake_case o camelCase.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilledFromArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      String? arg(List<String> keys) {
        for (final k in keys) {
          final v = args[k];
          if (v is String && v.trim().isNotEmpty) return v;
        }
        return null;
      }

      // Helper: sólo aceptar valores de dropdown que EXISTAN en sus catálogos
      String? accept(List<String> options, String? v) {
        if (v == null) return null;
        final i = options.indexWhere((o) => o.toLowerCase() == v.toLowerCase());
        return i >= 0 ? options[i] : null;
      }

      _curpCtrl.text = arg(['curp']) ?? '';
      _colonia = arg(['colonia']);
      _direccionCtrl.text = arg(['direccion']) ?? '';
      _comentariosCtrl.text = arg(['comentarios']) ?? '';
      _tipoIncidenciaCtrl.text = arg(['tipo_incidencia', 'tipoIncidencia']) ?? '';

      _tipoSolicitante = accept(
        MenuOptions.tiposSolicitante,
        arg(['tipo_solicitante', 'tipoSolicitante']),
      );
      _origen = accept(MenuOptions.origenes, arg(['origen']));
      _motivo = accept(MenuOptions.motivos, arg(['motivo']));
      _secretaria = accept(MenuOptions.secretarias, arg(['secretaria']));

      _prefilledFromArgs = true;
      setState(() {});
    }
  }

  String? _validateCurp(String? value) {
    if (value == null || value.isEmpty) return 'El CURP es obligatorio';
    final curpClean = value.trim().toUpperCase();

    if (curpClean.length != 18) return 'El CURP debe tener 18 caracteres';

    final curpRegex = RegExp(
      r'^[A-Z][AEIOUX][A-Z]{2}[0-9]{6}[HM][A-Z]{5}[A-Z0-9][0-9]$',
    );

    if (!curpRegex.hasMatch(curpClean)) return 'Formato de CURP inválido';

    return null;
  }

  Future<bool> _validateCurrentStep() async {
    switch (_currentStep) {
      case 0:
        return true; // CURP opcional en este paso (se advierte si viene vacío)
      case 1:
        return _colonia != null && _direccionCtrl.text.trim().isNotEmpty;
      case 2:
        return _tipoSolicitante != null &&
            _origen != null &&
            _motivo != null &&
            _secretaria != null &&
            _comentariosCtrl.text.trim().isNotEmpty &&
            _tipoIncidenciaCtrl.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _nextStep() async {
    if (await _validateCurrentStep()) {
      if (_currentStep == 0 && _curpCtrl.text.trim().isEmpty) {
        AlertHelper.showAlert(
          'No ingresaste CURP. Este registro no podrá subirse al sistema real sin CURP.',
          type: AlertType.warning,
        );
      }

      if (_currentStep < 2) {
        _stepAnimationController.reset();
        setState(() => _currentStep++);
        _stepAnimationController.forward();
      } else {
        _submit();
      }
    } else {
      _showValidationErrors();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _stepAnimationController.reset();
      setState(() => _currentStep--);
      _stepAnimationController.forward();
    }
  }

  void _showValidationErrors() {
    String message;
    AlertType type = AlertType.warning;

    switch (_currentStep) {
      case 0:
        message = '';
        break;
      case 1:
        message = _colonia == null
            ? 'Por favor seleccione una colonia'
            : 'Complete la dirección correctamente';
        break;
      case 2:
        message = _tipoSolicitante == null
            ? 'Seleccione el tipo de solicitante'
            : _origen == null
                ? 'Seleccione el origen'
                : _motivo == null
                    ? 'Seleccione el motivo'
                    : _secretaria == null
                        ? 'Seleccione la secretaría'
                        : _comentariosCtrl.text.isEmpty
                            ? 'Agregue una descripción detallada'
                            : 'Especifique el tipo de incidencia';
        break;
      default:
        message = 'Error desconocido';
    }

    if (message.isNotEmpty) {
      AlertHelper.showAlert(message, type: type);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final data = {
      'curp': _curpCtrl.text.trim(),
      'colonia': _colonia,
      'direccion': _direccionCtrl.text.trim(),
      'comentarios': _comentariosCtrl.text.trim(),
      'tipo_solicitante': _tipoSolicitante,
      'origen': _origen,
      'motivo': _motivo,
      'secretaria': _secretaria,
      'tipo_incidencia': _tipoIncidenciaCtrl.text.trim(),
    };

    await IncidenceLocalRepo.save(data);

    final prefs = await SharedPreferences.getInstance();
    final showSyncAlert = prefs.getBool('show_sync_alert') ?? true;
    if (showSyncAlert) {
      AlertHelper.showAlert(
        'Incidencia guardada localmente. Se sincronizará cuando haya conexión.',
        type: AlertType.warning,
      );
      await prefs.setBool('show_sync_alert', false);
    }

    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    AlertHelper.showAlert(
      '¡Incidencia registrada correctamente!',
      type: AlertType.success,
    );
    _resetForm();
  }

  void _resetForm() {
    setState(() {
      _curpCtrl.clear();
      _direccionCtrl.clear();
      _comentariosCtrl.clear();
      _tipoIncidenciaCtrl.clear();
      _colonia = null;
      _tipoSolicitante = null;
      _origen = null;
      _motivo = null;
      _secretaria = null;
      _currentStep = 0;
    });
    _stepAnimationController.reset();
    _stepAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = context.watch<ConnectivityService>().online;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildConnectivityBanner(online),
            _buildModernProgressIndicator(theme),
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildFormContent(theme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text(
        'Nueva Incidencia',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      backgroundColor: theme.primaryColor,
      elevation: 4,
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor,
              theme.primaryColor.withOpacity(0.9),
              theme.primaryColor.withOpacity(0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white70),
          onPressed: () {
            AlertHelper.showAlert(
              'Complete todos los campos marcados con *',
              type: AlertType.warning,
            );
          },
        ),
      ],
    );
  }

  Widget _buildConnectivityBanner(bool online) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      height: online ? 0 : 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[600]!, Colors.orange[700]!],
        ),
        boxShadow: online
            ? []
            : [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: online
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Modo offline - Los datos se guardarán localmente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () {}, // opcional: ocultar banner con estado local
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildModernProgressIndicator(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: theme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Paso ${_currentStep + 1} de 3',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.primaryColor
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    if (index < 2) const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 32 : 28,
                      height: isCurrent ? 32 : 28,
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.primaryColor
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color:
                                      theme.primaryColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: isCurrent ? 14 : 12,
                          ),
                          child: Text('${index + 1}'),
                        ),
                      ),
                    ),
                    if (index < 2) const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _getStepTitle(),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Datos del solicitante';
      case 1:
        return 'Ubicación de la incidencia';
      case 2:
        return 'Detalles específicos';
      default:
        return '';
    }
  }

  Widget _buildFormContent(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor.withOpacity(0.1),
                      theme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: _buildStepHeader(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildCurrentStepContent(),
                        ),
                      ),
                      _buildNavigationControls(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    final steps = [
      {'title': 'Datos del Solicitante', 'icon': Icons.person_outline},
      {'title': 'Ubicación', 'icon': Icons.not_listed_location},
      {'title': 'Detalles de la Incidencia', 'icon': Icons.library_books},
    ];

    final currentStep = steps[_currentStep];

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            currentStep['icon'] as IconData,
            size: 28,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentStep['title'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Complete la información requerida',
                style:
                    TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Content();
      case 1:
        return _buildStep2Content();
      case 2:
        return _buildStep3Content();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Para continuar, necesitamos verificar la identidad del ciudadano con su CURP',
          style: TextStyle(fontSize: 16, height: 1.4, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _curpCtrl,
          decoration: InputDecoration(
            labelText: 'CURP *',
            labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            floatingLabelStyle: const TextStyle(
              color: Color(0xFF6D1F70),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            hintText: 'Ej: ABCD123456HDFGHI09',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon:
                const Icon(Icons.credit_card, color: Color(0xFF6D1F70)),
            suffixIcon: _curpCtrl.text.isNotEmpty
                ? (_validateCurp(_curpCtrl.text) == null
                    ? const Icon(Icons.check_circle,
                        color: Color.fromARGB(255, 13, 151, 17))
                    : const Icon(Icons.error,
                        color: Color.fromARGB(255, 157, 16, 6)))
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFF6D1F70), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
          maxLength: 18,
          textCapitalization: TextCapitalization.characters,
          validator: _validateCurp,
          onChanged: (value) => setState(() {}),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStep2Content() {
    return Step2Form(
      colonia: _colonia,
      onColoniaChanged: (value) => setState(() => _colonia = value),
      direccionCtrl: _direccionCtrl,
    );
  }

  Widget _buildStep3Content() {
    return Step3Form(
      tipoSolicitante: _tipoSolicitante,
      onTipoSolicitanteChanged: (value) => setState(() => _tipoSolicitante = value),
      origen: _origen,
      onOrigenChanged: (value) => setState(() => _origen = value),
      motivo: _motivo,
      onMotivoChanged: (value) => setState(() => _motivo = value),
      secretaria: _secretaria,
      onSecretariaChanged: (value) => setState(() => _secretaria = value),
      comentariosCtrl: _comentariosCtrl,
      tipoIncidenciaCtrl: _tipoIncidenciaCtrl,
    );
  }

  Widget _buildNavigationControls(ThemeData theme) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _previousStep,
              icon:
                  const Icon(Icons.arrow_back, color: Color(0xFF6D1F70)),
              label: const Text('Anterior',
                  style: TextStyle(color: Color(0xFF6D1F70))),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _currentStep == 2 && !_isLoading
                    ? _pulseAnimation.value
                    : 1.0,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _nextStep,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(_currentStep < 2
                          ? Icons.arrow_forward
                          : Icons.save),
                  label: Text(
                    _isLoading
                        ? 'Guardando...'
                        : _currentStep < 2
                            ? 'Continuar'
                            : 'Guardar',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _currentStep == 2 ? 4 : 2,
                    shadowColor: theme.primaryColor.withOpacity(0.4),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _curpCtrl.dispose();
    _direccionCtrl.dispose();
    _comentariosCtrl.dispose();
    _tipoIncidenciaCtrl.dispose();
    _animationController.dispose();
    _stepAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
