import 'package:flutter/material.dart';
import 'package:atencion_ciudadana/screens/auth_screen.dart';
import 'package:atencion_ciudadana/screens/incidence_form_screen.dart';
import 'package:atencion_ciudadana/screens/home_screen.dart';

class AppRoutes {
  static const String auth = '/auth';
  static const String offlineForm = '/offlineForm';
  static const String home = '/home';

  static Map<String, WidgetBuilder> get routes {
    return {
      auth: (_) => const AuthScreen(),
      offlineForm: (_) => const IncidenceFormScreen(),
      home: (_) => const HomeScreen(),
    };
  }
}
