// lib/screens/login_screen.dart

import 'package:coachhub/models/coach_model.dart';
import 'package:coachhub/screens/dashboard_screen.dart';
import 'package:coachhub/screens/registration_screen.dart';
import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/utils/form_validators.dart';
import 'dart:developer' as developer;
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:coachhub/blocs/auth/auth_bloc.dart';
import 'package:coachhub/blocs/auth/auth_event.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'julian@coach.com');
  final _passwordController = TextEditingController(text: '123456');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- Helper Methods ---

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isChecking = false;
    bool emailFound = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Recuperar Contraseña'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!emailFound) ...[
                      const Text(
                        'Ingresa tu correo electrónico para buscar tu cuenta.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Ingresa tu correo';
                          }
                          if (!val.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                    ] else ...[
                      const Text(
                        '¡Cuenta encontrada! Ingresa tu nueva contraseña.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nueva Contraseña',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (isChecking)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isChecking
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setState(() => isChecking = true);
                          final db = DatabaseConnection.instance;

                          try {
                            if (!emailFound) {
                              // Paso 1: Verificar email
                              final email = emailController.text
                                  .toLowerCase()
                                  .replaceAll("'", "''");
                              final results = await db.query(
                                "SELECT id FROM coaches WHERE LOWER(email) = '$email'",
                              );

                              if (results.isNotEmpty) {
                                setState(() {
                                  emailFound = true;
                                  isChecking = false;
                                });
                              } else {
                                setState(() => isChecking = false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Correo no encontrado'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              // Paso 2: Actualizar contraseña
                              final email = emailController.text
                                  .toLowerCase()
                                  .replaceAll("'", "''");
                              final newHash = BCrypt.hashpw(
                                passwordController.text,
                                BCrypt.gensalt(),
                              );

                              await db.query(
                                "UPDATE coaches SET password_hash = '$newHash' WHERE LOWER(email) = '$email'",
                              );

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Contraseña actualizada exitosamente',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isChecking = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: Text(emailFound ? 'Actualizar' : 'Buscar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Correo Electrónico',
        prefixIcon: Icons.email,
      ),
      keyboardType: TextInputType.emailAddress,
      validator:
          (val) =>
              val == null || val.isEmpty
                  ? 'Ingresa tu correo'
                  : !val.contains('@')
                  ? 'Correo no válido'
                  : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Contraseña',
        prefixIcon: Icons.lock,
      ),
      validator:
          (val) => val == null || val.isEmpty ? 'Ingresa tu contraseña' : null,
    );
  }

  // --- End Helper Methods ---

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final db = DatabaseConnection.instance;
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      // Escape manual del email para seguridad
      final escapedEmail = email.toLowerCase().replaceAll("'", "''");
      final sqlGetHash =
          "SELECT id, nombre, email, plan, password_hash, profile_picture_url FROM coaches WHERE LOWER(email) = '$escapedEmail'";

      final results = await db.query(sqlGetHash);

      if (!mounted) return;

      if (results.isNotEmpty) {
        final coachData = results.first.fields;
        final String storedHash = coachData['password_hash'] as String;

        // Comparar contraseña con Bcrypt
        final bool passwordMatch = BCrypt.checkpw(password, storedHash);

        if (passwordMatch) {
          developer.log(
            'Coach login exitoso: ${coachData['nombre']}',
            name: 'LoginScreen',
          );
          try {
            final coach = Coach.fromMap(coachData);

            // Emitir evento de login al AuthBloc
            if (!mounted) return;
            context.read<AuthBloc>().add(LoginEvent(coach));

            // Navegar al Dashboard
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DashboardScreen(coach: coach),
              ),
            );
          } catch (e, s) {
            developer.log(
              'Error al mapear datos del coach: $coachData',
              name: 'LoginScreen',
              error: e,
              stackTrace: s,
            );
            if (!mounted) return;
            scaffoldMessenger.showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Error al procesar datos: $e')),
                  ],
                ),
              ),
            );
            return;
          }
        } else {
          // Contraseña incorrecta
          scaffoldMessenger.showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Correo o contraseña incorrectos'),
                ],
              ),
            ),
          );
        }
      } else {
        // Usuario no encontrado
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: const Row(
              children: [
                Icon(Icons.person_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Correo o contraseña incorrectos'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error de conexión: $e')),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para adaptarnos si la ventana es muy pequeña
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(children: [_buildBrandingPanel(), _buildFormPanel()]),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Expanded(
      flex: 2,
      child: Container(
        color: AppColors.primary,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo/Logo CoachHUB.png',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              'CoachHub',
              style: AppStyles.title.copyWith(
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel() {
    return Expanded(
      flex: 3,
      child: Container(
        color: AppColors.card,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bienvenido de nuevo',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inicia sesión para gestionar tu día.',
                style: AppStyles.secondary,
              ),
              const SizedBox(height: 32),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _showForgotPasswordDialog();
                  },
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _login,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Text(
                          'Iniciar Sesión',
                          style: TextStyle(fontSize: 16),
                        ),
              ),

              // --- AÑADE ESTO ---
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿No tienes cuenta?', style: AppStyles.secondary),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistrationScreen(),
                        ),
                      );
                    },
                    child: const Text('Regístrate'),
                  ),
                ],
              ),
              // --- FIN DEL CÓDIGO AÑADIDO ---
            ],
          ),
        ),
      ),
    );
  }
}
