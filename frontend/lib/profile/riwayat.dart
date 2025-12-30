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

  // --- FUNGSI BARU: Menghapus satu item ---
  Future<void> _deleteItem(int index) async {
    await RiwayatService.deleteRiwayat(index);
    _loadRiwayat();
  }

  // --- FUNGSI BARU: Konfirmasi & Hapus Semua ---
  Future<void> _confirmDeleteAll() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hapus Semua Riwayat?"),
          content: const Text("Tindakan ini tidak dapat dibatalkan. Semua data riwayat akan hilang."),
          actions: [
            TextButton(
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Tutup dialog
                await _processDeleteAll(); // Jalankan penghapusan
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processDeleteAll() async {
    setState(() => _isLoading = true);
    
    // PENTING: Idealnya tambahkan method 'clearAllRiwayat' di RiwayatService Anda.
    // Jika belum ada, kita lakukan loop penghapusan manual dari UI (kurang efisien tapi bekerja):
    try {
      // Loop menghapus dari index terakhir ke 0 agar index tidak bergeser
      for (int i = _riwayatList.length - 1; i >= 0; i--) {
        await RiwayatService.deleteRiwayat(i);
      }
      
      // Refresh data
      await _loadRiwayat();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Semua riwayat berhasil dihapus")),
        );
      }
    } catch (e) {
      debugPrint("Error deleting all: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // FUNGSI GAMBAR (Sama seperti sebelumnya)
  Widget _buildImage(String? path) {
    if (path == null || path.isEmpty) {
      return const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 30);
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.orange));
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.red));
    }
    File file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.error));
    }
    return const Icon(Icons.broken_image, color: Colors.grey);
  }

  String _getMonth(DateTime date) => DateFormat('MMMM').format(date);
  String _getDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

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
                      Text("Belum ada riwayat deteksi", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _riwayatList.length,
                  itemBuilder: (context, index) {
                    final item = _riwayatList[index];
                    final String timestamp = item['timestamp'] ?? DateTime.now().toIso8601String();
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
                        // --- HEADER TANGGAL YANG DIMODIFIKASI ---
                        if (showHeader) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Agar tombol ke kanan mentok
                            crossAxisAlignment: CrossAxisAlignment.end, // Agar teks dan tombol sejajar bawah
                            children: [
                              // Bagian Kiri: Bulan & Tanggal
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                ],
                              ),

                              // Bagian Kanan: Tombol Hapus Semua
                              // Hanya dimunculkan jika index == 0 (Paling Atas)
                              if (index == 0)
                                TextButton.icon(
                                  onPressed: _confirmDeleteAll,
                                  icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                                  label: const Text(
                                    "Hapus Semua",
                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    alignment: Alignment.centerRight,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Garis pembatas tipis agar lebih rapi (opsional)
                          Divider(color: Colors.grey.shade300, height: 1),
                          const SizedBox(height: 12),
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
                                color: Colors.black.withValues(alpha: 0.05),
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
                                            color: Colors.black),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
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
                                                  color: Colors.grey.shade600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Tombol Delete Item Satuan
                                IconButton(
                                  onPressed: () => _deleteItem(index),
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
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

  // Helper Icon (Sama seperti kode asli)
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