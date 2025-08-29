// lib/widgets/upload_result_dialog.dart
// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UploadResultDialog {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> result,
    required Color primaryColor,
    required VoidCallback onConfirm,
  }) {
    //* Entrada "cruda" con validación mejorada
    final bool apiSuccess = (result['success'] as bool?) ?? false;
    final String message = (result['message'] as String?)?.trim() ?? '';
    final Map<String, dynamic> details =
        (result['details'] as Map?)?.cast<String, dynamic>() ?? {};
    final Map<String, dynamic> meta =
        (result['meta'] as Map?)?.cast<String, dynamic>() ?? {};

    //* Listas con mejor manejo de nulos
    final List<String> skips = _safeStringList(details['skips']);
    final List<String> errores = _safeStringList(details['errores']);
    final List<String> duplicates = _safeStringList(meta['duplicates']);
    final List<String> trabajadores = _safeStringList(meta['trabajadores']);

    //* Métricas con mejor validación
    final int inserted = _safeInt(meta['inserted'] ?? meta['creados'] ?? meta['ok']);
    final int updated = _safeInt(meta['updated']);
    final int totalMeta = _safeInt(meta['total']);
    final bool hasTotal = totalMeta > 0;

    //* Lógica mejorada para determinar el estado
    final ResultState resultState = _determineResultState(
      apiSuccess: apiSuccess,
      errores: errores,
      trabajadores: trabajadores,
      duplicates: duplicates,
      inserted: inserted,
      updated: updated,
    );

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (context) => _UploadResultDialogContent(
        resultState: resultState,
        message: message,
        inserted: inserted,
        updated: updated,
        totalMeta: totalMeta,
        hasTotal: hasTotal,
        errores: errores,
        duplicates: duplicates,
        trabajadores: trabajadores,
        skips: skips,
        primaryColor: primaryColor,
        onConfirm: onConfirm,
      ),
    );
  }

  //* Helpers mejorados
  static List<String> _safeStringList(dynamic list) {
    return (list as List?)?.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList() ?? const [];
  }

  static int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static ResultState _determineResultState({
    required bool apiSuccess,
    required List<String> errores,
    required List<String> trabajadores,
    required List<String> duplicates,
    required int inserted,
    required int updated,
  }) {
    //! Error crítico
    if (errores.isNotEmpty) {
      return ResultState.error;
    }

    //* Éxito total
    if (apiSuccess && (inserted > 0 || updated > 0)) {
      return ResultState.success;
    }

    //! Solo duplicados (tratamos como información)
    if (!apiSuccess && errores.isEmpty && trabajadores.isEmpty && 
        duplicates.isNotEmpty && inserted == 0 && updated == 0) {
      return ResultState.duplicatesOnly;
    }

    //! Advertencias o casos mixtos
    if (trabajadores.isNotEmpty || duplicates.isNotEmpty) {
      return inserted > 0 || updated > 0 ? ResultState.partialSuccess : ResultState.warning;
    }

    return apiSuccess ? ResultState.success : ResultState.warning;
  }

  static String _maskCurp(String curp) {
    final c = curp.trim();
    if (c.length < 8) return c;
    if (c.length <= 10) {
      return '${c.substring(0, 2)}***${c.substring(c.length - 2)}';
    }
    return '${c.substring(0, 4)}****${c.substring(c.length - 4)}';
  }
}

enum ResultState {
  success,
  partialSuccess,
  warning,
  error,
  duplicatesOnly,
}

extension ResultStateExtension on ResultState {
  Color get primaryColor {
    switch (this) {
      case ResultState.success:
      case ResultState.duplicatesOnly:
        return Colors.green.shade500;
      case ResultState.partialSuccess:
        return Colors.blue.shade500;
      case ResultState.warning:
        return Colors.orange.shade500;
      case ResultState.error:
        return Colors.red.shade500;
    }
  }

  Color get secondaryColor {
    switch (this) {
      case ResultState.success:
      case ResultState.duplicatesOnly:
        return Colors.green.shade700;
      case ResultState.partialSuccess:
        return Colors.blue.shade700;
      case ResultState.warning:
        return Colors.orange.shade700;
      case ResultState.error:
        return Colors.red.shade700;
    }
  }

  IconData get icon {
    switch (this) {
      case ResultState.success:
        return Icons.check_circle_rounded;
      case ResultState.partialSuccess:
        return Icons.check_circle_outline_rounded;
      case ResultState.warning:
        return Icons.warning_rounded;
      case ResultState.error:
        return Icons.error_rounded;
      case ResultState.duplicatesOnly:
        return Icons.info_rounded;
    }
  }

  String get title {
    switch (this) {
      case ResultState.success:
        return 'Proceso completado exitosamente';
      case ResultState.partialSuccess:
        return 'Proceso completado parcialmente';
      case ResultState.warning:
        return 'Proceso completado con observaciones';
      case ResultState.error:
        return 'Error en el procesamiento';
      case ResultState.duplicatesOnly:
        return 'Registros ya existían';
    }
  }

  bool get isSuccess => this == ResultState.success || this == ResultState.partialSuccess || this == ResultState.duplicatesOnly;
}

class _UploadResultDialogContent extends StatelessWidget {
  const _UploadResultDialogContent({
    required this.resultState,
    required this.message,
    required this.inserted,
    required this.updated,
    required this.totalMeta,
    required this.hasTotal,
    required this.errores,
    required this.duplicates,
    required this.trabajadores,
    required this.skips,
    required this.primaryColor,
    required this.onConfirm,
  });

  final ResultState resultState;
  final String message;
  final int inserted;
  final int updated;
  final int totalMeta;
  final bool hasTotal;
  final List<String> errores;
  final List<String> duplicates;
  final List<String> trabajadores;
  final List<String> skips;
  final Color primaryColor;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            //* Backdrop blur mejorado
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(
                    resultState: resultState,
                    subtitle: _buildSubtitle(),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.isNotEmpty)
                            _MainMessage(
                              message: message,
                              resultState: resultState,
                            ),
                          if (message.isNotEmpty) const SizedBox(height: 16),
                          
                          if (_hasMetrics())
                            _MetricsCard(
                              inserted: inserted,
                              updated: updated,
                              total: hasTotal ? totalMeta : null,
                              errores: errores.length,
                              duplicates: duplicates.length,
                              trabajadores: trabajadores.length,
                              skips: skips.length,
                              resultState: resultState,
                            ),
                          
                          if (_hasMetrics()) const SizedBox(height: 16),
                          
                          ..._buildDetailSections(context),
                        ],
                      ),
                    ),
                  ),
                  _Footer(
                    primaryColor: primaryColor,
                    resultState: resultState,
                    onConfirm: onConfirm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (hasTotal) parts.add('Total: $totalMeta');
    if (inserted > 0) parts.add('Nuevos: $inserted');
    if (updated > 0) parts.add('Actualizados: $updated');
    if (duplicates.isNotEmpty) parts.add('Duplicados: ${duplicates.length}');
    if (trabajadores.isNotEmpty) parts.add('Trabajadores: ${trabajadores.length}');
    if (errores.isNotEmpty) parts.add('Errores: ${errores.length}');
    if (skips.isNotEmpty) parts.add('Omitidos: ${skips.length}');
    
    return parts.isEmpty ? 'Proceso finalizado' : parts.join(' • ');
  }

  bool _hasMetrics() {
    return inserted > 0 || updated > 0 || (hasTotal && totalMeta > 0) ||
           errores.isNotEmpty || duplicates.isNotEmpty || 
           trabajadores.isNotEmpty || skips.isNotEmpty;
  }

  List<Widget> _buildDetailSections(BuildContext context) {
    final sections = <Widget>[];

    //! Errores primero (más crítico)
    if (errores.isNotEmpty) {
      sections.addAll([
        _DetailSection(
          title: 'Errores de procesamiento',
          items: errores,
          color: Colors.red,
          icon: Icons.error_outline_rounded,
          itemMapper: (s) => s,
          priority: 1,
        ),
        const SizedBox(height: 12),
      ]);
    }

    //! Trabajadores (importante)
    if (trabajadores.isNotEmpty) {
      sections.addAll([
        _DetailSection(
          title: 'CURP de trabajadores existentes',
          items: trabajadores,
          color: Colors.purple,
          icon: Icons.badge_rounded,
          itemMapper: UploadResultDialog._maskCurp,
          priority: 2,
        ),
        const SizedBox(height: 12),
      ]);
    }

    //! Duplicados
    if (duplicates.isNotEmpty) {
      sections.addAll([
        _DetailSection(
          title: 'Registros duplicados',
          items: duplicates,
          color: Colors.orange,
          icon: Icons.content_copy_rounded,
          itemMapper: UploadResultDialog._maskCurp,
          priority: 3,
        ),
        const SizedBox(height: 12),
      ]);
    }

    //* Omitidos (menos crítico)
    if (skips.isNotEmpty) {
      sections.addAll([
        _DetailSection(
          title: 'Registros omitidos',
          items: skips,
          color: Colors.blueGrey,
          icon: Icons.skip_next_rounded,
          itemMapper: (s) => s,
          priority: 4,
        ),
        const SizedBox(height: 8),
      ]);
    }

    return sections;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.resultState,
    required this.subtitle,
  });

  final ResultState resultState;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [resultState.primaryColor, resultState.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
            child: Icon(
              resultState.icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resultState.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MainMessage extends StatelessWidget {
  const _MainMessage({
    required this.message,
    required this.resultState,
  });

  final String message;
  final ResultState resultState;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: resultState.primaryColor.withOpacity(isDark ? 0.15 : 0.08),
        border: Border.all(
          color: resultState.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: resultState.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: resultState.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({
    required this.inserted,
    required this.updated,
    required this.total,
    required this.errores,
    required this.duplicates,
    required this.trabajadores,
    required this.skips,
    required this.resultState,
  });

  final int inserted;
  final int updated;
  final int? total;
  final int errores;
  final int duplicates;
  final int trabajadores;
  final int skips;
  final ResultState resultState;

  @override
  Widget build(BuildContext context) {
    final metrics = <_Metric>[];

    if (total != null && total! > 0) {
      metrics.add(_Metric('Total procesados', '$total', Icons.description_rounded, Colors.blueGrey));
    }
    if (inserted > 0) {
      metrics.add(_Metric('Nuevos registros', '$inserted', Icons.add_circle_rounded, Colors.green));
    }
    if (updated > 0) {
      metrics.add(_Metric('Actualizados', '$updated', Icons.update_rounded, Colors.blue));
    }
    if (duplicates > 0) {
      metrics.add(_Metric('Duplicados', '$duplicates', Icons.content_copy_rounded, Colors.orange));
    }
    if (trabajadores > 0) {
      metrics.add(_Metric('Trabajadores', '$trabajadores', Icons.badge_rounded, Colors.purple));
    }
    if (errores > 0) {
      metrics.add(_Metric('Errores', '$errores', Icons.error_outline_rounded, Colors.red));
    }
    if (skips > 0) {
      metrics.add(_Metric('Omitidos', '$skips', Icons.skip_next_rounded, Colors.blueGrey));
    }

    if (metrics.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen del proceso',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics.map((metric) => _MetricChip(metric: metric)).toList(),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.color);
  
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.metric});
  
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: metric.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: metric.color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            metric.icon,
            size: 18,
            color: metric.color,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                metric.value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: metric.color,
                ),
              ),
              Text(
                metric.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: metric.color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatefulWidget {
  const _DetailSection({
    required this.title,
    required this.items,
    required this.color,
    required this.icon,
    required this.itemMapper,
    required this.priority,
  });

  final String title;
  final List<String> items;
  final Color color;
  final IconData icon;
  final String Function(String) itemMapper;
  final int priority;

  @override
  State<_DetailSection> createState() => _DetailSectionState();
}

class _DetailSectionState extends State<_DetailSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewItems = widget.items.take(3).toList();
    final hasMore = widget.items.length > 3;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.color.withOpacity(0.2),
          width: 1.5,
        ),
        color: widget.color.withOpacity(0.04),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: hasMore ? _toggleExpanded : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: widget.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.items.length} elemento${widget.items.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.color.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasMore) ...[
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: widget.color,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.copy_rounded,
                    color: widget.color,
                    onTap: () => _copyToClipboard(context),
                  ),
                ],
              ),
            ),
          ),
          //* Preview items (siempre visibles)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: previewItems.map((item) => 
                _ItemRow(text: widget.itemMapper(item))
              ).toList(),
            ),
          ),
          //* Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: widget.items
                    .skip(3)
                    .map((item) => _ItemRow(text: widget.itemMapper(item)))
                    .toList(),
              ),
            ),
          ),
          if (hasMore)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextButton(
                onPressed: _toggleExpanded,
                style: TextButton.styleFrom(
                  foregroundColor: widget.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isExpanded ? 'Ver menos' : 'Ver ${widget.items.length - 3} más',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final text = widget.items.map(widget.itemMapper).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('${widget.items.length} elemento${widget.items.length == 1 ? '' : 's'} copiado${widget.items.length == 1 ? '' : 's'}'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.text});
  
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.primaryColor,
    required this.resultState,
    required this.onConfirm,
  });

  final Color primaryColor;
  final ResultState resultState;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cerrar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                if (resultState.isSuccess) onConfirm();
              },
              icon: Icon(
                resultState.isSuccess 
                    ? Icons.arrow_forward_rounded 
                    : Icons.visibility_rounded,
              ),
              label: Text(
                resultState.isSuccess ? 'Continuar' : 'Entendido',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: resultState.isSuccess ? primaryColor : Colors.blueGrey,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}