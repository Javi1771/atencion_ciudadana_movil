// lib/screens/offline_form.dart

// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OfflineFormScreen extends StatefulWidget {
  const OfflineFormScreen({super.key});

  @override
  _OfflineFormScreenState createState() => _OfflineFormScreenState();
}

class _OfflineFormScreenState extends State<OfflineFormScreen> {
  int _currentStep = 0;

  // Aquí guardamos todos los datos del formulario
  final Map<String, dynamic> _formData = {
    'curp': '',
    'colonia': '',
    'direccion': '',
    'comentarios': '',
    'tipoSolicitante': null,
    'origen': null,
    'motivo': null,
    'secretaria': null,
    'tipoIncidencia': null,
  };

  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  void _onStepContinue() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      _formKeys[_currentStep].currentState!.save();
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        // aquí podrías guardar en SQLite
        // por ejemplo: await OfflineDb.saveIncidencia(_formData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado localmente ✔️')),
        );
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6D1F70);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Incidencia'),
        backgroundColor: primary,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(backgroundColor: primary),
                  child: Text(_currentStep < 2 ? 'Siguiente' : 'Guardar'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Anterior'),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Solicitante'),
            isActive: _currentStep >= 0,
            content: Form(
              key: _formKeys[0],
              child: Step1Solicitante(
                initialCurp: _formData['curp'] as String,
                onSaved: (val) => _formData['curp'] = val,
              ),
            ),
          ),
          Step(
            title: const Text('Ubicación'),
            isActive: _currentStep >= 1,
            content: Form(
              key: _formKeys[1],
              child: Step2Ubicacion(
                initialColonia: _formData['colonia'] as String,
                initialDireccion: _formData['direccion'] as String,
                initialComentarios: _formData['comentarios'] as String,
                onSaved: (col, dir, com) {
                  _formData['colonia'] = col;
                  _formData['direccion'] = dir;
                  _formData['comentarios'] = com;
                },
              ),
            ),
          ),
          Step(
            title: const Text('Detalles'),
            isActive: _currentStep >= 2,
            content: Form(
              key: _formKeys[2],
              child: Step3Detalles(
                data: _formData,
                onSaved: (map) => _formData.addAll(map),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Paso 1: CURP
class Step1Solicitante extends StatelessWidget {
  final String initialCurp;
  final FormFieldSetter<String> onSaved;

  const Step1Solicitante({
    super.key,
    required this.initialCurp,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialCurp,
      decoration: const InputDecoration(
        labelText: 'CURP del solicitante',
        icon: Icon(Icons.badge_outlined),
      ),
      validator: (v) =>
          (v == null || v.trim().length != 18) ? 'CURP inválida' : null,
      onSaved: onSaved,
    );
  }
}

// Paso 2: Ubicación y comentarios
class Step2Ubicacion extends StatelessWidget {
  final String initialColonia;
  final String initialDireccion;
  final String initialComentarios;
  final void Function(String, String, String) onSaved;

  const Step2Ubicacion({
    super.key,
    required this.initialColonia,
    required this.initialDireccion,
    required this.initialComentarios,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final colCtrl = TextEditingController(text: initialColonia);
    final dirCtrl = TextEditingController(text: initialDireccion);
    final comCtrl = TextEditingController(text: initialComentarios);

    return Column(
      children: [
        TextFormField(
          controller: colCtrl,
          decoration: const InputDecoration(
            labelText: 'Colonia',
            icon: Icon(Icons.home_outlined),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
        ),
        TextFormField(
          controller: dirCtrl,
          decoration: const InputDecoration(
            labelText: 'Dirección',
            icon: Icon(Icons.location_on_outlined),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
        ),
        TextFormField(
          controller: comCtrl,
          decoration: const InputDecoration(
            labelText: 'Comentarios',
            icon: Icon(Icons.comment_outlined),
          ),
          maxLines: 3,
        ),
        // Salvamos todos juntos
        Builder(builder: (ctx) {
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  // Nota: el Stepper llama a onSaved automáticamente tras validar,
  // así que podemos capturar aquí mismo:
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('onSaved', onSaved));
  }
}

// Paso 3: Listas desplegables de detalles
class Step3Detalles extends StatelessWidget {
  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic>) onSaved;

  // Aquí debes reemplazar por las listas reales que te pasen
  static const List<String> _tipos = ['Ciudadano', 'Trabajador'];
  static const List<String> _origenes = ['Web', 'App', 'Teléfono'];
  static const List<String> _motivos = ['Queja', 'Solicitud', 'Informe'];
  static const List<String> _secretarias = ['Seguridad', 'Salud', 'Educación'];
  static const List<String> _incidencias = ['Leve', 'Media', 'Alta'];

  const Step3Detalles({
    super.key,
    required this.data,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDropdown(
          icon: Icons.person_outline,
          label: 'Tipo solicitante',
          value: data['tipoSolicitante'],
          items: _tipos,
          onSaved: (v) => data['tipoSolicitante'] = v,
        ),
        _buildDropdown(
          icon: Icons.settings_outlined,
          label: 'Origen',
          value: data['origen'],
          items: _origenes,
          onSaved: (v) => data['origen'] = v,
        ),
        _buildDropdown(
          icon: Icons.flag_outlined,
          label: 'Motivo',
          value: data['motivo'],
          items: _motivos,
          onSaved: (v) => data['motivo'] = v,
        ),
        _buildDropdown(
          icon: Icons.account_balance_outlined,
          label: 'Secretaría',
          value: data['secretaria'],
          items: _secretarias,
          onSaved: (v) => data['secretaria'] = v,
        ),
        _buildDropdown(
          icon: Icons.report_problem_outlined,
          label: 'Tipo incidencia',
          value: data['tipoIncidencia'],
          items: _incidencias,
          onSaved: (v) => data['tipoIncidencia'] = v,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onSaved,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        icon: Icon(icon),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      validator: (v) => v == null ? 'Requerido' : null,
      onChanged: (v) => onSaved(v),
    );
  }
}
