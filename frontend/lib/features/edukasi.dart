import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Pastikan path import ini benar
import 'detailrambu.dart';

class EdukasiPage extends StatefulWidget {
  final String? initialCategory;

  const EdukasiPage({super.key, this.initialCategory});

  @override
  State<EdukasiPage> createState() => _EdukasiPageState();
}

class _EdukasiPageState extends State<EdukasiPage> {
  String selectedTab = 'Semua';
  String searchQuery = '';
  
  // Variabel untuk menampung data dari Backend
  List<dynamic> _rambuList = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> tabs = [
    'Semua',
    'Peringatan',
    'Larangan',
    'Petunjuk',
    'Perintah'
  ];

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialCategory ?? 'Semua';
    _fetchRambuData(); // Panggil fungsi ambil data saat halaman dibuka
  }

  // Fungsi mengambil data dari API Service
  Future<void> _fetchRambuData() async {
    try {
      final result = await ApiService.getRambuList();
      
      if (mounted) {
        setState(() {
          if (result['success']) {
            _rambuList = result['data'];
            _errorMessage = null;
          } else {
            _errorMessage = result['message'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi menyusun URL gambar lengkap
  String _getImageUrl(String? partialUrl) {
    if (partialUrl == null || partialUrl.isEmpty) return '';
    // Jika backend mengembalikan path relatif (misal: /static/...), gabungkan dengan Base URL
    if (partialUrl.startsWith('/')) {
      return '${ApiService.baseUrl}$partialUrl';
    }
    // Jika sudah full URL (http...), biarkan saja
    return partialUrl;
  }

  List<dynamic> getFilteredData() {
    List<dynamic> filtered = _rambuList;

    // Filter Kategori (Case Insensitive karena backend pakai huruf kecil)
    if (selectedTab != 'Semua') {
      filtered = filtered.where((item) {
        final kategoriBackend = (item['kategori'] ?? '').toString().toLowerCase();
        final kategoriTab = selectedTab.toLowerCase();
        return kategoriBackend == kategoriTab;
      }).toList();
    }

    // Filter Search (Berdasarkan 'nama')
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final nama = (item['nama'] ?? '').toString().toLowerCase();
        return nama.contains(searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> rambu) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailRambuScreen(rambu: rambu),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6D588),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Daftar Rambu',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔹 Tab Bar
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabs.map((tab) {
                  bool isSelected = selectedTab == tab;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTab = tab;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 🔹 Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari Nama Rambu',
                hintStyle: const TextStyle(color: Colors.black),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                filled: true,
                fillColor: const Color(0xFFD6D588),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 🔹 Content (Loading / Error / Grid)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD6D588)))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : getFilteredData().isEmpty
                        ? const Center(child: Text("Data tidak ditemukan"))
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: getFilteredData().length,
                            itemBuilder: (context, index) {
                              final item = getFilteredData()[index];
                              final imageUrl = _getImageUrl(item['gambar_url']);
                              final namaRambu = item['nama'] ?? 'Tanpa Nama';

                              return GestureDetector(
                                onTap: () => _navigateToDetail(context, item),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: imageUrl.isNotEmpty
                                              ? Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (ctx, err, stack) =>
                                                      const Icon(Icons.broken_image, size: 40),
                                                )
                                              : const Icon(Icons.image_not_supported, size: 40),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          namaRambu,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}