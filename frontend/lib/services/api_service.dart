import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ UNTUK WEB (Chrome) - Gunakan localhost
  static const String baseUrl = 'http://localhost:8000';
  
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ===========================================================================
  // DEBUG & TESTING FUNCTIONS
  // ===========================================================================

  static Future<void> testEndpoints() async {
    print('\n🔍 === TESTING ALL AVAILABLE ENDPOINTS ===');
    
    final endpoints = [
      '$baseUrl/jelajahi/',
      '$baseUrl/rambu/',
      '$baseUrl/jelajahi-with-rambu/',
      '$baseUrl/rambu-with-location/',
      '$baseUrl/map-markers/',
      '$baseUrl/all-rambu-locations/',
      '$baseUrl/api/rambus',
      '$baseUrl/api/jelajahi',
    ];

    for (var endpoint in endpoints) {
      try {
        print('\n📡 Testing: $endpoint');
        final response = await http
            .get(Uri.parse(endpoint), headers: headers)
            .timeout(const Duration(seconds: 3));
        
        print('✅ Status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            final dataLength = data is List ? data.length : (data['data'] is List ? data['data'].length : 'unknown');
            print('📊 Data type: ${data.runtimeType}');
            print('📊 Item count: $dataLength');
            
            // Print sample data (if available)
            if (data is List && data.isNotEmpty) {
              print('📋 Sample first item:');
              final sample = data.first;
              if (sample is Map) {
                sample.forEach((key, value) {
                  print('   $key: $value (${value.runtimeType})');
                });
              }
            } else if (data is Map && data.containsKey('data') && data['data'] is List && data['data'].isNotEmpty) {
              print('📋 Sample first item:');
              final sample = data['data'].first;
              if (sample is Map) {
                sample.forEach((key, value) {
                  print('   $key: $value (${value.runtimeType})');
                });
              }
            }
          } catch (e) {
            print('❌ JSON Parse Error: $e');
          }
        } else {
          print('❌ Failed with status: ${response.statusCode}');
        }
      } on TimeoutException {
        print('⏰ Timeout');
      } catch (e) {
        print('❌ Error: $e');
      }
    }
    
    print('\n🔍 === ENDPOINT TESTING COMPLETE ===\n');
  }

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
          .timeout(const Duration(seconds: 15));

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Login gagal',
        };
      }
    } on TimeoutException catch (e) {
      print('⏰ TIMEOUT: $e');
      return {
        'success': false,
        'message': 'Koneksi timeout. Pastikan backend berjalan di $baseUrl'
      };
    } on SocketException catch (e) {
      print('🔌 SOCKET ERROR: $e');
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server. Pastikan backend berjalan.'
      };
    } catch (e) {
      print('❌ ERROR: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String password, {
    String? namaLengkap,
  }) async {
    try {
      final url = '$baseUrl/register';
      
      final body = {
        'username': username,
        'password': password,
      };
      
      if (namaLengkap != null && namaLengkap.isNotEmpty) {
        body['nama_lengkap'] = namaLengkap;
      }
      
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
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
  // USER PROFILE ENDPOINTS
  // ===========================================================================

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final url = '$baseUrl/users/$userId/profile';
      print('🔵 Get Profile: $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> profile = jsonDecode(response.body);
        return {'success': true, 'data': profile};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal mengambil profil',
        };
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
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Foto profil berhasil dihapus',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal menghapus foto profil',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ===========================================================================
  // PRIVATE HELPERS FOR PROFILE UPDATE
  // ===========================================================================

  static Future<Map<String, dynamic>> _updateUserProfileMobile({
    required int userId,
    String? namaLengkap,
    String? username,
    String? alamat,
    String? password,
    XFile? profileImage,
  }) async {
    try {
      final url = '$baseUrl/users/$userId/profile';
      final request = http.MultipartRequest('PUT', Uri.parse(url));

      if (namaLengkap != null) request.fields['nama_lengkap'] = namaLengkap;
      if (username != null) request.fields['username'] = username;
      if (alamat != null) request.fields['alamat'] = alamat;
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      if (profileImage != null) {
        final bytes = await profileImage.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'profile_image',
          bytes,
          filename: profileImage.name,
        ));
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Profil berhasil diperbarui'
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal memperbarui profil'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _updateUserProfileWeb({
    required int userId,
    String? namaLengkap,
    String? username,
    String? alamat,
    String? password,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      final url = '$baseUrl/users/$userId/profile';
      var request = http.MultipartRequest('PUT', Uri.parse(url));

      if (namaLengkap != null) request.fields['nama_lengkap'] = namaLengkap;
      if (username != null) request.fields['username'] = username;
      if (alamat != null) request.fields['alamat'] = alamat;
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      if (imageBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'profile_image',
          imageBytes,
          filename: fileName,
        ));
      }

      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Profil berhasil diperbarui'
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal memperbarui profil'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ===========================================================================
  // ADMIN FEATURES (Dashboard & Users)
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
  // PRIVATE HELPERS (Mobile vs Web Implementation for Rambu)
  // ===========================================================================

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

  // ===========================================================================
  // JELAJAHI ENDPOINTS - DIPERBARUI UNTUK DATA LENGKAP
  // ===========================================================================

  static Future<Map<String, dynamic>> getJelajahiWithRambu() async {
    try {
      print('🔍 === MENGAMBIL DATA JELAJAHI DENGAN RAMBU ===');
      
      // OPTION 1: Coba endpoint utama dulu
      final url = '$baseUrl/jelajahi/';
      print('🔵 Menggunakan endpoint: $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      print('📥 Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Data diterima, tipe: ${data.runtimeType}');
        
        // Cek struktur data
        List<dynamic> finalData = [];
        
        if (data is List) {
          print('📊 Data adalah List dengan ${data.length} items');
          
          // Cek apakah data sudah lengkap
          if (data.isNotEmpty) {
            final firstItem = data.first;
            print('📋 Sample item keys: ${firstItem.keys}');
            
            // Cek apakah sudah ada data rambu
            bool hasRambuData = firstItem.containsKey('nama') && 
                               firstItem.containsKey('kategori') &&
                               firstItem.containsKey('deskripsi');
            
            if (hasRambuData) {
              print('✅ Data sudah lengkap dengan info rambu');
              finalData = data;
            } else {
              print('⚠️ Data tidak lengkap, mencoba mengambil data rambu...');
              // Coba OPTION 2: Ambil data gabungan
              return await _getCombinedData();
            }
          }
        } else if (data is Map && data.containsKey('data')) {
          print('📊 Data adalah Map dengan key "data"');
          finalData = data['data'] is List ? data['data'] : [];
        }
        
        print('✅ Mengembalikan ${finalData.length} items');
        return {'success': true, 'data': finalData};
        
      } else {
        print('❌ Endpoint utama gagal, mencoba alternatif...');
        // Coba OPTION 2: Ambil data gabungan
        return await _getCombinedData();
      }
      
    } catch (e) {
      print('❌ Error: $e');
      return {
        'success': false, 
        'message': 'Koneksi gagal: $e'
      };
    }
  }

  // Helper untuk mengambil data gabungan
  static Future<Map<String, dynamic>> _getCombinedData() async {
    try {
      print('🔄 Mencoba mengambil data gabungan...');
      
      // Ambil data rambu
      final rambuResponse = await getRambuList();
      if (!rambuResponse['success']) {
        return rambuResponse;
      }
      
      final rambuList = rambuResponse['data'] as List<dynamic>;
      print('📊 Jumlah data rambu: ${rambuList.length}');
      
      // Ambil data jelajahi (lokasi)
      final jelajahiUrl = '$baseUrl/jelajahi/';
      final jelajahiResponse = await http
          .get(Uri.parse(jelajahiUrl), headers: headers)
          .timeout(const Duration(seconds: 10));
      
      if (jelajahiResponse.statusCode != 200) {
        return {
          'success': false, 
          'message': 'Gagal mengambil data lokasi'
        };
      }
      
      final jelajahiList = jsonDecode(jelajahiResponse.body) as List<dynamic>;
      print('📊 Jumlah data lokasi: ${jelajahiList.length}');
      
      // Gabungkan data
      List<Map<String, dynamic>> combinedData = [];
      
      for (var location in jelajahiList) {
        try {
          // Pastikan location adalah Map
          if (location is! Map<String, dynamic>) continue;
          
          int? rambuId;
          
          // Cari rambu_id dengan berbagai kemungkinan format
          if (location['rambu_id'] != null) {
            rambuId = location['rambu_id'] is int 
                ? location['rambu_id'] 
                : int.tryParse(location['rambu_id'].toString());
          } else if (location['rambu'] != null && location['rambu'] is Map) {
            // Jika rambu sudah termasuk sebagai object
            rambuId = location['rambu']['id'];
          }
          
          if (rambuId != null) {
            // Cari data rambu yang sesuai
            var rambu = rambuList.firstWhere(
              (r) => r['id'] == rambuId,
              orElse: () => null,
            );
            
            if (rambu != null) {
              combinedData.add({
                ...location,
                'nama': rambu['nama'],
                'deskripsi': rambu['deskripsi'],
                'kategori': rambu['kategori'],
                'gambar_url': rambu['gambar_url'],
              });
            } else {
              print('⚠️ Tidak ditemukan rambu dengan id: $rambuId');
            }
          } else {
            print('⚠️ Lokasi tidak memiliki rambu_id: $location');
          }
        } catch (e) {
          print('⚠️ Error menggabungkan data: $e');
          continue;
        }
      }
      
      print('✅ Data gabungan berhasil: ${combinedData.length} items');
      return {'success': true, 'data': combinedData};
      
    } catch (e) {
      print('❌ Error mengambil data gabungan: $e');
      return {
        'success': false, 
        'message': 'Gagal mengambil data gabungan: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> createJelajahi({
    required int rambuId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = '$baseUrl/jelajahi/';
      print('🔵 Create Jelajahi: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode({
              'rambu_id': rambuId,
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal menambahkan lokasi',
        };
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
      print('🔵 Update Jelajahi: $url');

      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode({
              'rambu_id': rambuId,
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal memperbarui lokasi',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteJelajahi(int jelajahiId) async {
    try {
      final url = '$baseUrl/jelajahi/$jelajahiId';
      print('🔵 Delete Jelajahi: $url');

      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Gagal menghapus lokasi',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}