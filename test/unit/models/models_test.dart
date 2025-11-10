import 'package:coachhub/models/asesorado_pago_pendiente.dart';
import 'package:coachhub/models/nota_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Models - Unit Tests (E.5.1)', () {
    /// TEST 1: AsesoradoPagoPendiente.fromMap crea instancia correctamente
    test('AsesoradoPagoPendiente.fromMap convierte Map a objeto', () {
      final map = {
        'asesorado_id': 1,
        'nombre': 'Juan Pérez',
        'foto_perfil': 'https://example.com/juan.jpg',
        'plan': 'Premium',
        'monto_pendiente': 99.99,
        'fecha_vencimiento': '2025-11-10',
        'estado': 'atrasado',
        'costo_plan': 99.99,
        'email': 'juan@example.com',
        'telefono_contacto': '+573001234567',
      };

      final asesorado = AsesoradoPagoPendiente.fromMap(map);

      expect(asesorado.asesoradoId, 1);
      expect(asesorado.nombre, 'Juan Pérez');
      expect(asesorado.plan, 'Premium');
      expect(asesorado.montoPendiente, 99.99);
      expect(asesorado.estado, 'atrasado');
      expect(asesorado.email, 'juan@example.com');
    });

    /// TEST 2: AsesoradoPagoPendiente.toMap convierte objeto a Map
    test('AsesoradoPagoPendiente.toMap convierte objeto a Map', () {
      final asesorado = AsesoradoPagoPendiente(
        asesoradoId: 1,
        nombre: 'María García',
        fotoPerfil: 'https://example.com/maria.jpg',
        plan: 'Basic',
        montoPendiente: 49.99,
        fechaVencimiento: DateTime(2025, 11, 15),
        estado: 'proximo',
        costoPlan: 49.99,
        email: 'maria@example.com',
        telefonoContacto: '+573019876543',
      );

      final map = asesorado.toMap();

      expect(map['asesorado_id'], 1);
      expect(map['nombre'], 'María García');
      expect(map['plan'], 'Basic');
      expect(map['monto_pendiente'], 49.99);
      expect(map['estado'], 'proximo');
    });

    /// TEST 3: AsesoradoPagoPendiente.copyWith crea copia inmutable
    test('AsesoradoPagoPendiente.copyWith crea copia con cambios', () {
      final original = AsesoradoPagoPendiente(
        asesoradoId: 1,
        nombre: 'Carlos López',
        fotoPerfil: null,
        plan: 'Premium',
        montoPendiente: 100.0,
        fechaVencimiento: DateTime.now(),
        estado: 'pendiente',
      );

      final actualizado = original.copyWith(
        estado: 'atrasado',
        montoPendiente: 150.0,
      );

      expect(original.estado, 'pendiente');
      expect(original.montoPendiente, 100.0);
      expect(actualizado.estado, 'atrasado');
      expect(actualizado.montoPendiente, 150.0);
      expect(actualizado.asesoradoId, original.asesoradoId);
    });

    /// TEST 4: Nota.fromMap crea instancia correctamente
    test('Nota.fromMap convierte Map a objeto', () {
      final ahora = DateTime.now();
      final map = {
        'id': 1,
        'asesorado_id': 1,
        'contenido': 'Nota importante',
        'prioritaria': 1, // 1 = true en DB
        'fecha_creacion': ahora.toIso8601String(),
        'fecha_actualizacion': ahora.toIso8601String(),
      };

      final nota = Nota.fromMap(map);

      expect(nota.id, 1);
      expect(nota.asesoradoId, 1);
      expect(nota.contenido, 'Nota importante');
      expect(nota.prioritaria, true);
    });

    /// TEST 5: Nota.toMap convierte objeto a Map
    test('Nota.toMap convierte objeto a Map', () {
      final ahora = DateTime.now();
      final nota = Nota(
        id: 1,
        asesoradoId: 1,
        contenido: 'Contenido de nota',
        prioritaria: true,
        fechaCreacion: ahora,
        fechaActualizacion: ahora,
      );

      final map = nota.toMap();

      expect(map['id'], 1);
      expect(map['asesorado_id'], 1);
      expect(map['contenido'], 'Contenido de nota');
      expect(map['prioritaria'], 1); // true se convierte a 1
    });

    /// TEST 6: Nota.copyWith crea copia inmutable
    test('Nota.copyWith crea copia con cambios', () {
      final original = Nota(
        id: 1,
        asesoradoId: 1,
        contenido: 'Original',
        prioritaria: false,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      final actualizada = original.copyWith(
        contenido: 'Actualizada',
        prioritaria: true,
      );

      expect(original.contenido, 'Original');
      expect(original.prioritaria, false);
      expect(actualizada.contenido, 'Actualizada');
      expect(actualizada.prioritaria, true);
      expect(actualizada.id, original.id);
    });

    /// TEST 7: AsesoradoPagoPendiente.fromMap maneja valores null
    test(
      'AsesoradoPagoPendiente.fromMap maneja valores null correctamente',
      () {
        final map = {
          'asesorado_id': 2,
          'nombre': 'Sin datos',
          'foto_perfil': null,
          'plan': null,
          'monto_pendiente': 0.0,
          'fecha_vencimiento': null,
          'estado': null, // Debe calcular estado
          'costo_plan': null,
        };

        final asesorado = AsesoradoPagoPendiente.fromMap(map);

        expect(asesorado.fotoPerfil, null);
        expect(asesorado.plan, null);
        expect(asesorado.montoPendiente, 0.0);
      },
    );

    /// TEST 8: Nota.fromMap maneja prioritaria como bool string
    test('Nota.fromMap maneja prioritaria como string "true"', () {
      final ahora = DateTime.now();
      final map = {
        'id': 1,
        'asesorado_id': 1,
        'contenido': 'Prueba',
        'prioritaria': 'true', // String "true"
        'fecha_creacion': ahora.toIso8601String(),
        'fecha_actualizacion': ahora.toIso8601String(),
      };

      final nota = Nota.fromMap(map);

      expect(nota.prioritaria, true);
    });
  });
}
