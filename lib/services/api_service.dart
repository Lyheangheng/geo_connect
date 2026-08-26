import 'dart:convert';
import 'package:geo_connect/core/constants/api_constants.dart';
import 'package:geo_connect/core/errors/api_exception.dart';
import 'package:geo_connect/models/checkin_model.dart';
import 'package:geo_connect/models/user_model.dart';
import 'package:geo_connect/services/storage_service.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final StorageService _storageService = StorageService();
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Helper headers builder
  Map<String, String> _buildHeaders({String? token, String contentType = 'application/json'}) {
    final headers = <String, String>{
      'Content-Type': contentType,
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Handle standard HTTP responses
  Map<String, dynamic> _parseJsonResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    }
    throw ApiException.fromResponse(response);
  }

  // ---------------------------------------------------------------------------
  // AUTHENTICATION APIS
  // ---------------------------------------------------------------------------

  /// 1. Register new user (POST /api/auth/register)
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
    String? fname,
    String? lname,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.register);
      final body = jsonEncode({
        'email': email.trim(),
        'password': password,
        if (name != null) 'name': name.trim(),
        if (fname != null) 'fname': fname.trim(),
        if (lname != null) 'lname': lname.trim(),
      });

      final response = await _client.post(
        url,
        headers: _buildHeaders(),
        body: body,
      );

      final data = _parseJsonResponse(response);
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  /// 2. Verify OTP (POST /api/auth/verify-otp)
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.verifyOtp);
      final body = jsonEncode({
        'email': email.trim(),
        'otp': otp.trim(),
      });

      final response = await _client.post(
        url,
        headers: _buildHeaders(),
        body: body,
      );

      final data = _parseJsonResponse(response);
      if (data.containsKey('token') && data['token'] is String) {
        await _storageService.saveToken(data['token'] as String);
      }
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  /// 3. Resend OTP (POST /api/auth/resend-otp)
  Future<Map<String, dynamic>> resendOtp({required String email}) async {
    try {
      final url = Uri.parse(ApiConstants.resendOtp);
      final body = jsonEncode({'email': email.trim()});

      final response = await _client.post(
        url,
        headers: _buildHeaders(),
        body: body,
      );

      return _parseJsonResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  /// 4. Login (POST /api/auth/login)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.login);
      final body = jsonEncode({
        'email': email.trim(),
        'password': password,
      });

      final response = await _client.post(
        url,
        headers: _buildHeaders(),
        body: body,
      );

      final data = _parseJsonResponse(response);
      if (data.containsKey('token') && data['token'] is String) {
        await _storageService.saveToken(data['token'] as String);
      }
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  /// 5. Get Current User Profile (GET /api/auth/me)
  Future<UserModel> getCurrentUser({String? token}) async {
    try {
      final authToken = token ?? await _storageService.getToken();
      if (authToken == null || authToken.isEmpty) {
        throw ApiException('Unauthorized: No authentication token found.', statusCode: 401);
      }

      final url = Uri.parse(ApiConstants.me);
      final response = await _client.get(
        url,
        headers: _buildHeaders(token: authToken),
      );

      final data = _parseJsonResponse(response);
      final userJson = data['user'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  /// 6. Logout (POST /api/auth/logout)
  Future<void> logout({String? token}) async {
    try {
      final authToken = token ?? await _storageService.getToken();
      if (authToken != null && authToken.isNotEmpty) {
        final url = Uri.parse(ApiConstants.logout);
        await _client.post(
          url,
          headers: _buildHeaders(token: authToken),
        );
      }
    } catch (_) {
      // Continue clearing client storage even if server logout request fails
    } finally {
      await _storageService.deleteToken();
    }
  }

  // ---------------------------------------------------------------------------
  // CHECK-IN / LOCATION APIS
  // ---------------------------------------------------------------------------

  /// 7. Create Check-In (POST /api/checking)
  /// Uses multipart/form-data POST request
  Future<CheckInModel> createCheckIn({
    String? token,
    required double lat,
    required double lng,
    String? description,
    String? locationName,
    String? address,
    double? accuracy,
    String? imagePath,
    List<int>? imageBytes,
    String? filename,
  }) async {
    try {
      final authToken = token ?? await _storageService.getToken();
      if (authToken == null || authToken.isEmpty) {
        throw ApiException('Unauthorized: Bearer token is required.', statusCode: 401);
      }

      final url = Uri.parse(ApiConstants.checking);

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $authToken';

      request.fields['lat'] = lat.toString();
      request.fields['lng'] = lng.toString();
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description.trim();
      }
      if (locationName != null && locationName.isNotEmpty) {
        request.fields['locationName'] = locationName.trim();
      }
      if (address != null && address.isNotEmpty) {
        request.fields['address'] = address.trim();
      }
      if (accuracy != null) {
        request.fields['accuracy'] = accuracy.toString();
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        final file = await http.MultipartFile.fromPath('image', imagePath);
        request.files.add(file);
      } else if (imageBytes != null && filename != null) {
        final file = http.MultipartFile.fromBytes('image', imageBytes, filename: filename);
        request.files.add(file);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = _parseJsonResponse(response);

      final checkinData = data['checkin'];
      if (checkinData is List && checkinData.isNotEmpty) {
        return CheckInModel.fromJson(checkinData.first as Map<String, dynamic>);
      } else if (checkinData is Map<String, dynamic>) {
        return CheckInModel.fromJson(checkinData);
      }
      throw ApiException('Unexpected response format from server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  /// 8. Get All Check-Ins (GET /api/checking)
  Future<List<CheckInModel>> getCheckIns({int limit = 100}) async {
    try {
      final url = Uri.parse('${ApiConstants.checking}?limit=$limit');
      final response = await _client.get(url, headers: _buildHeaders());

      final data = _parseJsonResponse(response);
      final checkinsList = data['checkins'] as List? ?? [];
      return checkinsList
          .map((item) => CheckInModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  /// 9. Get Current User's Check-Ins (GET /api/checking?my=true)
  Future<List<CheckInModel>> getMyCheckIns({String? token, int limit = 100}) async {
    try {
      final authToken = token ?? await _storageService.getToken();
      if (authToken == null || authToken.isEmpty) {
        throw ApiException('Unauthorized: Bearer token is required.', statusCode: 401);
      }

      final url = Uri.parse('${ApiConstants.checking}?my=true&limit=$limit');
      final response = await _client.get(
        url,
        headers: _buildHeaders(token: authToken),
      );

      final data = _parseJsonResponse(response);
      final checkinsList = data['checkins'] as List? ?? [];
      return checkinsList
          .map((item) => CheckInModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  /// 10. Update Check-In (PUT /api/checking)
  Future<CheckInModel> updateCheckIn({
    String? token,
    required int id,
    String? description,
    String? locationName,
    String? address,
    String? imageUrl,
  }) async {
    try {
      final authToken = token ?? await _storageService.getToken();
      if (authToken == null || authToken.isEmpty) {
        throw ApiException('Unauthorized: Bearer token is required.', statusCode: 401);
      }

      final url = Uri.parse(ApiConstants.checking);
      final bodyMap = <String, dynamic>{
        'id': id,
        'description': ?description,
        'locationName': ?locationName,
        'address': ?address,
        'imageUrl': ?imageUrl,
      };
      final body = jsonEncode(bodyMap);

      final response = await _client.put(
        url,
        headers: _buildHeaders(token: authToken),
        body: body,
      );

      final data = _parseJsonResponse(response);
      final updatedData = data['checkin'];
      if (updatedData is List && updatedData.isNotEmpty) {
        return CheckInModel.fromJson(updatedData.first as Map<String, dynamic>);
      } else if (updatedData is Map<String, dynamic>) {
        return CheckInModel.fromJson(updatedData);
      }
      throw ApiException('Unexpected response format from server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  /// 11. Delete Check-In (DELETE /api/checking?id={id})
  Future<void> deleteCheckIn({
    String? token,
    required int id,
  }) async {
    try {
      final authToken = token ?? await _storageService.getToken();
      if (authToken == null || authToken.isEmpty) {
        throw ApiException('Unauthorized: Bearer token is required.', statusCode: 401);
      }

      final url = Uri.parse('${ApiConstants.checking}?id=$id');
      final response = await _client.delete(
        url,
        headers: _buildHeaders(token: authToken),
      );

      _parseJsonResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }
}
