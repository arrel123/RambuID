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

  // --- HELPER: Loading Cantik dengan Teks ---
  Widget _buildLoadingState() {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD6D588)),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isEnglish ? "Loading history..." : "Memuat riwayat...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER: Pop-up Sukses ---
  void _showSuccessPopup(String message) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFFD6D588), size: 64),
              const SizedBox(height: 16),
              Text(
                isEnglish ? "Success!" : "Berhasil!",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
              ),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // --- FUNGSI HAPUS ---
  Future<void> _confirmDeleteItem(int index) async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEnglish ? "Delete This Item?" : "Hapus Item Ini?",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(isEnglish ? "This history item will be permanently deleted." : "Item riwayat ini akan dihapus permanen."),
          actions: [
            TextButton(
              child: Text(isEnglish ? "Cancel" : "Batal", style: const TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isEnglish ? "Delete" : "Hapus", style: const TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _processDeleteItem(index);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processDeleteItem(int index) async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    await RiwayatService.deleteRiwayat(index);
    await _loadRiwayat();
    if (mounted) {
      _showSuccessPopup(isEnglish ? "Item successfully deleted." : "Item berhasil dihapus.");
    }
  }

  Future<void> _confirmDeleteAll() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEnglish ? "Delete All History?" : "Hapus Semua Riwayat?",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(isEnglish ? "This action cannot be undone. All history data will be lost." : "Tindakan ini tidak dapat dibatalkan. Semua data riwayat akan hilang."),
          actions: [
            TextButton(
              child: Text(isEnglish ? "Cancel" : "Batal", style: const TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isEnglish ? "Delete All" : "Hapus Semuanya", style: const TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(context).pop(); 
                await _processDeleteAll(); 
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processDeleteAll() async {
    setState(() => _isLoading = true);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    try {
      for (int i = _riwayatList.length - 1; i >= 0; i--) {
        await RiwayatService.deleteRiwayat(i);
      }
      await _loadRiwayat();
      if (mounted) {
        _showSuccessPopup(isEnglish ? "All history has been deleted." : "Semua riwayat berhasil dihapus.");
      }
    } catch (e) {
      debugPrint("Error deleting all: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- UI COMPONENTS ---
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
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFD6D588), 
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isEnglish ? "History" : "Riwayat",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: _isLoading
                  ? _buildLoadingState() // Panggil Loading Cantik
                  : _riwayatList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history, size: 80, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                isEnglish ? "No detection history yet" : "Belum ada riwayat deteksi", 
                                style: const TextStyle(color: Colors.grey)
                              ),
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
                            
                            String displayName = item['nama'] ?? 'Tanpa Nama';
                            if (isEnglish) {
                               if (displayName == "Jalur Sepeda") displayName = "Bicycle Lane";
                               if (displayName == "Pilih Salah Satu Jalur") displayName = "Choose One Lane";
                               if (item.containsKey('nama_en') && item['nama_en'] != null) {
                                 displayName = item['nama_en'];
                               }
                            }

                            String displayKategori = item['kategori'] ?? 'Kategori';
                             if (isEnglish) {
                               if (displayKategori.toLowerCase().contains("perintah")) displayKategori = "Command";
                               if (displayKategori.toLowerCase().contains("larangan")) displayKategori = "Prohibition";
                               if (displayKategori.toLowerCase().contains("peringatan")) displayKategori = "Warning";
                               if (displayKategori.toLowerCase().contains("petunjuk")) displayKategori = "Guidance";
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showHeader) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
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
                                      if (index == 0)
                                        TextButton.icon(
                                          onPressed: _confirmDeleteAll,
                                          icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                                          label: Text(
                                            isEnglish ? "Delete All" : "Hapus Semua",
                                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
                                  Divider(color: Colors.grey.shade300, height: 1),
                                  const SizedBox(height: 12),
                                ],

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
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
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
                                                      displayKategori,
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
                                        IconButton(
                                          onPressed: () => _confirmDeleteItem(index),
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
            ),
          ],
        ),
      ),
    );
  }

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