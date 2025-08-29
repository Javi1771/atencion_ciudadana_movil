// lib/controllers/citizen_home_controller.dart
// ignore_for_file: avoid_print, unused_local_variable

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_atencion_ciudadana/services/local_db.dart';

class CitizenHomeController extends ChangeNotifier {
  List<Map<String, dynamic>> _citizens = [];
  List<Map<String, dynamic>> _filteredCitizens = [];
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  bool _isLoading = false;

  //* NUEVO: bandera de subida y progreso
  bool _isUploading = false;
  final double _progress = 0.0;

  //* Getters
  List<Map<String, dynamic>> get citizens => _citizens;
  List<Map<String, dynamic>> get filteredCitizens => _filteredCitizens;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;

  bool get hasCitizens => _citizens.isNotEmpty;
  bool get isUploading => _isUploading;
  double get progress => _progress;

  //* Estadísticas
  int get totalCitizens => _citizens.length;
  int get citizensWithCurp => _citizens
      .where(
        (c) =>
            c['curp_ciudadano']?.toString().trim().isNotEmpty == true &&
            c['curp_ciudadano'].toString().trim().length == 18,
      )
      .length;
  int get citizensWithoutCurp => totalCitizens - citizensWithCurp;

  //? ---------------------------
  //? Carga, filtros, búsqueda...
  //? ---------------------------
  Future<void> loadCitizens() async {
    _isLoading = true;
    notifyListeners();

    try {
      _citizens = await CitizenLocalRepo.all();
      _applyFilters();
    } catch (e) {
      _citizens = [];
      _filteredCitizens = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_citizens);

    switch (_selectedFilter) {
      case 'Con CURP':
        filtered = filtered.where(_isValidForUpload).toList();
        break;
      case 'Sin CURP':
        filtered = filtered.where((c) => !_isValidForUpload(c)).toList();
        break;
      case 'Recientes':
        filtered.sort((a, b) {
          final idA = a['id_ciudadano'] as int? ?? 0;
          final idB = b['id_ciudadano'] as int? ?? 0;
          return idB.compareTo(idA);
        });
        filtered = filtered.take(10).toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((citizen) {
        final curp = citizen['curp_ciudadano']?.toString().toLowerCase() ?? '';
        final nombre = citizen['nombre']?.toString().toLowerCase() ?? '';
        final p1 = citizen['primer_apellido']?.toString().toLowerCase() ?? '';
        final p2 = citizen['segundo_apellido']?.toString().toLowerCase() ?? '';
        final nc = citizen['nombre_completo']?.toString().toLowerCase() ?? '';
        final tel = citizen['telefono']?.toString().toLowerCase() ?? '';
        final email = citizen['email']?.toString().toLowerCase() ?? '';
        final asent = citizen['asentamiento']?.toString().toLowerCase() ?? '';
        return curp.contains(q) ||
            nombre.contains(q) ||
            p1.contains(q) ||
            p2.contains(q) ||
            nc.contains(q) ||
            tel.contains(q) ||
            email.contains(q) ||
            asent.contains(q);
      }).toList();
    }

    _filteredCitizens = filtered;
  }

  List<String> getFilterOptions() => [
    'Todos',
    'Con CURP',
    'Sin CURP',
    'Recientes',
  ];

  String getFilterLabel(String filter) {
    switch (filter) {
      case 'Todos':
        return 'Todos ($totalCitizens)';
      case 'Con CURP':
        return 'Con CURP ($citizensWithCurp)';
      case 'Sin CURP':
        return 'Sin CURP ($citizensWithoutCurp)';
      case 'Recientes':
        return 'Recientes';
      default:
        return filter;
    }
  }

  String getCitizenStatus(Map<String, dynamic> c) {
    final nombre = (c['nombre']?.toString().trim() ?? '');
    final p1 = (c['primer_apellido']?.toString().trim() ?? '');
    final tel = (c['telefono']?.toString().trim() ?? '');

    if (_isValidForUpload(c)) return 'Completo';
    if (nombre.isNotEmpty && p1.isNotEmpty && tel.isNotEmpty) return 'Parcial';
    return 'Incompleto';
  }

  Color getCitizenStatusColor(Map<String, dynamic> c) {
    switch (getCitizenStatus(c)) {
      case 'Completo':
        return const Color(0xFF10B981);
      case 'Parcial':
        return const Color(0xFFF59E0B);
      case 'Incompleto':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  //? ---------------------------
  //? CRUD local
  //? ---------------------------
  Future<void> updateCitizen(int id, Map<String, dynamic> data) async {
    try {
      await CitizenLocalRepo.update(id, data);
      await loadCitizens();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCitizen(int id) async {
    try {
      await CitizenLocalRepo.delete(id);
      await loadCitizens();
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic>? getCitizenById(int id) {
    try {
      return _citizens.firstWhere((c) => c['id_ciudadano'] == id);
    } catch (_) {
      return null;
    }
  }

  bool isDuplicateCurp(String curp, {int? excludeId}) {
    final cc = curp.toUpperCase().trim();
    return _citizens.any(
      (c) =>
          (c['curp_ciudadano']?.toString().trim().toUpperCase() == cc) &&
          (excludeId == null || c['id_ciudadano'] != excludeId),
    );
  }

  bool isDuplicatePhone(String phone, {int? excludeId}) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return _citizens.any((c) {
      final p =
          c['telefono']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
      return p == cleanPhone &&
          (excludeId == null || c['id_ciudadano'] != excludeId);
    });
  }

  Map<String, int> getGenderStats() {
    final m = _citizens
        .where((c) => c['sexo']?.toString().toLowerCase() == 'masculino')
        .length;
    final f = _citizens
        .where((c) => c['sexo']?.toString().toLowerCase() == 'femenino')
        .length;
    return {
      'masculino': m,
      'femenino': f,
      'no_especificado': totalCitizens - m - f,
    };
  }

  Map<String, int> getStateStats() {
    final counts = <String, int>{};
    for (final c in _citizens) {
      final e = c['estado']?.toString() ?? 'No especificado';
      counts[e] = (counts[e] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  //? ---------------------------
  //? SUBIDA A API (JSON)
  //? ---------------------------

  //* ✅ Regla de validez para subir: CURP válida (18, alfanumérica, sin espacios + patrón)
  bool _isValidForUpload(Map<String, dynamic> c) {
    final curp = (c['curp_ciudadano']?.toString().trim().toUpperCase() ?? '');
    if (curp.length != 18) return false;
    if (curp.contains(' ')) return false;
    if (!RegExp(r'^[A-Z0-9]{18}$').hasMatch(curp)) return false;
    final pat = RegExp(
      r'^[A-Z]{4}[0-9]{6}[HMX]'
      r'(AS|BC|BS|CC|CL|CM|CS|CH|DF|DG|GT|GR|HG|JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|TC|TS|TL|VZ|YN|ZS|NE)'
      r'[A-Z]{3}[A-Z0-9][0-9]$',
    );
    return pat.hasMatch(curp);
  }

  //* Mapea un ciudadano local → objeto JSON esperado por el backend
  Map<String, dynamic> _toCitizenPayload(Map<String, dynamic> c) {
    String s(dynamic v) => (v ?? '').toString().trim();

    return {
      'nombre': s(c['nombre']),
      'primer_apellido': s(c['primer_apellido']),
      'segundo_apellido': s(c['segundo_apellido']),
      'nombre_completo': s(c['nombre_completo']),
      'curp_ciudadano': s(c['curp_ciudadano']).toUpperCase(),
      'fecha_nacimiento': s(c['fecha_nacimiento']),
      'password': s(c['password']),
      'sexo': s(c['sexo']),
      'estado': s(c['estado']),
      'telefono': s(c['telefono']),
      'email': s(c['email']),
      'asentamiento': s(c['asentamiento']),
      'calle': s(c['calle']),
      'numero_exterior': s(c['numero_exterior']),
      'numero_interior': s(c['numero_interior']),
      'codigo_postal': s(c['codigo_postal']),
    };
  }

  ///* Sube a la API **uno a uno**.
  ///* - Filtra válidos y deduplica por CURP.
  ///* - Envía cada registro por separado (array de 1 elemento, como espera el API).
  ///* - Si el envío del registro es success=true **o** el server lo reporta como duplicado,
  ///*   elimina ese ciudadano de la BD local.
  ///* - Devuelve un resumen agregado (skips/errores/duplicates/trabajadores).
  Future<Map<String, dynamic>?> uploadCitizensJson({
    List<Map<String, dynamic>>? citizensToUpload,
    String? idempotencyKey,
  }) async {
    if (_isUploading) {
      print('⏳ [UPLOAD] Ya hay una subida en proceso, cancelando.');
      return {
        'success': false,
        'message': 'Ya hay una subida en proceso',
        'details': {'skips': [], 'errores': []},
        'meta': {'duplicates': [], 'trabajadores': []},
      };
    }

    //? 1) Filtra válidos
    var toSend = (citizensToUpload ?? _citizens).where(_isValidForUpload);

    //? 2) Dedupe por CURP
    final seen = <String>{};
    toSend = toSend.where(
      (c) =>
          seen.add((c['curp_ciudadano'] ?? '').toString().trim().toUpperCase()),
    );
    final listToSend = toSend.toList();

    print(
      '📋 [UPLOAD] Total candidatos: ${(citizensToUpload ?? _citizens).length}',
    );
    print('✅ [UPLOAD] Filtrados válidos y únicos: ${listToSend.length}');
    for (final c in listToSend) {
      print(
        '   - CURP: ${c['curp_ciudadano']}  Nombre: ${c['nombre_completo']}',
      );
    }

    if (listToSend.isEmpty) {
      print('⚠️ [UPLOAD] No hay ciudadanos válidos para enviar');
      return {
        'success': false,
        'message': 'No hay ciudadanos con CURP válida para subir',
        'details': {
          'skips': [],
          'errores': ['No hay ciudadanos válidos'],
        },
        'meta': {'duplicates': [], 'trabajadores': []},
      };
    }

    //? 3) Token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isEmpty) {
      print('❌ [UPLOAD] Token no encontrado');
      return {
        'success': false,
        'message': 'Token no encontrado. Inicia sesión.',
        'details': {
          'skips': [],
          'errores': ['Token no encontrado'],
        },
        'meta': {'duplicates': [], 'trabajadores': []},
      };
    }

    _isUploading = true;
    notifyListeners();

    final uri = Uri.parse(
      'https://sanjuandelrio.gob.mx/tramites-sjr/Api/principal/cargar_usuarios_app',
    );

    //? 4) Acumuladores de resultado
    final List<dynamic> aggregatedSkips = [];
    final List<dynamic> aggregatedErrs = [];
    final List<String> aggregatedDuplicates = [];
    final List<String> aggregatedTrabajadores = [];
    int sentOk = 0;
    int total = listToSend.length;

    print('🚀 [UPLOAD] Envío UNO A UNO a: $uri');
    print('🔑 [UPLOAD] Token (recortado): ${token.substring(0, 10)}...');

    //? 5) Itera y envía de uno en uno
    for (final citizen in listToSend) {
      final payloadSingle = [_toCitizenPayload(citizen)];
      final curpUpper = citizen['curp_ciudadano']
          .toString()
          .trim()
          .toUpperCase();
      final idLocal = citizen['id_ciudadano'] as int?;

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      //* Idempotency por registro (si te pasan uno global, lo especializamos)
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        headers['Idempotency-Key'] = '$idempotencyKey:$curpUpper';
      }

      print('📦 [UPLOAD] POST 1/1 → ${jsonEncode(payloadSingle)}');

      try {
        final resp = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(payloadSingle),
        );

        print('🌐 [UPLOAD:$curpUpper] Status: ${resp.statusCode}');
        print('🌐 [UPLOAD:$curpUpper] Body: ${resp.body}');

        bool ok = false;
        String msg = 'Error en servidor';
        List<dynamic> skips = [];
        List<dynamic> errs = [];
        List<String> duplicates = [];
        List<String> trabajadores = [];

        try {
          final js = jsonDecode(resp.body);
          ok = js['success'] == true;
          msg = js['message']?.toString() ?? msg;
          skips = (js['details']?['skips'] ?? []) as List<dynamic>;
          errs = (js['details']?['errores'] ?? []) as List<dynamic>;
          duplicates = ((js['meta']?['duplicates'] ?? []) as List)
              .cast<String>();
          trabajadores = ((js['meta']?['trabajadores'] ?? []) as List)
              .cast<String>();

          print('📥 [UPLOAD:$curpUpper] ok=$ok, msg=$msg');
          print('   skips=$skips');
          print('   errores=$errs');
          print('   duplicates=$duplicates');
          print('   trabajadores=$trabajadores');
        } catch (e) {
          print('⚠️ [UPLOAD:$curpUpper] Error parseando respuesta: $e');
          //! fallback: si el server devuelve texto, lo guardamos como error
          aggregatedErrs.add('[$curpUpper] ${resp.body.trim()}');
        }

        //* Acumular detalles
        aggregatedSkips.addAll(skips);
        aggregatedErrs.addAll(errs);
        aggregatedDuplicates.addAll(duplicates.map((d) => d.toUpperCase()));
        aggregatedTrabajadores.addAll(trabajadores.map((t) => t.toUpperCase()));

        //* Éxito por registro si:
        //* - success==true, o
        //* - el server reporta el CURP de este registro en "duplicates"
        final isDuplicateOfThis =
            aggregatedDuplicates.contains(curpUpper) ||
            duplicates.contains(curpUpper);

        if (ok || isDuplicateOfThis) {
          //! Eliminar local
          if (idLocal != null) {
            await CitizenLocalRepo.delete(idLocal);
            print('🗑️ [UPLOAD:$curpUpper] Eliminado local id=$idLocal');
          }
          sentOk++;
        } else {
          //! No se elimina, queda pendiente.
          print(
            '⚠️ [UPLOAD:$curpUpper] No se eliminó local (fallo o pendiente).',
          );
        }
      } catch (e) {
        print('🚨 [UPLOAD:$curpUpper] Error de red: $e');
        aggregatedErrs.add('[$curpUpper] Error de red');
      }
    }

    //? 6) Refrescar lista local tras iteración
    await loadCitizens();

    _isUploading = false;
    notifyListeners();

    //? 7) Componer mensaje/estado final
    final allWereDuplicates =
        sentOk == 0 &&
        aggregatedErrs.isEmpty &&
        aggregatedDuplicates.length == total;

    bool finalSuccess = false;
    String finalMsg = '';

    if (sentOk > 0) {
      finalSuccess = true;
      finalMsg = 'Se subieron $sentOk de $total registro(s).';
    } else if (allWereDuplicates) {
      finalSuccess = true;
      finalMsg = 'Ya estaban registrados, sincronizado.';
    } else {
      finalSuccess = false;
      finalMsg = 'No se pudieron subir los registros.';
    }

    return {
      'success': finalSuccess,
      'message': finalMsg,
      'details': {'skips': aggregatedSkips, 'errores': aggregatedErrs},
      'meta': {
        'duplicates': aggregatedDuplicates,
        'trabajadores': aggregatedTrabajadores,
        'enviados_ok': sentOk,
        'total': total,
      },
    };
  }
}
