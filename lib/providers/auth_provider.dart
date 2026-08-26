import 'package:flutter/material.dart';
import 'package:geo_connect/core/errors/api_exception.dart';
import 'package:geo_connect/models/user_model.dart';
import 'package:geo_connect/services/api_service.dart';
import 'package:geo_connect/services/storage_service.dart';

enum AuthStatus {
  unauthenticated,
  otpPending,
  authenticated,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  AuthStatus _status = AuthStatus.unauthenticated;
  UserModel? _currentUser;
  String? _pendingEmail;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get pendingEmail => _pendingEmail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Check stored token on app launch
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        _currentUser = await _apiService.getCurrentUser(token: token);
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _storageService.deleteToken();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Real API Login call
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.login(email: email, password: password);
      if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
        _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Real API Register call
  Future<bool> register(String email, String password, {String? name}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.register(email: email, password: password, name: name);
      _pendingEmail = email;
      _status = AuthStatus.otpPending;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Real API Verify OTP call
  Future<bool> verifyOtp(String otp) async {
    if (_pendingEmail == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.verifyOtp(email: _pendingEmail!, otp: otp);
      if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
        _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Real API Resend OTP call
  Future<bool> resendOtp() async {
    if (_pendingEmail == null) return false;
    try {
      await _apiService.resendOtp(email: _pendingEmail!);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Logout action
  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    _pendingEmail = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Legacy Mock methods for Phase 1 compatibility
  void mockLogin(String email) {
    _currentUser = UserModel(
      id: 1,
      name: 'Student Demo User',
      email: email.isNotEmpty ? email : 'student@university.ac.th',
      bio: 'Flutter developer studying GeoConnect assignment.',
      isVerified: true,
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void mockRegister(String name, String email) {
    _pendingEmail = email;
    _status = AuthStatus.otpPending;
    notifyListeners();
  }

  void mockVerifyOtp() {
    _currentUser = UserModel(
      id: 1,
      name: 'Verified Student User',
      email: _pendingEmail ?? 'student@university.ac.th',
      bio: 'Verified student user account.',
      isVerified: true,
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
