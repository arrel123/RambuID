import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  static String get baseUrl {
    if (kIsWeb) {
      // Untuk web, selalu gunakan localhost:8000
      return 'http://localhost:$_port';
    }

    // Untuk Android Emulator
    if (defaultTargetPlatform == TargetPlatform.android && kDebugMode) {
      // Cek apakah menggunakan emulator (biasanya emulator menggunakan 10.0.2.2)
      // Untuk device fisik, gunakan IP PC dari environment variable
      final apiHost = const String.fromEnvironment('API_HOST');
      if (apiHost.isNotEmpty && apiHost != '127.0.0.1') {
        return 'http://$apiHost:$_port';
      }
      return 'http://10.0.2.2:$_port';
    }

    // Untuk iOS atau device fisik lainnya
    // Gunakan IP PC dari environment variable, atau fallback ke 127.0.0.1
    final apiHost = const String.fromEnvironment('API_HOST');
    if (apiHost.isNotEmpty && apiHost != '127.0.0.1') {
      return 'http://$apiHost:$_port';
    }

    return 'http://$_fallbackHost:$_port';
  }

  // Headers untuk request
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Fungsi untuk handle login
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final url = '$baseUrl/login';
      print('🔵 Login: Mengirim request ke $url');
      print('🔵 Login: Base URL = $baseUrl');

      final response = await http
          .post(
            Uri.parse(url),
        headers: headers,
        body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout - server tidak merespons');
            },
          );

      print('🔵 Login: Response status = ${response.statusCode}');
      print('🔵 Login: Response body = ${response.body}');

      // Terima semua status code 2xx sebagai sukses
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        // Handle error response
        try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Login gagal',
        };
    } catch (e) {
      return {
        'success': false,
            'message': 'Login gagal. Status: ${response.statusCode}',
          };
        }
      }
    } on http.ClientException catch (e) {
      print('🔴 Login ClientException: $e');
      return {
        'success': false,
        'message':
            'Tidak dapat terhubung ke server. Pastikan backend berjalan di http://localhost:8000',
      };
    } on Exception catch (e) {
      print('🔴 Login Exception: $e');
      return {
        'success': false,
        'message': e.toString().contains('timeout')
            ? 'Server tidak merespons. Pastikan backend berjalan.'
            : 'Koneksi gagal: ${e.toString()}',
      };
    } catch (e) {
      print('🔴 Login Error: $e');
      return {
        'success': false,
        'message':
            'Koneksi ke server gagal. Pastikan backend sedang berjalan di http://localhost:8000',
      };
    }
  }

  // Fungsi untuk handle register
  static Future<Map<String, dynamic>> register(
    String username,
    String password,
  ) async {
    try {
      final url = '$baseUrl/register';
      print('🔵 Register: Mengirim request ke $url');
      print('🔵 Register: Base URL = $baseUrl');

      final response = await http
          .post(
            Uri.parse(url),
        headers: headers,
        body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout - server tidak merespons');
            },
          );

      print('🔵 Register: Response status = ${response.statusCode}');
      print('🔵 Register: Response body = ${response.body}');

      // Backend mengembalikan status 201 untuk registrasi sukses
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        // Handle error response
        try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Registrasi gagal',
        };
        } catch (e) {
          return {
            'success': false,
            'message': 'Registrasi gagal. Status: ${response.statusCode}',
          };
        }
      }
    } on http.ClientException catch (e) {
      print('🔴 Register ClientException: $e');
      return {
        'success': false,
        'message':
            'Tidak dapat terhubung ke server. Pastikan backend berjalan di http://localhost:8000',
      };
    } on Exception catch (e) {
      print('🔴 Register Exception: $e');
      return {
        'success': false,
        'message': e.toString().contains('timeout')
            ? 'Server tidak merespons. Pastikan backend berjalan.'
            : 'Koneksi gagal: ${e.toString()}',
      };
    } catch (e) {
      print('🔴 Register Error: $e');
      return {
        'success': false,
        'message':
            'Koneksi ke server gagal. Pastikan backend sedang berjalan di http://localhost:8000',
      };
    }
  }

  // Fungsi untuk mendapatkan semua data pengguna (admin)
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final url = '$baseUrl/users/';
      print('🔵 Get Users: Mengirim request ke $url');
      print('🔵 Get Users: Base URL = $baseUrl');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout - server tidak merespons');
            },
          );

      print('🔵 Get Users: Response status = ${response.statusCode}');
      print('🔵 Get Users: Response body = ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> users = jsonDecode(response.body);
        return {'success': true, 'data': users};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['detail'] ?? 'Gagal mengambil data pengguna',
          };
        } catch (e) {
          return {
            'success': false,
            'message':
                'Gagal mengambil data pengguna. Status: ${response.statusCode}',
          };
        }
      }
    } on http.ClientException catch (e) {
      print('🔴 Get Users ClientException: $e');
      return {
        'success': false,
        'message':
            'Tidak dapat terhubung ke server. Pastikan backend berjalan di http://localhost:8000',
      };
    } on Exception catch (e) {
      print('🔴 Get Users Exception: $e');
      return {
        'success': false,
        'message': e.toString().contains('timeout')
            ? 'Server tidak merespons. Pastikan backend berjalan.'
            : 'Koneksi gagal: ${e.toString()}',
      };
    } catch (e) {
      print('🔴 Get Users Error: $e');
      return {
        'success': false,
        'message':
            'Koneksi ke server gagal. Pastikan backend sedang berjalan di http://localhost:8000',
      };
    }
  }

  // Fungsi untuk mendapatkan statistik dashboard (admin)
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final url = '$baseUrl/stats/';
      print('🔵 Get Stats: Mengirim request ke $url');
      print('🔵 Get Stats: Base URL = $baseUrl');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout - server tidak merespons');
            },
          );

      print('🔵 Get Stats: Response status = ${response.statusCode}');
      print('🔵 Get Stats: Response body = ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> stats = jsonDecode(response.body);
        return {'success': true, 'data': stats};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['detail'] ?? 'Gagal mengambil statistik',
          };
    } catch (e) {
      return {
        'success': false,
            'message':
                'Gagal mengambil statistik. Status: ${response.statusCode}',
          };
        }
      }
    } on http.ClientException catch (e) {
      print('🔴 Get Stats ClientException: $e');
      return {
        'success': false,
        'message':
            'Tidak dapat terhubung ke server. Pastikan backend berjalan di http://localhost:8000',
      };
    } on Exception catch (e) {
      print('🔴 Get Stats Exception: $e');
      return {
        'success': false,
        'message': e.toString().contains('timeout')
            ? 'Server tidak merespons. Pastikan backend berjalan.'
            : 'Koneksi gagal: ${e.toString()}',
      };
    } catch (e) {
      print('🔴 Get Stats Error: $e');
      return {
        'success': false,
        'message':
            'Koneksi ke server gagal. Pastikan backend sedang berjalan di http://localhost:8000',
      };
    }
  }

  // Fungsi untuk mendapatkan daftar rambu
  static Future<Map<String, dynamic>> getRambuList() async {
    try {
      final url = '$baseUrl/rambu/';
      print('🔵 Get Rambu: Mengirim request ke $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw Exception('Request timeout - server tidak merespons'),
          );

      print('🔵 Get Rambu: Response status = ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> rambu = jsonDecode(response.body);
        return {'success': true, 'data': rambu};
      } else {
        return {
          'success': false,
          'message':
              'Gagal mengambil data rambu. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('🔴 Get Rambu Error: $e');
      return {
        'success': false,
        'message': e.toString().contains('timeout')
            ? 'Server tidak merespons. Pastikan backend berjalan.'
            : 'Koneksi gagal: ${e.toString()}',
      };
    }
  }

  // Fungsi universal untuk create rambu (otomatis pilih metode berdasarkan platform)
  static Future<Map<String, dynamic>> createRambu({
    required String nama,
    required String deskripsi,
    required String kategori,
    required XFile? gambar,
  }) async {
    if (kIsWeb) {
      // Untuk web, gunakan metode web dengan bytes
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
      // Untuk mobile, gunakan metode original
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

  // Fungsi untuk create rambu mobile (private)
  static Future<Map<String, dynamic>> _createRambuMobile({
    required String nama,
    required String deskripsi,
    required String kategori,
    required XFile gambar,
  }) async {
    try {
      final url = '$baseUrl/rambu/';
      print('🔵 Create Rambu Mobile: Mengirim request ke $url');

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['nama'] = nama;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kategori'] = kategori;

      final bytes = await gambar.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('gambar', bytes, filename: gambar.name),
      );
      request.headers['Accept'] = 'application/json';

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 20),
        onTimeout: () =>
            throw Exception('Request timeout - server tidak merespons'),
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('🔵 Create Rambu Mobile: Response status = ${response.statusCode}');
      print('🔵 Create Rambu Mobile: Response body = ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Rambu berhasil dibuat',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal membuat rambu',
        };
      }
    } catch (e) {
      print('🔴 Create Rambu Mobile Error: $e');
      return {
        'success': false,
        'message': e.toString().contains('timeout')
            ? 'Server tidak merespons. Pastikan backend berjalan.'
            : 'Koneksi gagal: ${e.toString()}',
      };
    }
  }

  // Fungsi untuk create rambu web
  static Future<Map<String, dynamic>> createRambuWeb({
    required String nama,
    required String deskripsi,
    required String kategori,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final url = '$baseUrl/rambu/';
      print('🔵 Create Rambu Web: Mengirim request ke $url');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add text fields
      request.fields['nama'] = nama;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kategori'] = kategori;

      // Add image file
      var multipartFile = http.MultipartFile.fromBytes(
        'gambar',
        imageBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);
      request.headers['Accept'] = 'application/json';

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 20),
        onTimeout: () =>
            throw Exception('Request timeout - server tidak merespons'),
      );

      var response = await http.Response.fromStream(streamedResponse);
      print('🔵 Create Rambu Web: Response status = ${response.statusCode}');
      print('🔵 Create Rambu Web: Response body = ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Rambu berhasil dibuat',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal membuat rambu',
        };
      }
    } catch (e) {
      print('🔴 Create Rambu Web Error: $e');
      return {
        'success': false,
        'message': e.toString().contains('timeout')
            ? 'Server tidak merespons. Pastikan backend berjalan.'
            : 'Koneksi gagal: ${e.toString()}',
      };
    }
  }

  // Fungsi universal untuk update rambu (otomatis pilih metode berdasarkan platform)
  static Future<Map<String, dynamic>> updateRambu({
    required int id,
    required String nama,
    required String deskripsi,
    required String kategori,
    XFile? gambar,
  }) async {
    if (kIsWeb) {
      // Untuk web
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
      // Untuk mobile
      return await _updateRambuMobile(
        id: id,
        nama: nama,
        deskripsi: deskripsi,
        kategori: kategori,
        gambar: gambar,
      );
    }
  }

  // Fungsi untuk update rambu mobile (private)
  static Future<Map<String, dynamic>> _updateRambuMobile({
    required int id,
    required String nama,
    required String deskripsi,
    required String kategori,
    XFile? gambar,
  }) async {
    try {
      final url = '$baseUrl/rambu/$id';
      print('🔵 Update Rambu Mobile: Mengirim request ke $url');

      final request = http.MultipartRequest('PUT', Uri.parse(url));
      request.fields['nama'] = nama;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kategori'] = kategori;

      if (gambar != null) {
        final bytes = await gambar.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('gambar', bytes, filename: gambar.name),
        );
      }
      request.headers['Accept'] = 'application/json';

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 20),
        onTimeout: () =>
            throw Exception('Request timeout - server tidak merespons'),
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('🔵 Update Rambu Mobile: Response status = ${response.statusCode}');
      print('🔵 Update Rambu Mobile: Response body = ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Rambu berhasil diperbarui',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal memperbarui rambu',
        };
      }
    } catch (e) {
      print('🔴 Update Rambu Mobile Error: $e');
      return {
        'success': false,
        'message': e.toString().contains('timeout')
            ? 'Server tidak merespons. Pastikan backend berjalan.'
            : 'Koneksi gagal: ${e.toString()}',
      };
    }
  }

  // Fungsi untuk update rambu web
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
      print('🔵 Update Rambu Web: Mengirim request ke $url');

      var request = http.MultipartRequest('PUT', Uri.parse(url));

      // Add text fields
      request.fields['nama'] = nama;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kategori'] = kategori;

      // Add image file if provided
      if (imageBytes != null && fileName != null) {
        var multipartFile = http.MultipartFile.fromBytes(
          'gambar',
          imageBytes,
          filename: fileName,
        );
        request.files.add(multipartFile);
      }
      request.headers['Accept'] = 'application/json';

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 20),
        onTimeout: () =>
            throw Exception('Request timeout - server tidak merespons'),
      );

      var response = await http.Response.fromStream(streamedResponse);
      print('🔵 Update Rambu Web: Response status = ${response.statusCode}');
      print('🔵 Update Rambu Web: Response body = ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Rambu berhasil diperbarui',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal memperbarui rambu',
        };
      }
    } catch (e) {
      print('🔴 Update Rambu Web Error: $e');
      return {
        'success': false,
        'message': e.toString().contains('timeout')
            ? 'Server tidak merespons. Pastikan backend berjalan.'
            : 'Koneksi gagal: ${e.toString()}',
      };
    }
  }

  // Fungsi untuk menghapus rambu
  static Future<Map<String, dynamic>> deleteRambu(int id) async {
    try {
      final url = '$baseUrl/rambu/$id';
      print('🔵 Delete Rambu: Mengirim request ke $url');

      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw Exception('Request timeout - server tidak merespons'),
          );

      print('🔵 Delete Rambu: Response status = ${response.statusCode}');
      print('🔵 Delete Rambu: Response body = ${response.body}');

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
      print('🔴 Delete Rambu Error: $e');
      return {
        'success': false,
        'message': e.toString().contains('timeout')
            ? 'Server tidak merespons. Pastikan backend berjalan.'
            : 'Koneksi gagal: ${e.toString()}',
      };
    }
  }
}
