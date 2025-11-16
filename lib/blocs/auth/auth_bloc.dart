import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:coachhub/blocs/auth/auth_event.dart';
import 'package:coachhub/blocs/auth/auth_state.dart';
import 'package:coachhub/models/coach_model.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      emit(AuthenticationSuccess(event.coach));
    } catch (e) {
      emit(AuthenticationFailure('Error al autenticar: $e'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoggedOut());
    emit(const AuthInitial());
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthenticationSuccess) {
      final successState = state as AuthenticationSuccess;
      emit(AuthenticationSuccess(successState.coach));
    } else {
      emit(const AuthInitial());
    }
  }

  Coach? get currentCoach {
    final currentState = state;
    if (currentState is AuthenticationSuccess) {
      return currentState.coach;
    }
    return null;
  }

  int? get currentCoachId {
    return currentCoach?.id;
  }

  bool get isAuthenticated {
    return state is AuthenticationSuccess;
  }
}
