import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const secureStorage = FlutterSecureStorage();

Future<void> login(String email, String password) async {
  final url = Uri.parse("http://192.168.137.76:8000/api/auth/login");

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final accessToken = data['token']['access_token'];

      await secureStorage.write(key: 'access_token', value: accessToken);

      print('Access token berhasil disimpan!');
    } else {
      final error = json.decode(response.body);
      throw Exception("Login gagal: ${error['message'] ?? 'Kesalahan server'}");
    }
  } catch (e) {
    throw Exception("Login gagal: $e");
  }
}

Future<String?> fetchProtectedData() async {
  // Explicitly specify return type as String?
  final accessToken = await secureStorage.read(key: 'access_token');

  if (accessToken == null) {
    throw Exception("Access token tidak ditemukan. Silakan login ulang.");
  }

  final url = Uri.parse("http://192.168.137.76:8000/api/user/me");

  try {
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200) {
      return response.body; // Return response data when successful
    } else if (response.statusCode == 401) {
      print("Access token tidak valid atau expired. Silakan login ulang.");
      return null; // Return null when token is invalid/expired
    } else {
      final error = json.decode(response.body);
      print("Kesalahan: ${error['message'] ?? 'Kesalahan server'}");
      return null; // Return null in case of server errors
    }
  } catch (e) {
    print("Terjadi kesalahan: $e");
    return null; // Return null in case of a failure
  }
}

Future<void> logout() async {
  await secureStorage.delete(key: 'access_token');
  print("Access token berhasil dihapus.");
}
