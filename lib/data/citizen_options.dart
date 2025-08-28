// lib/data/citizen_options.dart

class CitizenOptions {
  static List<String> sexos = [
    'Masculino',
    'Femenino',
  ];

  static List<String> estados = [
    'Aguascalientes',
    'Baja California',
    'Baja California Sur',
    'Campeche',
    'Chiapas',
    'Chihuahua',
    'Ciudad de México',
    'Coahuila',
    'Colima',
    'Durango',
    'Estado de México',
    'Guanajuato',
    'Guerrero',
    'Hidalgo',
    'Jalisco',
    'Michoacán',
    'Morelos',
    'Nayarit',
    'Nuevo León',
    'Oaxaca',
    'Puebla',
    'Querétaro',
    'Quintana Roo',
    'San Luis Potosí',
    'Sinaloa',
    'Sonora',
    'Tabasco',
    'Tamaulipas',
    'Tlaxcala',
    'Veracruz',
    'Yucatán',
    'Zacatecas',
  ];

  //* Dominios comunes de email para ayudar en el reconocimiento por voz
  static List<String> emailDomains = [
    'gmail.com',
    'hotmail.com',
    'yahoo.com.mx',
    'outlook.com',
    'live.com',
    'prodigy.net.mx',
    'terra.com.mx',
    'msn.com',
  ];

  //* Palabras comunes que se pueden confundir en reconocimiento de voz
  static Map<String, String> voiceCorrections = {
    //? Números que se confunden
    'uno': '1',
    'dos': '2', 
    'tres': '3',
    'cuatro': '4',
    'cinco': '5',
    'seis': '6',
    'siete': '7',
    'ocho': '8',
    'nueve': '9',
    'cero': '0',
    
    //? Sexo
    'hombre': 'Masculino',
    'mujer': 'Femenino',
    'varón': 'Masculino',
    'dama': 'Femenino',
    'caballero': 'Masculino',
    'señora': 'Femenino',
    'señorita': 'Femenino',
    
    //? Estados que se confunden por voz
    'méxico': 'Estado de México',
    'cdmx': 'Ciudad de México',
    'df': 'Ciudad de México',
    'distrito federal': 'Ciudad de México',
    'queretaro': 'Querétaro',
    'michoacan': 'Michoacán',
    'yucatan': 'Yucatán',
    'leon': 'Nuevo León',
    
    //? Email símbolos
    'arroba': '@',
    'punto': '.',
    'guion': '-',
    'guión': '-',
    'bajo': '_',
    'baja': '_',
    'guion bajo': '_',
    'guión bajo': '_',
  };

  //* Patrones comunes de teléfono mexicano
  static List<RegExp> phonePatterns = [
    RegExp(r'^\d{10}$'), //* 10 dígitos
    RegExp(r'^\+52\d{10}$'), //* +52 + 10 dígitos
    RegExp(r'^52\d{10}$'), //* 52 + 10 dígitos
    RegExp(r'^\d{3}-\d{3}-\d{4}$'), //* formato con guiones
  ];
}