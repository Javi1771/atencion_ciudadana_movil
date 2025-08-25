// lib/components/step2_form.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:app_atencion_ciudadana/data/menu_options.dart';

class Step2Form extends StatefulWidget {
  final String? colonia;
  final ValueChanged<String?> onColoniaChanged;
  final TextEditingController direccionCtrl;

  const Step2Form({
    super.key,
    required this.colonia,
    required this.onColoniaChanged,
    required this.direccionCtrl,
  });

  @override
  State<Step2Form> createState() => _Step2FormState();
}

class _Step2FormState extends State<Step2Form> {
  List<String> filteredColonias = [];
  TextEditingController searchController = TextEditingController();
  bool _showDropdown = false;
  final FocusNode _descripcionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    filteredColonias = MenuOptions.colonias;
    searchController.addListener(_filterColonias);
    _descripcionFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    searchController.dispose();
    _descripcionFocus.dispose();
    super.dispose();
  }

  void _filterColonias() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredColonias =
          MenuOptions.colonias
              .where((colonia) => colonia.toLowerCase().contains(query))
              .toList();
    });
  }

  void _toggleDropdown() {
    setState(() {
      _showDropdown = !_showDropdown;
      if (!_showDropdown) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Colors.grey[850]! : Colors.grey[50]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //* Sección de colonia
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_city,
                      size: 24,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Colonia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      ' *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _toggleDropdown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            widget.colonia == null
                                ? Colors.grey[300]!
                                : theme.primaryColor.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.colonia ?? 'Selecciona una colonia',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  widget.colonia == null
                                      ? Colors.grey[500]
                                      : Colors.black,
                            ),
                          ),
                        ),
                        //* Botón para limpiar selección
                        if (widget.colonia != null)
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: () {
                              widget.onColoniaChanged(null);
                              searchController.clear();
                              _filterColonias();
                            },
                          ),
                        Icon(
                          _showDropdown
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        //* Dropdown de colonias (solo visible cuando se activa)
        if (_showDropdown) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 400),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de búsqueda
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar colonia...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  _filterColonias();
                                },
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),

                  //* Lista de colonias o mensaje de no resultados
                  if (filteredColonias.isNotEmpty)
                    Expanded(
                      child: Scrollbar(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredColonias.length,
                          itemBuilder: (context, index) {
                            final colonia = filteredColonias[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  widget.onColoniaChanged(colonia);
                                  searchController.clear();
                                  _toggleDropdown();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        widget.colonia == colonia
                                            ? theme.primaryColor.withOpacity(
                                              0.1,
                                            )
                                            : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          colonia,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                widget.colonia == colonia
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                            color:
                                                widget.colonia == colonia
                                                    ? theme.primaryColor
                                                    : Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                      if (widget.colonia == colonia)
                                        Icon(
                                          Icons.check_circle,
                                          color: theme.primaryColor,
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
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "No se encontraron colonias",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        //* Sección de dirección (sin cambios)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pin_drop, size: 24, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    const Text(
                      'Dirección completa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      ' *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: widget.direccionCtrl,
                    focusNode: _descripcionFocus,
                    decoration: InputDecoration(
                      hintText: 'Ej: Av de las Lomas #652...',
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
                        borderSide: BorderSide(
                          color: theme.primaryColor,
                          width: 2.0,
                        ),
                      ),
                      suffixIcon: Icon(
                        Icons.edit_note,
                        color:
                            _descripcionFocus.hasFocus
                                ? theme.primaryColor
                                : Colors.grey[500],
                      ),
                    ),
                    maxLines: 5,
                    minLines: 3,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  'Ej: Calle Principal #123, entre Calles Secundarias',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
