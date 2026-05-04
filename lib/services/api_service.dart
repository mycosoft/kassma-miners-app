import 'package:dio/dio.dart';
import 'dart:convert';
import '../config/constants.dart';
import '../data/models/user.dart';
import 'storage_service.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ),
  );

  static Dio get dio {
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('API[${options.method}] ${options.baseUrl}${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('API[${response.statusCode}] ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (DioException error, handler) async {
          print('API ERROR[${error.response?.statusCode}] ${error.requestOptions.path}: ${error.message}');
          if (error.response?.statusCode == 401) {
            await StorageService.clearAll();
          }
          handler.next(error);
        },
      ),
    );
    return _dio;
  }

  // Helper to unwrap API response data
  static dynamic unwrap(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  /// Get the user's primary role prefix for API routing
  static Future<String> _getRolePrefix() async {
    final role = await StorageService.getUserRole();
    if (role == 'pit-manager') return 'pit-manager';
    if (role == 'site-owner') return 'site-owner';
    if (role == 'cashier') return 'cashier';
    if (role == 'gold-buyer') return 'gold-buyer';
    return 'pit-owner';
  }

  // ========== Role-aware API methods ==========
  static Future<Response> getAvailableMembers() async {
    final prefix = await _getRolePrefix();
    return await dio.get('/\/pit-managers/available-members');
  }

  static Future<Response> getRoleAwareMembers() async {
    final prefix = await _getRolePrefix();
    return await dio.get('/$prefix/members');
  }

  static Future<Response> getRoleAwareReceipts() async {
    final prefix = await _getRolePrefix();
    return await dio.get('/$prefix/receipts');
  }

  static Future<Response> getRoleAwareIncidents() async {
    final prefix = await _getRolePrefix();
    return await dio.get('/$prefix/incidents');
  }

  static Future<Response> getRoleAwareIdCards() async {
    final prefix = await _getRolePrefix();
    return await dio.get('/$prefix/id-cards');
  }

  // Auth
  static Future<Response> login(String email, String password) async {
    return await dio.post('/login', data: {'email': email, 'password': password});
  }

  static Future<Response> register(Map<String, dynamic> data) async {
    return await dio.post('/register', data: data);
  }

  static Future<Response> logout() async {
    return await dio.post('/logout');
  }

  static Future<Response> getUser() async {
    return await dio.get('/user');
  }

  // Pit Owner
  static Future<Response> getPitOwnerDashboard() async {
    return await dio.get('/pit-owner/dashboard');
  }

  static Future<Response> getPitOwnerMembers() async {
    return await dio.get('/pit-owner/members');
  }

  static Future<Response> getPitOwnerReceipts() async {
    return await dio.get('/pit-owner/receipts');
  }

  static Future<Response> createReceipt(Map<String, dynamic> data) async {
    return await dio.post('/pit-owner/receipts', data: data);
  }

  static Future<Response> getPitOwnerIncidents() async {
    return await dio.get('/pit-owner/incidents');
  }

  static Future<Response> createIncident(Map<String, dynamic> data) async {
    return await dio.post('/pit-owner/incidents', data: data);
  }

  static Future<Response> getPitOwnerIdCards() async {
    return await dio.get('/pit-owner/id-cards');
  }

  static Future<Response> getPitOwnerPitManagers() async {
    return await dio.get('/pit-owner/pit-managers');
  }

  static Future<Response> assignMembers(Map<String, dynamic> data) async {
    return await dio.post('/pit-owner/pit-managers/assign', data: data);
  }


  // Role-aware create methods
  static Future<Response> createRoleAwareReceipt(Map<String, dynamic> data) async {
    final prefix = await _getRolePrefix();
    return await dio.post('/$prefix/receipts', data: data);
  }

  static Future<Response> createRoleAwareIncident(Map<String, dynamic> data) async {
    final prefix = await _getRolePrefix();
    return await dio.post('/$prefix/incidents', data: data);
  }

  static Future<Response> createRoleIdCard(Map<String, dynamic> data) async {
    final prefix = await _getRolePrefix();
    return await dio.post('/$prefix/id-cards', data: data);
  }

  static Future<Response> createRoleAwareMember(Map<String, dynamic> data) async {
    final prefix = await _getRolePrefix();
    return await dio.post('/$prefix/members', data: data);
  }

  // Fetch dropdown data
  static Future<Response> fetchMyPits() async {
    final prefix = await _getRolePrefix();
    return await dio.get('/$prefix/pits');
  }
  // Site Owner
  static Future<Response> getSiteOwnerDashboard() async {
    return await dio.get('/site-owner/dashboard');
  }

  static Future<Response> getSiteOwnerIncidents() async {
    return await dio.get('/site-owner/incidents');
  }

  static Future<Response> getSiteOwnerGoldRecords() async {
    return await dio.get('/site-owner/gold-records');
  }

  static Future<Response> getSiteOwnerOreProcessed() async {
    return await dio.get('/site-owner/ore-processed');
  }

  static Future<Response> getSiteOwnerLeachingTanks() async {
    return await dio.get('/site-owner/leaching-tanks');
  }

  static Future<Response> getSiteOwnerMembers() async {
    return await dio.get('/site-owner/members');
  }

  // Pit Manager
  static Future<Response> getPitManagerDashboard() async {
    return await dio.get('/pit-manager/dashboard');
  }

  static Future<Response> getPitManagerMembers() async {
    return await dio.get('/pit-manager/members');
  }

  static Future<Response> getPitManagerReceipts() async {
    return await dio.get('/pit-manager/receipts');
  }

  static Future<Response> getPitManagerIncidents() async {
    return await dio.get('/pit-manager/incidents');
  }

  static Future<Response> getPitManagerIdCards() async {
    return await dio.get('/pit-manager/id-cards');
  }
}
