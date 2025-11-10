import 'package:coachhub/screens/login_screen.dart'; // Importa tu pantalla de login
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/services/db_connection.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- AÑADE ESTA LÍNEA

Future<void> main() async {
  // <-- AÑADE 'Future<void>' y 'async'
  WidgetsFlutterBinding.ensureInitialized(); // <-- AÑADE ESTA LÍNEA
  await initializeDateFormatting('es_ES', null); // <-- AÑADE ESTA LÍNEA

  // Inicializar conexión a la base de datos y ejecutar seeding
  await DatabaseConnection.instance.connection;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoachHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.accentPurple,
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      ),
      home: const LoginScreen(), // <-- REGRESA A LOGINSCREEN
    );
  }
}
