import 'package:equatable/equatable.dart';
import 'package:coachhub/models/coach_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthenticationSuccess extends AuthState {
  final Coach coach;

  const AuthenticationSuccess(this.coach);

  @override
  List<Object?> get props => [coach];
}

class AuthenticationFailure extends AuthState {
  final String error;

  const AuthenticationFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}
