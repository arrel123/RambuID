import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatService {
  static const String _key = 'riwayat_deteksi';

  // Menyimpan data baru (Sekarang menerima imagePath)
  static Future<void> addRiwayat(String namaRambu, String kategori, [String? imagePath]) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ambil data lama
    List<String> listString = prefs.getStringList(_key) ?? [];
    
    // Buat data baru (JSON)
    Map<String, dynamic> data = {
      'nama': namaRambu,
      'kategori': kategori,
      'imagePath': imagePath ?? '', // Simpan path gambar (kosong jika tidak ada)
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Masukkan ke paling atas (terbaru)
    listString.insert(0, jsonEncode(data));
    
    // Simpan kembali
    await prefs.setStringList(_key, listString);
  }

  // Mengambil semua data
  static Future<List<Map<String, dynamic>>> getRiwayat() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> listString = prefs.getStringList(_key) ?? [];
    
    return listString.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  // Menghapus satu data berdasarkan index
  static Future<void> deleteRiwayat(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> listString = prefs.getStringList(_key) ?? [];
    
    if (index >= 0 && index < listString.length) {
      listString.removeAt(index);
      await prefs.setStringList(_key, listString);
    }
  }
}
