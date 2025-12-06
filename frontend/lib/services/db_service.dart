import 'dart:convert';
import 'package:http/http.dart' as http;

class DbService {
  // GANTI DENGAN IP KOMPUTER ANDA
  // Untuk Android Emulator: http://10.0.2.2:8000
  // Untuk Device Fisik di jaringan yang sama: http://192.168.x.x:8000
  static const String baseUrl = 'http://192.168.100.140:8000'; // GANTI IP INI!

  // === TEST CONNECTION ===
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Test connection failed: $e');
      return false;
    }
  }

  // === AUTH ENDPOINTS (Jika dibutuhkan) ===
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
      throw Exception('Error: $e');
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
      throw Exception('Error: $e');
    }
  }

  // === JELAJAHI ENDPOINTS ===
  static Future<List<Map<String, dynamic>>> getJelajahiWithRambu() async {
    try {
      print('🌐 Requesting: $baseUrl/jelajahi/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/jelajahi/'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Data berhasil di-parse: ${data.length} items');
        
        // Debug: print data pertama untuk melihat strukturnya
        if (data.isNotEmpty) {
          print('📝 Data contoh: ${data[0]}');
        }
        
        return data.map((item) {
          return {
            'id': item['id'],
            'rambu_id': item['rambu_id'],
            'latitude': item['latitude'],
            'longitude': item['longitude'],
            'nama': item['nama'] ?? '',
            'gambar_url': item['gambar_url'] ?? '',
            'deskripsi': item['deskripsi'] ?? '',
            'kategori': item['kategori'] ?? 'lainnya',
          };
        }).toList();
      } else {
        print('❌ Error response: ${response.body}');
        throw Exception('Gagal mengambil data jelajahi: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('🌐 Network error: $e');
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet dan IP address.');
    } on FormatException catch (e) {
      print('📄 Format error: $e');
      throw Exception('Response tidak valid dari server');
    } catch (e) {
      print('💥 Exception: $e');
      throw Exception('Error koneksi: $e');
    }
  }

  // Fungsi tambah lokasi rambu
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
      throw Exception('Error: $e');
    }
  }

  // Fungsi hapus lokasi
  static Future<bool> deleteJelajahiLocation(int jelajahiId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/jelajahi/$jelajahiId'),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Fungsi ambil semua rambu
  static Future<List<Map<String, dynamic>>> getAllRambu() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rambu/'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Gagal mengambil data rambu');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Fungsi ambil detail jelajahi by ID
  static Future<Map<String, dynamic>> getJelajahiById(int jelajahiId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jelajahi/$jelajahiId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Data tidak ditemukan');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Fungsi update jelajahi
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
      throw Exception('Error: $e');
    }
  }

  // === HELPER METHOD ===
  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // Pastikan path dimulai dengan /
    if (!imagePath.startsWith('/')) {
      imagePath = '/$imagePath';
    }
    
    return '$baseUrl$imagePath';
  }

  // Fungsi untuk debugging
  static void printNetworkInfo() {
    print('🔗 Network Configuration:');
    print('   Base URL: $baseUrl');
    print('   Test URL: $baseUrl/health');
    print('   Jelajahi URL: $baseUrl/jelajahi/');
  }
}