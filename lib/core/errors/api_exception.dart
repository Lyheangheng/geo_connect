import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromResponse(http.Response response) {
    String errorMessage = 'Request failed with status: ${response.statusCode}';
    try {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMessage = decoded['message'].toString();
        }
      }
    } catch (_) {
      // Fallback to default status code message if body is not JSON
    }
    return ApiException(errorMessage, statusCode: response.statusCode);
  }

  factory ApiException.networkError(Object error) {
    return ApiException('Network error: Please check your internet connection or server host URL.');
  }

  @override
  String toString() => message;
}
