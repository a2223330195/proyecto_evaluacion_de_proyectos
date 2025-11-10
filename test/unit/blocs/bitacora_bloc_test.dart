import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:coachhub/blocs/bitacora/bitacora_bloc.dart';
import 'package:coachhub/blocs/bitacora/bitacora_event.dart';
import 'package:coachhub/blocs/bitacora/bitacora_state.dart';
import 'package:coachhub/models/nota_model.dart';

void main() {
  group('BitacoraBloc - Unit Tests (E.5.1)', () {
    late BitacoraBloc bitacoraBloc;

    setUp(() {
      bitacoraBloc = BitacoraBloc();
    });

    tearDown(() {
      bitacoraBloc.close();
    });

    /// TEST 1: Estado inicial correcto
    test('estado inicial es BitacoraInitial', () {
      expect(bitacoraBloc.state, isA<BitacoraInitial>());
    });

    /// TEST 2: CargarNotasPrioritarias emite loading y loaded
    blocTest<BitacoraBloc, BitacoraState>(
      'CargarNotasPrioritarias emite [BitacoraLoading, NotasPrioritariasLoaded]',
      build: () => bitacoraBloc,
      act: (bloc) => bloc.add(const CargarNotasPrioritarias(1)),
      expect: () => [isA<BitacoraLoading>(), isA<NotasPrioritariasLoaded>()],
    );

    /// TEST 3: CargarTodasLasNotas con paginación
    blocTest<BitacoraBloc, BitacoraState>(
      'CargarTodasLasNotas emite [BitacoraLoading, TodasLasNotasLoaded] con página correcta',
      build: () => bitacoraBloc,
      act: (bloc) => bloc.add(const CargarTodasLasNotas(1, 1)),
      expect:
          () => [
            isA<BitacoraLoading>(),
            isA<TodasLasNotasLoaded>().having(
              (state) => state.currentPage,
              'currentPage',
              1,
            ),
          ],
    );

    /// TEST 4: CrearNota emite TodasLasNotasLoaded con feedbackMessage
    blocTest<BitacoraBloc, BitacoraState>(
      'CrearNota emite [TodasLasNotasLoaded] con feedbackMessage',
      build: () => bitacoraBloc,
      act:
          (bloc) => bloc.add(
            const CrearNota(
              asesoradoId: 1,
              contenido: 'Nota de prueba',
              prioritaria: true,
            ),
          ),
      expect:
          () => [
            isA<TodasLasNotasLoaded>().having(
              (state) => state.feedbackMessage,
              'feedbackMessage',
              'Nota creada correctamente',
            ),
          ],
    );

    /// TEST 5: ActualizarNota emite TodasLasNotasLoaded con feedbackMessage
    blocTest<BitacoraBloc, BitacoraState>(
      'ActualizarNota emite [TodasLasNotasLoaded] con feedbackMessage',
      build: () => bitacoraBloc,
      seed:
          () => TodasLasNotasLoaded(
            notas: [
              Nota(
                id: 1,
                asesoradoId: 1,
                contenido: 'Contenido original',
                prioritaria: false,
                fechaCreacion: DateTime.now(),
                fechaActualizacion: DateTime.now(),
              ),
            ],
            currentPage: 1,
            totalPages: 1,
          ),
      act: (bloc) {
        final nota = Nota(
          id: 1,
          asesoradoId: 1,
          contenido: 'Contenido actualizado',
          prioritaria: true,
          fechaCreacion: DateTime.now(),
          fechaActualizacion: DateTime.now(),
        );
        bloc.add(ActualizarNota(nota));
      },
      expect:
          () => [
            isA<TodasLasNotasLoaded>().having(
              (state) => state.feedbackMessage,
              'feedbackMessage',
              'Nota actualizada correctamente',
            ),
          ],
    );

    /// TEST 6: EliminarNota emite TodasLasNotasLoaded con feedbackMessage
    blocTest<BitacoraBloc, BitacoraState>(
      'EliminarNota emite [TodasLasNotasLoaded] con feedbackMessage',
      build: () => bitacoraBloc,
      seed:
          () => TodasLasNotasLoaded(
            notas: [
              Nota(
                id: 1,
                asesoradoId: 1,
                contenido: 'Nota a eliminar',
                prioritaria: false,
                fechaCreacion: DateTime.now(),
                fechaActualizacion: DateTime.now(),
              ),
            ],
            currentPage: 1,
            totalPages: 1,
          ),
      act: (bloc) => bloc.add(const EliminarNota(1)),
      expect:
          () => [
            isA<TodasLasNotasLoaded>().having(
              (state) => state.feedbackMessage,
              'feedbackMessage',
              'Nota eliminada correctamente',
            ),
          ],
    );

    /// TEST 7: BuscarNotas filtra notas por contenido
    blocTest<BitacoraBloc, BitacoraState>(
      'BuscarNotas emite [BitacoraLoading, ResultadosBusqueda]',
      build: () => bitacoraBloc,
      act: (bloc) => bloc.add(const BuscarNotas(1, 'búsqueda')),
      expect: () => [isA<BitacoraLoading>(), isA<ResultadosBusqueda>()],
    );

    /// TEST 8: TogglePrioritaria cambia estado prioritaria
    blocTest<BitacoraBloc, BitacoraState>(
      'TogglePrioritaria emite [TodasLasNotasLoaded] con feedbackMessage',
      build: () => bitacoraBloc,
      seed:
          () => TodasLasNotasLoaded(
            notas: [
              Nota(
                id: 1,
                asesoradoId: 1,
                contenido: 'Nota prioritaria',
                prioritaria: false,
                fechaCreacion: DateTime.now(),
                fechaActualizacion: DateTime.now(),
              ),
            ],
            currentPage: 1,
            totalPages: 1,
          ),
      act: (bloc) => bloc.add(const TogglePrioritaria(1, true)),
      expect:
          () => [
            isA<TodasLasNotasLoaded>().having(
              (state) => state.feedbackMessage,
              'feedbackMessage',
              'Nota marcada como prioritaria',
            ),
          ],
    );
  });
}
