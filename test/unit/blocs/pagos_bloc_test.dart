import 'package:flutter_test/flutter_test.dart';
import 'package:coachhub/blocs/pagos/pagos_bloc.dart';
import 'package:coachhub/blocs/pagos/pagos_state.dart';

void main() {
  group('PagosBloc', () {
    late PagosBloc pagosBloc;

    setUp(() {
      pagosBloc = PagosBloc();
    });

    tearDown(() async {
      await pagosBloc.close();
    });

    test('estado inicial es PagosInitial', () {
      expect(pagosBloc.state, isA<PagosInitial>());
    });
  });
}
