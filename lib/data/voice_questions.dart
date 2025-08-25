// lib/data/voice_questions.dart

import 'package:app_atencion_ciudadana/data/menu_options.dart';
import 'package:app_atencion_ciudadana/utils/curp_validator.dart';
import 'package:app_atencion_ciudadana/utils/voice_utils.dart';

class VoiceQuestions {
  static List<Map<String, dynamic>> getQuestions() {
    return [
      {
        'field': 'curp',
        'question':
            'Para comenzar, por favor dígame su CURP completa, puede pausar entre cada letra y número. Son 18 caracteres en total. Si no la conoce, diga "OMITIR".',
        'options': null,
        'skipOption': true,
        'validator': CurpValidator.validate,
        'isConditional': false,
      },
      {
        'field': 'nombre',
        'question': 'Como no proporcionó su CURP, por favor dígame su nombre completo para identificarlo.',
        'options': null,
        'skipOption': false,
        'validator': null,
        'isConditional': true,
        'condition': (Map<String, dynamic> formData) {
          // Solo preguntar el nombre si no hay CURP
          return formData['curp'] == null || formData['curp']?.toString().isEmpty == true;
        },
      },
      {
        'field': 'colonia',
        'question': '¿En qué colonia se encuentra la incidencia? ${VoiceUtils.generateOptionsText(MenuOptions.colonias, 'colonia')}',
        'options': MenuOptions.colonias,
        'skipOption': false,
        'validator': null,
        'isConditional': false,
      },
      {
        'field': 'direccion',
        'question': 'Por favor, describa la dirección con detalles.',
        'options': null,
        'skipOption': false,
        'validator': null,
        'isConditional': false,
      },
      {
        'field': 'tipo_incidencia',
        'question': '¿Qué tipo de problema está reportando?',
        'options': null,
        'skipOption': false,
        'validator': null,
        'isConditional': false,
      },
      {
        'field': 'comentarios',
        'question': 'Cuéntenos más detalles sobre la incidencia.',
        'options': null,
        'skipOption': false,
        'validator': null,
        'isConditional': false,
      },
      {
        'field': 'tipo_solicitante',
        'question':
            '¿Qué tipo de solicitante es usted? ${VoiceUtils.generateOptionsText(MenuOptions.tiposSolicitante, 'tipo_solicitante')}',
        'options': MenuOptions.tiposSolicitante,
        'skipOption': false,
        'validator': null,
        'isConditional': false,
      },
      {
        'field': 'origen',
        'question':
            '¿Cómo nos contactó? ${VoiceUtils.generateOptionsText(MenuOptions.origenes, 'origen')}',
        'options': MenuOptions.origenes,
        'skipOption': false,
        'validator': null,
        'isConditional': false,
      },
      {
        'field': 'motivo',
        'question':
            '¿Cuál es el motivo de su contacto? ${VoiceUtils.generateOptionsText(MenuOptions.motivos, 'motivo')}',
        'options': MenuOptions.motivos,
        'skipOption': false,
        'validator': null,
        'isConditional': false,
      },
      {
        'field': 'secretaria',
        'question': '¿Qué secretaría debería encargarse de esto? ${VoiceUtils.generateOptionsText(MenuOptions.secretarias, 'secretaria')}',
        'options': MenuOptions.secretarias,
        'skipOption': false,
        'validator': null,
        'isConditional': false,
      },
    ];
  }

  static Map<String, String> getFieldLabels() {
    return {
      'curp': 'CURP',
      'nombre': 'Nombre Completo', 
      'colonia': 'Colonia',
      'direccion': 'Dirección',
      'tipo_incidencia': 'Tipo de Incidencia',
      'comentarios': 'Comentarios',
      'tipo_solicitante': 'Tipo de Solicitante',
      'origen': 'Origen',
      'motivo': 'Motivo',
      'secretaria': 'Secretaría',
    };
  }

  /// Obtiene la siguiente pregunta válida basada en las condiciones
  static int getNextQuestionIndex(List<Map<String, dynamic>> questions, int currentIndex, Map<String, dynamic> formData) {
    for (int i = currentIndex + 1; i < questions.length; i++) {
      final question = questions[i];
      final isConditional = question['isConditional'] ?? false;
      
      if (!isConditional) {
        return i; // Pregunta incondicional, siempre se hace
      }
      
      // Verificar condición para preguntas condicionales
      final condition = question['condition'] as bool Function(Map<String, dynamic>)?;
      if (condition != null && condition(formData)) {
        return i; // La condición se cumple, hacer esta pregunta
      }
      
      // La condición no se cumple, continuar buscando
    }
    
    return questions.length; // No hay más preguntas válidas
  }

  /// Valida que el usuario tenga al menos CURP o nombre como identificador
  static String? validateIdentification(Map<String, dynamic> formData) {
    final curp = formData['curp']?.toString().trim();
    final nombre = formData['nombre']?.toString().trim();
    
    // Debe tener al menos uno de los dos
    if ((curp == null || curp.isEmpty) && (nombre == null || nombre.isEmpty)) {
      return 'Debe proporcionar al menos su CURP o nombre completo para poder procesar su solicitud.';
    }
    
    return null; // Validación exitosa
  }

  /// Cuenta el total de preguntas válidas según el contexto
  static int getTotalValidQuestions(List<Map<String, dynamic>> questions, Map<String, dynamic> formData) {
    int count = 0;
    
    for (final question in questions) {
      final isConditional = question['isConditional'] ?? false;
      
      if (!isConditional) {
        count++; // Pregunta incondicional, siempre cuenta
      } else {
        // Verificar condición para preguntas condicionales
        final condition = question['condition'] as bool Function(Map<String, dynamic>)?;
        if (condition != null && condition(formData)) {
          count++; // La condición se cumple, contar esta pregunta
        }
      }
    }
    
    return count;
  }

  /// Obtiene el índice de la pregunta actual dentro de las preguntas válidas
  static int getCurrentValidQuestionIndex(List<Map<String, dynamic>> questions, int currentIndex, Map<String, dynamic> formData) {
    int count = 0;
    
    for (int i = 0; i <= currentIndex && i < questions.length; i++) {
      final question = questions[i];
      final isConditional = question['isConditional'] ?? false;
      
      if (!isConditional) {
        count++; // Pregunta incondicional, siempre cuenta
      } else {
        // Verificar condición para preguntas condicionales
        final condition = question['condition'] as bool Function(Map<String, dynamic>)?;
        if (condition != null && condition(formData)) {
          count++; // La condición se cumple, contar esta pregunta
        }
      }
    }
    
    return count;
  }
}