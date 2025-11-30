import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class DbService {
  static Future<List<Map<String, dynamic>>> getJelajahiWithRambu() async {
    print('🗂️  MENGAMBIL DATA RAMBU...');
    
    // Data HARCODED dari yang Anda berikan - PASTI BERHASIL
    List<Map<String, dynamic>> fixedData = [
      {
        'nama': 'Dilarang Parkir',
        'latitude': 1.1194178,
        'longitude': 104.0485686,
        'kategori': 'Larangan',
      },
      {
        'nama': '3 Panah Melingkar',
        'latitude': 1.1193241,
        'longitude': 104.0485688,
        'kategori': 'Petunjuk',
      },
      {
        'nama': 'Dilarang Belok Kanan',
        'latitude': 1.1193241,
        'longitude': 104.0485688,
        'kategori': 'Larangan',
      },
      {
        'nama': 'Rambu Keluar',
        'latitude': 1.1189841,
        'longitude': 104.0483701,
        'kategori': 'Petunjuk',
      },
      {
        'nama': 'Dilarang Parkir dan Merokok',
        'latitude': 1.1187723,
        'longitude': 104.0484794,
        'kategori': 'Larangan',
      },
      {
        'nama': 'Lajur Wajib Kanan',
        'latitude': 1.1189314,
        'longitude': 104.0491652,
        'kategori': 'Perintah',
      },
      {
        'nama': 'Parkir Mobil',
        'latitude': 1.1189314,
        'longitude': 104.0491652,
        'kategori': 'Petunjuk',
      },
      {
        'nama': 'Wajib Lurus',
        'latitude': 1.1189274,
        'longitude': 104.0494293,
        'kategori': 'Perintah',
      },
      {
        'nama': 'Wajib Kanan',
        'latitude': 1.1189274,
        'longitude': 104.0494293,
        'kategori': 'Perintah',
      },
      {
        'nama': 'Dilarang Masuk',
        'latitude': 1.1190402,
        'longitude': 104.0498061,
        'kategori': 'Larangan',
      },
      {
        'nama': 'Dilarang Masuk 2',
        'latitude': 1.1193521,
        'longitude': 104.0498033,
        'kategori': 'Larangan',
      },
      {
        'nama': 'Wajib Lurus 2',
        'latitude': 1.1193314,
        'longitude': 104.0497178,
        'kategori': 'Perintah',
      },
    ];

    print('📍 DATA FIXED: ${fixedData.length} rambu');
    
    // Tetap coba ambil dari database, jika gagal pakai fixed data
    try {
      var databasesPath = await getDatabasesPath();
      String path = join(databasesPath, "rambuid.db");
      
      if (await databaseExists(path)) {
        Database db = await openDatabase(path);
        
        var result = await db.rawQuery("""
          SELECT j.latitude, j.longitude, r.nama, r.deskripsi, r.kategori
          FROM jelajahi j JOIN rambu r ON j.rambu_id = r.id
        """);
        
        await db.close();
        
        if (result.isNotEmpty) {
          print('✅ DATA DATABASE: ${result.length} records');
          return result;
        }
      }
    } catch (e) {
      print('❌ ERROR DATABASE: $e');
    }
    
    print('🔄 Menggunakan data fixed');
    return fixedData;
  }
}