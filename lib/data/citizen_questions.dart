// lib/data/citizen_questions.dart

import 'package:app_atencion_ciudadana/data/citizen_options.dart';
import 'package:app_atencion_ciudadana/data/menu_options.dart';
import 'package:app_atencion_ciudadana/utils/curp_validator.dart';
import 'package:app_atencion_ciudadana/utils/citizen_voice_utils.dart';

class CitizenQuestions {
  //? ===========================================================
  //? PREGUNTAS
  //? ===========================================================
  static List<Map<String, dynamic>> getQuestions() {
    return [
      {
        'field': 'nombre',
        'question':
            'Para comenzar con su registro, por favor dígame su nombre sin apellidos.',
        'options': null,
        'skipOption': false,
        'validator': (String value) {
          if (value.trim().length < 2) {
            return 'El nombre debe tener al menos 2 caracteres';
          }
          return null;
        },
        'isConditional': false,
      },
      {
        'field': 'primer_apellido',
        'question': 'Ahora dígame su primer apellido.',
        'options': null,
        'skipOption': false,
        'validator': (String value) {
          if (value.trim().length < 2) {
            return 'El apellido debe tener al menos 2 caracteres';
          }
          return null;
        },
        'isConditional': false,
      },
      {
        'field': 'segundo_apellido',
        'question':
            'Por favor dígame su segundo apellido. Si no tiene segundo apellido, puede decir "omitir".',
        'options': null,
        'skipOption': true,
        'validator': null,
        'isConditional': false,
      },
      {
        'field': 'curp_ciudadano',
        'question':
          'Para comenzar, por favor dígame su CURP completa, puede pausar entre cada letra y número. Si no la conoce, diga "OMITIR".',
        'options': null,
        'skipOption': true,
        'validator': CurpValidator.validate,
        'isConditional': false,
      },
      {
        'field': 'fecha_nacimiento',
        'question':
            'Dígame su fecha de nacimiento en formato día, mes y año. Por ejemplo: "15 de marzo de 1985".',
        'options': null,
        'skipOption': false,
        'validator': (String value) {
          if (value.trim().length < 8) {
            return 'Por favor proporcione una fecha válida';
          }
          return null;
        },
        'isConditional': false,
      },
      {
        'field': 'sexo',
        'question': 'Indique su sexo',
        'options': CitizenOptions.sexos
            .map((s) => {'value': s.value, 'label': s.label})
            .toList(),
        'skipOption': false,
        'validator': null,
        'isConditional': false,
      },
      {
        'field': 'estado',
        'question':
            'Dígame el estado donde nació. ${CitizenVoiceUtils.generateOptionsText(CitizenOptions.estados, 'estado')}',
        'options': CitizenOptions.estados,
        'skipOption': false,
        'validator': null,
        'isConditional': false,
      },
      {
        'field': 'telefono',
        'question':
            'Por favor proporcione su número de teléfono, dígalo dígito por dígito.',
        'options': null,
        'skipOption': false,
        'validator': (String value) {
          final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
          if (numbers.length < 10) {
            return 'El teléfono debe tener al menos 10 dígitos';
          }
          if (numbers.length > 13) {
            return 'El teléfono no puede tener más de 13 dígitos';
          }
          return null;
        },
        'isConditional': false,
      },
      {
        'field': 'email',
        'question':
            'Si tiene correo electrónico, por favor dígalo letra por letra, mencionando claramente el símbolo "arroba" y el punto. Si no tiene, puede decir "omitir".',
        'options': null,
        'skipOption': true,
        'validator': (String value) {
          final cleaned = value.replaceAll(' ', '');
          if (!cleaned.contains('@') || !cleaned.contains('.')) {
            return 'El correo debe contener arroba y punto';
          }
          return null;
        },
        'isConditional': false,
      },
      {
        'field': 'asentamiento',
        'question':
            'Dígame el nombre de su colonia o asentamiento donde vive.',
        'options': MenuOptions.colonias
            .map((c) => {'value': c, 'label': c})
            .toList(),
        'skipOption': false,
        'validator': (String value) {
          if (value.trim().length < 3) {
            return 'El asentamiento debe tener al menos 3 caracteres';
          }
          if (!MenuOptions.colonias
              .map((c) => c.toUpperCase())
              .contains(value.trim().toUpperCase())) {
            return 'Debe seleccionar una colonia válida de la lista';
          }
          return null;
        },
        'isConditional': false,
      },
      {
        'field': 'calle',
        'question': 'Indique el nombre de la calle donde vive.',
        'options': null,
        'skipOption': false,
        'validator': (String value) {
          if (value.trim().length < 3) {
            return 'La calle debe tener al menos 3 caracteres';
          }
          return null;
        },
        'isConditional': false,
      },
      {
        'field': 'numero_exterior',
        'question':
            'Dígame el número exterior de su domicilio. Si no tiene, diga "sin número".',
        'options': null,
        'skipOption': false,
        'validator': (String value) {
          final v = value.trim();
          if (v.isEmpty) return 'El número exterior es requerido';

          //* Acepta "sin número" / "s/n" / "sn"
          if (_isSinNumero(v)) return null;

          //* Solo dígitos
          if (RegExp(r'^\d+$').hasMatch(v)) return null;

          //* Alfanumérico típico de direcciones (12B, A-3, 4/2, etc.)
          if (RegExp(r'^[0-9A-Za-z\s\-/]+$').hasMatch(v)) return null;

          return 'Número exterior inválido';
        },
        'isConditional': false,
      },
      {
        'field': 'numero_interior',
        'question':
            'Si tiene número interior, departamento o letra, por favor dígalo. Si no tiene, puede decir "omitir" o "sin número".',
        'options': null,
        'skipOption': true,
        'validator': null,
        'isConditional': false,
      },
      {
        'field': 'codigo_postal',
        'question': 'Por último, dígame su código postal, son 5 números.',
        'options': null,
        'skipOption': false,
        'validator': (String value) {
          final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
          if (numbers.length != 5) {
            return 'El código postal debe tener exactamente 5 números';
          }
          return null;
        },
        'isConditional': false,
      },
      {
        'field': 'password',
        'question':
            'Para finalizar, cree una contraseña para su cuenta. Debe tener al menos 8 caracteres. Incluya letras, números y un símbolo.',
        'options': null,
        'skipOption': false,
        'validator': (String value) {
          // Validamos usando la contraseña SIN espacios
          final cleaned = value.replaceAll(RegExp(r'\s+'), '');

          if (cleaned.length < 8) {
            return 'La contraseña debe tener al menos 8 caracteres';
          }

          // Recomendado: exigir combinación de tipos
          final hasLetter = RegExp(r'[A-Za-z]').hasMatch(cleaned);
          final hasDigit  = RegExp(r'\d').hasMatch(cleaned);
          final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(cleaned);

          if (!(hasLetter && hasDigit && hasSymbol)) {
            return 'Incluya letras, números y un símbolo';
          }

          return null;
        },
        'isConditional': false,
      },
    ];
  }

  //? ===========================================================
  //? ETIQUETAS
  //? ===========================================================
  static Map<String, String> getFieldLabels() {
    return {
      'nombre': 'Nombre',
      'primer_apellido': 'Primer Apellido',
      'segundo_apellido': 'Segundo Apellido',
      'curp_ciudadano': 'CURP',
      'fecha_nacimiento': 'Fecha de Nacimiento',
      'password': 'Contraseña',
      'sexo': 'Sexo',
      'estado': 'Estado de Nacimiento',
      'telefono': 'Teléfono',
      'email': 'Correo Electrónico',
      'asentamiento': 'Colonia/Asentamiento',
      'calle': 'Calle',
      'numero_exterior': 'Número Exterior',
      'numero_interior': 'Número Interior',
      'codigo_postal': 'Código Postal',
    };
  }

  //? ===========================================================
  //? NAVEGACIÓN DE PREGUNTAS
  //? ===========================================================
  static int getNextQuestionIndex(
    List<Map<String, dynamic>> questions,
    int currentIndex,
    Map<String, dynamic> formData,
  ) {
    if (currentIndex < 0) currentIndex = 0;
    if (currentIndex >= questions.length) return questions.length;

    final curr = questions[currentIndex];
    final String field = (curr['field'] ?? '').toString();
    final bool skipOption =
        (curr['skipOption'] is bool) ? curr['skipOption'] as bool : false;

    final dynamic raw = formData[field];
    final String value = (raw == null) ? '' : raw.toString().trim();

    final prevSkipMap = formData['__skipped__'];
    final bool wasSkippedBefore =
        (prevSkipMap is Map && prevSkipMap[field] == true);

    final bool saysSkipNow = _wantsToSkip(field, value, skipOption);
    final bool wantsSkip = wasSkippedBefore || saysSkipNow;

    if (wantsSkip) {
      _markFieldAsSkipped(formData, field);
    }

    if (!wantsSkip && value.isEmpty) {
      return currentIndex;
    }

    final validator = curr['validator'];
    if (!wantsSkip && validator is String? Function(String)) {
      final String? err = validator(value);
      if (err != null && err.isNotEmpty) {
        return currentIndex;
      }
    }

    for (int i = currentIndex + 1; i < questions.length; i++) {
      final q = questions[i];
      final Object? flag = q['isConditional'];
      final bool isConditional = flag is bool ? flag : false;

      if (!isConditional) return i;

      final conditionRaw = q['condition'];
      if (conditionRaw is bool Function(Map<String, dynamic>)) {
        if (conditionRaw(formData)) return i;
      }
    }

    return questions.length;
  }

  static int getTotalValidQuestions(
    List<Map<String, dynamic>> questions,
    Map<String, dynamic> formData,
  ) {
    int count = 0;
    for (final q in questions) {
      final Object? flag = q['isConditional'];
      final bool isConditional = flag is bool ? flag : false;

      if (!isConditional) {
        count++;
      } else {
        final conditionRaw = q['condition'];
        if (conditionRaw is bool Function(Map<String, dynamic>)) {
          if (conditionRaw(formData)) count++;
        }
      }
    }
    return count;
  }

  static int getCurrentValidQuestionIndex(
    List<Map<String, dynamic>> questions,
    int currentIndex,
    Map<String, dynamic> formData,
  ) {
    int count = 0;
    for (int i = 0; i <= currentIndex && i < questions.length; i++) {
      final q = questions[i];
      final Object? flag = q['isConditional'];
      final bool isConditional = flag is bool ? flag : false;

      if (!isConditional) {
        count++;
      } else {
        final conditionRaw = q['condition'];
        if (conditionRaw is bool Function(Map<String, dynamic>)) {
          if (conditionRaw(formData)) count++;
        }
      }
    }
    return count;
  }

  //? ===========================================================
  //? VALIDACIONES GLOBALES (requeridos)
  //? ===========================================================
  static String? validateRequiredFields(Map<String, dynamic> formData) {
    final requiredFields = [
      'nombre',
      'primer_apellido',
      'fecha_nacimiento',
      'sexo',
      'estado',
      'telefono',
      'asentamiento',
      'calle',
      'numero_exterior',
      'codigo_postal',
      'password',
    ];

    for (final field in requiredFields) {
      final value = formData[field]?.toString().trim();
      if (value == null || value.isEmpty) {
        final label = getFieldLabels()[field] ?? field;
        return 'Falta el campo requerido: $label';
      }
    }

    final nombre = formData['nombre']?.toString().trim();
    final pApe = formData['primer_apellido']?.toString().trim();
    if ((nombre == null || nombre.isEmpty) ||
        (pApe == null || pApe.isEmpty)) {
      return 'Debe proporcionar al menos su nombre y primer apellido';
    }
    return null;
  }

  //? ===========================================================
  //? GENERADORES
  //? ===========================================================
  static String generateFullName(Map<String, dynamic> formData) {
    final nombre = formData['nombre']?.toString().trim() ?? '';
    final p1 = formData['primer_apellido']?.toString().trim() ?? '';
    final p2 = formData['segundo_apellido']?.toString().trim() ?? '';
    return [nombre, p1, p2].where((s) => s.isNotEmpty).join(' ').trim();
  }

  //? ===========================================================
  //? PREPARACIÓN PARA BD
  //? ===========================================================
  static Map<String, dynamic> prepareDataForDatabase(
    Map<String, dynamic> formData,
  ) {
    final prepared = Map<String, dynamic>.from(formData);

    //* Normaliza omisiones: si el usuario dijo "omitir" o está marcado como omitido
    final skipped = prepared['__skipped__'];
    bool isSkipped(String f) => (skipped is Map && skipped[f] == true);

    //! Eliminar si se omitieron (pero YA NO eliminamos numero_interior: lo pondremos como SN)
    for (final f in [
      'segundo_apellido',
      'curp_ciudadano',
      'email',
    ]) {
      final v = prepared[f];
      if (v != null) {
        final saidSkip = _wantsToSkip(f, v.toString(), true);
        if (saidSkip || isSkipped(f)) {
          prepared.remove(f);
        }
      } else if (isSkipped(f)) {
        prepared.remove(f);
      }
    }

    //* Nombre completo → MAYÚSCULAS sin acentos
    prepared['nombre_completo'] =
        _removeDiacritics(generateFullName(prepared).toUpperCase());

    //* Teléfono / CP → solo dígitos
    if (prepared['telefono'] != null) {
      prepared['telefono'] =
          prepared['telefono'].toString().replaceAll(RegExp(r'[^0-9]'), '');
    }
    if (prepared['codigo_postal'] != null) {
      prepared['codigo_postal'] =
          prepared['codigo_postal'].toString().replaceAll(RegExp(r'[^0-9]'), '');
    }

    //* Email → sin espacios, minúsculas
    if (prepared['email'] != null &&
        prepared['email'].toString().trim().isNotEmpty) {
      prepared['email'] =
          prepared['email'].toString().replaceAll(' ', '').toLowerCase().trim();
    }

    //* Campos texto → MAYÚSCULAS sin acentos (excepto email y password)
    final textFieldsUpper = <String>[
      'nombre',
      'primer_apellido',
      'segundo_apellido',
      'asentamiento',
      'calle',
      'curp_ciudadano',
      'estado',
      'sexo',
    ];
    for (final f in textFieldsUpper) {
      if (prepared[f] != null) {
        prepared[f] =
            _removeDiacritics(prepared[f].toString().trim().toUpperCase());
      }
    }

    //* CURP: quitar espacios internos y limitar a 18
    if (prepared['curp_ciudadano'] != null) {
      prepared['curp_ciudadano'] = _removeDiacritics(
        prepared['curp_ciudadano']
            .toString()
            .replaceAll(' ', '')
            .toUpperCase(),
      );
      if ((prepared['curp_ciudadano'] as String).length > 18) {
        prepared['curp_ciudadano'] =
            (prepared['curp_ciudadano'] as String).substring(0, 18);
      }
    }

    //* "Sin número" → SN
    //* - Exterior: si dijeron “sin número” lo normalizamos a SN.
    if (prepared['numero_exterior'] != null &&
        _isSinNumero(prepared['numero_exterior'].toString())) {
      prepared['numero_exterior'] = 'SN';
    }

    //* - Interior: si lo omitieron o dijeron “sin número”, guardamos SN (no lo eliminamos)
    if (isSkipped('numero_interior') ||
        (prepared['numero_interior'] != null &&
            _isSinNumero(prepared['numero_interior'].toString())) ||
        (prepared['numero_interior'] != null &&
            prepared['numero_interior'].toString().trim().isEmpty)) {
      prepared['numero_interior'] = 'SN';
    }

    //* Números exterior/interior: si son solo dígitos → int; si no, texto en MAYÚSC.
    for (final f in ['numero_exterior', 'numero_interior']) {
      if (prepared[f] != null) {
        final raw = prepared[f].toString().trim();
        if (raw.isEmpty) {
          //* Para interior ya lo cubrimos (SN); si exterior llega vacío, lo quitamos.
          if (f == 'numero_exterior') prepared.remove(f);
          continue;
        }
        if (RegExp(r'^\d+$').hasMatch(raw)) {
          prepared[f] = int.tryParse(raw);
        } else {
          prepared[f] = _removeDiacritics(raw.toUpperCase());
        }
      }
    }

    //* Password → sin espacios (no se cambia a mayúsculas)
    if (prepared['password'] != null &&
        prepared['password'].toString().isNotEmpty) {
      prepared['password'] =
          prepared['password'].toString().replaceAll(RegExp(r'\s+'), '');
    }
    return prepared;
  }

  //? ===========================================================
  //? HELPERS
  //? ===========================================================

  //* Marca un campo como omitido y limpia su valor para evitar revalidaciones/re-preguntas.
  static void _markFieldAsSkipped(Map<String, dynamic> formData, String field) {
    if (formData.containsKey(field)) {
      formData.remove(field);
    }
    final Map<String, bool> skipMap = <String, bool>{};
    final existing = formData['__skipped__'];
    if (existing is Map) {
      existing.forEach((k, v) {
        if (k is String && v is bool) skipMap[k] = v;
      });
    }
    skipMap[field] = true;
    formData['__skipped__'] = skipMap;
  }

  static bool _wantsToSkip(String field, String value, bool skipOption) {
    if (!skipOption) return false;
    final s = _normalizeForSkip(value);
    if (s.isEmpty) return false;

    final skipRe = RegExp(
        r'(^|\s)(omitir|omite|omito|omitelo|omitela|skip|saltar|salta|saltarlo|saltalo|saltala|ninguno|ninguna|no aplica|na|n a)($|\s)');
    if (skipRe.hasMatch(s)) return true;

    if (s.contains('no tengo') ||
        s.contains('no cuento') ||
        s.contains('no aplica') ||
        s.contains('no se') ||
        s.contains('no la se') ||
        s.contains('desconozco') ||
        s.startsWith('sin ')) {
      return true;
    }

    switch (field) {
      case 'segundo_apellido':
        if (s.contains('sin segundo apellido') ||
            s.contains('no tengo segundo apellido') ||
            s == 'sin apellido' ||
            s == 'sin') {
          return true;
        }
        break;
      case 'numero_interior':
        if (s.contains('sin interior') ||
            s.contains('no tengo numero interior') ||
            s.contains('no interior')) {
          return true;
        }
        break;
      case 'email':
        if (s.contains('no tengo correo') ||
            s.contains('no uso correo') ||
            s.contains('no tengo email') ||
            s.contains('no tengo e mail')) {
          return true;
        }
        break;
      case 'curp_ciudadano':
        if (s.contains('no tengo curp') ||
            s.contains('no me la se') ||
            s.contains('no la se') ||
            s.contains('no la recuerdo') ||
            s.contains('no recuerdo curp') ||
            s.contains('no se curp')) {
          return true;
        }
        break;
    }
    return false;
  }

  //* Detecta “sin número” y variantes comunes (incluye s/n, sn, sin num, etc.)
  static bool _isSinNumero(String input) {
    final s = _normalizeForSkip(input);
    if (s.isEmpty) return false;

    if (s == 'sn' || s == 's n') return true;
    if (s.contains('sin numero') || s.contains('sin num')) return true;
    if (s.contains('no numero') || s.contains('no tengo numero')) return true;
    if (s.contains('s n')) return true;

    return false;
  }

  //* Normaliza para comparación: minúsculas, sin acentos, sin signos, espacios colapsados
  static String _normalizeForSkip(String v) {
    var s = v.toLowerCase().trim();
    s = _removeDiacritics(s);
    s = s.replaceAll(RegExp(r'[^\w\s/]'), ''); 
    s = s.replaceAll('/', '');                 
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static String _removeDiacritics(String input) {
    const Map<String, String> map = {
      'á': 'a', 'à': 'a','ä': 'a', 'â': 'a',
      'ã': 'a','å': 'a','Á': 'A','À': 'A','Ä': 'A','Â': 'A','Ã': 'A','Å': 'A',
      'é': 'e','è': 'e','ë': 'e','ê': 'e','É': 'E','È': 'E','Ë': 'E','Ê': 'E',
      'í': 'i','ì': 'i','ï': 'i','î': 'i','Í': 'I','Ì': 'I','Ï': 'I','Î': 'I',
      'ó': 'o','ò': 'o','ö': 'o','ô': 'o','õ': 'o','Ó': 'O','Ò': 'O','Ö': 'O','Ô': 'O','Õ': 'O',
      'ú': 'u','ù': 'u','ü': 'u','û': 'u','Ú': 'U','Ù': 'U','Ü': 'U','Û': 'U',
      'ñ': 'n','Ñ': 'N','ç': 'c','Ç': 'C',
    };

    var out = input;
    map.forEach((k, v) => out = out.replaceAll(k, v));
    return out;
  }
}
