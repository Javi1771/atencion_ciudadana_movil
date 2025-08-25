// lib/utils/voice_utils.dart
// ignore_for_file: avoid_print

class VoiceUtils {
  /// Busca la mejor coincidencia entre un input y una lista de opciones
  static String? findBestMatch(String input, List<String> options) {
    print('\n--- BUSCANDO COINCIDENCIA ---');
    print('Input: "$input"');
    
    final cleanInput = input.toLowerCase().trim();
    print('Input limpiado: "$cleanInput"');

    // 1. Búsqueda exacta
    for (final option in options) {
      final cleanOption = option.toLowerCase();
      if (cleanOption == cleanInput) {
        print('✅ Coincidencia exacta: $option');
        return option;
      }
    }

    // 2. Búsqueda por palabras clave en colonias
    if (options.length > 50) { // Probablemente son colonias
      final match = _findColoniaMatch(cleanInput, options);
      if (match != null) {
        print('✅ Coincidencia en colonia: $match');
        return match;
      }
    }

    // 3. Búsqueda por palabras clave en secretarías
    if (options.any((opt) => opt.contains('SECRETARIA'))) {
      final match = _findSecretariaMatch(cleanInput, options);
      if (match != null) {
        print('✅ Coincidencia en secretaría: $match');
        return match;
      }
    }

    // 4. Búsqueda por contención parcial
    for (final option in options) {
      final cleanOption = option.toLowerCase();
      
      // Si el input contiene parte de la opción
      if (cleanInput.contains(cleanOption) || cleanOption.contains(cleanInput)) {
        print('✅ Coincidencia parcial: $option');
        return option;
      }
      
      // Búsqueda por palabras individuales
      final inputWords = cleanInput.split(' ');
      final optionWords = cleanOption.split(' ');
      
      int matches = 0;
      for (final inputWord in inputWords) {
        for (final optionWord in optionWords) {
          if (inputWord.length > 3 && optionWord.contains(inputWord)) {
            matches++;
            break;
          }
        }
      }
      
      // Si coincide más del 50% de las palabras
      if (matches > 0 && matches >= (inputWords.length * 0.5)) {
        print('✅ Coincidencia por palabras: $option');
        return option;
      }
    }

    print('❌ No se encontró coincidencia');
    return null;
  }

  /// Busca coincidencias específicas para colonias
  static String? _findColoniaMatch(String input, List<String> colonias) {
    // Diccionario de palabras clave para colonias comunes
    final Map<String, List<String>> keyWords = {
      'centro': ['Centro'],
      'santa': ['Santa Cruz Escandón', 'Santa Cruz Nieto', 'Santa Rita', 'Santa Elena', 'Santa Fe', 'Santa Isabel', 'Santa Lucia', 'Santa Matilde', 'Santa Anita', 'Santa Bárbara de la Cueva', 'Santa Rosa Xajay'],
      'san': ['San Antonio la Labor', 'San Antonio Zatlauco', 'San Cayetano', 'San Francisco', 'San Germán', 'San Gil', 'San Isidro', 'San Isidro Labrador', 'San Javier', 'San José', 'San José Galindo', 'San Juan Bosco', 'San Juan de Dios', 'San Martín', 'San Miguel Arcángel', 'San Miguel Galindo', 'San Pablo Potrerillos', 'San Pedro 1a Sección', 'San Pedro 2a. Sección', 'San Pedro 3a Sección', 'San Pedro Ahuacatlán', 'San Rafael', 'San Sebastián de las Barrancas', 'San Sebastián de las Barrancas Norte', 'San Sebastián de las Barrancas Sur'],
      'juarez': ['Benito Juárez', 'Juárez'],
      'villa': ['Francisco Villa', 'Villa de las Haciendas', 'Villa las Flores', 'Villa los Cipreses', 'Villa los Olivos'],
      'lomas': ['Lomas de Guadalupe', 'Lomas de la Estancia', 'Lomas del Pedregal', 'Lomas de San Juan', 'Lomas de San Juan 2da. Sección'],
      'jardines': ['Jardines Banthi', 'Jardines del Pedregal', 'Jardines del Valle', 'Jardines del Valle II', 'Jardines del Valle III', 'Jardines de San Juan'],
      'villas': ['Villas Corregidora', 'Villas del Centro', 'Villas del Parque', 'Villas del Pedregal', 'Villas del Pedregal 1a. Sección', 'Villas del Puente', 'Villas del Sol', 'Villas de San Isidro', 'Villas de San José', 'Villas de San Juan'],
      'infonavit': ['INFONAVIT Fatima', 'INFONAVIT la Paz', 'INFONAVIT los Fresnos', 'INFONAVIT Pedregoso', 'INFONAVIT Pedregoso 3a Sección', 'INFONAVIT San Cayetano', 'INFONAVIT San Isidro'],
    };

    // Buscar por palabras clave
    for (final key in keyWords.keys) {
      if (input.contains(key)) {
        final candidates = keyWords[key]!;
        // Si solo hay una opción, devolverla
        if (candidates.length == 1) {
          return candidates.first;
        }
        // Si hay múltiples, buscar la más específica
        for (final candidate in candidates) {
          if (colonias.contains(candidate)) {
            final candidateLower = candidate.toLowerCase();
            if (candidateLower.contains(input) || input.contains(candidateLower.split(' ').first)) {
              return candidate;
            }
          }
        }
        // Devolver la primera coincidencia válida
        for (final candidate in candidates) {
          if (colonias.contains(candidate)) {
            return candidate;
          }
        }
      }
    }

    return null;
  }

  /// Busca coincidencias específicas para secretarías
  static String? _findSecretariaMatch(String input, List<String> secretarias) {
    final Map<String, String> keyWords = {
      'administracion': 'SECRETARIA DE ADMINISTRACION',
      'administración': 'SECRETARIA DE ADMINISTRACION',
      'agua': 'JUNTA DE AGUA POTABLE Y ALCANTARILLADO MUNICIPAL',
      'alcantarillado': 'JUNTA DE AGUA POTABLE Y ALCANTARILLADO MUNICIPAL',
      'agropecuario': 'SECRETARIA DE DESARROLLO AGROPECUARIO',
      'atencion': 'SECRETARIA DE CENTRO DE ATENCION MUNICIPAL',
      'atención': 'SECRETARIA DE CENTRO DE ATENCION MUNICIPAL',
      'ayuntamiento': 'SECRETARIA DEL AYUNTAMIENTO',
      'desarrollo': 'SECRETARIA DE DESARROLLO INTEGRAL Y ECONOMICO',
      'economico': 'SECRETARIA DE DESARROLLO INTEGRAL Y ECONOMICO',
      'económico': 'SECRETARIA DE DESARROLLO INTEGRAL Y ECONOMICO',
      'familia': 'DESARROLLO INTEGRAL DE LA FAMILIA',
      'finanzas': 'SECRETARIA DE FINANZAS',
      'gobierno': 'SECRETARIA DE GOBIERNO',
      'gabinete': 'JEFATURA DE GABINETE',
      'mujer': 'SECRETARIA DE LA MUJER',
      'obras': 'SECRETARIA DE OBRAS PUBLICAS Y DESARROLLO URBANO',
      'publicas': 'SECRETARIA DE OBRAS PUBLICAS Y DESARROLLO URBANO',
      'públicas': 'SECRETARIA DE OBRAS PUBLICAS Y DESARROLLO URBANO',
      'presidencia': 'JEFATURA DE LA OFICINA DE LA PRESIDENCIA MUNICIPAL',
      'particular': 'SECRETARIA PARTICULAR',
      'seguridad': 'SECRETARIA DE SEGURIDAD PUBLICA',
      'pública': 'SECRETARIA DE SEGURIDAD PUBLICA',
      'publica': 'SECRETARIA DE SEGURIDAD PUBLICA',
      'servicios': 'SECRETARIA DE SERVICIOS PUBLICOS MUNICIPALES',
      'social': 'SECRETARIA DE DESARROLLO SOCIAL',
      'control': 'SECRETARIA DEL ORGANO INTERNO DE CONTROL',
    };

    for (final key in keyWords.keys) {
      if (input.contains(key)) {
        return keyWords[key]!;
      }
    }

    return null;
  }

  /// Genera una lista de opciones más corta para leer en voz
  static String generateOptionsText(List<String> options, String fieldType) {
    if (fieldType == 'colonia') {
      return 'Puede mencionar el nombre de su colonia. Tengo registradas más de 300 colonias como Centro, San Juan, Santa Cruz, Lomas, Jardines, Villas, INFONAVIT, entre otras.';
    }
    
    if (fieldType == 'secretaria') {
      return 'Las principales secretarías son: Administración, Obras Públicas, Seguridad Pública, Desarrollo Social, Finanzas, Gobierno, Servicios Públicos, entre otras.';
    }

    // Para listas cortas, leer todas las opciones
    if (options.length <= 5) {
      return 'Las opciones son: ${options.join(", ")}';
    }

    return 'Las opciones disponibles son: ${options.take(5).join(", ")} y ${options.length - 5} opciones más.';
  }

  /// Limpia el texto transcrito según el tipo de campo
  static String cleanTranscribedText(String text, String fieldType) {
    String cleaned = text.trim().toUpperCase();
    
    // Para campos que requieren formato específico (como CURP), eliminar TODOS los espacios
    if (fieldType == 'curp') {
      cleaned = cleaned.replaceAll(' ', '');
      print('Texto sin espacios para $fieldType: "$cleaned"');
    }
    
    return cleaned;
  }

  /// Verifica si el texto contiene la palabra "OMITIR"
  static bool shouldSkip(String text) {
    return text.toUpperCase().contains('OMITIR');
  }

  /// Procesa la respuesta de voz y devuelve el resultado procesado
  static VoiceProcessResult processVoiceInput({
    required String transcribedText,
    required String fieldType,
    List<String>? options,
    bool allowSkip = false,
    String? Function(String)? validator,
  }) {
    print('\n=== PROCESANDO ENTRADA DE VOZ ===');
    print('Texto transcrito: "$transcribedText"');
    print('Tipo de campo: $fieldType');

    if (transcribedText.isEmpty) {
      print('Texto vacío');
      return VoiceProcessResult.empty();
    }

    // Verificar si debe omitirse
    if (allowSkip && shouldSkip(transcribedText)) {
      print('Usuario eligió omitir');
      return VoiceProcessResult.skipped();
    }

    // Limpiar el texto
    String cleanedText = cleanTranscribedText(transcribedText, fieldType);
    print('Texto limpiado: "$cleanedText"');

    // Validar si hay validador
    if (validator != null) {
      print('Ejecutando validador...');
      final validationError = validator(cleanedText);
      if (validationError != null) {
        print('❌ Error de validación: $validationError');
        return VoiceProcessResult.error(validationError);
      }
      print('✅ Validación exitosa');
    }

    String finalValue = cleanedText;

    // Buscar en opciones si las hay
    if (options != null && options.isNotEmpty) {
      print('Buscando coincidencia en ${options.length} opciones...');
      final matchedOption = findBestMatch(cleanedText, options);
      if (matchedOption != null) {
        print('✅ Opción encontrada: $matchedOption');
        finalValue = matchedOption;
      } else {
        print('⚠️ No se encontró coincidencia, usando texto original');
        // Para campos con opciones, sugerir re-intentar
        if (fieldType == 'colonia' || fieldType == 'secretaria') {
          return VoiceProcessResult.error(
            'No se encontró esa opción. ${_getSuggestionText(fieldType, options)}',
          );
        }
      }
    }

    print('✅ Valor final: "$finalValue"');
    print('=====================================\n');

    return VoiceProcessResult.success(finalValue);
  }

  static String _getSuggestionText(String fieldType, List<String> options) {
    switch (fieldType) {
      case 'colonia':
        return 'Puede decir solo el nombre principal como "Centro", "San Juan", "Santa Cruz", etc.';
      case 'secretaria':
        return 'Puede decir palabras clave como "Obras Públicas", "Seguridad", "Administración", etc.';
      default:
        return 'Intente con una opción similar a: ${options.take(3).join(", ")}';
    }
  }
}

/// Clase para representar el resultado del procesamiento de voz
class VoiceProcessResult {
  final VoiceProcessStatus status;
  final String? value;
  final String? errorMessage;

  VoiceProcessResult._({
    required this.status,
    this.value,
    this.errorMessage,
  });

  factory VoiceProcessResult.success(String value) {
    return VoiceProcessResult._(
      status: VoiceProcessStatus.success,
      value: value,
    );
  }

  factory VoiceProcessResult.error(String message) {
    return VoiceProcessResult._(
      status: VoiceProcessStatus.error,
      errorMessage: message,
    );
  }

  factory VoiceProcessResult.skipped() {
    return VoiceProcessResult._(
      status: VoiceProcessStatus.skipped,
    );
  }

  factory VoiceProcessResult.empty() {
    return VoiceProcessResult._(
      status: VoiceProcessStatus.empty,
    );
  }

  bool get isSuccess => status == VoiceProcessStatus.success;
  bool get isError => status == VoiceProcessStatus.error;
  bool get isSkipped => status == VoiceProcessStatus.skipped;
  bool get isEmpty => status == VoiceProcessStatus.empty;
}

enum VoiceProcessStatus {
  success,
  error,
  skipped,
  empty,
}