// lib/utils/citizen_voice_utils.dart

// ignore_for_file: avoid_print

import 'package:app_atencion_ciudadana/data/citizen_options.dart';

class CitizenVoiceUtils {
  ///* Procesa la respuesta de voz específica para registro de ciudadanos
  static CitizenVoiceProcessResult processVoiceInput({
    required String transcribedText,
    required String fieldType,
    List<String>? options,
    bool allowSkip = false,
    String? Function(String)? validator,
  }) {
    //? print('\n=== PROCESANDO ENTRADA CIUDADANO ===');
    //? print('Texto transcrito: "$transcribedText"');
    //? print('Tipo de campo: $fieldType');

    if (transcribedText.isEmpty) {
      //? print('Texto vacío');
      return CitizenVoiceProcessResult.empty();
    }

    if (allowSkip && shouldSkip(transcribedText)) {
      //? print('Usuario eligió omitir');
      return CitizenVoiceProcessResult.skipped();
    }

    String cleanedText = cleanTranscribedText(transcribedText, fieldType);
    //? print('Texto limpiado: "$cleanedText"');

    //* Aplicar correcciones específicas por voz
    cleanedText = applyVoiceCorrections(cleanedText, fieldType);
    //? print('Texto corregido: "$cleanedText"');

    if (validator != null) {
      //? print('Ejecutando validador...');
      final validationError = validator(cleanedText);
      if (validationError != null) {
        //? print('❌ Error de validación: $validationError');
        return CitizenVoiceProcessResult.error(validationError);
      }
      //? print('✅ Validación exitosa');
    }

    String finalValue = cleanedText;

    //* Procesamiento específico por tipo de campo
    if (options != null && options.isNotEmpty) {
      //? print('Buscando coincidencia en ${options.length} opciones...');
      final matchedOption = findBestMatch(cleanedText, options);
      if (matchedOption != null) {
        //? print('✅ Opción encontrada: $matchedOption');
        finalValue = matchedOption;
      } else {
        //? print('⚠️ No se encontró coincidencia exacta');
        if (fieldType == 'sexo' || fieldType == 'estado') {
          return CitizenVoiceProcessResult.error(
            'No se reconoció esa opción. ${_getSuggestionText(fieldType, options)}',
          );
        }
      }
    }

    //* Post-procesamiento específico por campo
    finalValue = postProcessField(finalValue, fieldType);

    //? print('✅ Valor final: "$finalValue"');
    //? print('=====================================\n');
    return CitizenVoiceProcessResult.success(finalValue);
  }

  ///* Limpia el texto según el tipo de campo
  static String cleanTranscribedText(String text, String fieldType) {
    String cleaned = text.trim().toUpperCase();
    
    switch (fieldType) {
      case 'curp_ciudadano':
        cleaned = cleaned.replaceAll(' ', '');
        break;
      case 'telefono':
        //* Mantener solo números
        cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
        break;
      case 'codigo_postal':
        //* Mantener solo números
        cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
        break;
      case 'email':
        cleaned = cleaned.toLowerCase();
        break;
      case 'password':
        //* Para contraseña, mantener el texto original más limpio
        cleaned = text.trim();
        break;
      default:
        //* Para nombres y textos, capitalizar apropiadamente
        cleaned = _capitalizeWords(text.trim());
        break;
    }
    
    //? print('Texto limpio para $fieldType: "$cleaned"');
    return cleaned;
  }

  ///* Aplica correcciones específicas de reconocimiento de voz
  static String applyVoiceCorrections(String text, String fieldType) {
    String corrected = text;

    switch (fieldType) {
      case 'telefono':
      case 'codigo_postal':
        //* Convertir números dictados a dígitos
        for (final entry in CitizenOptions.voiceCorrections.entries) {
          if (RegExp(r'^\d$').hasMatch(entry.value)) {
            corrected = corrected.replaceAll(RegExp('\\b${entry.key}\\b', caseSensitive: false), entry.value);
          }
        }
        break;

      case 'email':
        //* Reemplazar palabras por símbolos de email
        corrected = corrected.replaceAll(RegExp('\\barroba\\b', caseSensitive: false), '@');
        corrected = corrected.replaceAll(RegExp('\\bpunto\\b', caseSensitive: false), '.');
        corrected = corrected.replaceAll(RegExp('\\bguion bajo\\b', caseSensitive: false), '_');
        corrected = corrected.replaceAll(RegExp('\\bguión bajo\\b', caseSensitive: false), '_');
        break;

      case 'sexo':
        //* Normalizar términos de sexo
        for (final entry in CitizenOptions.voiceCorrections.entries) {
          if (entry.value == 'Masculino' || entry.value == 'Femenino') {
            corrected = corrected.replaceAll(RegExp('\\b${entry.key}\\b', caseSensitive: false), entry.value);
          }
        }
        break;

      case 'estado':
        //* Corregir nombres de estados
        for (final entry in CitizenOptions.voiceCorrections.entries) {
          if (CitizenOptions.estados.contains(entry.value)) {
            corrected = corrected.replaceAll(RegExp('\\b${entry.key}\\b', caseSensitive: false), entry.value);
          }
        }
        break;
    }

    return corrected;
  }

  ///* Post-procesa el campo según su tipo específico
  static String postProcessField(String value, String fieldType) {
    switch (fieldType) {
      case 'telefono':
        //* Limpiar y formatear teléfono
        String phone = value.replaceAll(RegExp(r'[^0-9]'), '');
        if (phone.startsWith('52') && phone.length == 12) {
          phone = phone.substring(2); //! Remover código de país
        }
        return phone;

      case 'email':
        return _processEmail(value);

      case 'fecha_nacimiento':
        return _processDate(value);

      case 'nombre':
      case 'primer_apellido':
      case 'segundo_apellido':
      case 'asentamiento':
      case 'calle':
        return _capitalizeWords(value);

      default:
        return value;
    }
  }

  ///* Procesa y normaliza direcciones de email
  static String _processEmail(String email) {
    String processed = email.toLowerCase().trim();
    
    //! Remover espacios alrededor de @ y .
    processed = processed.replaceAll(RegExp(r'\s*@\s*'), '@');
    processed = processed.replaceAll(RegExp(r'\s*\.\s*'), '.');
    
    //* Intentar completar dominios comunes
    for (final domain in CitizenOptions.emailDomains) {
      final domainParts = domain.split('.');
      if (processed.contains(domainParts[0]) && !processed.contains(domain)) {
        processed = processed.replaceAll(domainParts[0], domain);
        break;
      }
    }
    
    return processed;
  }

  ///* Procesa fechas dictadas
  static String _processDate(String dateText) {
    String processed = dateText.toLowerCase();
    
    //* Mapear meses en español
    final months = {
      'enero': '01', 'febrero': '02', 'marzo': '03', 'abril': '04',
      'mayo': '05', 'junio': '06', 'julio': '07', 'agosto': '08',
      'septiembre': '09', 'octubre': '10', 'noviembre': '11', 'diciembre': '12'
    };
    
    for (final entry in months.entries) {
      processed = processed.replaceAll(entry.key, entry.value);
    }
    
    //* Extraer números para formato YYYY-MM-DD
    final numbers = RegExp(r'\d+').allMatches(processed).map((m) => m.group(0)!).toList();
    
    if (numbers.length >= 3) {
      String day = numbers[0].padLeft(2, '0');
      String month = numbers[1].padLeft(2, '0');
      String year = numbers[2];
      
      //* Ajustar año si es de 2 dígitos
      if (year.length == 2) {
        int yearInt = int.parse(year);
        year = yearInt > 30 ? '19$year' : '20$year';
      }
      
      return '$year-$month-$day';
    }
    
    return processed;
  }

  ///* Busca la mejor coincidencia en opciones
  static String? findBestMatch(String input, List<String> options) {
    //? print('\n--- BUSCANDO COINCIDENCIA CIUDADANO ---');
    //? print('Input: "$input"');

    final raw = input.trim();
    if (raw.isEmpty) {
      //? print('❌ Input vacío');
      return null;
    }

    final cleanInput = _normalizeBasic(raw);
    //? print('Input limpiado: "$cleanInput"');

    //* Coincidencia exacta
    for (final option in options) {
      if (_normalizeBasic(option).toLowerCase() == cleanInput.toLowerCase()) {
        //? print('✅ Coincidencia exacta: $option');
        return option;
      }
    }

    //* Coincidencia parcial
    for (final option in options) {
      final normalized = _normalizeBasic(option).toLowerCase();
      if (normalized.contains(cleanInput.toLowerCase()) || 
          cleanInput.toLowerCase().contains(normalized)) {
        //? print('✅ Coincidencia parcial: $option');
        return option;
      }
    }

    //? print('❌ No se encontró coincidencia');
    return null;
  }

  ///* Normalización básica de texto
  static String _normalizeBasic(String text) {
    String normalized = text.trim().toLowerCase();
    
    //! Remover acentos
    const accents = 'áéíóúüñ';
    const normal = 'aeiouun';
    
    for (int i = 0; i < accents.length; i++) {
      normalized = normalized.replaceAll(accents[i], normal[i]);
    }
    
    return normalized;
  }

  ///* Capitaliza palabras apropiadamente
  static String _capitalizeWords(String text) {
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  ///* Verifica si debe omitir el campo
  static bool shouldSkip(String text) {
    return text.toUpperCase().contains('OMITIR');
  }

  ///* Genera texto de opciones para lectura
  static String generateOptionsText(List<String> options, String fieldType) {
    switch (fieldType) {
      case 'sexo':
        return 'Las opciones son: ${options.join(" o ")}';
      
      case 'estado':
        return 'Por ejemplo: Querétaro, Jalisco, Ciudad de México, Nuevo León, entre otros';
      
      default:
        if (options.length <= 5) {
          return 'Las opciones son: ${options.join(", ")}';
        }
        return 'Algunas opciones son: ${options.take(5).join(", ")} y ${options.length - 5} más';
    }
  }

  ///* Obtiene texto de sugerencia para errores
  static String _getSuggestionText(String fieldType, List<String> options) {
    switch (fieldType) {
      case 'sexo':
        return 'Puede decir "masculino" o "femenino"';
      case 'estado':
        return 'Intente con el nombre completo del estado, por ejemplo "Querétaro" o "Jalisco"';
      default:
        return 'Intente con una opción similar a: ${options.take(3).join(", ")}';
    }
  }
}

///* Enums y clases de resultado
enum CitizenVoiceProcessStatus {
  success,
  error,
  skipped,
  empty,
}

class CitizenVoiceProcessResult {
  final CitizenVoiceProcessStatus status;
  final String? value;
  final String? errorMessage;

  CitizenVoiceProcessResult._({
    required this.status,
    this.value,
    this.errorMessage,
  });

  factory CitizenVoiceProcessResult.success(String value) {
    return CitizenVoiceProcessResult._(
      status: CitizenVoiceProcessStatus.success,
      value: value,
    );
  }

  factory CitizenVoiceProcessResult.error(String message) {
    return CitizenVoiceProcessResult._(
      status: CitizenVoiceProcessStatus.error,
      errorMessage: message,
    );
  }

  factory CitizenVoiceProcessResult.skipped() {
    return CitizenVoiceProcessResult._(status: CitizenVoiceProcessStatus.skipped);
  }

  factory CitizenVoiceProcessResult.empty() {
    return CitizenVoiceProcessResult._(status: CitizenVoiceProcessStatus.empty);
  }

  bool get isSuccess => status == CitizenVoiceProcessStatus.success;
  bool get isError => status == CitizenVoiceProcessStatus.error;
  bool get isSkipped => status == CitizenVoiceProcessStatus.skipped;
  bool get isEmpty => status == CitizenVoiceProcessStatus.empty;
}