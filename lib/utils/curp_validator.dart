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
    _log('=== VALIDACIÓN CURP (robusta voz) ===');
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
  ///* Soporta:
  /// - Nombres de letras: "eme"->M, "uve/ve"->V, "hache"->H, "equis"->X, etc.
  /// - "doble ve", "doble u", "doble uve" -> W
  /// - Números en palabras: "cero"->0 ... "nueve"->9
  /// - Elimina "guion"/"-" y signos.
  /// - Mapea "hombre"->H, "mujer"->M (por si el STT lo mete).
  static String _normalizeVoiceToCurp(String input) {
    String text = _removeDiacritics(input.toUpperCase());
    //! Elimina símbolos comunes
    text = text.replaceAll(RegExp(r'[\.\,\;\:\_\(\)\[\]\{\}\|\\\/]'), ' ');
    //! Palabras irrelevantes
    text = text.replaceAll(
      RegExp(r'\b(GUION|GUIONMEDIO|GUION BAJO|GUION-BAJO|GUION-MEDIO)\b'),
      ' ',
    );
    text = text.replaceAll(RegExp(r'\bESPACIO(S)?\b'), ' ');

    //* Tokenizar
    final tokens = text
        .split(RegExp(r'[^A-Z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    _log('Tokens: $tokens');

    //? FIX 1: si viene como una sola pieza alfanumérica, úsala directamente
    if (tokens.length == 1 && RegExp(r'^[A-Z0-9]{12,}$').hasMatch(tokens[0])) {
      final curpRaw = cleanCurp(tokens[0]);
      return curpRaw.length <= 18 ? curpRaw : curpRaw.substring(0, 18);
    }

    //* Frases (multi-palabra) primero
    final Map<String, String> phrases = {
      'DOBLE VE': 'W',
      'DOBLE UVE': 'W',
      'DOBLE U': 'W',
      'VE CHICA': 'V',
      'VE PEQUENA': 'V',
      'VE PEQUEÑA': 'V',
      'V CHICA': 'V',
      'B GRANDE': 'B',
      'BE GRANDE': 'B',
      'I GRIEGA': 'Y',
      'Y GRIEGA': 'Y',
      'GUE': 'G',
    };

    //* Palabras simples
    final Map<String, String> single = {
      'A': 'A',
      'BE': 'B',
      'B': 'B',
      'VE': 'V',
      'UVE': 'V',
      'V': 'V',
      'CE': 'C',
      'C': 'C',
      'DE': 'D',
      'D': 'D',
      'E': 'E',
      'EFE': 'F',
      'F': 'F',
      'GE': 'G',
      'G': 'G',
      'JE': 'G',
      'HACHE': 'H',
      'H': 'H',
      'I': 'I',
      'JOTA': 'J',
      'J': 'J',
      'KA': 'K',
      'K': 'K',
      'ELE': 'L',
      'L': 'L',
      'EME': 'M',
      'M': 'M',
      'ENE': 'N',
      'N': 'N',
      'ENIE': 'X',
      'ENYE': 'X',
      'EÑE': 'X',
      'EQUIS': 'X',
      'X': 'X',
      'YE': 'Y',
      'IGRIEGA': 'Y',
      'Y': 'Y',
      'ZETA': 'Z',
      'Z': 'Z',
      'ERRE': 'R',
      'R': 'R',
      'DOBLEVE': 'W',
      'DOBLEUVE': 'W',
      'DOBLEU': 'W',
      'W': 'W',
      'DOUBLEU': 'W',
      'HOMBRE': 'H',
      'VARON': 'H',
      'VARONIL': 'H',
      'MUJER': 'M',
      'FEMENINO': 'M',
      'FEMENINA': 'M',
      'CERO': '0',
      'UNO': '1',
      'DOS': '2',
      'TRES': '3',
      'CUATRO': '4',
      'CINCO': '5',
      'SEIS': '6',
      'SIETE': '7',
      'OCHO': '8',
      'NUEVE': '9',
      '0': '0',
      '1': '1',
      '2': '2',
      '3': '3',
      '4': '4',
      '5': '5',
      '6': '6',
      '7': '7',
      '8': '8',
      '9': '9',
    };

    final List<String> out = [];
    int i = 0;

    while (i < tokens.length && out.length < 18) {
      String pick = '';
      int consumed = 0;

      //* trigram
      if (i + 2 < tokens.length) {
        final tri = _removeDiacritics(
          '${tokens[i]} ${tokens[i + 1]} ${tokens[i + 2]}',
        );
        if (phrases.containsKey(tri)) {
          pick = phrases[tri]!;
          consumed = 3;
        }
      }
      //* bigram
      if (pick.isEmpty && i + 1 < tokens.length) {
        final bi = _removeDiacritics('${tokens[i]} ${tokens[i + 1]}');
        if (phrases.containsKey(bi)) {
          pick = phrases[bi]!;
          consumed = 2;
        }
      }
      //* single
      if (pick.isEmpty) {
        //* Si el token ya es alfanumérico de más de 1 char, úsalo tal cual
        final raw = cleanCurp(tokens[i]);
        if (RegExp(r'^[A-Z0-9]{2,}$').hasMatch(raw)) {
          pick = raw;
        } else {
          final key = _removeDiacritics(tokens[i]);
          pick = single[key] ?? _fallbackTokenToChar(tokens[i]);
        }
        consumed = 1;
      }

      if (pick.isNotEmpty) {
        for (var ch in pick.split('')) {
          if (RegExp(r'[A-Z0-9]').hasMatch(ch)) {
            out.add(ch);
            if (out.length == 18) break;
          }
        }
      }
      i += consumed;
    }

    //? FIX 2: Relleno sin duplicar prefijo
    if (out.length < 18) {
      final fallback = cleanCurp(text);
      final current = out.join();
      int start = 0;
      if (current.isNotEmpty && fallback.startsWith(current)) {
        start = current.length;
      }
      for (int k = start; k < fallback.length && out.length < 18; k++) {
        final ch = fallback[k];
        if (RegExp(r'[A-Z0-9]').hasMatch(ch)) {
          out.add(ch);
        }
      }
    }

    return out.join();
  }

  ///! Si el token no coincide con diccionarios, intenta inferir:
  /// - Token de una letra ya válida
  /// - Token de un dígito
  /// - Primer carácter alfanumérico del token
  static String _fallbackTokenToChar(String token) {
    final t = _removeDiacritics(token.toUpperCase());
    if (t.length == 1 && RegExp(r'^[A-Z0-9]$').hasMatch(t)) return t;
    final m = RegExp(r'[A-Z0-9]').firstMatch(t);
    return m != null ? m.group(0)! : '';
  }

  ///! Correcciones por posición (0..17):
  /// - 0,1,2,3,11..15: letras
  /// - 4..9: dígitos (fecha AAMMDD)
  /// - 10: H/M
  /// - 16: letra o dígito
  /// - 17: dígito
  static String _applyPositionalCorrections(String s) {
    List<String> chars = cleanCurp(s).split('');
    if (chars.length < 18) return cleanCurp(s);

    //* Confusiones comunes
    final Map<String, String> toDigit = {
      'O': '0',
      'Q': '0',
      'D': '0',
      'I': '1',
      'L': '1',
      'Z': '2',
      'S': '5',
      'B': '8',
      'G': '6',
      'T': '7',
    };
    final Map<String, String> toLetter = {
      '0': 'O',
      '1': 'I',
      '2': 'Z',
      '5': 'S',
    };

    bool inDigitsRange(int i) => (i >= 4 && i <= 9) || i == 17;

    for (int i = 0; i < 18; i++) {
      String c = chars[i];

      if (inDigitsRange(i)) {
        if (!_isDigit(c)) {
          if (toDigit.containsKey(c)) {
            chars[i] = toDigit[c]!;
          } else if (_isLetter(c)) {
            if (c == 'O')
              chars[i] = '0';
            else if (c == 'I' || c == 'L')
              chars[i] = '1';
            else if (c == 'Z')
              chars[i] = '2';
            else if (c == 'S')
              chars[i] = '5';
          }
        }
      } else if (i == 10) {
        //* Sexo H/M
        //* si no es H/M lo dejamos; el regex lo detectará
      } else {
        if (!_isLetter(c)) {
          if (toLetter.containsKey(c)) chars[i] = toLetter[c]!;
        }
      }
    }

    return chars.join();
  }

  static bool _isLetter(String c) => RegExp(r'^[A-Z]$').hasMatch(c);
  static bool _isDigit(String c) => RegExp(r'^[0-9]$').hasMatch(c);

  ///! Quita acentos/diacríticos de manera segura (sin usar índices paralelos).
  static String _removeDiacritics(String s) {
    //* Mapeo seguro (MAYÚSCULAS y minúsculas por si acaso)
    const Map<String, String> map = {
      //? A
      'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
      //? E
      'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      //? I
      'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      //? O
      'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      //? U
      'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      //? Ñ
      'Ñ': 'N', 'ñ': 'n',
      //? Otros comunes
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
