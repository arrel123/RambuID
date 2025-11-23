import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _fallbackHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '127.0.0.1',
  );
  static const String _port = String.fromEnvironment(
    'API_PORT',
    defaultValue: '8000',
  );

  // --- CONFIGURATION BASE URL ---
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_port';
    }

    if (defaultTargetPlatform == TargetPlatform.android && kDebugMode) {
      final apiHost = const String.fromEnvironment('API_HOST');
      if (apiHost.isNotEmpty && apiHost != '127.0.0.1') {
        return 'http://$apiHost:$_port';
      }
      return 'http://10.0.2.2:$_port';
    }

    final apiHost = const String.fromEnvironment('API_HOST');
    if (apiHost.isNotEmpty && apiHost != '127.0.0.1') {
      return 'http://$apiHost:$_port';
    }

    return 'http://$_fallbackHost:$_port';
  }

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ===========================================================================
  // AUTHENTICATION (Login & Register)
  // ===========================================================================

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final url = '$baseUrl/login';
      print('🔵 Login: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String password,
  ) async {
    try {
      final url = '$baseUrl/register';
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Registrasi gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ===========================================================================
  // ADMIN FEATURES (Dashboard & Users) -> INI YANG SEBELUMNYA HILANG
  // ===========================================================================

  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final url = '$baseUrl/users/';
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> users = jsonDecode(response.body);
        return {'success': true, 'data': users};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal mengambil data pengguna',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final url = '$baseUrl/stats/';
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> stats = jsonDecode(response.body);
        return {'success': true, 'data': stats};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal mengambil statistik',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ===========================================================================
  // CRUD RAMBU (Read, Create, Update, Delete)
  // ===========================================================================

  static Future<Map<String, dynamic>> getRambuList() async {
    try {
      final url = '$baseUrl/rambu/';
      print('🔵 Get Rambu: $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> rambu = jsonDecode(response.body);
        return {'success': true, 'data': rambu};
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data rambu: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteRambu(int id) async {
    try {
      final url = '$baseUrl/rambu/$id';
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Rambu berhasil dihapus',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal menghapus rambu',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // --- CREATE (Universal) ---
  static Future<Map<String, dynamic>> createRambu({
    required String nama,
    required String deskripsi,
    required String kategori,
    required XFile? gambar,
  }) async {
    if (kIsWeb) {
      if (gambar == null) {
        return {'success': false, 'message': 'Gambar harus dipilih'};
      }
      final bytes = await gambar.readAsBytes();
      return await createRambuWeb(
        nama: nama,
        deskripsi: deskripsi,
        kategori: kategori,
        imageBytes: bytes,
        fileName: gambar.name,
      );
    } else {
      if (gambar == null) {
        return {'success': false, 'message': 'Gambar harus dipilih'};
      }
      return await _createRambuMobile(
        nama: nama,
        deskripsi: deskripsi,
        kategori: kategori,
        gambar: gambar,
      );
    }
  }

  // --- UPDATE (Universal) -> INI YANG SEBELUMNYA HILANG ---
  static Future<Map<String, dynamic>> updateRambu({
    required int id,
    required String nama,
    required String deskripsi,
    required String kategori,
    XFile? gambar,
  }) async {
    if (kIsWeb) {
      if (gambar != null) {
        final bytes = await gambar.readAsBytes();
        return await updateRambuWeb(
          id: id,
          nama: nama,
          deskripsi: deskripsi,
          kategori: kategori,
          imageBytes: bytes,
          fileName: gambar.name,
        );
      } else {
        return await updateRambuWeb(
          id: id,
          nama: nama,
          deskripsi: deskripsi,
          kategori: kategori,
        );
      }
    } else {
      return await _updateRambuMobile(
        id: id,
        nama: nama,
        deskripsi: deskripsi,
        kategori: kategori,
        gambar: gambar,
      );
    }
  }

  // ===========================================================================
  // PRIVATE HELPERS (Mobile vs Web Implementation)
  // ===========================================================================

  // Mobile Create
  static Future<Map<String, dynamic>> _createRambuMobile({
    required String nama,
    required String deskripsi,
    required String kategori,
    required XFile gambar,
  }) async {
    try {
      final url = '$baseUrl/rambu/';
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['nama'] = nama;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kategori'] = kategori;

      final bytes = await gambar.readAsBytes();
      request.files.add(
          http.MultipartFile.fromBytes('gambar', bytes, filename: gambar.name));

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Rambu berhasil dibuat'
        };
      }
      return {'success': false, 'message': 'Gagal upload'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Mobile Update
  static Future<Map<String, dynamic>> _updateRambuMobile({
    required int id,
    required String nama,
    required String deskripsi,
    required String kategori,
    XFile? gambar,
  }) async {
    try {
      final url = '$baseUrl/rambu/$id';
      final request = http.MultipartRequest('PUT', Uri.parse(url));
      request.fields['nama'] = nama;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kategori'] = kategori;

      if (gambar != null) {
        final bytes = await gambar.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('gambar', bytes,
            filename: gambar.name));
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Rambu berhasil diperbarui'
        };
      }
      return {'success': false, 'message': 'Gagal update'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Web Create
  static Future<Map<String, dynamic>> createRambuWeb({
    required String nama,
    required String deskripsi,
    required String kategori,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final url = '$baseUrl/rambu/';
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['nama'] = nama;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kategori'] = kategori;

      request.files.add(http.MultipartFile.fromBytes('gambar', imageBytes,
          filename: fileName));

      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Rambu berhasil dibuat'
        };
      }
      return {'success': false, 'message': 'Gagal upload'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Web Update
  static Future<Map<String, dynamic>> updateRambuWeb({
    required int id,
    required String nama,
    required String deskripsi,
    required String kategori,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      final url = '$baseUrl/rambu/$id';
      var request = http.MultipartRequest('PUT', Uri.parse(url));
      request.fields['nama'] = nama;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kategori'] = kategori;

      if (imageBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes('gambar', imageBytes,
            filename: fileName));
      }

      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Rambu berhasil diperbarui'
        };
      }
      return {'success': false, 'message': 'Gagal update'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}