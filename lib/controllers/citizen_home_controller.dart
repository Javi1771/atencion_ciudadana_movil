// lib/controllers/citizen_home_controller.dart
// ignore_for_file: avoid_print, unused_local_variable

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_atencion_ciudadana/services/local_db.dart';
import 'package:app_atencion_ciudadana/widgets/alert_helper.dart';

class CitizenHomeController extends ChangeNotifier {
  List<Map<String, dynamic>> _citizens = [];
  List<Map<String, dynamic>> _filteredCitizens = [];
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  bool _isLoading = false;

  //* NUEVO: bandera de subida y progreso
  bool _isUploading = false;
  double _progress = 0.0;

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
  int get citizensWithCurp => _citizens.where((c) =>
    c['curp_ciudadano']?.toString().trim().isNotEmpty == true &&
    c['curp_ciudadano'].toString().trim().length == 18).length;
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
      //? print('[CitizenHomeController] Cargados ${_citizens.length} ciudadanos');
    } catch (e) {
      //? print('[CitizenHomeController] Error al cargar ciudadanos: $e');
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

  List<String> getFilterOptions() => ['Todos', 'Con CURP', 'Sin CURP', 'Recientes'];

  String getFilterLabel(String filter) {
    switch (filter) {
      case 'Todos': return 'Todos ($totalCitizens)';
      case 'Con CURP': return 'Con CURP ($citizensWithCurp)';
      case 'Sin CURP': return 'Sin CURP ($citizensWithoutCurp)';
      case 'Recientes': return 'Recientes';
      default: return filter;
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
      case 'Completo': return const Color(0xFF10B981);
      case 'Parcial': return const Color(0xFFF59E0B);
      case 'Incompleto': return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }

  //? ---------------------------
  //? CRUD local
  //? ---------------------------
  Future<void> updateCitizen(int id, Map<String, dynamic> data) async {
    try {
      await CitizenLocalRepo.update(id, data);
      await loadCitizens();
      //? print('[CitizenHomeController] Ciudadano actualizado: $id');
    } catch (e) {
      //? print('[CitizenHomeController] Error al actualizar ciudadano: $e');
      rethrow;
    }
  }

  Future<void> deleteCitizen(int id) async {
    try {
      await CitizenLocalRepo.delete(id);
      await loadCitizens();
      //? print('[CitizenHomeController] Ciudadano eliminado: $id');
    } catch (e) {
      //? print('[CitizenHomeController] Error al eliminar ciudadano: $e');
      rethrow;
    }
  }

  Map<String, dynamic>? getCitizenById(int id) {
    try { return _citizens.firstWhere((c) => c['id_ciudadano'] == id); }
    catch (_) { return null; }
  }

  bool isDuplicateCurp(String curp, {int? excludeId}) {
    final cc = curp.toUpperCase().trim();
    return _citizens.any((c) =>
      (c['curp_ciudadano']?.toString().trim().toUpperCase() == cc) &&
      (excludeId == null || c['id_ciudadano'] != excludeId));
  }

  bool isDuplicatePhone(String phone, {int? excludeId}) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return _citizens.any((c) {
      final p = c['telefono']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
      return p == cleanPhone && (excludeId == null || c['id_ciudadano'] != excludeId);
    });
  }

  Map<String, int> getGenderStats() {
    final m = _citizens.where((c) => c['sexo']?.toString().toLowerCase() == 'masculino').length;
    final f = _citizens.where((c) => c['sexo']?.toString().toLowerCase() == 'femenino').length;
    return {'masculino': m, 'femenino': f, 'no_especificado': totalCitizens - m - f};
  }

  Map<String, int> getStateStats() {
    final counts = <String,int>{};
    for (final c in _citizens) {
      final e = c['estado']?.toString() ?? 'No especificado';
      counts[e] = (counts[e] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  //? ---------------------------
  //? SUBIDA A API (JSON)
  //? ---------------------------

  //* ✅ Regla de validez para subir: CURP válida (18, alfanumérica, sin espacios)
  bool _isValidForUpload(Map<String, dynamic> c) {
    final curp = (c['curp_ciudadano']?.toString().trim().toUpperCase() ?? '');

    //? print('[DEBUG] Validando CURP: "$curp" (longitud: ${curp.length})');

    if (curp.length != 18) {
      //? print('[DEBUG] CURP rechazada: longitud != 18');
      return false;
    }
    if (curp.contains(' ')) {
      //? print('[DEBUG] CURP rechazada: contiene espacios');
      return false;
    }
    if (!RegExp(r'^[A-Z0-9]{18}$').hasMatch(curp)) {
      //? print('[DEBUG] CURP rechazada: no es alfanumérica de 18 caracteres');
      return false;
    }

    //* Patrón con catálogo de estados
    final pat = RegExp(
      r'^[A-Z]{4}[0-9]{6}[HM](AS|BC|BS|CC|CL|CM|CS|CH|DF|DG|GT|GR|HG|JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|TC|TS|TL|VZ|YN|ZS|NE)[A-Z]{3}[A-Z0-9]{1}[0-9]$'
    );
    final isValid = pat.hasMatch(curp);

    if (!isValid) {
      //? print('[DEBUG] CURP rechazada: no coincide con patrón CURP');
      if (curp.length >= 4) {
        final primeras4 = curp.substring(0, 4);
        final ok = RegExp(r'^[A-Z]{4}$').hasMatch(primeras4);
        //? print('[DEBUG] Primeras 4 letras: "$primeras4" ${ok ? "✓" : "✗"}');
      }
      if (curp.length >= 10) {
        final fecha = curp.substring(4, 10);
        final ok = RegExp(r'^[0-9]{6}$').hasMatch(fecha);
        //? print('[DEBUG] Fecha (pos 4-9): "$fecha" ${ok ? "✓" : "✗"}');
      }
      if (curp.length >= 11) {
        final sexo = curp.substring(10, 11);
        final ok = RegExp(r'^[HMX]$').hasMatch(sexo);
        //? print('[DEBUG] Sexo (pos 10): "$sexo" ${ok ? "✓" : "✗"}');
      }
      if (curp.length >= 13) {
        final estado = curp.substring(11, 13);
        final ok = RegExp(r'^(AS|BC|BS|CC|CL|CM|CS|CH|DF|DG|GT|GR|HG|JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|TC|TS|TL|VZ|YN|ZS|NE)$').hasMatch(estado);
        //? print('[DEBUG] Estado (pos 11-12): "$estado" ${ok ? "✓" : "✗"}');
      }
      if (curp.length >= 17) {
        final cons = curp.substring(13, 17);
        final ok = RegExp(r'^[A-Z]{3}[A-Z0-9]{1}$').hasMatch(cons);
        //? print('[DEBUG] Consonantes (pos 13-16): "$cons" ${ok ? "✓" : "✗"}');
      }
      if (curp.length >= 18) {
        final dig = curp.substring(17, 18);
        final ok = RegExp(r'^[0-9]$').hasMatch(dig);
        //? print('[DEBUG] Dígito verificador (pos 17): "$dig" ${ok ? "✓" : "✗"}');
      }
    } else {
      //? print('[DEBUG] ✓ CURP VÁLIDA: $curp');
    }

    return isValid;
  }

  //* Mapea un ciudadano local → objeto JSON esperado por el backend
  Map<String, dynamic> _toCitizenPayload(Map<String, dynamic> c) {
    String s(dynamic v) => (v ?? '').toString().trim();

    return {
      //* Tabla: ciudadanos
      'nombre'           : s(c['nombre']),
      'primer_apellido'  : s(c['primer_apellido']),
      'segundo_apellido' : s(c['segundo_apellido']),
      'nombre_completo'  : s(c['nombre_completo']),
      'curp_ciudadano'   : s(c['curp_ciudadano']).toUpperCase(),
      'fecha_nacimiento' : s(c['fecha_nacimiento']),
      'password'         : s(c['password']),
      'sexo'             : s(c['sexo']),
      'estado'           : s(c['estado']),

      //* Tabla: ciudadano_contacto
      'telefono'         : s(c['telefono']),
      'email'            : s(c['email']),

      //* Tabla: ciudadano_direccion
      'asentamiento'     : s(c['asentamiento']),
      'calle'            : s(c['calle']),
      'numero_exterior'  : s(c['numero_exterior']),
      'numero_interior'  : s(c['numero_interior']),
      'codigo_postal'    : s(c['codigo_postal']),
    };
  }

  //* --------- Helpers privados para reportes/limpieza ---------
  String _maskCurp(String c) =>
      (c.length == 18) ? '${c.substring(0,4)}******${c.substring(10)}' : c;

  Set<int> _extractRowIndexes(List<dynamic> items) {
    final idx = <int>{};
    final re = RegExp(r'Fila\s+(\d+)', caseSensitive: false);
    for (final it in items) {
      final m = re.firstMatch(it.toString());
      if (m != null) idx.add(int.parse(m.group(1)!));
    }
    return idx;
  }

  List<String> _extractDuplicateCurps(List<dynamic> skips) {
    final dups = <String>[];
    final re = RegExp(r'CURP\s+([A-Z0-9]{18})\s+ya existe', caseSensitive: false);
    for (final s in skips) {
      final m = re.firstMatch(s.toString());
      if (m != null) dups.add(m.group(1)!.toUpperCase());
    }
    return dups;
  }

  ///* Sube a la API todos los ciudadanos CON CURP válida.
  ///* - Endpoint: /Api/principal/cargar_usuarios_app
  ///* - En caso de éxito, elimina del local SOLO los subidos.
  Future<void> uploadCitizensJson({int batchSize = 150}) async {
    //* Filtra válidos
    final valid = _citizens.where(_isValidForUpload).toList();

    //? print('[DEBUG] === VALIDACIÓN DE CIUDADANOS ===');
    for (int i = 0; i < _citizens.length; i++) {
      final citizen = _citizens[i];
      final curp = citizen['curp_ciudadano']?.toString() ?? 'SIN_CURP';
      final isValid = _isValidForUpload(citizen);
      //? print('[DEBUG] Ciudadano $i: CURP="$curp" -> ${isValid ? 'VÁLIDO' : 'INVÁLIDO'}');
    }
    //? print('[DEBUG] Total ciudadanos: ${_citizens.length}, Válidos: ${valid.length}');

    if (valid.isEmpty) {
      AlertHelper.showAlert('No hay ciudadanos con CURP válida para subir', type: AlertType.warning);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isEmpty) {
      AlertHelper.showAlert('Token no encontrado. Inicia sesión.', type: AlertType.error);
      return;
    }

    _isUploading = true;
    _progress = 0;
    notifyListeners();

    final uri = Uri.parse('https://sanjuandelrio.gob.mx/tramites-sjr/Api/principal/cargar_usuarios_app');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    int uploaded = 0;
    final client = http.Client();

    try {
      for (var i = 0; i < valid.length; i += batchSize) {
        final batch = valid.skip(i).take(batchSize).toList();
        final payload = batch.map(_toCitizenPayload).toList();

        //? print('[DEBUG] Enviando batch de ${batch.length} ciudadanos');
        for (int j = 0; j < batch.length; j++) {
          //? print('[DEBUG] Batch[$j] CURP: ${payload[j]['curp_ciudadano']}');
        }

        http.Response resp;
        try {
          resp = await client
              .post(uri, headers: headers, body: jsonEncode(payload))
              .timeout(const Duration(seconds: 25));
        } on TimeoutException {
          AlertHelper.showAlert('Timeout del servidor al subir ciudadanos.', type: AlertType.error);
          break;
        }

        bool ok = false;
        String msg = 'Error en servidor';
        List<dynamic> skips = [];
        List<dynamic> errs  = [];
        List<String> duplicatesCurps = [];

        try {
          final js = jsonDecode(resp.body);
          ok = js['success'] == true;
          msg = (js['message']?.toString() ?? msg);

          if (js['details'] is Map) {
            final det = js['details'] as Map;
            if (det['skips'] is List)  skips = (det['skips'] as List);
            if (det['errores'] is List) errs  = (det['errores'] as List);
          }
          if (js['meta'] is Map && (js['meta']['duplicates'] is List)) {
            duplicatesCurps = (js['meta']['duplicates'] as List)
                .map((e) => e.toString().toUpperCase())
                .toList();
          } else {
            //! fallback si backend no envía meta.duplicates
            duplicatesCurps = _extractDuplicateCurps(skips);
          }
        } catch (_) {
          msg = resp.body.toString();
        }

        //? print('[DEBUG] Respuesta del servidor: status=${resp.statusCode}, success=$ok, message="$msg"');

        if (resp.statusCode == 401) {
          AlertHelper.showAlert('Sesión expirada. Inicia sesión nuevamente.', type: AlertType.error);
          break;
        }

        //* Índices por fila del batch que fallaron
        final failedIdx = _extractRowIndexes([...skips, ...errs]);
        final dupSet = duplicatesCurps.toSet();

        final onlyDuplicates = (!ok) &&
            (resp.statusCode == 409 || (duplicatesCurps.isNotEmpty && errs.isEmpty));

        //? -------- Mensajes SENCILLOS --------
        if (!ok && !onlyDuplicates) {
          //! error general
          AlertHelper.showAlert('No se pudo completar la carga. Intenta más tarde.', type: AlertType.error);
          break;
        }

        if (onlyDuplicates) {
          if (duplicatesCurps.length == 1) {
            final c = _maskCurp(duplicatesCurps.first);
            AlertHelper.showAlert('La CURP $c ya existe en el sistema. Se eliminará del dispositivo.', type: AlertType.warning);
          } else {
            final muestra = duplicatesCurps.take(3).map(_maskCurp).join(', ');
            AlertHelper.showAlert(
              '${duplicatesCurps.length} registros ya existían. Se eliminaron del dispositivo. Ej.: $muestra',
              type: AlertType.warning,
            );
          }
        } else if (ok) {
          final totalFallidos = failedIdx.length;
          final totalDup = duplicatesCurps.length;
          if (totalFallidos == 0) {
            AlertHelper.showAlert('Carga completada.', type: AlertType.success);
          } else if (totalDup > 0) {
            AlertHelper.showAlert(
              'Carga completada con $totalDup duplicados (eliminados del dispositivo) '
              'y ${totalFallidos - totalDup} con error.',
              type: AlertType.warning,
            );
          } else {
            AlertHelper.showAlert('Carga con incidencias: $totalFallidos registros con error.', type: AlertType.warning);
          }
        }

        //! -------- BORRADO LOCAL CONTROLADO --------
        //! - Si ok: borrar los éxitos (todos menos failedIdx)
        //! - Siempre: borrar duplicados (aunque haya sido error por duplicidad)
        final idsAEliminar = <int>{};

        //* Mapa índice -> CURP (del payload) para cruzar duplicados
        final batchCurps = <int, String>{};
        for (int k = 0; k < payload.length; k++) {
          batchCurps[k] = (payload[k]['curp_ciudadano']?.toString().toUpperCase() ?? '');
        }

        //? 1) Éxitos (cuando ok)
        if (ok) {
          for (int k = 0; k < batch.length; k++) {
            if (!failedIdx.contains(k)) {
              final id = batch[k]['id_ciudadano'] as int?;
              if (id != null) idsAEliminar.add(id);
            }
          }
        }

        //? 2) Duplicados (siempre)
        if (dupSet.isNotEmpty) {
          for (int k = 0; k < batch.length; k++) {
            if (dupSet.contains(batchCurps[k])) {
              final id = batch[k]['id_ciudadano'] as int?;
              if (id != null) idsAEliminar.add(id);
            }
          }
        }

        for (final id in idsAEliminar) {
          await CitizenLocalRepo.delete(id);
        }
        uploaded += idsAEliminar.length;

        //* Avance
        _progress = uploaded / valid.length;
        notifyListeners();

        //! Si no fue ok y no era solo duplicados, ya hicimos break arriba.
        //! Para "solo duplicados", continuamos al siguiente batch.
      }

      //* Recarga desde local
      await loadCitizens();

      if (uploaded > 0) {
        //! Aviso general si aún hay incompletos por otras causas
        if (_citizens.any((c) => !_isValidForUpload(c))) {
          AlertHelper.showAlert(
            'Algunos registros no se subieron por CURP inválida o datos incompletos.',
            type: AlertType.warning,
          );
        }
      }

    } catch (e) {
      //? print('[CitizenHomeController] Error al subir ciudadanos: $e');
      AlertHelper.showAlert('Error de red al subir ciudadanos.', type: AlertType.error);
    } finally {
      client.close();
      _isUploading = false;
      _progress = 0;
      notifyListeners();
    }
  }
}
