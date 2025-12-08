import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Wajib: Pastikan sudah add intl di pubspec.yaml
import '../services/riwayat_service.dart'; // Import service yang baru dibuat
import '../l10n/app_localizations.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  // Data dinamis dari penyimpanan lokal
  List<Map<String, dynamic>> _riwayatList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  // Mengambil data dari RiwayatService
  Future<void> _loadRiwayat() async {
    final data = await RiwayatService.getRiwayat();
    setState(() {
      _riwayatList = data;
      _isLoading = false;
    });
  }

  // Menghapus satu item
  Future<void> _deleteItem(int index) async {
    await RiwayatService.deleteRiwayat(index);
    _loadRiwayat(); // Refresh tampilan setelah hapus
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Riwayat berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

// Menghapus semua item
  Future<void> _deleteAllItems() async {
    // --- HAPUS BARIS YANG ERROR TADI ---
    // Langsung jalankan looping untuk menghapus satu per satu dari belakang
    
    for (int i = _riwayatList.length - 1; i >= 0; i--) {
        await RiwayatService.deleteRiwayat(i);
    }
    
    // Refresh tampilan setelah semua terhapus
    _loadRiwayat();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua riwayat dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  // --- LOGIKA MAPPING GAMBAR ASET ---
  // Mencocokkan Nama Rambu dari AI dengan File Gambar di Assets
  String _getAssetPath(String namaRambu) {
    String lower = namaRambu.toLowerCase();
    
    // Sesuaikan nama file ini dengan aset yang kamu punya di folder assets/images/
    if (lower.contains('belok kiri')) return 'assets/images/dilarang_belok_kiri.png';
    if (lower.contains('belok kanan')) return 'assets/images/dilarang_belok_kanan.png';
    if (lower.contains('parkir')) return 'assets/images/dilarang_parkir.png';
    if (lower.contains('berhenti')) return 'assets/images/dilarang_berhenti.png';
    if (lower.contains('putar balik')) return 'assets/images/dilarang_putar_balik.png';
    if (lower.contains('hati')) return 'assets/images/hati_hati.png'; // Sesuaikan nama file
    if (lower.contains('licin')) return 'assets/images/jalan_licin.png'; // Sesuaikan nama file
    if (lower.contains('rata')) return 'assets/images/jalan_tidak_rata.png';
    
    // Gambar default jika tidak ditemukan (Wajib punya gambar ini atau ganti return Icon)
    return 'assets/images/logo.png'; // Ganti dengan logo aplikasi atau gambar default
  }

  // Dialog Konfirmasi Hapus Satu
  void _showDeleteConfirmation(int index, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: Text('Apakah Anda yakin ingin menghapus "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Dialog Konfirmasi Hapus Semua
  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua'),
        content: const Text('Apakah Anda yakin ingin menghapus seluruh riwayat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllItems();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // --- LOGIKA GROUPING BERDASARKAN TANGGAL ---
    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    
    for (var i = 0; i < _riwayatList.length; i++) {
      var item = _riwayatList[i];
      // Tambahkan index asli ke dalam item map agar bisa dihapus dengan tepat
      item['original_index'] = i; 

      DateTime date = DateTime.parse(item['timestamp']);
      
      // Format Bulan (September) dan Tanggal (18/09/2025)
      String month = DateFormat('MMMM').format(date); 
      String dateStr = DateFormat('dd/MM/yyyy').format(date);
      
      // Key unik untuk grouping
      String key = '$month|$dateStr'; 
      
      if (!groupedItems.containsKey(key)) {
        groupedItems[key] = [];
      }
      groupedItems[key]!.add(item);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFFD6D588)),
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
                      l10n.history, // Fallback jika l10n null
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (_riwayatList.isNotEmpty)
                    IconButton(
                      onPressed: _showDeleteAllConfirmation,
                      icon: const Icon(Icons.delete_outline),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _riwayatList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 100, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noHistory,
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            for (var entry in groupedItems.entries) ...[
                              // Header Bulan/Tanggal
                              _buildMonthHeader(
                                entry.key.split('|')[0], // Bulan
                                entry.key.split('|')[1], // Tanggal
                              ),
                              const SizedBox(height: 12),
                              
                              // List Item per Tanggal
                              for (var item in entry.value) ...[
                                _buildHistoryItem(
                                  title: item['nama'],
                                  kategori: item['kategori'],
                                  originalIndex: item['original_index'], // Index asli untuk hapus
                                ),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(String month, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          month,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(date, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String kategori,
    required int originalIndex,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          // Icon (Dari Aset)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // Menggunakan helper untuk cari gambar yang cocok
              child: Image.asset(
                _getAssetPath(title), 
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback jika gambar tidak ditemukan di aset: Tampilkan Icon Warning
                  return const Icon(Icons.image_not_supported, color: Colors.grey);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Title & Kategori
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  kategori,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Delete Button
          IconButton(
            onPressed: () => _showDeleteConfirmation(originalIndex, title),
            icon: const Icon(Icons.delete_outline),
            color: Colors.red[400],
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}