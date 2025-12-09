import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://smart-xerox-sdbv.onrender.com'; // Use your backend IP and port
  final Duration timeout = const Duration(seconds: 15);

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  /// 🧾 Create order with file upload and progress tracking
  Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> fileMaps, {
    required Function(double progress) onProgress,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/upload');
      var request = http.MultipartRequest('POST', uri);

      // Add normal fields
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add files
      for (var fileMap in fileMaps) {
        String name = fileMap['name'];
        if (fileMap.containsKey('bytes')) {
          List<int> bytes = fileMap['bytes'];
          request.files.add(
            http.MultipartFile.fromBytes('files', bytes, filename: name),
          );
        } else {
          File file = fileMap['file'];
          request.files.add(
            await http.MultipartFile.fromPath('files', file.path, filename: name),
          );
        }
      }

      // Send request and track upload progress
      var streamedResponse = await request.send();

      // Optional: call progress = 1.0 once upload finishes
      onProgress(1.0);

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            '❌ Failed to create order [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      throw Exception('⚠️ Error in createOrder: $e');
    }
  }

  /// 📦 Get all orders for a student
  Future<List<Map<String, dynamic>>> getStudentOrders(String studentName) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/api/orders/student?name=${Uri.encodeComponent(studentName)}');
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final List orders = jsonDecode(response.body);
        return orders.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            '❌ Failed to fetch orders [${response.statusCode}]: ${response.body}');
      }
    } on SocketException {
      throw Exception('🚫 Network error. Check your internet connection.');
    } on http.ClientException {
      throw Exception('🚫 Server connection failed.');
    } on TimeoutException {
      throw Exception('⏰ Request timed out.');
    } catch (e) {
      throw Exception('⚠️ Error in getStudentOrders: $e');
    }
  }

  /// 🔍 Get order by orderId
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/orders/$orderId');
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            '❌ Failed to fetch order [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      throw Exception('⚠️ Error in getOrderDetails: $e');
    }
  }



  /// 🧍‍♂️ Student registration
  Future<Map<String, dynamic>> registerStudent(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl/api/register');
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(data))
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            '❌ Registration failed [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      throw Exception('⚠️ Error in registerStudent: $e');
    }
  }

  /// 🔐 Student login
  Future<Map<String, dynamic>> loginStudent(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/login');
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(data))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            '❌ Login failed [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      throw Exception('⚠️ Error in loginStudent: $e');
    }
  }

  /// 🧾 Get student profile
  Future<Map<String, dynamic>> getStudentProfile(int studentId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/profile/$studentId');
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            '❌ Failed to fetch profile [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      throw Exception('⚠️ Error in getStudentProfile: $e');
    }
  }
}
