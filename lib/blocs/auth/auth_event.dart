import 'package:coachhub/models/coach_model.dart';

abstract class AuthEvent {
  const AuthEvent();
}

class LoginEvent extends AuthEvent {
  final Coach coach;
  const LoginEvent(this.coach);
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class UpdateCoachProfileEvent extends AuthEvent {
  final Coach coach;
  const UpdateCoachProfileEvent(this.coach);
}
