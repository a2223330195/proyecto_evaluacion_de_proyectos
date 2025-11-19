import 'dart:io';
import 'package:bcrypt/bcrypt.dart';
import 'package:coachhub/blocs/auth/auth_bloc.dart';
import 'package:coachhub/blocs/auth/auth_event.dart';
import 'package:coachhub/models/coach_model.dart';
import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/services/image_service.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CoachProfileScreen extends StatefulWidget {
  final Coach coach;

  const CoachProfileScreen({super.key, required this.coach});

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  File? _imageFile;
  bool _isLoading = false;
  bool _isEditingPassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.coach.nombre);
    _emailController = TextEditingController(text: widget.coach.email);
    _passwordController = TextEditingController();
    _loadCurrentProfilePicture();
  }

  Future<void> _loadCurrentProfilePicture() async {
    if (widget.coach.profilePictureUrl != null) {
      final file = await ImageService.getCoachProfilePicture(
        widget.coach.profilePictureUrl,
      );
      if (mounted && file != null) {
        setState(() {
          _imageFile = file;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImageService.pickImageFromDevice();
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = DatabaseConnection.instance;
      String? newProfilePictureUrl = widget.coach.profilePictureUrl;

      // 1. Guardar imagen si se seleccionó una nueva
      if (_imageFile != null) {
        newProfilePictureUrl = await ImageService.saveCoachProfilePicture(
          _imageFile!,
          widget.coach.id,
          oldImagePath: widget.coach.profilePictureUrl,
        );
      }

      // 2. Actualizar contraseña si se proporcionó
      String? passwordHash;
      if (_isEditingPassword && _passwordController.text.isNotEmpty) {
        passwordHash = BCrypt.hashpw(
          _passwordController.text,
          BCrypt.gensalt(),
        );
      }

      // 3. Actualizar base de datos
      final nombre = _nameController.text.replaceAll("'", "''");
      final email = _emailController.text.replaceAll("'", "''");

      final updateQuery = StringBuffer("UPDATE coaches SET ");
      updateQuery.write("nombre = '$nombre', ");
      updateQuery.write("email = '$email'");

      if (newProfilePictureUrl != null) {
        final escapedUrl = newProfilePictureUrl.replaceAll("'", "''");
        updateQuery.write(", profile_picture_url = '$escapedUrl'");
      }

      if (passwordHash != null) {
        final escapedHash = passwordHash.replaceAll("'", "''");
        updateQuery.write(", password_hash = '$escapedHash'");
      }

      updateQuery.write(" WHERE id = ${widget.coach.id}");

      await db.query(updateQuery.toString());

      // 4. Actualizar estado global
      final updatedCoach = Coach(
        id: widget.coach.id,
        nombre: _nameController.text,
        email: _emailController.text,
        plan: widget.coach.plan,
        profilePictureUrl: newProfilePictureUrl,
      );

      if (!mounted) return;
      context.read<AuthBloc>().add(UpdateCoachProfileEvent(updatedCoach));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar perfil: $e'),
          backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildProfileImage(),
                      const SizedBox(height: 32),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nombre Completo',
                        icon: Icons.person,
                        validator:
                            (v) =>
                                v?.isEmpty == true
                                    ? 'El nombre es requerido'
                                    : null,
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Correo Electrónico',
                        icon: Icons.email,
                        validator:
                            (v) =>
                                v?.isEmpty == true || !v!.contains('@')
                                    ? 'Correo inválido'
                                    : null,
                      ),
                      const SizedBox(height: 24),
                      _buildPasswordSection(),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    'Guardar Cambios',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
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

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
            child:
                _imageFile == null
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _isEditingPassword,
              onChanged: (val) {
                setState(() {
                  _isEditingPassword = val ?? false;
                  if (!_isEditingPassword) {
                    _passwordController.clear();
                  }
                });
              },
              activeColor: AppColors.primary,
            ),
            const Text('Cambiar contraseña'),
          ],
        ),
        if (_isEditingPassword) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Nueva Contraseña',
            icon: Icons.lock,
            obscureText: true,
            validator:
                (v) =>
                    _isEditingPassword && (v == null || v.length < 6)
                        ? 'Mínimo 6 caracteres'
                        : null,
          ),
        ],
      ],
    );
  }
}
