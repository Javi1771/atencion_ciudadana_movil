// lib/utils/curp_validator.dart
// ignore_for_file: avoid_print

class CurpValidator {
  static String? validate(String value) {
    print('=== VALIDACIÓN CURP ===');
    print('Valor original recibido: "$value"');
    print('Longitud original: ${value.length}');

    if (value.isEmpty) {
      print('Valor vacío, retornando null');
      return null;
    }

    // IMPORTANTE: Eliminar TODOS los espacios y convertir a mayúsculas
    String cleanedValue = value.replaceAll(' ', '').trim().toUpperCase();
    print('Valor después de eliminar espacios: "$cleanedValue"');
    print('Longitud después de limpiar: ${cleanedValue.length}');

    final curpRegex = RegExp(
      r'^[A-Z][AEIOUX][A-Z]{2}[0-9]{6}[HM][A-Z]{5}[A-Z0-9][0-9]$',
    );

    print('Regex CURP: ${curpRegex.pattern}');

    // Solo mostrar análisis detallado si la longitud es incorrecta
    if (cleanedValue.length != 18) {
      print(
        '\n⚠️ LONGITUD INCORRECTA: Se esperan 18 caracteres, se recibieron ${cleanedValue.length}',
      );
      _printDetailedAnalysis(cleanedValue);
    }

    // Verificaciones rápidas
    print('\nVerificaciones específicas:');

    // Longitud
    bool correctLength = cleanedValue.length == 18;
    print('✓ Longitud correcta (18): $correctLength');

    if (!correctLength) {
      print(
        'RESULTADO: Longitud incorrecta. Se esperan 18 caracteres, se recibieron ${cleanedValue.length}',
      );
      print('======================\n');
      return 'La CURP debe tener exactamente 18 caracteres. Verifique que haya dicho todos los caracteres.';
    }

    // Prueba del regex completo
    bool regexMatch = curpRegex.hasMatch(cleanedValue);
    print('✓ Coincide con formato CURP: $regexMatch');

    if (!regexMatch) {
      // Verificaciones detalladas para dar mejor mensaje de error
      if (!RegExp(r'^[A-Z]$').hasMatch(cleanedValue[0])) {
        print('RESULTADO: Primer carácter inválido');
        return 'El primer carácter debe ser una letra.';
      }

      if (!RegExp(r'^[AEIOUX]$').hasMatch(cleanedValue[1])) {
        print('RESULTADO: Segunda posición debe ser vocal');
        return 'El segundo carácter debe ser una vocal (A, E, I, O, U, X).';
      }

      if (!RegExp(r'^[0-9]{6}$').hasMatch(cleanedValue.substring(4, 10))) {
        print('RESULTADO: Fecha inválida');
        return 'Los caracteres 5 al 10 deben ser números (fecha de nacimiento).';
      }

      if (!RegExp(r'^[HM]$').hasMatch(cleanedValue[10])) {
        print('RESULTADO: Sexo inválido');
        return 'El carácter 11 debe ser H (hombre) o M (mujer).';
      }

      print('RESULTADO: Formato de CURP inválido - error general');
      print('======================\n');
      return 'El formato de CURP es inválido. Verifique que todos los caracteres sean correctos.';
    }

    print('✓ RESULTADO: CURP válido');
    print('======================\n');
    return null;
  }

  static void _printDetailedAnalysis(String cleanedValue) {
    print('Análisis carácter por carácter:');
    for (int i = 0; i < cleanedValue.length; i++) {
      String char = cleanedValue[i];
      String position = '';
      String expected = '';

      switch (i) {
        case 0:
          position = 'Primera letra del apellido paterno';
          expected = 'Letra A-Z';
          break;
        case 1:
          position = 'Primera vocal del apellido paterno';
          expected = 'Vocal (A, E, I, O, U, X)';
          break;
        case 2:
          position = 'Primera letra del apellido materno';
          expected = 'Letra A-Z';
          break;
        case 3:
          position = 'Primera letra del nombre';
          expected = 'Letra A-Z';
          break;
        case 4:
        case 5:
          position = 'Año de nacimiento (${i - 3}° dígito)';
          expected = 'Número 0-9';
          break;
        case 6:
        case 7:
          position = 'Mes de nacimiento (${i - 5}° dígito)';
          expected = 'Número 0-9';
          break;
        case 8:
        case 9:
          position = 'Día de nacimiento (${i - 7}° dígito)';
          expected = 'Número 0-9';
          break;
        case 10:
          position = 'Sexo';
          expected = 'H o M';
          break;
        case 11:
        case 12:
        case 13:
        case 14:
        case 15:
          position = 'Entidad federativa y consonantes (${i - 10}° carácter)';
          expected = 'Letra A-Z';
          break;
        case 16:
          position = 'Diferenciador';
          expected = 'Letra A-Z o número 0-9';
          break;
        case 17:
          position = 'Dígito verificador';
          expected = 'Número 0-9';
          break;
        default:
          position = 'Carácter extra (no debería existir)';
          expected = 'N/A';
      }

      print('Posición $i: "$char" - $position - Esperado: $expected');
    }
  }

  /// Limpia una CURP eliminando espacios y convirtiéndola a mayúsculas
  static String cleanCurp(String curp) {
    return curp.replaceAll(' ', '').trim().toUpperCase();
  }

  /// Verifica si una CURP tiene el formato básico correcto
  static bool hasValidFormat(String curp) {
    final cleaned = cleanCurp(curp);
    if (cleaned.length != 18) return false;
    
    final curpRegex = RegExp(
      r'^[A-Z][AEIOUX][A-Z]{2}[0-9]{6}[HM][A-Z]{5}[A-Z0-9][0-9]$',
    );
    
    return curpRegex.hasMatch(cleaned);
  }
}