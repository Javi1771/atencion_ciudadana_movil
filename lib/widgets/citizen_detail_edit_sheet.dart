// lib/widgets/citizen_detail_edit_sheet.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_atencion_ciudadana/controllers/citizen_home_controller.dart';

///* Formatter para forzar MAYÚSCULAS al teclear
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

///* Formulario unificado para editar ciudadanos
class CitizenDetailEditSheet extends StatefulWidget {
  final Map<String, dynamic> citizen;
  final Color primaryColor;
  final Color accentColor;
  final CitizenHomeController controller;

  const CitizenDetailEditSheet({
    super.key,
    required this.citizen,
    required this.primaryColor,
    required this.accentColor,
    required this.controller,
  });

  @override
  State<CitizenDetailEditSheet> createState() => _CitizenDetailEditSheetState();

  ///* Método estático para mostrar el componente
  static Future<String?> showSheet({
    required BuildContext context,
    required Map<String, dynamic> citizen,
    required Color primaryColor,
    required Color accentColor,
    required CitizenHomeController controller,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CitizenDetailEditSheet(
        citizen: citizen,
        primaryColor: primaryColor,
        accentColor: accentColor,
        controller: controller,
      ),
    );
  }
}

class _CitizenDetailEditSheetState extends State<CitizenDetailEditSheet> with SingleTickerProviderStateMixin {
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  //* Controllers para los campos de texto
  late final TextEditingController nameCtrl;
  late final TextEditingController pApeCtrl;
  late final TextEditingController sApeCtrl;  
  late final TextEditingController telCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController asentCtrl;
  late final TextEditingController calleCtrl;
  late final TextEditingController numExtCtrl;
  late final TextEditingController numIntCtrl;
  late final TextEditingController cpCtrl;
  late final TextEditingController curpCtrl;   
  late final TextEditingController fechaCtrl;
  late final TextEditingController estadoCtrl;
  late final TextEditingController sexoCtrl;

  final formKey = GlobalKey<FormState>();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _initializeControllers();
    _animationController.forward();
  }

  void _initializeControllers() {
    final c = widget.citizen;
    nameCtrl   = TextEditingController(text: (c['nombre']?.toString() ?? '').toUpperCase());
    pApeCtrl   = TextEditingController(text: (c['primer_apellido']?.toString() ?? '').toUpperCase());
    sApeCtrl   = TextEditingController(text: (c['segundo_apellido']?.toString() ?? '').toUpperCase());
    telCtrl    = TextEditingController(text: c['telefono']?.toString() ?? '');
    emailCtrl  = TextEditingController(text: c['email']?.toString() ?? '');
    asentCtrl  = TextEditingController(text: (c['asentamiento']?.toString() ?? '').toUpperCase());
    calleCtrl  = TextEditingController(text: (c['calle']?.toString() ?? '').toUpperCase());
    numExtCtrl = TextEditingController(text: (c['numero_exterior']?.toString() ?? '').toUpperCase());
    numIntCtrl = TextEditingController(text: (c['numero_interior']?.toString() ?? '').toUpperCase());
    cpCtrl     = TextEditingController(text: c['codigo_postal']?.toString() ?? '');
    curpCtrl   = TextEditingController(text: (c['curp_ciudadano']?.toString() ?? '').toUpperCase());
    fechaCtrl  = TextEditingController(text: c['fecha_nacimiento']?.toString() ?? '');
    estadoCtrl = TextEditingController(text: (c['estado']?.toString() ?? '').toUpperCase());
    sexoCtrl   = TextEditingController(text: (c['sexo']?.toString() ?? '').toUpperCase());
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameCtrl.dispose();
    pApeCtrl.dispose();
    sApeCtrl.dispose();
    telCtrl.dispose();
    emailCtrl.dispose();
    asentCtrl.dispose();
    calleCtrl.dispose();
    numExtCtrl.dispose();
    numIntCtrl.dispose();
    cpCtrl.dispose();
    curpCtrl.dispose();
    fechaCtrl.dispose();
    estadoCtrl.dispose();
    sexoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: Form(
                          key: formKey,
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            children: [
                              _buildSectionTitle('Información Personal', Icons.person),
                              _buildPersonalInfoSection(),
                              const SizedBox(height: 32),
                              _buildSectionTitle('Contacto', Icons.contact_phone),
                              _buildContactSection(),
                              const SizedBox(height: 32),
                              _buildSectionTitle('Ubicación', Icons.location_on),
                              _buildLocationSection(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                      _buildActionButtons(),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final status = widget.controller.getCitizenStatus(widget.citizen);
    final statusColor = widget.controller.getCitizenStatusColor(widget.citizen);
    final curp = widget.citizen['curp_ciudadano']?.toString() ?? '';
    final nombre = widget.citizen['nombre_completo']?.toString() ?? 'Sin nombre';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.primaryColor.withOpacity(0.08), 
            widget.accentColor.withOpacity(0.08)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.primaryColor, widget.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  curp.isNotEmpty && curp.length == 18
                      ? Icons.verified_user_rounded
                      : Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editar Ciudadano',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.primaryColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (curp.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                curp,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: widget.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryColor.withOpacity(0.3), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildEditField(
                controller: nameCtrl,
                label: 'Nombre',
                icon: Icons.person,
                required: true,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEditField(
                controller: pApeCtrl,
                label: 'Primer Apellido',
                icon: Icons.badge,
                required: true,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
            ),
          ],
        ),
        _buildEditField(
          controller: sApeCtrl,
          label: 'Segundo Apellido (Opcional)',
          icon: Icons.badge_outlined,
          inputFormatters: [UpperCaseTextFormatter()],
        ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildEditField(
                controller: curpCtrl,
                label: 'CURP (Opcional)',
                icon: Icons.verified_user,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                  LengthLimitingTextInputFormatter(18),
                ],
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  if (t.length != 18) return 'La CURP debe tener 18 caracteres';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEditField(
                controller: sexoCtrl,
                label: 'Sexo',
                icon: Icons.face_retouching_natural,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
            ),
          ],
        ),
        _buildEditField(
          controller: fechaCtrl,
          label: 'Fecha de Nacimiento (YYYY-MM-DD)',
          icon: Icons.cake,
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return null;
            final ok = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(t);
            if (!ok) return 'Formato esperado: YYYY-MM-DD';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        _buildEditField(
          controller: telCtrl,
          label: 'Teléfono',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            final t = (v ?? '').replaceAll(RegExp(r'\D'), '');
            if (t.isEmpty) return 'Ingrese un teléfono';
            if (t.length < 10 || t.length > 13) return 'Teléfono de 10 a 13 dígitos';
            return null;
          },
        ),
        _buildEditField(
          controller: emailCtrl,
          label: 'Correo Electrónico',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return null;
            if (!t.contains('@') || !t.contains('.')) return 'Correo inválido';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildEditField(
                controller: estadoCtrl,
                label: 'Estado',
                icon: Icons.flag,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEditField(
                controller: cpCtrl,
                label: 'Código Postal',
                icon: Icons.local_post_office,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5)
                ],
                validator: (v) {
                  final t = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (t.isEmpty) return 'Ingrese el código postal';
                  if (t.length != 5) return 'Debe tener 5 dígitos';
                  return null;
                },
              ),
            ),
          ],
        ),
        _buildEditField(
          controller: asentCtrl,
          label: 'Asentamiento',
          icon: Icons.location_on,
          inputFormatters: [UpperCaseTextFormatter()],
        ),
        _buildEditField(
          controller: calleCtrl,
          label: 'Calle',
          icon: Icons.signpost,
          inputFormatters: [UpperCaseTextFormatter()],
        ),
        Row(
          children: [
            Expanded(
              child: _buildEditField(
                controller: numExtCtrl,
                label: 'Número Exterior',
                icon: Icons.home,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEditField(
                controller: numIntCtrl,
                label: 'Núm. Interior (Opcional)',
                icon: Icons.home_work,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator ??
            (required
                ? (v) {
                    if ((v ?? '').trim().isEmpty) return 'Campo requerido';
                    return null;
                  }
                : null),
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: widget.primaryColor, size: 20),
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: widget.primaryColor, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              icon: Icon(Icons.close, color: widget.primaryColor),
              label: Text(
                'Cancelar',
                style: TextStyle(
                  color: widget.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: widget.primaryColor.withOpacity(0.5), width: 2.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : _saveChanges,
              icon: isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(
                isSaving ? 'Guardando...' : 'Guardar Cambios',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: widget.primaryColor.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!formKey.currentState!.validate()) return;
    
    setState(() => isSaving = true);

    final id = widget.citizen['id_ciudadano'] as int;
    final payload = <String, dynamic>{
      'nombre': nameCtrl.text.trim().toUpperCase(),
      'primer_apellido': pApeCtrl.text.trim().toUpperCase(),
      'segundo_apellido': sApeCtrl.text.trim().toUpperCase(), 
      'telefono': telCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'asentamiento': asentCtrl.text.trim().toUpperCase(),
      'calle': calleCtrl.text.trim().toUpperCase(),
      'numero_exterior': numExtCtrl.text.trim().toUpperCase(),
      'numero_interior': numIntCtrl.text.trim().toUpperCase(),
      'codigo_postal': cpCtrl.text.trim(),
      'curp_ciudadano': curpCtrl.text.trim().toUpperCase(), 
      'fecha_nacimiento': fechaCtrl.text.trim(),
      'estado': estadoCtrl.text.trim().toUpperCase(),
      'sexo': sexoCtrl.text.trim().toUpperCase(),
    };

    try {
      await widget.controller.updateCitizen(id, payload);
      if (mounted) {
        Navigator.pop(context, 'updated');
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error al actualizar: $e')),
              ],
            ),
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}