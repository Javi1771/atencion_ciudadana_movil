// lib/routes/app_routes.dart 
import 'package:app_atencion_ciudadana/screens/citizen_voice_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_atencion_ciudadana/screens/auth_screen.dart';
import 'package:app_atencion_ciudadana/screens/incidence_form_screen.dart';        //* elección
import 'package:app_atencion_ciudadana/screens/home_screen.dart';
import 'package:app_atencion_ciudadana/screens/incidence_voice_intake_screen.dart';//* NUEVO: por voz
import 'package:app_atencion_ciudadana/screens/incidence_steps_screen.dart';       //* manual

class AppRoutes {
  static const String auth = '/auth';
  static const String offlineForm = '/offlineForm';                       //* elección
  static const String offlineFormIncidence = '/offlineForm/incidence';    //* manual
  static const String offlineFormIncidenceVoice = '/offlineForm/incidence/voice'; //* VOZ
  static const String offlineCitizen = '/offlineForm/citizen'; //* Registro ciudadano 
  static const String home = '/home';

  static Map<String, WidgetBuilder> get routes => {
    auth: (_) => const AuthScreen(),
    offlineForm: (_) => const IncidenceFormScreen(),              //* elección
    offlineFormIncidence: (_) => const IncidenceStepsScreen(),   //* manual
    offlineFormIncidenceVoice: (_) => const VoiceIncidenceScreen(), //* VOZ
    offlineCitizen: (_) => const CitizenVoiceScreen(), //* Registro ciudadano
    home: (_) => const HomeScreen(),
  };
}
