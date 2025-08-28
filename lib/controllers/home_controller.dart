// lib/controllers/home_controller.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_atencion_ciudadana/services/local_db.dart';
import 'package:app_atencion_ciudadana/widgets/alert_helper.dart';

class HomeController extends ChangeNotifier {
  List<Map<String, dynamic>> _allPendingRows = [];
  List<Map<String, dynamic>> _filteredRows = [];
  bool _isUploading = false;
  String _searchQuery = '';
  String _selectedFilter = 'todos'; //* 'todos', 'con_curp', 'sin_curp', 'con_nombre'

  //* Getters
  List<Map<String, dynamic>> get filteredRows => _filteredRows;
  bool get isUploading => _isUploading;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  
  bool get hasPending => _allPendingRows.isNotEmpty;
  bool get hasValidRows => _allPendingRows.any((row) => _isValidForUpload(row));
  int get totalRows => _allPendingRows.length;
  int get validRows => _allPendingRows.where((row) => _isValidForUpload(row)).length;
  int get invalidRows => totalRows - validRows;

  Future<void> loadPending() async {
    final rows = await IncidenceLocalRepo.pending();
    _allPendingRows = rows;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredRows = _allPendingRows.where((row) {
      //* Aplicar filtro de búsqueda
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final curp = (row['curp']?.toString() ?? '').toLowerCase();
        final nombre = (row['nombre']?.toString() ?? '').toLowerCase();
        final colonia = (row['colonia']?.toString() ?? '').toLowerCase();
        final comentarios = (row['comentarios']?.toString() ?? '').toLowerCase();
        
        matchesSearch = curp.contains(query) ||
                       nombre.contains(query) ||
                       colonia.contains(query) ||
                       comentarios.contains(query);
      }

      //* Aplicar filtro de tipo
      bool matchesFilter = true;
      switch (_selectedFilter) {
        case 'con_curp':
          matchesFilter = _isValidForUpload(row);
          break;
        case 'sin_curp':
          matchesFilter = !_isValidForUpload(row);
          break;
        case 'todos':
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  bool _isValidForUpload(Map<String, dynamic> row) {
    final curp = row['curp']?.toString() ?? '';
    //* Validar que sea una CURP válida (18 caracteres alfanuméricos)
    //! Y que NO sea solo un nombre (no debe contener espacios)
    return curp.isNotEmpty && 
           curp.length == 18 && 
           RegExp(r'^[A-Z0-9]{18}$').hasMatch(curp) &&
           !curp.contains(' '); //* No debe contener espacios (nombres)
  }

  bool _isValidCurp(String curp) {
    //* Validación estricta de CURP
    if (curp.length != 18) return false;
    if (!RegExp(r'^[A-Z0-9]{18}$').hasMatch(curp)) return false;
    if (curp.contains(' ')) return false; //! No debe contener espacios
    
    //* Validación adicional: patrón básico de CURP
    final curpPattern = RegExp(r'^[A-Z][AEIOUX][A-Z]{2}[0-9]{6}[HM][A-Z]{5}[A-Z0-9][0-9]$');
    return curpPattern.hasMatch(curp);
  }

  Future<void> uploadJson() async {
    //* Filtrar solo registros con CURP válida (no nombres)
    final validRows = _allPendingRows.where((row) => _isValidForUpload(row)).toList();

    if (validRows.isEmpty) {
      AlertHelper.showAlert(
        'No hay registros con CURP válida para subir',
        type: AlertType.warning,
      );
      return;
    }

    _isUploading = true;
    notifyListeners();

    final payload = validRows.map((row) {
      return {
        'curp_solicitante': row['curp']?.toString() ?? '',
        'colonia': row['colonia']?.toString() ?? '',
        'direccion': row['direccion']?.toString() ?? '',
        'comentarios': row['comentarios']?.toString() ?? '',
        'tipo_solicitante': row['tipo_solicitante']?.toString() ?? '',
        'origen': row['origen']?.toString() ?? '',
        'motivo': row['motivo']?.toString() ?? '',
        'secretaria': row['secretaria']?.toString() ?? '',
        'tipo_incidencia': row['tipo_incidencia']?.toString() ?? '',
      };
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    
    if (token.isEmpty) {
      AlertHelper.showAlert('Token no encontrado. Inicia sesión.', type: AlertType.error);
      _isUploading = false;
      notifyListeners();
      return;
    }

    final uri = Uri.parse(
      'https://sanjuandelrio.gob.mx/tramites-sjr/Api/principal/cargar_indicadores_app',
    );

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      //? debugPrint('🌐 Status: ${response.statusCode}');
      //? debugPrint('📦 Body: ${response.body.trim()}');

      bool ok = false;
      String msg = 'Error en servidor';
      
      try {
        final json = jsonDecode(response.body);
        ok = json['success'] == true;
        msg = json['message']?.toString() ?? msg;
      } catch (_) {
        msg = response.body.trim();
      }

      if (ok) {
        //! Eliminar solo los registros válidos que se subieron
        for (var row in validRows) {
          await IncidenceLocalRepo.delete(row['id'] as int);
        }
        await loadPending();

        AlertHelper.showAlert(msg, type: AlertType.success);

        //* Mostrar advertencia si quedan registros sin CURP válida
        if (_allPendingRows.isNotEmpty) {
          AlertHelper.showAlert(
            'Algunos registros no se subieron porque no tienen CURP válida o solo tienen nombre',
            type: AlertType.warning,
          );
        }
      } else {
        AlertHelper.showAlert(msg, type: AlertType.error);
      }
    } catch (e) {
      AlertHelper.showAlert('Error de red: Revisa tu conexión a internet', type: AlertType.error);
      //? debugPrint('🚨 Upload error: $e');
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> updateCurp(int id, String newCurp) async {
    if (newCurp.isEmpty) {
      AlertHelper.showAlert('La CURP no puede estar vacía', type: AlertType.error);
      return;
    }

    if (!_isValidCurp(newCurp)) {
      AlertHelper.showAlert(
        'Formato de CURP inválido. Debe ser una CURP válida de 18 caracteres sin espacios',
        type: AlertType.error,
      );
      return;
    }

    try {
      await IncidenceLocalRepo.updateCurp(id, newCurp);
      await loadPending();
      AlertHelper.showAlert('CURP actualizada correctamente', type: AlertType.success);
    } catch (e) {
      AlertHelper.showAlert('Error al actualizar', type: AlertType.error);
    }
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    Navigator.pushReplacementNamed(context, '/auth');
    AlertHelper.showAlert('Sesión cerrada correctamente', type: AlertType.success);
  }

  String getRecordStatus(Map<String, dynamic> row) {
    if (_isValidForUpload(row)) {
      return 'LISTO PARA SUBIR';
    } else if ((row['nombre']?.toString() ?? '').isNotEmpty) {
      return 'SOLO TIENE NOMBRE';
    } else {
      return 'SIN IDENTIFICACIÓN';
    }
  }

  Color getRecordStatusColor(Map<String, dynamic> row) {
    if (_isValidForUpload(row)) {
      return const Color(0xFF2E7D32); //* Verde
    } else if ((row['nombre']?.toString() ?? '').isNotEmpty) {
      return const Color(0xFFE65100); //todo: Naranja
    } else {
      return const Color(0xFFD32F2F); //! Rojo
    }
  }

  List<String> getFilterOptions() {
    return [
      'todos',
      'con_curp',
      'sin_curp', 
    ];
  }

  String getFilterLabel(String filter) {
    switch (filter) {
      case 'todos':
        return 'Todos ($totalRows)';
      case 'con_curp':
        return 'Con CURP válida ($validRows)';
      case 'sin_curp':
        return 'Sin CURP ($invalidRows)';
      default:
        return filter;
    }
  }
}