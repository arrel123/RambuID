import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../services/riwayat_service.dart'; 
import '../l10n/app_localizations.dart';
import '../services/api_service.dart'; // IMPORT API SERVICE AGAR BISA PANGGIL getImageUrl

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
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Riwayat berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteAllItems() async {
    for (int i = _riwayatList.length - 1; i >= 0; i--) {
        await RiwayatService.deleteRiwayat(i);
    }
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

    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    
    for (var i = 0; i < _riwayatList.length; i++) {
      var item = _riwayatList[i];
      item['original_index'] = i; 

      DateTime date = DateTime.parse(item['timestamp']);
      
      String month = DateFormat('MMMM').format(date); 
      String dateStr = DateFormat('dd/MM/yyyy').format(date);
      
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
                      l10n.history, // Safety check jika l10n null
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
                              _buildMonthHeader(
                                entry.key.split('|')[0], 
                                entry.key.split('|')[1], 
                              ),
                              const SizedBox(height: 12),
                              
                              for (var item in entry.value) ...[
                                _buildHistoryItem(
                                  title: item['nama'],
                                  kategori: item['kategori'],
                                  originalIndex: item['original_index'],
                                  gambarUrl: item['gambar_url'], // Kirim URL gambar ke widget
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

  // UPDATE: Terima parameter gambarUrl
  Widget _buildHistoryItem({
    required String title,
    required String kategori,
    required int originalIndex,
    String? gambarUrl, 
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
          // UPDATE: Pakai Image.network + ApiService.getImageUrl
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ApiService.getImageUrl(gambarUrl), // Panggil helper dari ApiService
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported, color: Colors.grey);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          
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