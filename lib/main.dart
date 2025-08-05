import 'package:atencion_ciudadana/widgets/alert_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:atencion_ciudadana/services/connectivity_service.dart';
import 'package:atencion_ciudadana/routes/routes.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        // aquí más providers (Auth, IncidenciasRepo…)
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atención Ciudadana',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AlertHelper.messengerKey,
      theme: ThemeData(
        primaryColor: const Color(0xFF6D1F70),
        colorScheme: ColorScheme.fromSwatch(
          accentColor: const Color(0xFF6D1F70),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF6D1F70)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6D1F70),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      initialRoute: '/auth',
      routes: AppRoutes.routes,
    );
  }
}
