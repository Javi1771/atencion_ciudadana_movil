// lib/screens/incidence_form_screen.dart

// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:atencion_ciudadana/services/connectivity_service.dart';
import 'package:atencion_ciudadana/data/menu_options.dart';
import '/widgets/alert_helper.dart';

class IncidenceFormScreen extends StatefulWidget {
  const IncidenceFormScreen({super.key});
  @override
  State<IncidenceFormScreen> createState() => _IncidenceFormScreenState();
}

class _IncidenceFormScreenState extends State<IncidenceFormScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _curpCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _comentariosCtrl = TextEditingController();
  final _tipoIncidenciaCtrl = TextEditingController();

  // Variables de estado
  String? _colonia;
  String? _tipoSolicitante;
  String? _origen;
  String? _motivo;
  String? _secretaria;
  bool _isLoading = false;

  late Database _db;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initDb();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  Future<void> _initDb() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'incidencias.db');
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE incidencias(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              curp TEXT NOT NULL UNIQUE,
              colonia TEXT NOT NULL,
              direccion TEXT NOT NULL,
              comentarios TEXT NOT NULL,
              tipoSolicitante TEXT NOT NULL,
              origen TEXT NOT NULL,
              motivo TEXT NOT NULL,
              secretaria TEXT NOT NULL,
              tipoIncidencia TEXT NOT NULL,
              fechaCreacion TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');
          
          await db.execute('''
            CREATE INDEX idx_curp ON incidencias(curp)
          ''');
        },
      );
    } catch (e) {
      AlertHelper.showAlert(
        'Error al inicializar la base de datos: $e',
        type: AlertType.error,
      );
    }
  }

  Future<bool> _curpExists(String curp) async {
    try {
      final result = await _db.query(
        'incidencias',
        where: 'curp = ?',
        whereArgs: [curp.toUpperCase()],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error verificando CURP: $e');
      return false;
    }
  }

  String? _validateCurp(String? value) {
    if (value == null || value.isEmpty) {
      return 'El CURP es obligatorio';
    }
    
    final curpClean = value.trim().toUpperCase();
    
    if (curpClean.length != 18) {
      return 'El CURP debe tener exactamente 18 caracteres';
    }
    
    final curpRegex = RegExp(
      r'^[A-Z][AEIOUX][A-Z]{2}[0-9]{6}[HM][A-Z]{5}[A-Z0-9][0-9]$'
    );
    
    if (!curpRegex.hasMatch(curpClean)) {
      return 'Formato de CURP inválido';
    }
    
    final yearStr = curpClean.substring(4, 6);
    final year = int.tryParse(yearStr);
    if (year == null) {
      return 'Año inválido en CURP';
    }
    
    final currentYear = DateTime.now().year;
    final fullYear = year <= (currentYear - 2000) ? 2000 + year : 1900 + year;
    
    if (fullYear < 1900 || fullYear > currentYear) {
      return 'Año de nacimiento inválido';
    }
    
    final monthStr = curpClean.substring(6, 8);
    final month = int.tryParse(monthStr);
    if (month == null || month < 1 || month > 12) {
      return 'Mes inválido en CURP';
    }
    
    final dayStr = curpClean.substring(8, 10);
    final day = int.tryParse(dayStr);
    if (day == null || day < 1 || day > 31) {
      return 'Día inválido en CURP';
    }
    
    try {
      final birthDate = DateTime(fullYear, month, day);
      if (birthDate.isAfter(DateTime.now())) {
        return 'Fecha de nacimiento no puede ser futura';
      }
    } catch (e) {
      return 'Fecha de nacimiento inválida';
    }
    
    final gender = curpClean.substring(10, 11);
    if (gender != 'H' && gender != 'M') {
      return 'Género inválido en CURP (debe ser H o M)';
    }
    
    final stateCode = curpClean.substring(11, 13);
    final validStates = [
      'AS', 'BC', 'BS', 'CC', 'CL', 'CM', 'CS', 'CH', 'DF', 'DG',
      'GT', 'GR', 'HG', 'JC', 'MC', 'MN', 'MS', 'NT', 'NL', 'OC',
      'PL', 'QT', 'QR', 'SP', 'SL', 'SR', 'TC', 'TS', 'TL', 'VZ',
      'YN', 'ZS', 'NE'
    ];
    
    if (!validStates.contains(stateCode)) {
      return 'Código de estado inválido en CURP';
    }
    
    return null;
  }

  Future<String?> _validateCurpComplete(String? value) async {
    final formatError = _validateCurp(value);
    if (formatError != null) {
      return formatError;
    }
    
    final curpClean = value!.trim().toUpperCase();
    final exists = await _curpExists(curpClean);
    if (exists) {
      return 'Esta CURP ya está registrada en el sistema';
    }
    
    return null;
  }

  String? _validateDireccion(String? value) {
    if (value == null || value.isEmpty) {
      return 'La dirección es obligatoria';
    }
    if (value.trim().length < 10) {
      return 'La dirección debe tener al menos 10 caracteres';
    }
    return null;
  }

  String? _validateTipoIncidencia(String? value) {
    if (value == null || value.isEmpty) {
      return 'El tipo de incidencia es obligatorio';
    }
    if (value.trim().length < 5) {
      return 'Debe describir mejor el tipo de incidencia';
    }
    return null;
  }

  String? _validateComentarios(String? value) {
    if (value == null || value.isEmpty) {
      return 'Los comentarios son obligatorios';
    }
    if (value.trim().length < 10) {
      return 'Los comentarios deben tener al menos 10 caracteres';
    }
    return null;
  }

  Future<bool> _validateCurrentStep() async {
    switch (_currentStep) {
      case 0:
        final curpError = await _validateCurpComplete(_curpCtrl.text);
        return curpError == null;
      case 1:
        return _colonia != null && 
               _validateDireccion(_direccionCtrl.text) == null;
      case 2:
        return _tipoSolicitante != null &&
               _origen != null &&
               _motivo != null &&
               _secretaria != null &&
               _validateComentarios(_comentariosCtrl.text) == null &&
               _validateTipoIncidencia(_tipoIncidenciaCtrl.text) == null;
      default:
        return false;
    }
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      setState(() => _isLoading = true);
    }
    
    final isValid = await _validateCurrentStep();
    
    if (_currentStep == 0) {
      setState(() => _isLoading = false);
    }
    
    if (isValid) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        _submit();
      }
    } else {
      await _showValidationErrors();
    }
  }

  Future<void> _showValidationErrors() async {
    String message = '';
    switch (_currentStep) {
      case 0:
        message = await _validateCurpComplete(_curpCtrl.text) ?? '';
        break;
      case 1:
        if (_colonia == null) {
          message = 'Debe seleccionar una colonia';
        } else {
          message = _validateDireccion(_direccionCtrl.text) ?? '';
        }
        break;
      case 2:
        if (_tipoSolicitante == null) {
          message = 'Debe seleccionar el tipo de solicitante';
        } else if (_origen == null) {
          message = 'Debe seleccionar el origen';
        } else if (_motivo == null) {
          message = 'Debe seleccionar el motivo';
        } else if (_secretaria == null) {
          message = 'Debe seleccionar la secretaría';
        } else {
          message = _validateComentarios(_comentariosCtrl.text) ??
                   _validateTipoIncidencia(_tipoIncidenciaCtrl.text) ??
                   '';
        }
        break;
    }
    
    if (message.isNotEmpty) {
      AlertHelper.showAlert(message, type: AlertType.warning);
    }
  }

  void _submit() async {
    final isValid = await _validateCurrentStep();
    if (!isValid) {
      await _showValidationErrors();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final curpClean = _curpCtrl.text.trim().toUpperCase();
      
      final exists = await _curpExists(curpClean);
      if (exists) {
        AlertHelper.showAlert(
          'Esta CURP ya está registrada en el sistema',
          type: AlertType.warning,
        );
        setState(() => _isLoading = false);
        return;
      }

      final record = {
        'curp': curpClean,
        'colonia': _colonia!,
        'direccion': _direccionCtrl.text.trim(),
        'comentarios': _comentariosCtrl.text.trim(),
        'tipoSolicitante': _tipoSolicitante!,
        'origen': _origen!,
        'motivo': _motivo!,
        'secretaria': _secretaria!,
        'tipoIncidencia': _tipoIncidenciaCtrl.text.trim(),
        'fechaCreacion': DateTime.now().toIso8601String(),
      };

      await _db.insert(
        'incidencias', 
        record,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      
      AlertHelper.showAlert(
        'Incidencia registrada exitosamente',
        type: AlertType.success,
      );

      _resetForm();
    } catch (e) {
      String errorMessage = 'Error al guardar la incidencia';
      
      if (e.toString().contains('UNIQUE constraint failed')) {
        errorMessage = 'Esta CURP ya está registrada en el sistema';
      } else {
        errorMessage = 'Error al guardar: ${e.toString()}';
      }
      
      AlertHelper.showAlert(errorMessage, type: AlertType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _curpCtrl.clear();
      _direccionCtrl.clear();
      _comentariosCtrl.clear();
      _tipoIncidenciaCtrl.clear();
      _colonia = _tipoSolicitante = _origen = _motivo = _secretaria = null;
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = context.watch<ConnectivityService>().online;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Nueva Incidencia',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Indicador de conexión
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: online ? 0 : 48,
              color: Colors.orange[700],
              child: online
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Sin conexión - Los datos se guardarán localmente',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            
            // Indicador de progreso
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = index <= _currentStep;
                  final isCompleted = index < _currentStep;
                  
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? theme.primaryColor
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isActive 
                                ? theme.primaryColor
                                : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isActive ? Colors.white : Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // Contenido del formulario
            Expanded(
              child: Form(
                key: _formKey,
                child: Stepper(
                  currentStep: _currentStep,
                  onStepTapped: (step) {
                    if (step < _currentStep) {
                      setState(() => _currentStep = step);
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          if (details.stepIndex > 0)
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : () {
                                setState(() => _currentStep--);
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Anterior'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _nextStep,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      details.stepIndex < 2
                                          ? Icons.arrow_forward
                                          : Icons.save,
                                    ),
                              label: Text(
                                _isLoading
                                    ? 'Guardando...'
                                    : details.stepIndex < 2
                                        ? 'Continuar'
                                        : 'Guardar Incidencia',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep1() {
    return Step(
      title: const Text(
        'Datos del Solicitante',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person_outline,
                size: 32,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              const Text(
                'Ingresa tu CURP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _curpCtrl,
                decoration: InputDecoration(
                  labelText: 'CURP *',
                  hintText: 'Ej: ABCD123456HDFGHI09',
                  prefixIcon: const Icon(Icons.credit_card),
                  suffixIcon: _curpCtrl.text.isNotEmpty
                      ? (_validateCurp(_curpCtrl.text) == null
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.error, color: Colors.red))
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context as BuildContext).primaryColor,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  helperText: 'Formato: 4 letras + 6 números + H/M + 5 letras + 2 dígitos',
                  helperMaxLines: 2,
                ),
                maxLength: 18,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return newValue.copyWith(
                      text: newValue.text.toUpperCase(),
                    );
                  }),
                ],
                validator: (value) => _validateCurp(value),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
      isActive: _currentStep >= 0,
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text(
        'Ubicación',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 32,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              const Text(
                'Especifica la ubicación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _colonia,
                decoration: InputDecoration(
                  labelText: 'Colonia *',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context as BuildContext).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                items: MenuOptions.colonias
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _colonia = v),
                validator: (value) => value == null ? 'Selecciona una colonia' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionCtrl,
                decoration: InputDecoration(
                  labelText: 'Dirección completa *',
                  hintText: 'Calle, número, referencias...',
                  prefixIcon: const Icon(Icons.home_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context as BuildContext).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 2,
                validator: _validateDireccion,
              ),
            ],
          ),
        ),
      ),
      isActive: _currentStep >= 1,
    );
  }

  Step _buildStep3() {
    return Step(
      title: const Text(
        'Detalles de la Incidencia',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.report_problem_outlined,
                size: 32,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              const Text(
                'Describe la incidencia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              // Comentarios
              TextFormField(
                controller: _comentariosCtrl,
                decoration: InputDecoration(
                  labelText: 'Descripción del problema *',
                  hintText: 'Explica detalladamente el problema...',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context as BuildContext).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 4,
                validator: _validateComentarios,
              ),
              const SizedBox(height: 16),

              // Tipo de Incidencia
              TextFormField(
                controller: _tipoIncidenciaCtrl,
                decoration: InputDecoration(
                  labelText: 'Tipo de Incidencia *',
                  hintText: 'Ej: Fuga de agua, Bache, Alumbrado...',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context as BuildContext).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                validator: _validateTipoIncidencia,
              ),
              const SizedBox(height: 16),

              // Dropdowns en grid 2x2
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _tipoSolicitante,
                      decoration: InputDecoration(
                        labelText: 'Tipo Solicitante *',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: MenuOptions.tiposSolicitante
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _tipoSolicitante = v),
                      validator: (value) => value == null ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _origen,
                      decoration: InputDecoration(
                        labelText: 'Origen *',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: MenuOptions.origenes
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _origen = v),
                      validator: (value) => value == null ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _motivo,
                      decoration: InputDecoration(
                        labelText: 'Motivo *',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: MenuOptions.motivos
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _motivo = v),
                      validator: (value) => value == null ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _secretaria,
                      decoration: InputDecoration(
                        labelText: 'Secretaría *',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: MenuOptions.secretarias
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _secretaria = v),
                      validator: (value) => value == null ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isActive: _currentStep >= 2,
    );
  }

  @override
  void dispose() {
    _curpCtrl.dispose();
    _direccionCtrl.dispose();
    _comentariosCtrl.dispose();
    _tipoIncidenciaCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }
}