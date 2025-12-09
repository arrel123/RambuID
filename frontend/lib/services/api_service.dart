import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data'; // Penting untuk Web Support
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // ===========================================================================
  // KONFIGURASI KONEKSI (Gabungan Logic IP & Web)
  // ===========================================================================
  
  // IP Laptop kamu (Sesuai kode yang kamu kirim)
  static const String _myLaptopIp = '10.29.88.221'; 
  static const String _port = '8000';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_port';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$_myLaptopIp:$_port'; 
    }
    return 'http://$_myLaptopIp:$_port';
  }

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ===========================================================================
  // DEBUG & TESTING
  // ===========================================================================

  static Future<void> testEndpoints() async {
    debugPrint('\n🔍 === TESTING ALL AVAILABLE ENDPOINTS ===');
    final endpoints = [
      '$baseUrl/jelajahi/',
      '$baseUrl/rambu/',
      '$baseUrl/users/',
      '$baseUrl/stats/',
    ];

    for (var endpoint in endpoints) {
      try {
        debugPrint('📡 Testing: $endpoint');
        final response = await http
            .get(Uri.parse(endpoint), headers: headers)
            .timeout(const Duration(seconds: 3));
        
        debugPrint('✅ Status: ${response.statusCode}');
      } catch (e) {
        debugPrint('❌ Error: $e');
      }
    }
    debugPrint('\n🔍 === ENDPOINT TESTING COMPLETE ===\n');
  }

  // ===========================================================================
  // AUTHENTICATION
  // ===========================================================================

  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = '$baseUrl/login';
      debugPrint('🔵 Login: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['detail'] ?? 'Login gagal'};
      }
    } catch (e) {
      debugPrint('❌ ERROR Login: $e');
      return {'success': false, 'message': 'Koneksi gagal. Cek IP Address.'};
    }
  }

  static Future<Map<String, dynamic>> register(String username, String password, {String? namaLengkap}) async {
    try {
      final url = '$baseUrl/register';
      final body = {'username': username, 'password': password};
      if (namaLengkap != null && namaLengkap.isNotEmpty) body['nama_lengkap'] = namaLengkap;
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['detail'] ?? 'Registrasi gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ===========================================================================
  // USER PROFILE
  // ===========================================================================

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final url = '$baseUrl/users/$userId/profile';
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Gagal mengambil profil'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    String? namaLengkap,
    String? username,
    String? alamat,
    String? password,
    XFile? profileImage,
  }) async {
    if (kIsWeb) {
      Uint8List? imageBytes;
      String? fileName;
      if (profileImage != null) {
        imageBytes = await profileImage.readAsBytes();
        fileName = profileImage.name;
      }
      return await _updateUserProfileWeb(
        userId: userId,
        namaLengkap: namaLengkap,
        username: username,
        alamat: alamat,
        password: password,
        imageBytes: imageBytes,
        fileName: fileName,
      );
    } else {
      return await _updateUserProfileMobile(
        userId: userId,
        namaLengkap: namaLengkap,
        username: username,
        alamat: alamat,
        password: password,
        profileImage: profileImage,
      );
    }
  }

  static Future<Map<String, dynamic>> deleteProfileImage(int userId) async {
    try {
      final url = '$baseUrl/users/$userId/profile-image';
      final response = await http.delete(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body), 'message': 'Foto profil dihapus'};
      } else {
        return {'success': false, 'message': 'Gagal menghapus foto'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ===========================================================================
  // ADMIN FEATURES
  // ===========================================================================

  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final url = '$baseUrl/users/';
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Gagal mengambil data pengguna'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final url = '$baseUrl/stats/';
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Gagal mengambil statistik'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ===========================================================================
  // CRUD RAMBU
  // ===========================================================================
  
  static Future<Map<String, dynamic>> getRambuList() async {
    try {
      final url = '$baseUrl/rambu/';
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Gagal mengambil data rambu'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteRambu(int id) async {
    try {
      final url = '$baseUrl/rambu/$id';
      final response = await http.delete(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body), 'message': 'Rambu berhasil dihapus'};
      } else {
        return {'success': false, 'message': 'Gagal menghapus rambu'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> createRambu({
    required String nama,
    required String deskripsi,
    required String kategori,
    required XFile? gambar,
  }) async {
    if (kIsWeb) {
      if (gambar == null) return {'success': false, 'message': 'Gambar harus dipilih'};
      final bytes = await gambar.readAsBytes();
      return await createRambuWeb(
        nama: nama, deskripsi: deskripsi, kategori: kategori, imageBytes: bytes, fileName: gambar.name
      );
    } else {
      if (gambar == null) return {'success': false, 'message': 'Gambar harus dipilih'};
      return await _createRambuMobile(
        nama: nama, deskripsi: deskripsi, kategori: kategori, gambar: gambar
      );
    }
  }

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
          id: id, nama: nama, deskripsi: deskripsi, kategori: kategori, imageBytes: bytes, fileName: gambar.name
        );
      } else {
        return await updateRambuWeb(id: id, nama: nama, deskripsi: deskripsi, kategori: kategori);
      }
    } else {
      return await _updateRambuMobile(
        id: id, nama: nama, deskripsi: deskripsi, kategori: kategori, gambar: gambar
      );
    }
  }

  // ===========================================================================
  // AI DETECTION SERVICE
  // ===========================================================================

  static Future<Map<String, dynamic>> detectRambu(XFile image) async {
    try {
      final url = '$baseUrl/deteksi-rambu/';
      debugPrint('🔵 Mengirim gambar ke AI: $url');

      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        bytes,
        filename: image.name,
      ));

      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('🟢 Status Code AI: ${response.statusCode}'); 
      debugPrint('🟢 Response AI: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mendeteksi: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('🔴 Error AI: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ===========================================================================
  // JELAJAHI ENDPOINTS
  // ===========================================================================

  static Future<Map<String, dynamic>> getJelajahiWithRambu() async {
    try {
      debugPrint('🔍 === MENGAMBIL DATA JELAJAHI DENGAN RAMBU ===');
      
      final url = '$baseUrl/jelajahi/';
      debugPrint('🔵 Menggunakan endpoint: $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final firstItem = data.first;
          if (firstItem.containsKey('nama') && firstItem.containsKey('gambar_url')) {
            return {'success': true, 'data': data};
          }
        }
        debugPrint('⚠️ Data simple, mencoba mengambil data gabungan...');
        return await _getCombinedData();
      } else {
        debugPrint('❌ Endpoint utama gagal, mencoba alternatif...');
        return await _getCombinedData();
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> _getCombinedData() async {
    try {
      final rambuResponse = await getRambuList();
      if (!rambuResponse['success']) return rambuResponse;
      final rambuList = rambuResponse['data'] as List<dynamic>;
      
      final jelajahiUrl = '$baseUrl/jelajahi/';
      final jelajahiResponse = await http.get(Uri.parse(jelajahiUrl), headers: headers);
      if (jelajahiResponse.statusCode != 200) return {'success': false, 'message': 'Gagal ambil lokasi'};
      
      final jelajahiList = jsonDecode(jelajahiResponse.body) as List<dynamic>;
      
      List<Map<String, dynamic>> combinedData = [];
      for (var location in jelajahiList) {
        int? rambuId = location['rambu_id'];
        var rambu = rambuList.firstWhere((r) => r['id'] == rambuId, orElse: () => null);
        
        if (rambu != null) {
          combinedData.add({
            ...location,
            'nama': rambu['nama'],
            'deskripsi': rambu['deskripsi'],
            'kategori': rambu['kategori'],
            'gambar_url': rambu['gambar_url'],
          });
        }
      }
      return {'success': true, 'data': combinedData};
    } catch (e) {
      return {'success': false, 'message': 'Gagal combine data: $e'};
    }
  }

  static Future<Map<String, dynamic>> createJelajahi({
    required int rambuId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = '$baseUrl/jelajahi/';
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'rambu_id': rambuId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Gagal menambahkan lokasi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateJelajahi({
    required int jelajahiId,
    required int rambuId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = '$baseUrl/jelajahi/$jelajahiId';
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'rambu_id': rambuId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Gagal memperbarui lokasi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteJelajahi(int jelajahiId) async {
    try {
      final url = '$baseUrl/jelajahi/$jelajahiId';
      final response = await http.delete(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Gagal menghapus lokasi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  static Future<Map<String, dynamic>> _updateUserProfileMobile({
    required int userId, String? namaLengkap, String? username, String? alamat, String? password, XFile? profileImage,
  }) async {
      try {
      final url = '$baseUrl/users/$userId/profile';
      final request = http.MultipartRequest('PUT', Uri.parse(url));

      if (namaLengkap != null) request.fields['nama_lengkap'] = namaLengkap;
      if (username != null) request.fields['username'] = username;
      if (alamat != null) request.fields['alamat'] = alamat;
      if (password != null && password.isNotEmpty) request.fields['password'] = password;

      if (profileImage != null) {
        final bytes = await profileImage.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('profile_image', bytes, filename: profileImage.name));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body), 'message': 'Profil diperbarui'};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['detail'] ?? 'Gagal update'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _updateUserProfileWeb({
    required int userId, String? namaLengkap, String? username, String? alamat, String? password, Uint8List? imageBytes, String? fileName,
  }) async {
    try {
      final url = '$baseUrl/users/$userId/profile';
      var request = http.MultipartRequest('PUT', Uri.parse(url));

      if (namaLengkap != null) request.fields['nama_lengkap'] = namaLengkap;
      if (username != null) request.fields['username'] = username;
      if (alamat != null) request.fields['alamat'] = alamat;
      if (password != null && password.isNotEmpty) request.fields['password'] = password;

      if (imageBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes('profile_image', imageBytes, filename: fileName));
      }

      var streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body), 'message': 'Profil berhasil diperbarui'};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['detail'] ?? 'Gagal memperbarui profil'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _createRambuMobile({
    required String nama, required String deskripsi, required String kategori, required XFile gambar,
  }) async {
    try {
      final url = '$baseUrl/rambu/';
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['nama'] = nama;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kategori'] = kategori;

      final bytes = await gambar.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('gambar', bytes, filename: gambar.name));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body), 'message': 'Rambu berhasil dibuat'};
      }
      return {'success': false, 'message': 'Gagal upload'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _updateRambuMobile({
    required int id, required String nama, required String deskripsi, required String kategori, XFile? gambar,
  }) async {
    try {
      final url = '$baseUrl/rambu/$id';
      final request = http.MultipartRequest('PUT', Uri.parse(url));
      request.fields['nama'] = nama;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kategori'] = kategori;

      if (gambar != null) {
        final bytes = await gambar.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('gambar', bytes, filename: gambar.name));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body), 'message': 'Rambu berhasil diperbarui'};
      }
      return {'success': false, 'message': 'Gagal update'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createRambuWeb({
    required String nama, required String deskripsi, required String kategori, required Uint8List imageBytes, required String fileName,
  }) async {
    try {
      final url = '$baseUrl/rambu/';
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['nama'] = nama;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kategori'] = kategori;

      request.files.add(http.MultipartFile.fromBytes('gambar', imageBytes, filename: fileName));

      var streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body), 'message': 'Rambu berhasil dibuat'};
      }
      return {'success': false, 'message': 'Gagal upload'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateRambuWeb({
    required int id, required String nama, required String deskripsi, required String kategori, Uint8List? imageBytes, String? fileName,
  }) async {
    try {
      final url = '$baseUrl/rambu/$id';
      var request = http.MultipartRequest('PUT', Uri.parse(url));
      request.fields['nama'] = nama;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kategori'] = kategori;

      if (imageBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes('gambar', imageBytes, filename: fileName));
      }

      var streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body), 'message': 'Rambu berhasil diperbarui'};
      }
      return {'success': false, 'message': 'Gagal update'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

// === FUNGSI FIX GAMBAR (UPDATE) ===
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://via.placeholder.com/150';
    }

    // 1. Jika sudah ada http, langsung pakai
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // 2. FIX WINDOWS: Ubah Backslash (\) jadi Forward Slash (/)
    String cleanPath = imagePath.replaceAll('\\', '/');

    // 3. Pastikan diawali dengan /
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }

    // 4. Gabungkan dengan Base URL
    String finalUrl = '$baseUrl$cleanPath';
    
    // DEBUG: Cek di Terminal apakah URL-nya benar
    debugPrint('🖼️ LOAD GAMBAR: $finalUrl');
    
    return finalUrl;
  }
}