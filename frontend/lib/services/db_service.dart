import 'dart:convert';
import 'package:flutter/foundation.dart'; // Untuk debugPrint
import 'package:http/http.dart' as http;

class DbService {
  // === KONFIGURASI SERVER VPS NAT ===
  // UPDATE: Pastikan IP dan Port ini sesuai dengan yang di api_service.dart
  static const String baseUrl = 'http://151.243.222.93:56789'; 

  // === DATA CADANGAN (FIXED DATA) ===
  // Diambil dari kodingan Stash kamu.
  // Berguna jika server mati atau tidak ada koneksi internet.
  static final List<Map<String, dynamic>> _fixedBackupData = [
    {
      'id': 991, 'rambu_id': 5, 'nama': 'Dilarang Parkir',
      'latitude': 1.1194178, 'longitude': 104.0485686, 'kategori': 'Larangan', 'gambar_url': ''
    },
    {
      'id': 992, 'rambu_id': 17, 'nama': '3 Panah Melingkar',
      'latitude': 1.1193241, 'longitude': 104.0485688, 'kategori': 'Petunjuk', 'gambar_url': ''
    },
    {
      'id': 993, 'rambu_id': 2, 'nama': 'Dilarang Belok Kanan',
      'latitude': 1.1193241, 'longitude': 104.0485688, 'kategori': 'Larangan', 'gambar_url': ''
    },
    {
      'id': 994, 'rambu_id': 99, 'nama': 'Rambu Keluar',
      'latitude': 1.1189841, 'longitude': 104.0483701, 'kategori': 'Petunjuk', 'gambar_url': ''
    },
    {
      'id': 995, 'rambu_id': 99, 'nama': 'Lajur Wajib Kanan',
      'latitude': 1.1189314, 'longitude': 104.0491652, 'kategori': 'Perintah', 'gambar_url': ''
    },
    {
      'id': 996, 'rambu_id': 99, 'nama': 'Wajib Lurus',
      'latitude': 1.1189274, 'longitude': 104.0494293, 'kategori': 'Perintah', 'gambar_url': ''
    },
    {
      'id': 997, 'rambu_id': 99, 'nama': 'Dilarang Masuk',
      'latitude': 1.1190402, 'longitude': 104.0498061, 'kategori': 'Larangan', 'gambar_url': ''
    },
  ];

  // === TEST CONNECTION ===
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Test connection failed: $e');
      return false;
    }
  }

  // === JELAJAHI ENDPOINTS (HYBRID) ===
  // Mencoba API dulu, jika gagal pakai data backup
  static Future<List<Map<String, dynamic>>> getJelajahiWithRambu() async {
    try {
      debugPrint('🌐 Requesting MAPS data: $baseUrl/jelajahi/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/jelajahi/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10)); // Timeout 10 detik

      debugPrint('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('✅ Data API berhasil di-parse: ${data.length} items');
        
        return data.map((item) {
          return {
            'id': item['id'],
            'rambu_id': item['rambu_id'],
            'latitude': item['latitude'],
            'longitude': item['longitude'],
            'nama': item['nama'] ?? 'Tanpa Nama',
            'gambar_url': item['gambar_url'] ?? '',
            'deskripsi': item['deskripsi'] ?? '',
            'kategori': item['kategori'] ?? 'lainnya',
          };
        }).toList();
      } else {
        debugPrint('⚠️ Gagal ambil API (${response.statusCode}), beralih ke Data Backup...');
        return _fixedBackupData;
      }
    } catch (e) {
      debugPrint('💥 Koneksi Error/Timeout: $e');
      debugPrint('🔄 Menggunakan Data Backup Lokal (Stashed Data)');
      return _fixedBackupData;
    }
  }

  // === AUTH ENDPOINTS ===
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Login gagal');
      }
    } catch (e) {
      throw Exception('Error Login: $e');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String? namaLengkap,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'nama_lengkap': namaLengkap,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      throw Exception('Error Register: $e');
    }
  }

  // === CRUD LOKASI ===
  static Future<Map<String, dynamic>> addJelajahiLocation({
    required int rambuId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jelajahi/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rambu_id': rambuId,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Gagal menambahkan lokasi');
      }
    } catch (e) {
      throw Exception('Error Add Location: $e');
    }
  }

  static Future<bool> deleteJelajahiLocation(int jelajahiId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/jelajahi/$jelajahiId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error Delete: $e');
    }
  }

  static Future<Map<String, dynamic>> updateJelajahiLocation({
    required int jelajahiId,
    required int rambuId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/jelajahi/$jelajahiId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rambu_id': rambuId,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Gagal update lokasi');
      }
    } catch (e) {
      throw Exception('Error Update: $e');
    }
  }

  // === UTILS ===
  static Future<List<Map<String, dynamic>>> getAllRambu() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rambu/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Gagal mengambil data rambu');
      }
    } catch (e) {
      throw Exception('Error Get Rambu: $e');
    }
  }

  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    if (!imagePath.startsWith('/')) imagePath = '/$imagePath';
    return '$baseUrl$imagePath';
  }
}