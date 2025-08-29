// lib/utils/curp_validator.dart
// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures, equal_keys_in_map

class CurpValidator {
  ///* Activa/desactiva logs en consola
  static const bool _debug = true;

  ///* Regex oficial (estructura general)
  static final RegExp _curpRegex = RegExp(
    r'^[A-Z][AEIOUX][A-Z]{2}[0-9]{6}[HM][A-Z]{5}[A-Z0-9][0-9]$',
  );

  ///* Valida una CURP. Devuelve null si es válida; mensaje de error si no.
  static String? validate(String value) {
    _log('=== VALIDACIÓN CURP (robusta voz SÚPER PRECISA) ===');
    _log('Valor original: "$value"');

    if (value.trim().isEmpty) {
      _log('Valor vacío -> null (no valida ni invalida)');
      return null;
    }

    //? 1) Normalizar voz a posible CURP (corrige "eme", "uve", "doble ve", números, etc.)
    String candidate = _normalizeVoiceToCurp(value);
    _log(
      'Candidato tras normalización voz -> CURP: "$candidate" (len: ${candidate.length})',
    );

    //? 2) Correcciones por posición (0-17) según se esperan letras o dígitos
    candidate = _applyPositionalCorrections(candidate);
    _log(
      'Candidato tras correcciones posicionales: "$candidate" (len: ${candidate.length})',
    );

    //? 3) Revalidar longitud
    if (candidate.length != 18) {
      _log('Longitud incorrecta: se esperan 18, hay ${candidate.length}');
      return 'La CURP debe tener exactamente 18 caracteres. Verifique que haya dicho todas las letras y números.';
    }

    //? 4) Validar contra regex completo
    final ok = _curpRegex.hasMatch(candidate);
    _log('Coincide con formato CURP: $ok');

    if (!ok) {
      //* Mensajes amigables
      if (!_isLetter(candidate[0])) {
        return 'El primer carácter debe ser una letra (A-Z).';
      }
      if (!RegExp(r'^[AEIOUX]$').hasMatch(candidate[1])) {
        return 'El segundo carácter debe ser una vocal (A, E, I, O, U) o X.';
      }
      if (!RegExp(r'^[0-9]{6}$').hasMatch(candidate.substring(4, 10))) {
        return 'Los caracteres 5 al 10 deben ser números (fecha de nacimiento en formato AAMMDD).';
      }
      if (!RegExp(r'^[HM]$').hasMatch(candidate[10])) {
        return 'El carácter 11 debe ser H (hombre) o M (mujer).';
      }
      return 'El formato de la CURP es inválido. Revise letras y números dictados.';
    }

    _log('✓ RESULTADO: CURP válida');
    return null;
  }

  ///* Devuelve true si la CURP (ya normalizada) cumple formato.
  static bool hasValidFormat(String curp) {
    final candidate = _applyPositionalCorrections(_normalizeVoiceToCurp(curp));
    return candidate.length == 18 && _curpRegex.hasMatch(candidate);
  }

  ///* Limpia: quita espacios y mayúsculas (no corrige voz a letras)
  static String cleanCurp(String curp) {
    return curp.replaceAll(RegExp(r'\s+'), '').trim().toUpperCase();
  }

  //? ==================== Internals ====================

  ///* Normaliza dictado de voz a una cadena candidata de CURP (A-Z/0-9).
  ///* SÚPER PRECISO: maneja casos como "TE E" = T + E, no solo TE
  static String _normalizeVoiceToCurp(String input) {
    String text = _removeDiacritics(input.toUpperCase());
    _log('Texto normalizado: "$text"');
    
    //! Elimina símbolos comunes
    text = text.replaceAll(RegExp(r'[\.\,\;\:\_\(\)\[\]\{\}\|\\\/]'), ' ');
    //! Palabras irrelevantes
    text = text.replaceAll(
      RegExp(r'\b(GUION|GUIONMEDIO|GUION BAJO|GUION-BAJO|GUION-MEDIO)\b'),
      ' ',
    );
    text = text.replaceAll(RegExp(r'\bESPACIO(S)?\b'), ' ');

    //* Tokenizar con espacios múltiples normalizados
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final tokens = text.split(' ').where((t) => t.isNotEmpty).toList();
    _log('Tokens iniciales: $tokens');

    //? NUEVO: Pre-procesar tokens para casos especiales antes del mapeo
    final processedTokens = _preprocessTokens(tokens);
    _log('Tokens pre-procesados: $processedTokens');

    //? FIX 1: si viene como una sola pieza alfanumérica, úsala directamente
    if (processedTokens.length == 1 && RegExp(r'^[A-Z0-9]{12,}$').hasMatch(processedTokens[0])) {
      final curpRaw = cleanCurp(processedTokens[0]);
      return curpRaw.length <= 18 ? curpRaw : curpRaw.substring(0, 18);
    }

    //* Aplicar mapeo inteligente con contexto
    return _applyIntelligentMapping(processedTokens);
  }

  ///* PRE-PROCESA tokens para casos especiales como "TE E" -> ["T", "E"]
  static List<String> _preprocessTokens(List<String> tokens) {
    final List<String> result = [];
    
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      bool processed = false;
      
      //? Caso 1: "TE E" debe ser T + E (no TE como letra T)
      if (token == 'TE' && i + 1 < tokens.length) {
        final nextToken = tokens[i + 1];
        //* Si el siguiente token es una vocal sola, probablemente TE es T
        if (RegExp(r'^[AEIOU]$').hasMatch(nextToken)) {
          _log('Detectado patrón "TE $nextToken" -> separando como T + $nextToken');
          result.add('T');
          //! No procesamos el siguiente token aquí, lo dejamos para el siguiente ciclo
          processed = true;
        }
        //* Si el siguiente es una letra completa escrita, también separamos
        else if (_isSingleLetterName(nextToken)) {
          _log('Detectado patrón "TE $nextToken" -> separando como T + $nextToken');
          result.add('T');
          processed = true;
        }
      }
      
      //? Caso 2: "BE A" debe ser B + A
      else if (token == 'BE' && i + 1 < tokens.length) {
        final nextToken = tokens[i + 1];
        if (RegExp(r'^[AEIOU]$').hasMatch(nextToken) || _isSingleLetterName(nextToken)) {
          _log('Detectado patrón "BE $nextToken" -> separando como B + $nextToken');
          result.add('B');
          processed = true;
        }
      }
      
      //? Caso 3: "DE O" debe ser D + O
      else if (token == 'DE' && i + 1 < tokens.length) {
        final nextToken = tokens[i + 1];
        if (RegExp(r'^[AEIOU]$').hasMatch(nextToken) || _isSingleLetterName(nextToken)) {
          _log('Detectado patrón "DE $nextToken" -> separando como D + $nextToken');
          result.add('D');
          processed = true;
        }
      }
      
      //? Caso 4: Nombres de letras seguidos de vocales solas
      else if (_isDoubleLetterName(token) && i + 1 < tokens.length) {
        final nextToken = tokens[i + 1];
        if (RegExp(r'^[AEIOU]$').hasMatch(nextToken)) {
          //* Convertir el nombre de letra doble a su letra simple
          final singleLetter = _doubleLetterToSingle(token);
          if (singleLetter != null) {
            _log('Detectado patrón "$token $nextToken" -> separando como $singleLetter + $nextToken');
            result.add(singleLetter);
            processed = true;
          }
        }
      }
      
      if (!processed) {
        result.add(token);
      }
    }
    
    return result;
  }

  ///* Verifica si un token es el nombre de una letra sola (A, E, I, etc.)
  static bool _isSingleLetterName(String token) {
    return RegExp(r'^[A-Z]$').hasMatch(token);
  }

  ///* Verifica si un token es el nombre de una letra doble (BE, CE, DE, etc.)
  static bool _isDoubleLetterName(String token) {
    const doubleNames = ['BE', 'CE', 'DE', 'GE', 'PE', 'TE', 'VE', 'UVE'];
    return doubleNames.contains(token);
  }

  ///* Convierte nombre de letra doble a letra simple
  static String? _doubleLetterToSingle(String token) {
    const Map<String, String> mapping = {
      'BE': 'B',
      'CE': 'C', 
      'DE': 'D',
      'GE': 'G',
      'PE': 'P',
      'TE': 'T',
      'VE': 'V',
      'UVE': 'V',
    };
    return mapping[token];
  }

  ///* Aplica mapeo inteligente considerando contexto y patrones
  static String _applyIntelligentMapping(List<String> tokens) {
    //* Frases (multi-palabra) - ORDEN IMPORTANTE: más específicas primero
    final Map<String, String> phrases = {
      //? Específicas de 3+ palabras
      'DOBLE DOBLE VE': 'W',
      'DOBLE VE DOBLE': 'W', 
      //? Dobles comunes
      'DOBLE VE': 'W',
      'DOBLE UVE': 'W',
      'DOBLE U': 'W',
      'DOBLE UVE': 'W',
      'DOBLE W': 'W',
      'DOBLE DOUBLE U': 'W',
      //? Variantes de V
      'VE CHICA': 'V',
      'VE PEQUENA': 'V',
      'VE PEQUEÑA': 'V',
      'V CHICA': 'V',
      'V PEQUENA': 'V',
      'UVE CHICA': 'V',
      //? Variantes de B  
      'B GRANDE': 'B',
      'BE GRANDE': 'B',
      'BE LARGA': 'B',
      'B LARGA': 'B',
      //? Y griega
      'I GRIEGA': 'Y',
      'Y GRIEGA': 'Y',
      'YE GRIEGA': 'Y',
      //? Otras
      'GUE': 'G',
      'GUIE': 'G',
      'DOBLE RE': 'R',
      'DOBLE R': 'R',
      'DOBLE ERRE': 'R',
      //? Números compuestos
      'DIEZ': '10', //* Se manejará como 1,0
      'ONCE': '11',
      'DOCE': '12',
      'TRECE': '13',
      'CATORCE': '14',
      'QUINCE': '15',
      'DIECISEIS': '16',
      'DIECISIETE': '17',
      'DIECIOCHO': '18',
      'DIECINUEVE': '19',
      'VEINTE': '20',
    };

    //* Palabras simples - MÁS COMPLETO
    final Map<String, String> single = {
      //? Letras básicas
      'A': 'A',
      'BE': 'B', 'B': 'B',
      'CE': 'C', 'C': 'C',
      'DE': 'D', 'D': 'D',
      'E': 'E',
      'EFE': 'F', 'F': 'F',
      'GE': 'G', 'G': 'G', 'JE': 'G',
      'HACHE': 'H', 'H': 'H',
      'I': 'I',
      'JOTA': 'J', 'J': 'J',
      'KA': 'K', 'K': 'K',
      'ELE': 'L', 'L': 'L',
      'EME': 'M', 'M': 'M',
      'ENE': 'N', 'N': 'N',
      'ENIE': 'Ñ', 'ENYE': 'Ñ', 'EÑE': 'Ñ', 'Ñ': 'Ñ',
      'O': 'O',
      'PE': 'P', 'P': 'P',
      'CU': 'Q', 'Q': 'Q', 'QU': 'Q',
      'ERE': 'R', 'ERRE': 'R', 'R': 'R',
      'ESE': 'S', 'S': 'S',
      'TE': 'T', 'T': 'T',
      'U': 'U',
      //? V con todas sus variantes
      'VE': 'V', 'UVE': 'V', 'V': 'V', 'UVE': 'V',
      'W': 'W', 'DOBLEVE': 'W', 'DOBLEUVE': 'W', 'DOBLEU': 'W', 'DOUBLEU': 'W',
      'EQUIS': 'X', 'X': 'X', 'EKIS': 'X',
      'YE': 'Y', 'IGRIEGA': 'Y', 'Y': 'Y',
      'ZETA': 'Z', 'Z': 'Z', 'ZEDA': 'Z',
      
      //? Contexto específico CURP
      'HOMBRE': 'H', 'VARON': 'H', 'VARONIL': 'H', 'MASCULINO': 'H',
      'MUJER': 'M', 'FEMENINO': 'M', 'FEMENINA': 'M',
      
      //? Números con variantes
      'CERO': '0', 'ZERO': '0', '0': '0',
      'UNO': '1', 'UN': '1', '1': '1',
      'DOS': '2', '2': '2',
      'TRES': '3', '3': '3',
      'CUATRO': '4', '4': '4',
      'CINCO': '5', '5': '5',
      'SEIS': '6', '6': '6',
      'SIETE': '7', '7': '7',
      'OCHO': '8', '8': '8',
      'NUEVE': '9', '9': '9',
      
      //* Casos especiales de confusión fonética
      'VA': 'B', //? "va" a veces se confunde con "be"
      'CA': 'K', //? "ca" -> K en algunos contextos
    };

    final List<String> out = [];
    int i = 0;

    _log('Iniciando mapeo inteligente...');

    while (i < tokens.length && out.length < 18) {
      String pick = '';
      int consumed = 0;

      _log('Procesando token $i: "${tokens[i]}" (salida actual: ${out.join()})');

      //* Buscar trigram (3 tokens)
      if (i + 2 < tokens.length) {
        final tri = '${tokens[i]} ${tokens[i + 1]} ${tokens[i + 2]}';
        if (phrases.containsKey(tri)) {
          pick = phrases[tri]!;
          consumed = 3;
          _log('Trigram encontrado: "$tri" -> "$pick"');
        }
      }
      
      //* Buscar bigram (2 tokens)
      if (pick.isEmpty && i + 1 < tokens.length) {
        final bi = '${tokens[i]} ${tokens[i + 1]}';
        if (phrases.containsKey(bi)) {
          pick = phrases[bi]!;
          consumed = 2;
          _log('Bigram encontrado: "$bi" -> "$pick"');
        }
      }
      
      //* Token individual
      if (pick.isEmpty) {
        final token = tokens[i];
        
        //* Si el token ya es alfanumérico válido y largo, úsalo
        if (RegExp(r'^[A-Z0-9]{2,}$').hasMatch(token)) {
          pick = cleanCurp(token);
          _log('Token alfanumérico largo: "$token" -> "$pick"');
        }
        //* Buscar en diccionario
        else if (single.containsKey(token)) {
          pick = single[token]!;
          _log('Token en diccionario: "$token" -> "$pick"');
        }
        //* Fallback inteligente
        else {
          pick = _intelligentFallback(token, i, tokens, out);
          _log('Fallback inteligente: "$token" -> "$pick"');
        }
        consumed = 1;
      }

      //* Agregar caracteres válidos al resultado
      if (pick.isNotEmpty) {
        for (var ch in pick.split('')) {
          if (RegExp(r'[A-Z0-9]').hasMatch(ch) && out.length < 18) {
            out.add(ch);
            _log('Agregado: "$ch" (posición ${out.length - 1})');
          }
        }
      }
      
      i += consumed;
    }

    _log('Resultado del mapeo: ${out.join()}');

    //! Si aún falta contenido, intentar rescatar del texto original
    if (out.length < 18) {
      final current = out.join();
      final fallbackText = cleanCurp(tokens.join(''));
      _log('Aplicando fallback para completar: actual="$current", texto="$fallbackText"');
      
      int start = 0;
      if (current.isNotEmpty && fallbackText.startsWith(current)) {
        start = current.length;
      }
      
      for (int k = start; k < fallbackText.length && out.length < 18; k++) {
        final ch = fallbackText[k];
        if (RegExp(r'[A-Z0-9]').hasMatch(ch)) {
          out.add(ch);
          _log('Completado con: "$ch"');
        }
      }
    }

    return out.join();
  }

  ///* Fallback inteligente que considera posición y contexto
  static String _intelligentFallback(String token, int position, List<String> allTokens, List<String> currentOutput) {
    _log('Fallback inteligente para "$token" en posición $position');
    
    //* Si es un solo carácter válido, úsalo
    if (token.length == 1 && RegExp(r'^[A-Z0-9]$').hasMatch(token)) {
      return token;
    }
    
    //* Buscar primer carácter alfanumérico válido
    final match = RegExp(r'[A-Z0-9]').firstMatch(token);
    if (match != null) {
      return match.group(0)!;
    }
    
    //! Si no hay nada válido, retornar vacío
    return '';
  }

  ///! Correcciones por posición (0..17) MEJORADAS:
  static String _applyPositionalCorrections(String s) {
    List<String> chars = cleanCurp(s).split('');
    if (chars.length < 18) return cleanCurp(s);

    _log('Aplicando correcciones posicionales: "$s"');

    //* Confusiones comunes mejoradas
    final Map<String, String> toDigit = {
      'O': '0', 'Q': '0', 'D': '0',
      'I': '1', 'L': '1', 'T': '1', //* T también se confunde con 1
      'Z': '2', 'S': '5', 'B': '8', 'G': '6', 
      'F': '7', //* F también se puede confundir con 7
    };
    
    final Map<String, String> toLetter = {
      '0': 'O', '1': 'I', '2': 'Z', '5': 'S', '6': 'G', '8': 'B',
    };

    //* Rangos donde esperamos dígitos
    bool expectsDigit(int i) => (i >= 4 && i <= 9) || i == 17;
    //* Rangos donde esperamos letras  
    bool expectsLetter(int i) => i <= 3 || (i >= 11 && i <= 15) || i == 16;

    for (int i = 0; i < 18; i++) {
      String c = chars[i];
      String original = c;

      if (expectsDigit(i)) {
        if (!_isDigit(c) && _isLetter(c)) {
          if (toDigit.containsKey(c)) {
            chars[i] = toDigit[c]!;
            _log('Posición $i: "$original" -> "${chars[i]}" (letra->dígito)');
          }
        }
      } else if (i == 10) {
        //* Posición del sexo (H/M) - casos especiales
        if (c == '0' || c == 'O') {
          chars[i] = 'H'; //* Asumir H si se confunde
          _log('Posición $i (sexo): "$original" -> "H" (asumiendo hombre)');
        } else if (c == '1' || c == 'I') {
          chars[i] = 'M'; //* o M si parece I
          _log('Posición $i (sexo): "$original" -> "M" (asumiendo mujer)');
        }
      } else if (expectsLetter(i)) {
        if (!_isLetter(c) && _isDigit(c)) {
          if (toLetter.containsKey(c)) {
            chars[i] = toLetter[c]!;
            _log('Posición $i: "$original" -> "${chars[i]}" (dígito->letra)');
          }
        }
      }
    }

    final result = chars.join();
    _log('Resultado correcciones posicionales: "$result"');
    return result;
  }

  static bool _isLetter(String c) => RegExp(r'^[A-Z]$').hasMatch(c);
  static bool _isDigit(String c) => RegExp(r'^[0-9]$').hasMatch(c);

  ///! Quita acentos/diacríticos de manera segura
  static String _removeDiacritics(String s) {
    const Map<String, String> map = {
      'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
      'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'Ñ': 'N', 'ñ': 'n',
      'Ç': 'C', 'ç': 'c',
    };

    final sb = StringBuffer();
    for (final ch in s.split('')) {
      sb.write(map[ch] ?? ch);
    }
    return sb.toString();
  }

  static void _log(Object msg) {
    if (_debug) print(msg);
  }
}