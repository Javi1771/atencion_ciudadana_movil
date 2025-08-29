// lib/utils/citizen_voice_utils.dart
// ignore_for_file: avoid_print, equal_keys_in_map, non_constant_identifier_names

import 'package:app_atencion_ciudadana/data/citizen_options.dart';

///? ============================================================================
///? Enums / Resultados públicos
///? ============================================================================
enum CitizenVoiceProcessStatus { success, error, skipped, empty }

class CitizenVoiceProcessResult {
  final CitizenVoiceProcessStatus status;
  final String? value;
  final String? errorMessage;

  CitizenVoiceProcessResult._({
    required this.status,
    this.value,
    this.errorMessage,
  });

  factory CitizenVoiceProcessResult.success(String value) =>
      CitizenVoiceProcessResult._(
        status: CitizenVoiceProcessStatus.success,
        value: value,
      );

  factory CitizenVoiceProcessResult.error(String message) =>
      CitizenVoiceProcessResult._(
        status: CitizenVoiceProcessStatus.error,
        errorMessage: message,
      );

  factory CitizenVoiceProcessResult.skipped() =>
      CitizenVoiceProcessResult._(status: CitizenVoiceProcessStatus.skipped);

  factory CitizenVoiceProcessResult.empty() =>
      CitizenVoiceProcessResult._(status: CitizenVoiceProcessStatus.empty);

  bool get isSuccess => status == CitizenVoiceProcessStatus.success;
  bool get isError => status == CitizenVoiceProcessStatus.error;
  bool get isSkipped => status == CitizenVoiceProcessStatus.skipped;
  bool get isEmpty => status == CitizenVoiceProcessStatus.empty;
}

///* Compatibilidad “legacy”, por si algo viejo del proyecto lo usa.
enum VoiceProcessStatus { success, error, skipped, empty }

class VoiceProcessResult {
  final VoiceProcessStatus status;
  final String? value;
  final String? errorMessage;

  VoiceProcessResult._({required this.status, this.value, this.errorMessage});

  factory VoiceProcessResult.success(String value) =>
      VoiceProcessResult._(status: VoiceProcessStatus.success, value: value);

  factory VoiceProcessResult.error(String message) => VoiceProcessResult._(
        status: VoiceProcessStatus.error,
        errorMessage: message,
      );

  factory VoiceProcessResult.skipped() =>
      VoiceProcessResult._(status: VoiceProcessStatus.skipped);

  factory VoiceProcessResult.empty() =>
      VoiceProcessResult._(status: VoiceProcessStatus.empty);

  bool get isSuccess => status == VoiceProcessStatus.success;
  bool get isError => status == VoiceProcessStatus.error;
  bool get isSkipped => status == VoiceProcessStatus.skipped;
  bool get isEmpty => status == VoiceProcessStatus.empty;
}

///? ============================================================================
///? Utilidades de voz para registro de ciudadanos
///? ============================================================================
class CitizenVoiceUtils {
  /// Procesa la entrada de voz (flujo: limpiar → corregir → matching → post → validar)
  static CitizenVoiceProcessResult processVoiceInput({
    required String transcribedText,
    required String fieldType,
    List<String>? options,
    bool allowSkip = false,
    String? Function(String)? validator,
  }) {
    print('\n=== PROCESANDO ENTRADA CIUDADANO ===');
    print('Texto transcrito: "$transcribedText"');
    print('Tipo de campo: $fieldType');

    if (transcribedText.isEmpty) {
      print('Texto vacío');
      return CitizenVoiceProcessResult.empty();
    }

    //* Si permite omitir y el usuario lo pidió:
    if (allowSkip && shouldSkip(transcribedText)) {
      //* Para numero_interior queremos GUARDAR "SN" en lugar de omitir
      if (fieldType == 'numero_interior') {
        print('Usuario eligió omitir → guardamos "SN" para numero_interior');
        return CitizenVoiceProcessResult.success('SN');
      }
      print('Usuario eligió omitir');
      return CitizenVoiceProcessResult.skipped();
    }

    //? 1) Limpia
    String cleanedText = cleanTranscribedText(transcribedText, fieldType);
    print('Texto limpiado: "$cleanedText"');

    //? 2) Corrige (incluye detección de "sin número")
    cleanedText = applyVoiceCorrections(cleanedText, fieldType);
    print('Texto corregido: "$cleanedText"');

    //? 3) Matching (antes de validar) si hay catálogo de opciones
    String finalValue = cleanedText;

    if (options != null && options.isNotEmpty) {
      print('Buscando coincidencia en ${options.length} opciones...');
      final matchedOption = findBestMatch(cleanedText, options, fieldType);
      if (matchedOption != null) {
        print('✅ Opción encontrada: $matchedOption');
        finalValue = matchedOption;
      } else {
        print('⚠️ No se encontró coincidencia exacta');
        if (fieldType == 'sexo' || fieldType == 'estado') {
          return CitizenVoiceProcessResult.error(
            'No se reconoció esa opción. ${_getSuggestionText(fieldType, options)}',
          );
        } else if (fieldType == 'asentamiento') {
          return CitizenVoiceProcessResult.error(
            'No se encontró esa colonia. ${_getSuggestionText(fieldType, options)}',
          );
        }
      }
    }

    //? 4) Post-proceso del campo
    finalValue = postProcessField(finalValue, fieldType);

    //? 5) Validación final (post-matching)
    if (validator != null) {
      print('Ejecutando validador (post-matching)...');
      final validationError = validator(finalValue);
      if (validationError != null) {
        print('❌ Error de validación: $validationError');
        return CitizenVoiceProcessResult.error(validationError);
      }
      print('✅ Validación exitosa');
    }

    print('✅ Valor final: "$finalValue"');
    print('=====================================\n');
    return CitizenVoiceProcessResult.success(finalValue);
  }

  //*/ Detecta expresiones tipo “sin número”, “s/n”, “sn”, “no tengo número”, etc.
  static bool _looksLikeSinNumero(String input) {
    var s = input.toLowerCase().trim();
    s = _removeDiacritics(s);
    s = s.replaceAll(RegExp(r'[^\w\s/]'), ''); //* deja letras/números/espacios/slash
    s = s.replaceAll('/', ''); //* "s/n" -> "sn"
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (s == 'sn' || s == 's n') return true;
    if (s.contains('sin numero') || s.contains('sin num')) return true;
    if (s.contains('no numero') || s.contains('no tengo numero')) return true;
    return false;
  }

  static String _removeDiacritics(String input) {
    const map = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
      'Á': 'A', 'À': 'A', 'Ä': 'A', 'Â': 'A', 'Ã': 'A',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'É': 'E', 'È': 'E', 'Ë': 'E', 'Ê': 'E',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'Í': 'I', 'Ì': 'I', 'Ï': 'I', 'Î': 'I',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
      'Ó': 'O', 'Ò': 'O', 'Ö': 'O', 'Ô': 'O', 'Õ': 'O',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'Ú': 'U', 'Ù': 'U', 'Ü': 'U', 'Û': 'U',
      'ñ': 'n', 'Ñ': 'N', 'ç': 'c', 'Ç': 'C',
    };
    var out = input;
    map.forEach((k, v) => out = out.replaceAll(k, v));
    return out;
  }

  ///* Limpia el texto según el tipo de campo
  static String cleanTranscribedText(String text, String fieldType) {
    String cleaned = text.trim().toUpperCase();

    switch (fieldType) {
      case 'curp_ciudadano':
        cleaned = cleaned.replaceAll(' ', '');
        break;

      case 'telefono':
      case 'codigo_postal':
      case 'numero_exterior':
      case 'numero_interior':
        //* Permitir frases como "sin número"/"s/n" (no restringir a dígitos aquí)
        cleaned = _capitalizeWords(text.trim());
        break;

      case 'email':
        cleaned = cleaned.toLowerCase();
        break;

      case 'password':
        cleaned = text.trim(); //* mantener como lo dijo el usuario
        break;

      default:
        cleaned = _capitalizeWords(text.trim()); //* nombres/direcciones
        break;
    }

    print('Texto limpio para $fieldType: "$cleaned"');
    return cleaned;
  }

  ///* Aplica correcciones por tipo de campo
  static String applyVoiceCorrections(String text, String fieldType) {
    String corrected = text;

    switch (fieldType) {
      case 'telefono':
      case 'codigo_postal':
        corrected = _convertSpokenNumbersToDigits(corrected);
        corrected = corrected.replaceAll(RegExp(r'[^0-9]'), '');
        break;

      case 'numero_exterior':
      case 'numero_interior':
        //* Detectar "sin número" ANTES de tocar nada
        if (_looksLikeSinNumero(text)) {
          print('Detectado "sin número" → mapeando a "SN"');
          return 'SN';
        }
        //* Convertir números hablados a dígitos, pero NO borrar letras/símbolos
        corrected = _convertSpokenNumbersToDigits(text);
        //* Normalizar espacios; lo demás se sanea en postProcessField
        corrected = corrected.replaceAll(RegExp(r'\s+'), ' ').trim();
        break;

      case 'email':
        corrected =
            corrected.replaceAll(RegExp('\\barroba\\b', caseSensitive: false), '@');
        corrected =
            corrected.replaceAll(RegExp('\\bpunto\\b', caseSensitive: false), '.');
        corrected = corrected.replaceAll(
            RegExp('\\bguion bajo\\b', caseSensitive: false), '_');
        corrected = corrected.replaceAll(
            RegExp('\\bguión bajo\\b', caseSensitive: false), '_');
        corrected = _cleanEmailSpaces(corrected);
        break;

      case 'sexo':
        for (final entry in CitizenOptions.voiceCorrections.entries) {
          if (entry.value == 'Masculino' || entry.value == 'Femenino') {
            corrected = corrected.replaceAll(
              RegExp('\\b${entry.key}\\b', caseSensitive: false),
              entry.value,
            );
          }
        }
        break;

      case 'estado':
        for (final entry in CitizenOptions.voiceCorrections.entries) {
          if (CitizenOptions.estados.contains(entry.value)) {
            corrected = corrected.replaceAll(
              RegExp('\\b${entry.key}\\b', caseSensitive: false),
              entry.value,
            );
          }
        }
        break;
    }

    return corrected;
  }

  ///* Matching robusto (búsqueda de mejor coincidencia) con heurísticas por campo
  static String? findBestMatch(
    String input,
    List<String> options,
    String fieldType,
  ) {
    print('\n--- BUSCANDO COINCIDENCIA ---');
    print('Input: "$input"');
    print('Tipo de campo: $fieldType');

    final raw = input.trim();
    if (raw.isEmpty) {
      print('❌ Input vacío');
      return null;
    }

    final cleanInput = _normalizeBasic(raw);
    print('Input limpiado: "$cleanInput"');

    //? 0) Exacta ignorando acentos/mayúsculas
    for (final option in options) {
      if (_normalizeBasic(option) == cleanInput) {
        print('✅ Coincidencia exacta (básica): $option');
        return option;
      }
    }

    //? 1) Exacta agresiva (fonética/artículos)
    final inputAgg = _normalizeAggressive(cleanInput);
    for (final option in options) {
      if (_normalizeAggressive(_normalizeBasic(option)) == inputAgg) {
        print('✅ Coincidencia exacta (agresiva): $option');
        return option;
      }
    }

    //? 2) Heurística especial para colonias
    if (fieldType == 'asentamiento') {
      final colonia = _findColoniaMatch(cleanInput, options);
      if (colonia != null) {
        print('✅ Coincidencia en colonia: $colonia');
        return colonia;
      }
    }

    //? 3) Fuzzy global (Levenshtein + tokens + fonética)
    String? bestOption;
    double bestScore = -1.0;

    for (final option in options) {
      final oBasic = _normalizeBasic(option);
      final oAgg = _normalizeAggressive(oBasic);

      final distBasic = _levDistance(cleanInput, oBasic);
      final distAgg = _levDistance(inputAgg, oAgg);

      final maxLenBasic =
          cleanInput.length > oBasic.length ? cleanInput.length : oBasic.length;
      final maxLenAgg = inputAgg.length > oAgg.length ? inputAgg.length : oAgg.length;

      final simBasic = maxLenBasic == 0 ? 0.0 : 1.0 - (distBasic / maxLenBasic);
      final simAgg = maxLenAgg == 0 ? 0.0 : 1.0 - (distAgg / maxLenAgg);

      final tokenSim = _tokenSimilarity(inputAgg, oAgg);
      final phoneticSim = _phoneticSimilarity(inputAgg, oAgg);

      final score = [simBasic, simAgg, tokenSim, phoneticSim]
          .reduce((a, b) => a > b ? a : b);

      if (score > bestScore) {
        bestScore = score;
        bestOption = option;
      }
    }

    double threshold = 0.75; 
    if (fieldType == 'asentamiento') threshold = 0.70;

    if (bestOption != null && bestScore >= threshold) {
      print('✅ Coincidencia difusa: $bestOption (score: ${bestScore.toStringAsFixed(3)})');
      return bestOption;
    }

    //? 4) Contención parcial (fallback)
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

  ///* Genera texto amigable de opciones para TTS
  static String generateOptionsText(List<String> options, String fieldType) {
    switch (fieldType) {
      case 'sexo':
        return 'Las opciones son: ${options.join(" o ")}';
      case 'estado':
        return 'Por ejemplo: Querétaro, Jalisco, Ciudad de México, Nuevo León, entre otros';
      case 'asentamiento':
        return 'Puede mencionar el nombre de su colonia. Tengo registradas más de 300 colonias como Centro, Lomas, Jardines, Villas, INFONAVIT, entre otras.';
      default:
        if (options.length <= 5) {
          return 'Las opciones son: ${options.join(", ")}';
        }
        return 'Algunas opciones son: ${options.take(5).join(", ")} y ${options.length - 5} más';
    }
  }

  ///? ========================= Helpers de normalización/similitud ========================

  static final Set<String> _stopwords = {
    'el','la','los','las','de','del','y','en','san','santa','santo',
    'colonia','barrio','fraccionamiento','fracc','col',
  };

  static String _stripArticles(String s) {
    final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final filtered = words.where((w) => !_stopwords.contains(w)).toList();
    return filtered.join(' ').trim();
  }

  static String _normalizeBasic(String s) {
    s = s.trim().toLowerCase();

    //! quitar acentos
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

  ///* Normalización agresiva con reglas fonéticas flexibles
  static String _normalizeAggressive(String s) {
    s = _normalizeBasic(s);
    s = _stripArticles(s);

    //? b ~ v
    s = s.replaceAll('v', 'b');

    //? z ~ s ~ c(ce/ci)
    s = s.replaceAll('z', 's');
    s = s.replaceAll(RegExp(r'ce'), 'se');
    s = s.replaceAll(RegExp(r'ci'), 'si');

    //? qu->k ; ca/co/cu -> k
    s = s.replaceAll('qu', 'k');
    s = s.replaceAll(RegExp(r'ca'), 'ka');
    s = s.replaceAll(RegExp(r'co'), 'ko');
    s = s.replaceAll(RegExp(r'cu'), 'ku');

    //? ll ~ y ~ j
    s = s.replaceAll('ll', 'y');
    s = s.replaceAll('j', 'y');

    //? h muda
    s = s.replaceAll('h', '');

    //? x ~ y (Xajay/Jajay)
    s = s.replaceAll('x', 'y');

    //? rr ~ r
    s = s.replaceAll('rr', 'r');

    //? ge/gi ~ ye/yi
    s = s.replaceAll(RegExp(r'ge'), 'ye');
    s = s.replaceAll(RegExp(r'gi'), 'yi');

    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static double _tokenSimilarity(String a, String b) {
    final ta = a.split(' ').where((t) => t.isNotEmpty).toSet();
    final tb = b.split(' ').where((t) => t.isNotEmpty).toSet();
    if (ta.isEmpty || tb.isEmpty) return 0.0;

    final inter = ta.intersection(tb).length;
    final uni = ta.union(tb).length;
    final jaccard = inter / uni;

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

  static String? _bestFuzzy(String inputAgg, List<String> options) {
    String? best;
    double bestScore = -1.0;

    for (final option in options) {
      final oAgg = _normalizeAggressive(option);
      final dist = _levDistance(inputAgg, oAgg);
      final maxLen = inputAgg.length > oAgg.length ? inputAgg.length : oAgg.length;
      final sim = maxLen == 0 ? 0.0 : 1.0 - (dist / maxLen);
      final tokenSim = _tokenSimilarity(inputAgg, oAgg);
      final phoneticSim = _phoneticSimilarity(inputAgg, oAgg);

      final score = [sim, tokenSim, phoneticSim].reduce((a, b) => a > b ? a : b);
      if (score > bestScore) {
        bestScore = score;
        best = option;
      }
    }

    if (best != null && bestScore >= 0.75) return best;
    return null;
  }

  static double _phoneticSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final pa = _applyPhoneticTransforms(a);
    final pb = _applyPhoneticTransforms(b);
    final dist = _levDistance(pa, pb);
    final maxLen = pa.length > pb.length ? pa.length : pb.length;
    return maxLen == 0 ? 0.0 : 1.0 - (dist / maxLen);
  }

  static String _applyPhoneticTransforms(String s) {
    String result = s;
    final phoneticMap = {
      's': 'S', 'z': 'S', 'c': 'S',
      'b': 'B', 'v': 'B', 'p': 'B',
      'j': 'Y', 'y': 'Y', 'll': 'Y', 'g': 'Y',
      'r': 'R', 'rr': 'R',
      'd': 'D', 't': 'D',
      'k': 'K', 'qu': 'K', 'c': 'K',
      'f': 'F',
      'm': 'M', 'n': 'M', 'ñ': 'M',
    };
    for (final e in phoneticMap.entries) {
      result = result.replaceAll(e.key, e.value);
    }
    final consonants = result.replaceAll(RegExp(r'[aeiou]'), '');
    return consonants.length > 4 ? consonants.substring(0, 4) : consonants;
  }

  static int _levDistance(String a, String b) {
    final n = a.length, m = b.length;
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
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        );
      }
    }
    return dp[n][m];
  }

  static int _min3(int a, int b, int c) =>
      (a < b ? a : b) < c ? (a < b ? a : b) : c;

  ///? =============================== Heurística colonias ===============================
  static String? _findColoniaMatch(String input, List<String> colonias) {
    print('Buscando coincidencia específica para colonia: "$input"');
    final correctedInput = _applyColoniaPhoneticCorrections(input);
    print('Input con correcciones fonéticas: "$correctedInput"');

    final Map<String, List<String>> keyWords = {
      'centro': ['Centro'],
      'santa': [
        'Santa Cruz Escandón','Santa Cruz Nieto','Santa Rita','Santa Elena',
        'Santa Fe','Santa Isabel','Santa Lucia','Santa Matilde','Santa Anita',
        'Santa Bárbara de la Cueva','Santa Rosa Xajay',
      ],
      'san': [
        'San Antonio la Labor','San Antonio Zatlauco','San Cayetano','San Francisco',
        'San Germán','San Gil','San Isidro','San Isidro Labrador','San Javier',
        'San José','San José Galindo','San Juan Bosco','San Juan de Dios','San Martín',
        'San Miguel Arcángel','San Miguel Galindo','San Pablo Potrerillos',
        'San Pedro 1a Sección','San Pedro 2a. Sección','San Pedro 3a Sección',
        'San Pedro Ahuacatlán','San Rafael','San Sebastián de las Barrancas',
        'San Sebastián de las Barrancas Norte','San Sebastián de las Barrancas Sur',
      ],
      'juarez': ['Benito Juárez', 'Juárez'],
      'villa': [
        'Francisco Villa','Villa de las Haciendas','Villa las Flores',
        'Villa los Cipreses','Villa los Olivos',
      ],
      'lomas': [
        'Lomas de Guadalupe','Lomas de la Estancia','Lomas del Pedregal',
        'Lomas de San Juan','Lomas de San Juan 2da. Sección',
      ],
      'jardines': [
        'Jardines Banthi','Jardines del Pedregal','Jardines del Valle',
        'Jardines del Valle II','Jardines del Valle III','Jardines de San Juan',
      ],
      'villas': [
        'Villas Corregidora','Villas del Centro','Villas del Parque',
        'Villas del Pedregal','Villas del Pedregal 1a. Sección','Villas del Puente',
        'Villas del Sol','Villas de San Isidro','Villas de San José','Villas de San Juan',
      ],
      'infonavit': [
        'INFONAVIT Fatima','INFONAVIT la Paz','INFONAVIT los Fresnos',
        'INFONAVIT Pedregoso','INFONAVIT Pedregoso 3a Sección',
        'INFONAVIT San Cayetano','INFONAVIT San Isidro',
      ],
    };

    final inAgg = _normalizeAggressive(correctedInput);
    print('Input agresivo para colonia: "$inAgg"');

    for (final key in keyWords.keys) {
      final keyAgg = _normalizeAggressive(key);
      if (inAgg.contains(keyAgg)) {
        print('Palabra clave encontrada: "$key"');
        for (final candidate in keyWords[key]!) {
          if (colonias.contains(candidate)) {
            print('✅ Candidato encontrado por palabra clave: $candidate');
            return candidate;
          }
        }
      }
    }

    final fuzzyResult = _bestFuzzy(inAgg, colonias);
    if (fuzzyResult != null) {
      print('✅ Resultado fuzzy para colonia: $fuzzyResult');
    }
    return fuzzyResult;
  }

  static String _applyColoniaPhoneticCorrections(String input) {
    String corrected = input.toLowerCase().trim();
    final phoneticCorrections = {
      'santa crus': 'santa cruz',
      'santa krus': 'santa cruz',
      'casadero': 'cazadero',
      'kasadero': 'cazadero',
      'san sebatian': 'san sebastian',
      'san sevatian': 'san sebastian',
      'san sevastian': 'san sebastian',
      'banti': 'banthi', 'vanthi': 'banthi',
      'correjidora': 'corregidora', 'korrejidora': 'corregidora',
      'pedrejal': 'pedregal', 'pedreyar': 'pedregal',
      'san yose': 'san josé',
      'yavier': 'javier', 'llavier': 'javier',
      'billa': 'villa', 'billas': 'villas',
      'primera seccion': '1a sección',
      'segunda seccion': '2a sección',
      'tercera seccion': '3a sección',
      'primero': '1a','segundo': '2a','tercero': '3a',
    };
    for (final e in phoneticCorrections.entries) {
      if (corrected.contains(e.key)) {
        corrected = corrected.replaceAll(e.key, e.value);
        print('Corrección aplicada: "${e.key}" -> "${e.value}"');
      }
    }
    return corrected;
  }

  ///? ============================== Helpers de campo ==============================

  static String postProcessField(String value, String fieldType) {
    switch (fieldType) {
      case 'telefono': {
        String phone = value.replaceAll(RegExp(r'[^0-9]'), '');
        if (phone.startsWith('52') && phone.length == 12) {
          phone = phone.substring(2);
        }
        return phone;
      }

      case 'codigo_postal': {
        final cp = value.replaceAll(RegExp(r'[^0-9]'), '');
        return cp.length > 5 ? cp.substring(0, 5) : cp;
      }

      case 'numero_exterior':
      case 'numero_interior': {
        final raw = value.trim();
        if (_looksLikeSinNumero(raw)) return 'SN';     
        if (raw.isEmpty) return raw;
        if (RegExp(r'^\d+$').hasMatch(raw)) return raw; 
        //* permitir formatos 12B, A-3, 4/2, etc. y normalizar
        final cleaned =
            raw.replaceAll(RegExp(r'[^0-9A-Za-z\-/ ]'), '').toUpperCase();
        return cleaned;
      }

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

  static String _processEmail(String email) {
    String processed = email.toLowerCase().trim();
    processed = processed.replaceAll(RegExp(r'\s*@\s*'), '@');
    processed = processed.replaceAll(RegExp(r'\s*\.\s*'), '.');
    processed = processed.replaceAll(RegExp(r'\s+'), '');

    for (final domain in CitizenOptions.emailDomains) {
      final parts = domain.split('.');
      if (processed.contains(parts[0]) && !processed.contains(domain)) {
        processed = processed.replaceAll(parts[0], domain);
        break;
      }
    }

    print('Email procesado final: "$processed"');
    return processed;
  }

  static String _processDate(String dateText) {
    String processed = dateText.toLowerCase();
    final months = {
      'enero': '01','febrero': '02','marzo': '03','abril': '04',
      'mayo': '05','junio': '06','julio': '07','agosto': '08',
      'septiembre': '09','octubre': '10','noviembre': '11','diciembre': '12',
    };
    for (final e in months.entries) {
      processed = processed.replaceAll(e.key, e.value);
    }
    final numbers = RegExp(r'\d+').allMatches(processed).map((m) => m.group(0)!).toList();
    if (numbers.length >= 3) {
      String day = numbers[0].padLeft(2, '0');
      String month = numbers[1].padLeft(2, '0');
      String year = numbers[2];
      if (year.length == 2) {
        final yi = int.parse(year);
        year = yi > 30 ? '19$year' : '20$year';
      }
      return '$year-$month-$day';
    }
    return processed;
  }

  static String _convertSpokenNumbersToDigits(String text) {
    String result = text.toLowerCase().trim();
    final Map<String, String> numberMap = {
      //? básicos
      'cero':'0','zero':'0','uno':'1','una':'1','un':'1','dos':'2','tres':'3',
      'cuatro':'4','cinco':'5','seis':'6','siete':'7','ocho':'8','nueve':'9',
      //? decenas
      'diez':'10','once':'11','doce':'12','trece':'13','catorce':'14','quince':'15',
      'dieciséis':'16','dieciseis':'16','diecisiete':'17','dieciocho':'18','diecinueve':'19',
      'veinte':'20','veintiuno':'21','veintiuna':'21','veintidós':'22','veintidos':'22',
      'veintitrés':'23','veintitres':'23','veinticuatro':'24','veinticinco':'25',
      'veintiséis':'26','veintiseis':'26','veintisiete':'27','veintiocho':'28','veintinueve':'29',
      'treinta':'30','cuarenta':'40','cincuenta':'50','sesenta':'60','setenta':'70',
      'ochenta':'80','noventa':'90',
      //? centenas comunes
      'cien':'100','ciento':'100','doscientos':'200','doscientas':'200',
      'trescientos':'300','trescientas':'300','cuatrocientos':'400','cuatrocientas':'400',
      'quinientos':'500','quinientas':'500',
    };

    print('Convirtiendo números hablados: "$result"');

    final sorted = numberMap.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final e in sorted) {
      final pattern = RegExp('\\b${e.key}\\b', caseSensitive: false);
      if (result.contains(RegExp(e.key, caseSensitive: false))) {
        result = result.replaceAll(pattern, ' ${e.value} ');
        print('Reemplazado "${e.key}" -> "${e.value}"');
      }
    }

    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    print('Resultado conversión números: "$result"');
    return result;
  }

  static String _cleanEmailSpaces(String email) {
    String result = email.toLowerCase().trim();
    print('Limpiando espacios en email: "$result"');
    result = result.replaceAll(RegExp(r'\s*@\s*'), '@');
    result = result.replaceAll(RegExp(r'\s*\.\s*'), '.');
    result = result.replaceAll(RegExp(r'\s*_\s*'), '_');

    final emailPattern = RegExp(r'^([a-zA-Z0-9\s_-]+)@([a-zA-Z0-9\s.-]+)$');
    final match = emailPattern.firstMatch(result);
    if (match != null) {
      final local = match.group(1)!.replaceAll(RegExp(r'\s+'), '');
      final domain = match.group(2)!.replaceAll(RegExp(r'\s+'), '');
      result = '$local@$domain';
      print('Email reconstruido: "$result"');
    } else {
      result = result.replaceAll(RegExp(r'\s+'), '');
    }

    print('Email final limpio: "$result"');
    return result;
  }

  ///? ====== Versiones legacy por compatibilidad opcional ======
  static String cleanTranscribedText_Legacy(String text, String fieldType) {
    String cleaned = text.trim().toUpperCase();
    if (fieldType == 'curp') {
      cleaned = cleaned.replaceAll(' ', '');
      print('Texto sin espacios para $fieldType: "$cleaned"');
    }
    return cleaned;
  }

  static VoiceProcessResult processVoiceInput_Legacy({
    required String transcribedText,
    required String fieldType,
    List<String>? options,
    bool allowSkip = false,
    String? Function(String)? validator,
  }) {
    print('\n=== PROCESANDO ENTRADA DE VOZ LEGACY ===');
    print('Texto transcrito: "$transcribedText"');
    print('Tipo de campo: $fieldType');

    if (transcribedText.isEmpty) return VoiceProcessResult.empty();
    if (allowSkip && shouldSkip(transcribedText)) {
      return VoiceProcessResult.skipped();
    }

    String cleanedText = cleanTranscribedText_Legacy(transcribedText, fieldType);
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
      final matchedOption = findBestMatch(cleanedText, options, fieldType);
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

  ///? ============================= Helpers varios =============================
  static String _capitalizeWords(String text) => text
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
      .join(' ');

  static bool shouldSkip(String text) => text.toUpperCase().contains('OMITIR');

  static String _getSuggestionText(String fieldType, List<String> options) {
    switch (fieldType) {
      case 'sexo':
        return 'Puede decir "masculino" o "femenino"';
      case 'estado':
        return 'Intente con el nombre completo del estado, por ejemplo "Querétaro" o "Jalisco"';
      case 'asentamiento':
        return 'Puede decir solo el nombre principal como "Centro", "San Juan", "Santa Cruz", etc.';
      default:
        return 'Intente con una opción similar a: ${options.take(3).join(", ")}';
    }
  }
}
