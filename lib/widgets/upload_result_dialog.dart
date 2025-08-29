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
    //* Entrada “cruda”
    final bool apiSuccess = (result['success'] as bool?) ?? false;
    final String message = (result['message'] as String?)?.trim() ?? '';
    final Map<String, dynamic> details =
        (result['details'] as Map?)?.cast<String, dynamic>() ?? {};
    final Map<String, dynamic> meta =
        (result['meta'] as Map?)?.cast<String, dynamic>() ?? {};

    //* Listas
    final List<String> skips =
        (details['skips'] as List?)?.map((e) => '$e').toList() ?? const [];
    final List<String> errores =
        (details['errores'] as List?)?.map((e) => '$e').toList() ?? const [];
    final List<String> duplicates =
        (meta['duplicates'] as List?)?.map((e) => '$e').toList() ?? const [];
    final List<String> trabajadores =
        (meta['trabajadores'] as List?)?.map((e) => '$e').toList() ?? const [];

    //* Métricas opcionales
    final int inserted =
        ((meta['inserted'] ?? meta['creados'] ?? meta['ok']) as num?)
            ?.toInt() ??
        0;
    final int updated = (meta['updated'] as num?)?.toInt() ?? 0;
    final int totalMeta = (meta['total'] as num?)?.toInt() ?? 0;
    final bool hasTotal = totalMeta > 0;

    //* --- Nueva lógica: “duplicados solamente” = tratamos como éxito ---
    final bool duplicatesOnlySuccess =
        !apiSuccess && //! la API dijo false…
        errores.isEmpty && //! …pero no hubo errores reales
        trabajadores.isEmpty && //! …ni bloqueos por trabajadores
        duplicates.isNotEmpty && //! …sí hubo duplicados
        inserted == 0 && //! …no se insertó nadie
        updated == 0; //! …ni se actualizó nadie

    final bool success = apiSuccess || duplicatesOnlySuccess;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (context) {
        final Color pos = Colors.green.shade500;
        final Color neg = Colors.red.shade500;
        final Color headerA = success ? pos : neg;
        final Color headerB = success
            ? Colors.green.shade700
            : Colors.red.shade700;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withOpacity(0.08)),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Header(
                        title: success
                            ? (duplicatesOnlySuccess
                                  ? 'Sin inserciones: ya existían'
                                  : 'Proceso completado')
                            : 'Proceso con observaciones',
                        subtitle: _makeHeaderSubtitle(
                          hasTotal: hasTotal,
                          total: totalMeta,
                          inserted: inserted,
                          updated: updated,
                          errors: errores.length,
                          dups: duplicates.length,
                          skips: skips.length,
                          workers: trabajadores.length,
                        ),
                        gradient: LinearGradient(
                          colors: [headerA, headerB],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        icon: success
                            ? Icons.verified_rounded
                            : Icons.error_rounded,
                      ),

                      //* Contenido
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.isNotEmpty)
                                _MainMessage(
                                  message: message,
                                  success: success,
                                ),
                              const SizedBox(height: 14),

                              if (_hasIssues(
                                errores,
                                duplicates,
                                trabajadores,
                                skips,
                                inserted,
                                updated,
                                hasTotal ? totalMeta : null,
                              ))
                                _SummaryBar(
                                  inserted: inserted,
                                  updated: updated,
                                  total: hasTotal ? totalMeta : null,
                                  errores: errores.length,
                                  duplicates: duplicates.length,
                                  trabajadores: trabajadores.length,
                                  skips: skips.length,
                                  primaryColor: primaryColor,
                                  showAllDuplicatedAsOk: duplicatesOnlySuccess,
                                ),

                              const SizedBox(height: 12),

                              ..._buildDetailSections(
                                context: context,
                                errores: errores,
                                duplicates: duplicates,
                                trabajadores: trabajadores,
                                skips: skips,
                              ),
                            ],
                          ),
                        ),
                      ),

                      _Footer(
                        primaryColor: primaryColor,
                        success: success,
                        onConfirm: onConfirm,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //? ---------- Subtítulo preciso ----------
  static String _makeHeaderSubtitle({
    required bool hasTotal,
    required int total,
    required int inserted,
    required int updated,
    required int errors,
    required int dups,
    required int skips,
    required int workers,
  }) {
    final parts = <String>[];
    if (hasTotal) parts.add('Total: $total');
    if (inserted > 0) parts.add('Insertados: $inserted');
    if (updated > 0) parts.add('Actualizados: $updated');
    if (dups > 0) parts.add('Duplicados: $dups');
    if (workers > 0) parts.add('Trabajadores: $workers');
    if (errors > 0) parts.add('Errores: $errors');
    if (skips > 0) parts.add('Omitidos: $skips');
    return parts.isEmpty ? 'Revisión finalizada' : parts.join(' • ');
  }

  //? ---------- Secciones ----------
  static List<Widget> _buildDetailSections({
    required BuildContext context,
    required List<String> errores,
    required List<String> duplicates,
    required List<String> trabajadores,
    required List<String> skips,
  }) {
    final sections = <Widget>[];

    if (errores.isNotEmpty) {
      sections.add(
        _Section(
          color: Colors.red,
          icon: Icons.error_outline_rounded,
          title: 'Errores de procesamiento',
          items: errores,
          itemMapper: (s) => s,
        ),
      );
      sections.add(const SizedBox(height: 10));
    }

    if (duplicates.isNotEmpty) {
      sections.add(
        _Section(
          color: Colors.orange,
          icon: Icons.dataset_linked_rounded,
          title: 'CURP ya registrada',
          items: duplicates,
          itemMapper: (s) => _maskCurp(s),
        ),
      );
      sections.add(const SizedBox(height: 10));
    }

    if (trabajadores.isNotEmpty) {
      sections.add(
        _Section(
          color: Colors.purple,
          icon: Icons.badge_rounded,
          title: 'CURP de trabajadores (no se insertan)',
          items: trabajadores,
          itemMapper: (s) => _maskCurp(s),
        ),
      );
      sections.add(const SizedBox(height: 10));
    }

    if (skips.isNotEmpty) {
      sections.add(
        _Section(
          color: Colors.blueGrey,
          icon: Icons.skip_next_rounded,
          title: 'Registros omitidos',
          items: skips,
          itemMapper: (s) => s,
        ),
      );
    }

    return sections;
  }

  //? ---------- Helpers ----------
  static bool _hasIssues(
    List<String> errores,
    List<String> duplicates,
    List<String> trabajadores,
    List<String> skips,
    int inserted,
    int updated, [
    int? total,
  ]) {
    return errores.isNotEmpty ||
        duplicates.isNotEmpty ||
        trabajadores.isNotEmpty ||
        skips.isNotEmpty ||
        inserted > 0 ||
        updated > 0 ||
        (total != null && total > 0);
  }

  static String _maskCurp(String curp) {
    final c = curp.trim();
    if (c.length < 10) return c;
    final left = c.substring(0, 4);
    final right = c.substring(c.length - 4);
    return '$left****$right';
  }
}

//? ===================================================================
//? UI Pieces
//? ===================================================================

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Gradient gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 22, bottom: 18),
      decoration: BoxDecoration(gradient: gradient),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.92),
                    fontSize: 12.5,
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
  const _MainMessage({required this.message, required this.success});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final Color bg = success ? Colors.green.shade50 : Colors.red.shade50;
    final Color bd = success ? Colors.green.shade200 : Colors.red.shade200;
    final Color fg = success ? Colors.green.shade800 : Colors.red.shade800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: bd),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.inserted,
    required this.updated,
    required this.total,
    required this.errores,
    required this.duplicates,
    required this.trabajadores,
    required this.skips,
    required this.primaryColor,
    required this.showAllDuplicatedAsOk,
  });

  final int inserted;
  final int updated;
  final int? total;
  final int errores;
  final int duplicates;
  final int trabajadores;
  final int skips;
  final Color primaryColor;
  final bool showAllDuplicatedAsOk;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (total != null) {
      chips.add(
        _statChip(
          Icons.library_add_check_rounded,
          'Total: $total',
          Colors.blueGrey,
        ),
      );
    }
    if (inserted > 0) {
      chips.add(
        _statChip(
          Icons.check_circle_rounded,
          'Insertados: $inserted',
          Colors.green,
        ),
      );
    }
    if (updated > 0) {
      chips.add(
        _statChip(Icons.update_rounded, 'Actualizados: $updated', Colors.teal),
      );
    }
    if (duplicates > 0) {
      chips.add(
        _statChip(
          Icons.dataset_linked_rounded,
          'Duplicados: $duplicates',
          Colors.orange,
        ),
      );
    }
    if (trabajadores > 0) {
      chips.add(
        _statChip(
          Icons.badge_rounded,
          'Trabajadores: $trabajadores',
          Colors.purple,
        ),
      );
    }
    if (errores > 0) {
      chips.add(
        _statChip(Icons.error_outline_rounded, 'Errores: $errores', Colors.red),
      );
    }
    if (skips > 0) {
      chips.add(
        _statChip(Icons.skip_next_rounded, 'Omitidos: $skips', Colors.blueGrey),
      );
    }
    //* Chip extra cuando todo fue duplicado (éxito lógico)
    if (showAllDuplicatedAsOk && inserted == 0 && duplicates > 0) {
      chips.add(
        _statChip(
          Icons.done_all_rounded,
          'Sin inserciones (ya existían)',
          Colors.green,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(spacing: 10, runSpacing: 8, children: chips),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
    required this.itemMapper,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;
  final String Function(String) itemMapper;

  @override
  Widget build(BuildContext context) {
    final display = items.take(5).toList();
    final remaining = items.length - display.length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.18)),
        color: color.withOpacity(.04),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(.12),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: .2,
            ),
          ),
          subtitle: Text(
            '${items.length} elemento${items.length == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 12, color: color.withOpacity(.85)),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                children: [
                  ...display.map((e) => _BulletRow(text: itemMapper(e))),
                  if (remaining > 0) ...[
                    const SizedBox(height: 6),
                    _SeeAllButton(
                      color: color,
                      onTap: () => _showAllBottomSheet(
                        context,
                        title: title,
                        color: color,
                        icon: icon,
                        items: items.map(itemMapper).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  _CopyButton(
                    color: color,
                    data: items.map(itemMapper).join('\n'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllBottomSheet(
    BuildContext context, {
    required String title,
    required Color color,
    required IconData icon,
    required List<String> items,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .78,
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(.12),
                child: Icon(icon, color: color),
              ),
              title: Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${items.length} elemento${items.length == 1 ? '' : 's'}',
              ),
              trailing: _CopyButton(color: color, data: items.join('\n')),
            ),
            const Divider(height: 0),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  title: Text(items[i]),
                  leading: const Icon(Icons.chevron_right_rounded, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.onTap, required this.color});
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        icon: const Icon(Icons.unfold_more_rounded, size: 18),
        label: const Text('Ver todo'),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.color, required this.data});
  final Color color;
  final String data;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: data));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copiado al portapapeles'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        icon: const Icon(Icons.copy_rounded, size: 18),
        label: const Text('Copiar'),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.primaryColor,
    required this.success,
    required this.onConfirm,
  });

  final Color primaryColor;
  final bool success;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(.9),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, color: Color(0xFF0D9488)),
              label: Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFF0D9488),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Color(0xFF0D9488).withOpacity(0.5),
                  width: 2.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                if (success) onConfirm();
              },
              icon: Icon(
                success
                    ? Icons.arrow_forward_rounded
                    : Icons.visibility_rounded,
              ),
              label: Text(success ? 'Continuar' : 'Entendido'),
              style: ElevatedButton.styleFrom(
                backgroundColor: success ? primaryColor : Colors.blueGrey,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
