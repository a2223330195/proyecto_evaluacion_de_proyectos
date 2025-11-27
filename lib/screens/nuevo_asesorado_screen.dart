// lib/screens/nuevo_asesorado_screen.dart

import 'dart:io';
import 'package:coachhub/screens/planes_editor_screen.dart';
import 'package:coachhub/services/asesorados_service.dart';
import 'package:coachhub/services/image_service.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/utils/form_validators.dart';
import 'package:coachhub/widgets/validated_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/asesorado_model.dart';
import '../models/plan_model.dart';
import '../utils/string_formatters.dart';

class NuevoAsesoradoScreen extends StatefulWidget {
  final Asesorado? asesorado; // Optional parameter for editing
  final int? coachId; // Coach ID for new asesorados

  const NuevoAsesoradoScreen({super.key, this.asesorado, this.coachId});

  @override
  NuevoAsesoradoScreenState createState() => NuevoAsesoradoScreenState();
}

class NuevoAsesoradoScreenState extends State<NuevoAsesoradoScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late TabController _tabController;

  // Gestión de imágenes
  XFile? _selectedProfileImage;
  String? _existingImagePath; // Ruta de imagen existente si está editando
  bool _imageMarkedForDeletion = false;

  // Planes cargados dinámicamente
  List<Plan> _planes = [];
  int? _selectedPlanId;
  bool _isLoadingPlanes = true;
  String? _loadPlanesError;

  final _dueDateController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  int? _calculatedAge;
  final _sexoOptions = ['Masculino', 'Femenino', 'Otro', 'NoEspecifica'];
  String? _selectedSexo;
  final _alturaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaInicioController = TextEditingController();
  final _objetivoPrincipalController = TextEditingController();
  final _objetivoSecundarioController = TextEditingController();
  AsesoradoStatus _selectedStatus = AsesoradoStatus.activo;

  // Estado de carga
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dueDateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _selectFechaInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _fechaInicioController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _selectFechaNacimiento(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _fechaNacimientoController.text.isNotEmpty
              ? DateTime.parse(_fechaNacimientoController.text)
              : DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimientoController.text = "${picked.toLocal()}".split(' ')[0];
        // Calcular edad automáticamente
        final now = DateTime.now();
        int calculatedAge = now.year - picked.year;
        if (now.month < picked.month ||
            (now.month == picked.month && now.day < picked.day)) {
          calculatedAge--;
        }
        _calculatedAge = calculatedAge;
      });
    }
  }

  Future<void> _loadPlanes() async {
    try {
      setState(() {
        _isLoadingPlanes = true;
        _loadPlanesError = null;
      });

      final asesoradosService = AsesoradosService();
      final planes = await asesoradosService.getPlanesForCoach(widget.coachId);

      setState(() {
        _planes = planes;
        _isLoadingPlanes = false;

        if (_planes.isNotEmpty) {
          final currentPlanExists =
              _selectedPlanId != null &&
              _planes.any((plan) => plan.id == _selectedPlanId);
          if (!currentPlanExists) {
            _selectedPlanId = _planes.first.id;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPlanes = false;
          _loadPlanesError = 'Error al cargar planes: $e';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlanes();

    if (widget.asesorado != null) {
      // Populate fields if in edit mode
      final asesorado = widget.asesorado!;
      _nameController.text = asesorado.name;
      _existingImagePath = asesorado.avatarUrl;
      _selectedPlanId = asesorado.planId;
      _dueDateController.text =
          asesorado.dueDate?.toIso8601String().split('T')[0] ?? '';
      _fechaNacimientoController.text =
          asesorado.fechaNacimiento?.toIso8601String().split('T')[0] ?? '';
      _calculatedAge = asesorado.edad;
      _selectedSexo = asesorado.sexo;
      _alturaController.text = asesorado.alturaCm?.toString() ?? '';
      _telefonoController.text = asesorado.telefono ?? '';
      _fechaInicioController.text =
          asesorado.fechaInicioPrograma?.toIso8601String().split('T')[0] ?? '';
      _objetivoPrincipalController.text = asesorado.objetivoPrincipal ?? '';
      _objetivoSecundarioController.text = asesorado.objetivoSecundario ?? '';
      _selectedStatus = asesorado.status;
    }
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _tabController.dispose();
    _nameController.dispose();
    _dueDateController.dispose();
    _fechaNacimientoController.dispose();
    _alturaController.dispose();
    _telefonoController.dispose();
    _fechaInicioController.dispose();
    _objetivoPrincipalController.dispose();
    _objetivoSecundarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.asesorado == null
              ? 'Crear Nuevo Asesorado'
              : 'Editar Asesorado',
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          tabs: const [
            Tab(text: 'Perfil', icon: Icon(Icons.person, color: Colors.white)),
            Tab(
              text: 'Membresía',
              icon: Icon(Icons.card_membership, color: Colors.white),
            ),
            Tab(text: 'Objetivos', icon: Icon(Icons.flag, color: Colors.white)),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: PERFIL
            _buildProfileTab(),
            // TAB 2: MEMBRESÍA
            _buildMembershipTab(),
            // TAB 3: OBJETIVOS Y ESTADO
            _buildObjectivesTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _handleSaveAsesorado,
        backgroundColor: _isLoading ? Colors.grey : AppColors.primary,
        tooltip: 'Guardar asesorado',
        child:
            _isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
                : const Icon(Icons.save, color: Colors.white),
      ),
    );
  }

  /// TAB 1: Información de Perfil
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Tarjeta destacada del tab
        _buildTabHeaderCard(
          icon: Icons.person,
          title: 'Perfil',
          subtitle: 'Información personal del asesorado',
          color: Colors.blue,
        ),
        const SizedBox(height: 24),

        // Sección: Foto de Perfil
        _buildProfileImageSection(),
        const SizedBox(height: 24),

        // Sección: Información Personal
        _buildSectionTitle('Información Personal'),
        const SizedBox(height: 12),
        _buildNameField(),
        const SizedBox(height: 12),
        _buildAgeAndGenderRow(),
        const SizedBox(height: 12),
        _buildHeightAndPhoneRow(),
        const SizedBox(height: 32),
      ],
    );
  }

  /// TAB 2: Plan y Membresía
  Widget _buildMembershipTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Tarjeta destacada del tab
        _buildTabHeaderCard(
          icon: Icons.card_membership,
          title: 'Membresía',
          subtitle: 'Gestiona el plan y vigencia del asesorado',
          color: Colors.teal,
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('Plan y Membresía'),
        const SizedBox(height: 12),
        _buildPlanDropdown(),
        const SizedBox(height: 8),
        _buildManagePlansButton(),
        const SizedBox(height: 24),
        _buildStartDateField(),
        const SizedBox(height: 24),
        _buildDueDateField(),
        const SizedBox(height: 24),
        _buildSectionTitle('Estado'),
        const SizedBox(height: 12),
        _buildStatusDropdown(),
        const SizedBox(height: 32),
      ],
    );
  }

  /// TAB 3: Objetivos y Estado
  Widget _buildObjectivesTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Tarjeta destacada del tab
        _buildTabHeaderCard(
          icon: Icons.flag,
          title: 'Objetivos',
          subtitle: 'Define las metas del programa de entrenamiento',
          color: Colors.orange,
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('Objetivos del Programa'),
        const SizedBox(height: 12),
        _buildMainObjectiveField(),
        const SizedBox(height: 12),
        _buildSecondaryObjectiveField(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDefaultAvatar(double previewSize) {
    return Container(
      width: previewSize,
      height: previewSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey, width: 2),
      ),
      child: const Icon(Icons.person, size: 60),
    );
  }

  /// Construye el preview de la imagen
  Widget _buildImagePreview() {
    const double previewSize = 120.0;

    if (_imageMarkedForDeletion) {
      return _buildDefaultAvatar(previewSize);
    }

    // Si hay imagen nueva seleccionada
    if (_selectedProfileImage != null) {
      return FutureBuilder<Uint8List?>(
        future: _selectedProfileImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Container(
              width: previewSize,
              height: previewSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(previewSize / 2),
                child: Image.memory(snapshot.data!, fit: BoxFit.cover),
              ),
            );
          }
          return const SizedBox(
            width: previewSize,
            height: previewSize,
            child: CircularProgressIndicator(),
          );
        },
      );
    }

    // Si hay imagen existente (editando)
    if (_existingImagePath != null && _existingImagePath!.isNotEmpty) {
      return FutureBuilder<File?>(
        future: ImageService.getProfilePicture(_existingImagePath),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Container(
              width: previewSize,
              height: previewSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(previewSize / 2),
                child: Image.file(snapshot.data!, fit: BoxFit.cover),
              ),
            );
          }
          return _buildDefaultAvatar(previewSize);
        },
      );
    }

    // Sin imagen
    return _buildDefaultAvatar(previewSize);
  }

  /// Abre el selector de imagen
  Future<void> _selectProfileImage() async {
    try {
      final imageFile = await ImageService.pickImageFromDevice();
      if (imageFile != null) {
        setState(() {
          _selectedProfileImage = imageFile;
          _imageMarkedForDeletion = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  /// Elimina la imagen seleccionada
  void _removeProfileImage() {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Eliminar Imagen'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar la imagen de perfil?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedProfileImage = null;
                    // No eliminar _existingImagePath aquí, se eliminará al guardar si es necesario
                    _imageMarkedForDeletion = true;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  // ===== MÉTODOS HELPER PARA CONSTRUIR WIDGETS =====

  /// Tarjeta destacada para la cabecera de cada pestaña con icon, título y color de fondo
  Widget _buildTabHeaderCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildNameField() {
    return ValidatedTextField(
      controller: _nameController,
      labelText: 'Nombre completo',
      hintText: 'Ej: Juan Pérez García',
      prefixIcon: Icons.person,
      validator: FormValidators.validateNombre,
      keyboardType: TextInputType.text,
      isRequired: true,
    );
  }

  Widget _buildAgeAndGenderRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fechaNacimientoController,
                decoration: FormFieldStyles.buildInputDecoration(
                  labelText: 'Fecha de Nacimiento',
                  prefixIcon: Icons.cake,
                ),
                readOnly: true,
                onTap: () => _selectFechaNacimiento(context),
                validator: FormValidators.validateFechaNacimiento,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedSexo,
                decoration: FormFieldStyles.buildInputDecoration(
                  labelText: 'Sexo',
                  prefixIcon: Icons.wc,
                ),
                items:
                    _sexoOptions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(formatUserFacingLabel(s)),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _selectedSexo = v),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona un sexo';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        if (_calculatedAge != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE6E9F0), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edad calculada: $_calculatedAge años',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeightAndPhoneRow() {
    return Row(
      children: [
        Expanded(
          child: ValidatedTextField(
            controller: _alturaController,
            labelText: 'Altura (cm)',
            hintText: '175',
            prefixIcon: Icons.height,
            validator: FormValidators.validateAltura,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            isRequired: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ValidatedTextField(
            controller: _telefonoController,
            labelText: 'Teléfono',
            hintText: '+1 234 567 8900',
            prefixIcon: Icons.phone,
            validator: FormValidators.validateTelefono,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            isRequired: true,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Foto de Perfil', style: AppStyles.titleStyle),
          const SizedBox(height: 16),
          Center(child: _buildImagePreview()),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _selectProfileImage,
                icon: const Icon(Icons.image, color: Colors.white),
                label: Text(
                  _selectedProfileImage != null
                      ? 'Cambiar Imagen'
                      : 'Seleccionar Imagen',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              if (_selectedProfileImage != null || _existingImagePath != null)
                ElevatedButton.icon(
                  onPressed: _removeProfileImage,
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainObjectiveField() {
    return TextFormField(
      controller: _objetivoPrincipalController,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Objetivo Principal',
        hintText: 'Perder 5 kg en 3 meses',
        prefixIcon: Icons.assignment,
      ),
      maxLines: 3,
      validator: FormValidators.validateObjetivo,
      textInputAction: TextInputAction.newline,
    );
  }

  Widget _buildSecondaryObjectiveField() {
    return TextFormField(
      controller: _objetivoSecundarioController,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Objetivo Secundario',
        hintText: 'Mejorar resistencia cardiovascular',
        prefixIcon: Icons.assignment_add,
      ),
      maxLines: 3,
      validator: FormValidators.validateObjetivo,
      textInputAction: TextInputAction.newline,
    );
  }

  Widget _buildPlanDropdown() {
    // Mostrar indicador de carga
    if (_isLoadingPlanes) {
      return InputDecorator(
        decoration: FormFieldStyles.buildInputDecoration(
          labelText: 'Plan Actual',
          prefixIcon: Icons.card_membership,
        ),
        child: Row(
          children: [
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            const Text('Cargando planes...'),
          ],
        ),
      );
    }

    // Mostrar error con botón de reintentar
    if (_loadPlanesError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: FormFieldStyles.buildInputDecoration(
              labelText: 'Plan Actual',
              prefixIcon: Icons.error_outline,
            ),
            child: Text(
              _loadPlanesError!,
              style: const TextStyle(color: AppColors.warning),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _loadPlanes,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      );
    }

    // Mostrar dropdown normal
    return DropdownButtonFormField<int>(
      value: _selectedPlanId,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Plan Actual',
        prefixIcon: Icons.card_membership,
      ),
      items:
          _planes
              .map(
                (plan) => DropdownMenuItem(
                  value: plan.id,
                  child: Text(
                    '${plan.nombre} (\$${plan.costo.toStringAsFixed(2)})',
                  ),
                ),
              )
              .toList(),
      onChanged: (value) {
        setState(() {
          _selectedPlanId = value;
        });
      },
      validator: FormValidators.validatePlan,
    );
  }

  Widget _buildManagePlansButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () async {
          // Usar showDialog en lugar de Navigator.push
          // Mantiene el formulario actual seguro en el fondo
          await showDialog<void>(
            context: context,
            builder:
                (_) => Dialog(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 600,
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
                    child: const PlanesEditorScreen(),
                  ),
                ),
          );

          if (!mounted) return;
          // Recargar planes después de cerrar el diálogo
          await _loadPlanes();
        },
        icon: const Icon(Icons.settings),
        label: const Text('Gestionar planes'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }

  Widget _buildDueDateField() {
    return TextFormField(
      controller: _dueDateController,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Fecha de Próximo Vencimiento',
        prefixIcon: Icons.calendar_today,
      ),
      readOnly: true,
      onTap: () => _selectDate(context),
      validator: (value) {
        // Validar que la fecha no esté vacía
        if (value == null || value.isEmpty) {
          return 'La fecha de vencimiento es requerida';
        }

        // Validar lógica: fecha_vencimiento debe ser >= fecha_inicio
        if (_fechaInicioController.text.isNotEmpty) {
          try {
            final fechaVencimiento = DateTime.parse(value);
            final fechaInicio = DateTime.parse(_fechaInicioController.text);

            if (fechaVencimiento.isBefore(fechaInicio)) {
              return 'Fecha de vencimiento no puede ser anterior a la fecha de inicio';
            }
          } catch (e) {
            return 'Formato de fecha inválido';
          }
        }

        return null;
      },
    );
  }

  Widget _buildStartDateField() {
    return TextFormField(
      controller: _fechaInicioController,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Fecha Inicio Programa',
        prefixIcon: Icons.date_range,
      ),
      readOnly: true,
      onTap: () => _selectFechaInicio(context),
      validator: (value) {
        // Validar que la fecha no esté vacía
        if (value == null || value.isEmpty) {
          return 'La fecha de inicio es requerida';
        }

        // Validar lógica: fecha_inicio debe ser <= fecha_vencimiento
        if (_dueDateController.text.isNotEmpty) {
          try {
            final fechaInicio = DateTime.parse(value);
            final fechaVencimiento = DateTime.parse(_dueDateController.text);

            if (fechaInicio.isAfter(fechaVencimiento)) {
              return 'Fecha de inicio no puede ser posterior a la fecha de vencimiento';
            }
          } catch (e) {
            return 'Formato de fecha inválido';
          }
        }

        return null;
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<AsesoradoStatus>(
      value: _selectedStatus,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Estado',
        prefixIcon: Icons.info,
      ),
      items:
          AsesoradoStatus.values.map((AsesoradoStatus status) {
            return DropdownMenuItem<AsesoradoStatus>(
              value: status,
              child: Text(status.displayLabel),
            );
          }).toList(),
      onChanged: (AsesoradoStatus? newValue) {
        setState(() {
          _selectedStatus = newValue!;
        });
      },
    );
  }

  /// Construye el objeto Asesorado (DTO) a partir de los controladores del formulario
  /// Centraliza la lógica de mapeo entre UI y modelo
  Asesorado _buildDtoFromForm() {
    return Asesorado(
      id: widget.asesorado?.id ?? 0,
      coachId: widget.coachId,
      name: _nameController.text.trim(),
      avatarUrl: _existingImagePath ?? '',
      status: _selectedStatus,
      planId: _selectedPlanId,
      dueDate:
          _dueDateController.text.isEmpty
              ? null
              : DateTime.parse(_dueDateController.text),
      fechaNacimiento:
          _fechaNacimientoController.text.isEmpty
              ? null
              : DateTime.parse(_fechaNacimientoController.text),
      sexo: _selectedSexo,
      alturaCm: double.tryParse(_alturaController.text),
      telefono: _telefonoController.text.trim(),
      fechaInicioPrograma:
          _fechaInicioController.text.isEmpty
              ? null
              : DateTime.parse(_fechaInicioController.text),
      objetivoPrincipal: _objetivoPrincipalController.text.trim(),
      objetivoSecundario: _objetivoSecundarioController.text.trim(),
    );
  }

  Future<void> _handleSaveAsesorado() async {
    if (_formKey.currentState!.validate()) {
      // Validación cruzada adicional de fechas
      if (_fechaInicioController.text.isNotEmpty &&
          _dueDateController.text.isNotEmpty) {
        try {
          final fechaInicio = DateTime.parse(_fechaInicioController.text);
          final fechaVencimiento = DateTime.parse(_dueDateController.text);

          if (fechaVencimiento.isBefore(fechaInicio)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'La fecha de vencimiento debe ser posterior a la de inicio',
                        style: TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red.shade600,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error al validar fechas: $e',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      setState(() => _isLoading = true);

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final asesoradosService = AsesoradosService();

      try {
        // Construir objeto Asesorado como DTO
        final asesoradoData = _buildDtoFromForm();

        if (widget.asesorado == null) {
          // Crear nuevo asesorado
          await asesoradosService.createAsesorado(
            data: asesoradoData,
            profileImage: _selectedProfileImage,
          );
        } else {
          // Actualizar asesorado existente
          await asesoradosService.updateAsesorado(
            id: widget.asesorado!.id,
            data: asesoradoData,
            newProfileImage: _selectedProfileImage,
            deleteImage: _imageMarkedForDeletion,
          );
        }

        if (!mounted) return;

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  widget.asesorado == null
                      ? 'Asesorado creado con éxito ✓'
                      : 'Asesorado actualizado con éxito ✓',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
        navigator.pop(true);
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      // 🚀 MEJORA: Mostrar Toast si hay errores de validación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_outlined, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Por favor, completa todos los campos requeridos ✱',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
