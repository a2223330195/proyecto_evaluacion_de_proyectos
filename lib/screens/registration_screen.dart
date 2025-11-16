// lib/screens/registration_screen.dart
import 'dart:io';
import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/services/image_service.dart';
import 'package:coachhub/services/image_compression_service.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/utils/form_validators.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  File? _profilePicture; // Para almacenar la foto seleccionada
  final _imagePicker = ImagePicker();

  // --- Helper Methods for Form Fields ---

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Nombre Completo',
        prefixIcon: Icons.person,
      ),
      validator: FormValidators.validateNombre,
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
          (val) =>
              val == null || val.isEmpty
                  ? 'Ingresa tu contraseña'
                  : val.length < 6
                  ? 'Mínimo 6 caracteres'
                  : null,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: true,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Confirmar Contraseña',
        prefixIcon: Icons.lock_outline,
      ),
      validator:
          (val) => val == null || val.isEmpty ? 'Confirma tu contraseña' : null,
    );
  }

  // Widget para seleccionar foto de perfil
  Widget _buildProfilePictureSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_profilePicture != null)
              // Mostrar foto seleccionada
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_profilePicture!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                        onPressed: () => setState(() => _profilePicture = null),
                      ),
                    ),
                  ),
                ],
              )
            else
              // Mostrar placeholder
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 12),
            Text('Foto de Perfil', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.image, color: Colors.white),
              label: Text(
                _profilePicture != null ? 'Cambiar Foto' : 'Seleccionar Foto',
              ),
              onPressed: _pickProfilePicture,
            ),
            const SizedBox(height: 8),
            Text(
              'Opcional - Puedes agregar tu foto de perfil ahora o después',
              style: AppStyles.secondary.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Método para seleccionar foto
  Future<void> _pickProfilePicture() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() => _profilePicture = File(pickedFile.path));
    }
  }

  // --- End Helper Methods ---

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Las contraseñas no coinciden'),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final db = DatabaseConnection.instance;
    final email = _emailController.text.trim().toLowerCase();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 1. Verificar si el email ya existe
      final escapedEmail = email.replaceAll("'", "''");
      final checkSql =
          "SELECT email FROM coaches WHERE LOWER(email) = '$escapedEmail' LIMIT 1";
      final checkResults = await db.query(checkSql);

      if (checkResults.isNotEmpty) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange,
            content: const Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('Este correo ya está registrado'),
              ],
            ),
          ),
        );
        return;
      }

      // 2. Hash de contraseña
      final String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // 3. Guardar foto de perfil si existe
      String? profilePictureUrl;
      if (_profilePicture != null) {
        try {
          // Comprimir foto antes de guardar (-76% tamaño)
          final compressed = await ImageCompressionService.compressImage(
            imageFile: _profilePicture!,
            targetMaxWidth: 500,
            targetMaxHeight: 500,
            quality: 80,
          );

          // Usar timestamp como ID único para la foto
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          profilePictureUrl = await ImageService.saveCoachProfilePicture(
            compressed,
            timestamp,
          );
        } catch (e) {
          // Log error pero continuar sin foto
          debugPrint('Error comprimiendo/guardando foto: $e');
        }
      }

      // 4. Insertar coach en BD
      final insertSql =
          'INSERT INTO coaches (nombre, email, password_hash, profile_picture_url) VALUES (?, ?, ?, ?)';
      await db.query(insertSql, [
        name,
        email,
        hashedPassword,
        profilePictureUrl,
      ]);

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('¡Registro exitoso! Inicia sesión ahora')),
            ],
          ),
        ),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: $e')),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Crear Cuenta',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ingresa tus datos para comenzar.',
                        style: AppStyles.secondary,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildEmailField(),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      const SizedBox(height: 16),
                      _buildConfirmPasswordField(),
                      const SizedBox(height: 24),
                      _buildProfilePictureSelector(),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isLoading ? null : _register,
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
                                  'Crear Cuenta',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('¿Ya tienes cuenta? Inicia Sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
