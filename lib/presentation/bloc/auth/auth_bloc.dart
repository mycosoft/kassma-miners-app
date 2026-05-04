import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/user.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        emit(Unauthenticated());
        return;
      }
      final response = await ApiService.getUser();
      final user = User.fromJson(response.data is Map<String, dynamic> ? response.data : {'id': '0', 'name': 'User', 'email': '', 'roles': []});
      await StorageService.saveUserRole(user.roles.isNotEmpty ? user.roles.first : '');
      await StorageService.saveUserData(jsonEncode(user.toJson()));
      emit(Authenticated(user));
    } catch (e) {
      await StorageService.clearAll();
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await ApiService.login(event.email, event.password);
      final data = response.data is Map<String, dynamic> ? response.data : <String, dynamic>{};
      
      final token = data['token']?.toString() ?? data['access_token']?.toString();
      if (token == null || token.isEmpty) {
        emit(const AuthError('Login failed: No token received from server'));
        emit(Unauthenticated());
        return;
      }
      
      await StorageService.saveToken(token);
      
      User user;
      try {
        final userResponse = await ApiService.getUser();
        final userData = userResponse.data is Map<String, dynamic> ? userResponse.data : <String, dynamic>{};
        user = User.fromJson(userData);
      } catch (_) {
        user = User(
          id: data['user']?['id']?.toString() ?? '0',
          name: data['user']?['name'] ?? data['user']?['first_name'] ?? event.email.split('@').first,
          email: event.email,
          roles: (data['user']?['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        );
      }
      
      await StorageService.saveUserRole(user.roles.isNotEmpty ? user.roles.first : '');
      await StorageService.saveUserData(jsonEncode(user.toJson()));
      emit(Authenticated(user));
    } on DioException catch (e) {
      String message = 'Login failed';
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic>) {
          message = data['message'] ?? 'Invalid credentials';
          if (data['errors'] != null) {
            final errors = data['errors'] as Map<String, dynamic>;
            message = errors.values.expand((e) => e is List ? e : [e]).map((e) => e.toString()).join(', ');
          }
        } else {
          message = 'Server error (${e.response?.statusCode ?? 'unknown'})';
        }
      } else {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            message = 'Connection timed out. Please try again.';
            break;
          case DioExceptionType.connectionError:
            message = 'No internet connection. Please check your network.';
            break;
          default:
            message = 'Network error. Please try again.';
        }
      }
      emit(AuthError(message));
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await ApiService.logout();
    } catch (_) {}
    await StorageService.clearAll();
    emit(Unauthenticated());
  }
}
