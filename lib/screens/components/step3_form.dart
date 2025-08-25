// lib/components/step3_form.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:app_atencion_ciudadana/data/menu_options.dart';

class Step3Form extends StatefulWidget {
  final String? tipoSolicitante;
  final ValueChanged<String?> onTipoSolicitanteChanged;
  final String? origen;
  final ValueChanged<String?> onOrigenChanged;
  final String? motivo;
  final ValueChanged<String?> onMotivoChanged;
  final String? secretaria;
  final ValueChanged<String?> onSecretariaChanged;
  final TextEditingController comentariosCtrl;
  final TextEditingController tipoIncidenciaCtrl;

  const Step3Form({
    super.key,
    required this.tipoSolicitante,
    required this.onTipoSolicitanteChanged,
    required this.origen,
    required this.onOrigenChanged,
    required this.motivo,
    required this.onMotivoChanged,
    required this.secretaria,
    required this.onSecretariaChanged,
    required this.comentariosCtrl,
    required this.tipoIncidenciaCtrl,
  });

  @override
  State<Step3Form> createState() => _Step3FormState();
}

class _Step3FormState extends State<Step3Form> {
  bool _showSecretariaSearch = false;
  late TextEditingController _secretariaSearchCtrl;
  List<String> _filteredSecretarias = [];
  final FocusNode _descripcionFocus = FocusNode();
  final FocusNode _tipoIncidenciaFocus = FocusNode();
  final ScrollController _secretariaScrollController =
      ScrollController(); //* Inicializado directamente

  //* Colores personalizados
  static const Color primaryColor = Color(0xFF6D1F70);

  @override
  void initState() {
    super.initState();
    _secretariaSearchCtrl = TextEditingController();
    _secretariaSearchCtrl.addListener(_filterSecretarias);
    _filteredSecretarias = MenuOptions.secretarias;

    _descripcionFocus.addListener(() => setState(() {}));
    _tipoIncidenciaFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _secretariaSearchCtrl.dispose();
    _descripcionFocus.dispose();
    _tipoIncidenciaFocus.dispose();
    _secretariaScrollController.dispose();
    super.dispose();
  }

  void _filterSecretarias() {
    final query = _secretariaSearchCtrl.text.toLowerCase();
    setState(() {
      _filteredSecretarias =
          MenuOptions.secretarias
              .where((secretaria) => secretaria.toLowerCase().contains(query))
              .toList();
    });
  }

  void _handleChipSelection(String value) {
    widget.tipoIncidenciaCtrl.text = value;
    setState(() {});
  }

  void _handleSecretariaSelection(String secretaria) {
    widget.onSecretariaChanged(secretaria);
    _secretariaSearchCtrl.clear();
    setState(() => _showSecretariaSearch = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final bgColor = isDark ? Colors.grey[850]! : Colors.grey[50]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            icon: Icons.description_outlined,
            title: 'Descripción del problema',
            isRequired: true,
            cardColor: cardColor,
            titleSize: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Describe detalladamente el problema que deseas reportar',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: widget.comentariosCtrl,
                    focusNode: _descripcionFocus,
                    decoration: InputDecoration(
                      hintText: 'Ej: Hay una fuga de agua en la esquina de...',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: bgColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: primaryColor,
                          width: 2.0,
                        ),
                      ),
                      suffixIcon: Icon(
                        Icons.edit_note,
                        color:
                            _descripcionFocus.hasFocus
                                ? primaryColor
                                : Colors.grey[500],
                      ),
                    ),
                    maxLines: 5,
                    minLines: 3,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionCard(
            icon: Icons.list_alt,
            title: 'Tipo de Incidencia',
            isRequired: true,
            cardColor: cardColor,
            titleSize: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona o describe el tipo de problema',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: widget.tipoIncidenciaCtrl,
                    focusNode: _tipoIncidenciaFocus,
                    decoration: InputDecoration(
                      hintText: 'Ej: Fuga de agua, Bache, Alumbrado...',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color:
                            _tipoIncidenciaFocus.hasFocus
                                ? primaryColor
                                : Colors.grey[500],
                      ),
                      filled: true,
                      fillColor: bgColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: primaryColor,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChip('Fuga de agua', Icons.water_drop),
                    _buildChip('Bache', Icons.remove_road),
                    _buildChip('Alumbrado', Icons.lightbulb_outline),
                    _buildChip('Basura', Icons.delete_outline),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionCard(
            icon: Icons.tune,
            title: 'Detalles adicionales',
            cardColor: cardColor,
            titleSize: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proporciona más información para procesar tu reporte',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildSecretariaField(bgColor, cardColor),

                const SizedBox(height: 16),
                _buildDropdownRow(
                  label: 'Tipo Solicitante',
                  value: widget.tipoSolicitante,
                  items: MenuOptions.tiposSolicitante,
                  onChanged: widget.onTipoSolicitanteChanged,
                  bgColor: bgColor,
                ),
                const SizedBox(height: 16),
                _buildDropdownRow(
                  label: 'Origen',
                  value: widget.origen,
                  items: MenuOptions.origenes,
                  onChanged: widget.onOrigenChanged,
                  bgColor: bgColor,
                ),
                const SizedBox(height: 16),
                _buildDropdownRow(
                  label: 'Motivo',
                  value: widget.motivo,
                  items: MenuOptions.motivos,
                  onChanged: widget.onMotivoChanged,
                  bgColor: bgColor,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: primaryColor),
      label: Text(label),
      backgroundColor: primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primaryColor.withOpacity(0.3)),
      ),
      onPressed: () => _handleChipSelection(label),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Color bgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryColor, width: 2.0),
                ),
                suffixIcon: const Icon(Icons.arrow_drop_down, size: 30),
              ),
              items:
                  items
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: onChanged,
              hint: Text(
                'Selecciona $label',
                style: TextStyle(color: Colors.grey[500]),
              ),
              icon: const SizedBox.shrink(),
              dropdownColor: bgColor,
              style: TextStyle(fontSize: 14, color: Colors.black87),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    required Color cardColor,
    bool isRequired = false,
    double titleSize = 18,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 28, color: primaryColor),
                ),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isRequired)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      ' *',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSecretariaField(Color bgColor, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Secretaría',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap:
              () => setState(
                () => _showSecretariaSearch = !_showSecretariaSearch,
              ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    _showSecretariaSearch
                        ? primaryColor
                        : (widget.secretaria == null
                            ? Colors.transparent
                            : primaryColor.withOpacity(0.3)),
                width: _showSecretariaSearch ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.business, color: primaryColor),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    widget.secretaria ?? 'Buscar secretaría...',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          widget.secretaria == null
                              ? Colors.grey[500]
                              : primaryColor,
                      fontWeight:
                          widget.secretaria == null
                              ? FontWeight.normal
                              : FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _showSecretariaSearch ? Icons.expand_less : Icons.expand_more,
                  color: primaryColor,
                  size: 28,
                ),
              ],
            ),
          ),
        ),

        if (_showSecretariaSearch) ...[
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: primaryColor.withOpacity(0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: primaryColor),
                          const SizedBox(width: 10),
                          const Text(
                            'Buscar secretaría',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: primaryColor),
                            onPressed:
                                () => setState(
                                  () => _showSecretariaSearch = false,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _secretariaSearchCtrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Buscar secretaría...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              _secretariaSearchCtrl.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _secretariaSearchCtrl.clear();
                                      _filterSecretarias();
                                    },
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: bgColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _secretariaScrollController,
                        thumbVisibility: true,
                        thickness: 6,
                        radius: const Radius.circular(3),
                        child: ListView.builder(
                          controller: _secretariaScrollController,
                          itemCount: _filteredSecretarias.length,
                          itemBuilder: (context, index) {
                            final secretaria = _filteredSecretarias[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap:
                                    () =>
                                        _handleSecretariaSelection(secretaria),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        widget.secretaria == secretaria
                                            ? primaryColor.withOpacity(0.1)
                                            : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          secretaria,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                widget.secretaria == secretaria
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                            color:
                                                widget.secretaria == secretaria
                                                    ? primaryColor
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color,
                                          ),
                                        ),
                                      ),
                                      if (widget.secretaria == secretaria)
                                        Icon(
                                          Icons.check_circle,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
