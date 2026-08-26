class ApiConstants {
  // Configurable Base URL for Professor's Backend API
  // Default: http://10.0.2.2:3000 (Android Emulator) or http://localhost:3000 (iOS / Web)
  static String _baseUrl = 'http://10.0.2.2:3000';

  static String get baseUrl => _baseUrl;

  /// Configures the backend base URL dynamically (e.g., http://192.168.1.100:3000)
  static void setBaseUrl(String url) {
    if (url.endsWith('/')) {
      _baseUrl = url.substring(0, url.length - 1);
    } else {
      _baseUrl = url;
    }
  }

  // Auth Endpoints
  static String get register => '$_baseUrl/api/auth/register';
  static String get login => '$_baseUrl/api/auth/login';
  static String get verifyOtp => '$_baseUrl/api/auth/verify-otp';
  static String get resendOtp => '$_baseUrl/api/auth/resend-otp';
  static String get me => '$_baseUrl/api/auth/me';
  static String get logout => '$_baseUrl/api/auth/logout';

  // Check-in Endpoints
  static String get checking => '$_baseUrl/api/checking';
}
