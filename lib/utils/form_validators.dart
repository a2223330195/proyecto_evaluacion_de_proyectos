import 'package:flutter/material.dart';

/// Clase con validadores reutilizables para formularios
class FormValidators {
  // Validar nombre completo
  // Solo permite letras, espacios y acentos
  static String? validateNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (value.length > 255) {
      return 'El nombre no puede exceder 255 caracteres';
    }
    // Validar solo letras, espacios y acentos
    final regex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!regex.hasMatch(value)) {
      return 'El nombre solo puede contener letras y espacios';
    }
    return null;
  }

  // Validar fecha de nacimiento
  static String? validateFechaNacimiento(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Opcional
    }

    try {
      final fechaNacimiento = DateTime.parse(value);
      final ahora = DateTime.now();

      // Validar que no sea una fecha futura
      if (fechaNacimiento.isAfter(ahora)) {
        return 'La fecha de nacimiento no puede ser futura';
      }

      // Calcular la edad
      int edad = ahora.year - fechaNacimiento.year;
      if (ahora.month < fechaNacimiento.month ||
          (ahora.month == fechaNacimiento.month &&
              ahora.day < fechaNacimiento.day)) {
        edad--;
      }

      // Validar que la edad esté entre 1 y 120 años
      if (edad < 1 || edad > 120) {
        return 'La edad calculada debe estar entre 1 y 120 años';
      }

      return null;
    } catch (e) {
      return 'Fecha de nacimiento inválida';
    }
  }

  // Validar edad (0-120)
  static String? validateEdad(String? value) {
    if (value == null || value.isEmpty) {
      return 'La edad es requerida';
    }
    final edad = int.tryParse(value);
    if (edad == null) {
      return 'La edad debe ser un número válido';
    }
    if (edad < 1 || edad > 120) {
      return 'La edad debe estar entre 1 y 120 años';
    }
    return null;
  }

  // Validar altura en cm (50-250)
  static String? validateAltura(String? value) {
    if (value == null || value.isEmpty) {
      return 'La altura es requerida';
    }
    final altura = double.tryParse(value);
    if (altura == null) {
      return 'La altura debe ser un número válido';
    }
    if (altura < 50 || altura > 250) {
      return 'La altura debe estar entre 50 y 250 cm';
    }
    return null;
  }

  // Validar teléfono (7-15 dígitos)
  // La UI usa FilteringTextInputFormatter.digitsOnly para prevenir no-dígitos
  // El servicio limpia defensivamente, así que el validador solo verifica longitud
  static String? validateTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }
    // El valor ya debería contener solo dígitos (filtro UI)
    // Si llega aquí sucio, el servicio lo limpiará
    final cleanedPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanedPhone.length < 7 || cleanedPhone.length > 15) {
      return 'El teléfono debe tener entre 7 y 15 dígitos';
    }
    return null;
  }

  // Validar objetivo (texto, max 500 caracteres)
  static String? validateObjetivo(String? value) {
    if (value != null && value.length > 500) {
      return 'El objetivo no puede exceder 500 caracteres';
    }
    return null;
  }

  // Validar plan
  static String? validatePlan(int? value) {
    if (value == null) {
      return 'Debes seleccionar un plan';
    }
    return null;
  }

  // Validar fecha
  static String? validateFecha(String? value) {
    if (value == null || value.isEmpty) {
      return 'La fecha es requerida';
    }
    return null;
  }

  // Validar peso (kg, 20-300)
  static String? validatePeso(String? value) {
    if (value == null || value.isEmpty) {
      return 'El peso es requerido';
    }
    final peso = double.tryParse(value);
    if (peso == null) {
      return 'El peso debe ser un número válido';
    }
    if (peso < 20 || peso > 300) {
      return 'El peso debe estar entre 20 y 300 kg';
    }
    return null;
  }

  // Limpiar teléfono (remover caracteres especiales)
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  // Formatear teléfono mientras se escribe
  static String formatPhoneNumber(String phone) {
    final cleaned = cleanPhoneNumber(phone);
    if (cleaned.length <= 3) {
      return cleaned;
    }
    if (cleaned.length <= 6) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3)}';
    }
    if (cleaned.length <= 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return cleaned.substring(0, 10);
  }

  // --- NUTRICIÓN (Planes Nutricionales) ---

  // Validar nombre del plan nutricional
  static String? validateNombrePlan(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre del plan es requerido';
    }
    if (value.length < 3) {
      return 'Mínimo 3 caracteres';
    }
    if (value.length > 255) {
      return 'Máximo 255 caracteres';
    }
    return null;
  }

  // Validar calorías diarias
  static String? validateCalories(String? value) {
    if (value == null || value.isEmpty) {
      return 'Las calorías son requeridas';
    }
    final calories = int.tryParse(value);
    if (calories == null) {
      return 'Ingrese un número válido';
    }
    if (calories <= 0) {
      return 'Debe ser mayor a 0';
    }
    if (calories < 800) {
      return 'Mínimo recomendado: 800 kcal';
    }
    if (calories > 10000) {
      return 'Máximo: 10,000 kcal';
    }
    return null;
  }

  // Validar macronutrientes (proteínas, grasas, carbos)
  static String? validateMacro(String? value, String macroName) {
    if (value == null || value.isEmpty) {
      return null; // Opcional
    }
    final macro = int.tryParse(value);
    if (macro == null) {
      return 'Ingrese un número válido para $macroName';
    }
    if (macro < 0) {
      return '$macroName no puede ser negativo';
    }
    final maxValue = macroName == 'Carbohidratos' ? 1000 : 500;
    if (macro > maxValue) {
      return 'Máximo para $macroName: $maxValue g';
    }
    return null;
  }

  // Validar peso (para mediciones)
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'El peso es requerido';
    }
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Ingrese un número válido';
    }
    if (weight <= 0) {
      return 'Debe ser mayor a 0';
    }
    if (weight < 20) {
      return 'Mínimo: 20 kg';
    }
    if (weight > 500) {
      return 'Máximo: 500 kg';
    }
    return null;
  }

  // Validar IMC
  static String? validateBMI(String? value) {
    if (value == null || value.isEmpty) {
      return 'El IMC es requerido';
    }
    final bmi = double.tryParse(value);
    if (bmi == null) {
      return 'Ingrese un número válido';
    }
    if (bmi <= 0) {
      return 'Debe ser mayor a 0';
    }
    if (bmi < 10) {
      return 'Mínimo: 10';
    }
    if (bmi > 60) {
      return 'Máximo: 60';
    }
    return null;
  }

  // Validar porcentaje de grasa corporal
  static String? validateBodyFatPercentage(String? value) {
    if (value == null || value.isEmpty) {
      return 'El porcentaje es requerido';
    }
    final percentage = double.tryParse(value);
    if (percentage == null) {
      return 'Ingrese un número válido';
    }
    if (percentage < 0) {
      return 'Debe ser mayor a 0%';
    }
    if (percentage > 100) {
      return 'Máximo: 100%';
    }
    return null;
  }

  // Validar circunferencias (pecho, cintura, brazo, pierna)
  static String? validateCircumference(String? value, String partName) {
    if (value == null || value.isEmpty) {
      return null; // Opcional
    }
    final measure = double.tryParse(value);
    if (measure == null) {
      return 'Ingrese un número válido para $partName';
    }
    if (measure <= 0) {
      return '$partName debe ser mayor a 0 cm';
    }
    if (measure > 300) {
      return 'Valor muy alto para $partName';
    }
    return null;
  }
}

/// Clase con estilos de decoración para TextFormField
class FormFieldStyles {
  static InputDecoration buildInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    String? errorText,
    Widget? suffixWidget,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon:
          suffixWidget ?? (suffixIcon != null ? Icon(suffixIcon) : null),
      suffixText: suffixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE6E9F0), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE6E9F0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E1A6F), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFBFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorText: errorText,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }
}
