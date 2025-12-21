import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/riwayat_service.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<Map<String, dynamic>> _riwayatList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    final data = await RiwayatService.getRiwayat();
    setState(() {
      _riwayatList = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteItem(int index) async {
    await RiwayatService.deleteRiwayat(index);
    _loadRiwayat(); 
  }

  // FUNGSI DIPERBAIKI: Support File path, URL, dan Asset
  Widget _buildImage(String? path) {
    if (path == null || path.isEmpty) {
      return const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 30);
    }

    // 1. Jika gambar dari Asset (Database asli)
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, color: Colors.orange);
        },
      );
    }
    
    // 2. Jika gambar dari URL (Jelajahi/Edukasi)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, color: Colors.red);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
      );
    }
    
    // 3. Jika gambar File lokal (Deteksi/Kamera)
    File file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
      );
    }

    // Fallback
    return const Icon(Icons.broken_image, color: Colors.grey);
  }

  String _getMonth(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  String _getDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Riwayat',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFD6D588),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _riwayatList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "Belum ada riwayat deteksi", 
                        style: TextStyle(color: Colors.grey)
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _riwayatList.length,
                  itemBuilder: (context, index) {
                    final item = _riwayatList[index];
                    final String timestamp = item['timestamp'] ?? 
                        DateTime.now().toIso8601String();
                    final DateTime currentDate = DateTime.parse(timestamp);

                    // Logika grouping tanggal
                    bool showHeader = false;
                    if (index == 0) {
                      showHeader = true;
                    } else {
                      final prevItem = _riwayatList[index - 1];
                      final prevDate = DateTime.parse(prevItem['timestamp']);
                      if (currentDate.day != prevDate.day || 
                          currentDate.month != prevDate.month || 
                          currentDate.year != prevDate.year) {
                        showHeader = true;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Tanggal
                        if (showHeader) ...[
                          const SizedBox(height: 10),
                          Text(
                            _getMonth(currentDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _getDate(currentDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Card Item
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Box Gambar
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildImage(item['imagePath']),
                                  ),
                                ),
                                
                                const SizedBox(width: 16),

                                // Teks
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['nama'] ?? 'Tanpa Nama',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          // Icon kategori
                                          Icon(
                                            _getCategoryIcon(item['kategori']),
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              item['kategori'] ?? 'Kategori',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Tombol Delete
                                IconButton(
                                  onPressed: () => _deleteItem(index),
                                  icon: const Icon(
                                    Icons.delete_outline, 
                                    color: Colors.red
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  // Helper: Icon berdasarkan kategori
  IconData _getCategoryIcon(String? kategori) {
    if (kategori == null) return Icons.info_outline;
    
    final kat = kategori.toLowerCase();
    if (kat.contains('larangan')) return Icons.block;
    if (kat.contains('peringatan')) return Icons.warning_amber;
    if (kat.contains('perintah')) return Icons.arrow_forward;
    if (kat.contains('petunjuk')) return Icons.signpost;
    
    return Icons.traffic;
  }
}