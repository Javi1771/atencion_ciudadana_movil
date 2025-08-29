// utils/voice_utils.dart
// ignore_for_file: avoid_print

class VoiceUtils {
  ///* Busca la mejor coincidencia entre un input y una lista de opciones (robusto/fonético).
  static String? findBestMatch(String input, List<String> options) {
    print('\n--- BUSCANDO COINCIDENCIA ---');
      print('Input: "$input"');

    final raw = input.trim();
    if (raw.isEmpty) {
        print('❌ Input vacío');
      return null;
    }

    final cleanInput = _normalizeBasic(raw);
      print('Input limpiado: "$cleanInput"');

    //? 0) Coincidencia exacta (ignorando mayúsculas/acentos)
    for (final option in options) {
      if (_normalizeBasic(option) == cleanInput) {
        print('✅ Coincidencia exacta (básica): $option');
        return option;
      }
    }

    //? 1) Coincidencia exacta agresiva (fonética/artículos)
    final inputAgg = _normalizeAggressive(cleanInput);
    for (final option in options) {
      if (_normalizeAggressive(_normalizeBasic(option)) == inputAgg) {
        print('✅ Coincidencia exacta (agresiva): $option');
        return option;
      }
    }

    //? 2) Heurísticas específicas (si aplican)
    //*    - Secretarías (palabras clave)
    if (options.any((opt) => opt.toUpperCase().contains('SECRETARIA'))) {
      final sec = _findSecretariaMatch(cleanInput, options);
      if (sec != null) {
        print('✅ Coincidencia en secretaría: $sec');
        return sec;
      }
    }
    //*    - Colonias (muchas opciones)
    if (options.length >= 50) {
      final col = _findColoniaMatch(cleanInput, options);
      if (col != null) {
        print('✅ Coincidencia en colonia (heurística): $col');
        return col;
      }
    }

    //? 3) Fuzzy matching global (Levenshtein + fonético + tokens)
    String? bestOption;
    double bestScore = -1.0;

    for (final option in options) {
      final oBasic = _normalizeBasic(option);
      final oAgg = _normalizeAggressive(oBasic);

      //* Distancias básicas y agresivas
      final distBasic = _levDistance(cleanInput, oBasic);
      final distAgg = _levDistance(inputAgg, oAgg);

      final maxLenBasic = cleanInput.length > oBasic.length ? cleanInput.length : oBasic.length;
      final maxLenAgg = inputAgg.length > oAgg.length ? inputAgg.length : oAgg.length;

      final simBasic = maxLenBasic == 0 ? 0.0 : 1.0 - (distBasic / maxLenBasic);
      final simAgg = maxLenAgg == 0 ? 0.0 : 1.0 - (distAgg / maxLenAgg);

      //* Similaridad por tokens (quita artículos y stopwords)
      final tokenSim = _tokenSimilarity(inputAgg, oAgg);

      //* Tomamos el mejor score de los tres
      final score = [simBasic, simAgg, tokenSim].reduce((a, b) => a > b ? a : b);

      if (score > bestScore) {
        bestScore = score;
        bestOption = option;
      }
    }

    //* Umbrales: si es suficientemente parecido, aceptamos
    //* - Score >= 0.82 funciona excelente para casos "CASADERO" ~ "CAZADERO"
    if (bestOption != null && bestScore >= 0.82) {
      print('✅ Coincidencia difusa: $bestOption (score: ${bestScore.toStringAsFixed(3)})');
      return bestOption;
    }

    //? 4) Contención parcial (fallback suave)
    for (final option in options) {
      final o = _normalizeBasic(option);
      if (cleanInput.contains(o) || o.contains(cleanInput)) {
        print('✅ Coincidencia por contención: $option');
        return option;
      }
    }

    print('❌ No se encontró coincidencia');
    return null;
  }

  ///* Busca coincidencias específicas para colonias (ahora con fuzzy interno sencillo).
  static String? _findColoniaMatch(String input, List<String> colonias) {
    //* Intento directo por palabras típicas (tu dicionario original puede quedarse)
    final Map<String, List<String>> keyWords = {
      'centro': ['Centro'],
      'santa': [
        'Santa Cruz Escandón', 'Santa Cruz Nieto', 'Santa Rita', 'Santa Elena',
        'Santa Fe', 'Santa Isabel', 'Santa Lucia', 'Santa Matilde', 'Santa Anita',
        'Santa Bárbara de la Cueva', 'Santa Rosa Xajay'
      ],
      'san': [
        'San Antonio la Labor', 'San Antonio Zatlauco', 'San Cayetano',
        'San Francisco', 'San Germán', 'San Gil', 'San Isidro',
        'San Isidro Labrador', 'San Javier', 'San José', 'San José Galindo',
        'San Juan Bosco', 'San Juan de Dios', 'San Martín', 'San Miguel Arcángel',
        'San Miguel Galindo', 'San Pablo Potrerillos', 'San Pedro 1a Sección',
        'San Pedro 2a. Sección', 'San Pedro 3a Sección', 'San Pedro Ahuacatlán',
        'San Rafael', 'San Sebastián de las Barrancas',
        'San Sebastián de las Barrancas Norte', 'San Sebastián de las Barrancas Sur'
      ],
      'juarez': ['Benito Juárez', 'Juárez'],
      'villa': ['Francisco Villa', 'Villa de las Haciendas', 'Villa las Flores', 'Villa los Cipreses', 'Villa los Olivos'],
      'lomas': ['Lomas de Guadalupe', 'Lomas de la Estancia', 'Lomas del Pedregal', 'Lomas de San Juan', 'Lomas de San Juan 2da. Sección'],
      'jardines': ['Jardines Banthi', 'Jardines del Pedregal', 'Jardines del Valle', 'Jardines del Valle II', 'Jardines del Valle III', 'Jardines de San Juan'],
      'villas': ['Villas Corregidora', 'Villas del Centro', 'Villas del Parque', 'Villas del Pedregal', 'Villas del Pedregal 1a. Sección', 'Villas del Puente', 'Villas del Sol', 'Villas de San Isidro', 'Villas de San José', 'Villas de San Juan'],
      'infonavit': ['INFONAVIT Fatima', 'INFONAVIT la Paz', 'INFONAVIT los Fresnos', 'INFONAVIT Pedregoso', 'INFONAVIT Pedregoso 3a Sección', 'INFONAVIT San Cayetano', 'INFONAVIT San Isidro'],
    };

    final inAgg = _normalizeAggressive(input);

    for (final key in keyWords.keys) {
      if (inAgg.contains(_normalizeAggressive(key))) {
        for (final candidate in keyWords[key]!) {
          if (colonias.contains(candidate)) return candidate;
        }
      }
    }

    //! Si no hay match por palabras, corremos un fuzzy simple entre colonias.
    return _bestFuzzy(inAgg, colonias);
  }

  ///* Busca coincidencias específicas para secretarías (tu diccionario original).
  static String? _findSecretariaMatch(String input, List<String> secretarias) {
    final Map<String, String> keyWords = {
      'administracion': 'SECRETARIA DE ADMINISTRACION',
      'administración': 'SECRETARIA DE ADMINISTRACION',
      'agua': 'JUNTA DE AGUA POTABLE Y ALCANTARILLADO MUNICIPAL',
      'JAPAM': 'JUNTA DE AGUA POTABLE Y ALCANTARILLADO MUNICIPAL',
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

    final inAgg = _normalizeAggressive(input);
    for (final key in keyWords.keys) {
      if (inAgg.contains(_normalizeAggressive(key))) {
        final value = keyWords[key]!;
        //* Asegura que exista en opciones
        final hit = secretarias.firstWhere(
          (s) => _normalizeAggressive(s) == _normalizeAggressive(value),
          orElse: () => value,
        );
        return hit;
      }
    }
    return null;
  }

  ///* Genera una lista de opciones más corta para leer en voz
  static String generateOptionsText(List<String> options, String fieldType) {
    if (fieldType == 'colonia') {
      return 'Puede mencionar el nombre de su colonia. Tengo registradas más de 300 colonias como Centro, Lomas, Jardines, Villas, INFONAVIT, entre otras.';
    }

    if (fieldType == 'secretaria') {
      return 'Las principales secretarías son: Obras Públicas, Seguridad Pública, Desarrollo Social, Finanzas, Servicios Públicos, entre otras.';
    }

    if (options.length <= 5) {
      return 'Las opciones son: ${options.join(", ")}';
    }
    return 'Las opciones disponibles son: ${options.take(5).join(", ")} y ${options.length - 5} opciones más.';
  }

  ///* Limpia el texto transcrito según el tipo de campo
  static String cleanTranscribedText(String text, String fieldType) {
    String cleaned = text.trim().toUpperCase();
    if (fieldType == 'curp') {
      cleaned = cleaned.replaceAll(' ', '');
      print('Texto sin espacios para $fieldType: "$cleaned"');
    }
    return cleaned;
  }

  ///* Verifica si el texto contiene la palabra "OMITIR"
  static bool shouldSkip(String text) {
    return text.toUpperCase().contains('OMITIR');
  }

  ///* Procesa la respuesta de voz y devuelve el resultado procesado
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

    if (allowSkip && shouldSkip(transcribedText)) {
      print('Usuario eligió omitir');
      return VoiceProcessResult.skipped();
    }

    String cleanedText = cleanTranscribedText(transcribedText, fieldType);
    print('Texto limpiado: "$cleanedText"');

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

    if (options != null && options.isNotEmpty) {
      print('Buscando coincidencia en ${options.length} opciones...');
      final matchedOption = findBestMatch(cleanedText, options);
      if (matchedOption != null) {
        print('✅ Opción encontrada: $matchedOption');
        finalValue = matchedOption;
      } else {
        print('⚠️ No se encontró coincidencia, usando texto original');
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

  //? =================== Helpers de normalización y similitud ===================

  static final Set<String> _stopwords = {
    'el','la','los','las','de','del','y','en','san','santa','santo',
    'colonia','barrio','fraccionamiento','fracc','col'
  };

  static String _stripArticles(String s) {
    //! quita artículos iniciales y palabras de poco valor
    final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final filtered = words.where((w) => !_stopwords.contains(w)).toList();
    return filtered.join(' ').trim();
  }

  static String _normalizeBasic(String s) {
    s = s.trim().toLowerCase();

    //! quitar acentos/diacríticos
    const src = 'áéíóúüäëïöàèìòùãõñÁÉÍÓÚÜÄËÏÖÀÈÌÒÙÃÕÑ';
    const dst = 'aeiouuaeioaeiouaonAEIOUUAeioAEIOUAON';
    final map = <String, String>{};
    for (int i = 0; i < src.length; i++) {
      map[src[i]] = dst[i];
    }
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      buf.write(map[ch] ?? ch);
    }
    s = buf.toString();

    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  //*/ Normalización agresiva con reglas fonéticas comunes en español (aprox).
  static String _normalizeAggressive(String s) {
    s = _normalizeBasic(s);

    //* quitar artículos/stopwords
    s = _stripArticles(s);

    //* reglas fonéticas:
    //* - b ~ v
    s = s.replaceAll('v', 'b');

    //* - z ~ s
    s = s.replaceAll('z', 's');

    //* - c + e/i -> s
    s = s.replaceAll(RegExp(r'ce'), 'se');
    s = s.replaceAll(RegExp(r'ci'), 'si');

    //* - qu -> k ; c + a/o/u -> k
    s = s.replaceAll('qu', 'k');
    s = s.replaceAll(RegExp(r'ca'), 'ka');
    s = s.replaceAll(RegExp(r'co'), 'ko');
    s = s.replaceAll(RegExp(r'cu'), 'ku');

    //* - ll -> y
    s = s.replaceAll('ll', 'y');

    //* - h muda: quitarla
    s = s.replaceAll('h', '');

    //* - x ≈ j (Xajay ~ Jajay). Probamos mapeando x -> j
    s = s.replaceAll('x', 'j');

    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  ///* Similaridad por tokens (Jaccard suave)
  static double _tokenSimilarity(String a, String b) {
    final ta = a.split(' ').where((t) => t.isNotEmpty).toSet();
    final tb = b.split(' ').where((t) => t.isNotEmpty).toSet();
    if (ta.isEmpty || tb.isEmpty) return 0.0;

    final inter = ta.intersection(tb).length;
    final uni = ta.union(tb).length;
    final jaccard = inter / uni;

    //* Además, ponderamos por coincidencias de prefijo
    int prefixHits = 0;
    for (final wa in ta) {
      for (final wb in tb) {
        if (wa.length >= 4 && wb.startsWith(wa.substring(0, 4))) {
          prefixHits++;
          break;
        }
      }
    }
    final prefixBoost = prefixHits > 0 ? 0.05 : 0.0;

    return (jaccard + prefixBoost).clamp(0.0, 1.0);
  }

  ///* Fuzzy helper entre todas las opciones con normalización agresiva
  static String? _bestFuzzy(String inputAgg, List<String> options) {
    String? best;
    double bestScore = -1.0;

    for (final option in options) {
      final oAgg = _normalizeAggressive(option);
      final dist = _levDistance(inputAgg, oAgg);
      final maxLen = inputAgg.length > oAgg.length ? inputAgg.length : oAgg.length;
      final sim = maxLen == 0 ? 0.0 : 1.0 - (dist / maxLen);
      final tokenSim = _tokenSimilarity(inputAgg, oAgg);

      final score = sim > tokenSim ? sim : tokenSim;
      if (score > bestScore) {
        bestScore = score;
        best = option;
      }
    }

    if (best != null && bestScore >= 0.8) {
      return best;
    }
    return null;
  }

  ///* Distancia de Levenshtein (iterativa, O(n*m))
  static int _levDistance(String a, String b) {
    final n = a.length;
    final m = b.length;
    if (n == 0) return m;
    if (m == 0) return n;

    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));

    for (int i = 0; i <= n; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= m; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = _min3(
          dp[i - 1][j] + 1,      //* eliminación
          dp[i][j - 1] + 1,      //* inserción
          dp[i - 1][j - 1] + cost, //* sustitución
        );
      }
    }
    return dp[n][m];
  }

  static int _min3(int a, int b, int c) => (a < b ? a : b) < c ? (a < b ? a : b) : c;
}

///* Clase para representar el resultado del procesamiento de voz
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
    return VoiceProcessResult._(status: VoiceProcessStatus.skipped);
  }

  factory VoiceProcessResult.empty() {
    return VoiceProcessResult._(status: VoiceProcessStatus.empty);
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
