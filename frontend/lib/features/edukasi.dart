import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
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
  
  List<dynamic> _rambuList = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<String> get tabs => [
    AppLocalizations.of(context).translate('category_all'),
    AppLocalizations.of(context).translate('category_warning'),
    AppLocalizations.of(context).translate('category_prohibition'),
    AppLocalizations.of(context).translate('category_direction'),
    AppLocalizations.of(context).translate('category_command'),
  ];

  // Map kategori dari UI ke database
  Map<String, String> get categoryMapping => {
    AppLocalizations.of(context).translate('category_all'): 'Semua',
    AppLocalizations.of(context).translate('category_warning'): 'Peringatan',
    AppLocalizations.of(context).translate('category_prohibition'): 'Larangan',
    AppLocalizations.of(context).translate('category_direction'): 'Petunjuk',
    AppLocalizations.of(context).translate('category_command'): 'Perintah',
  };

  @override
  void initState() {
    super.initState();
    // Delay initialization to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCategory != null) {
        // Find the display name for the initial category
        final entry = categoryMapping.entries.firstWhere(
          (e) => e.value == widget.initialCategory,
          orElse: () => MapEntry(tabs.first, 'Semua'),
        );
        setState(() {
          selectedTab = entry.key;
        });
      }
      _fetchRambuData();
    });
  }

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

  String _getImageUrl(String? partialUrl) {
    if (partialUrl == null || partialUrl.isEmpty) return '';
    if (partialUrl.startsWith('/')) {
      return '${ApiService.baseUrl}$partialUrl';
    }
    return partialUrl;
  }

  List<dynamic> getFilteredData() {
    List<dynamic> filtered = _rambuList;

    // Get database category name from selected tab
    final dbCategory = categoryMapping[selectedTab] ?? 'Semua';

    if (dbCategory != 'Semua') {
      filtered = filtered.where((item) {
        final kategoriBackend = (item['kategori'] ?? '').toString().toLowerCase();
        final kategoriFilter = dbCategory.toLowerCase();
        return kategoriBackend == kategoriFilter;
      }).toList();
    }

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
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
  backgroundColor: const Color(0xFFD6D588),
  elevation: 0,
  // ⬅️ TOMBOL BACK (PASTI MUNCUL)
  leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () {
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {
        'userId': 0,
        'username': '',
        'initialIndex': 0, // ⬅️ BERANDA
      },
    );
  },
),

  title: Text(
    l10n.translate('sign_list'),
    style: const TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),

  iconTheme: const IconThemeData(
    color: Colors.black, // warna panah
  ),

  centerTitle: true,
),
      body: Column(
        children: [
          // Tab Bar
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

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: l10n.translate('search_sign_name'),
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

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD6D588),
                    ),
                  )
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : getFilteredData().isEmpty
                        ? Center(child: Text(l10n.translate('data_not_found')))
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