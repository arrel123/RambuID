import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import 'detailrambu.dart';

class EdukasiPage extends StatefulWidget {
  final String? initialCategory;
  final int userId; // --- TAMBAHAN: Menerima UserId dari Home ---

  // Default userId 0 jika tidak dikirim
  const EdukasiPage({super.key, this.initialCategory, this.userId = 0});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCategory != null) {
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
        final namaEn = (item['nama_en'] ?? '').toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        return nama.contains(query) || namaEn.contains(query);
      }).toList();
    }

    return filtered;
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> rambu) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // --- PERBAIKAN: Mengirim userId ke halaman detail ---
        builder: (context) => DetailRambuScreen(
          rambu: rambu,
          userId: widget.userId, 
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
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
            "Memuat data rambu...",
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLang = languageProvider.locale.languageCode;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6D588),
        elevation: 0,
        automaticallyImplyLeading: false, 
        title: Text(
          l10n.translate('sign_list'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabs.map((tab) {
                  bool isSelected = selectedTab == tab;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedTab = tab);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: l10n.translate('search_sign_name'),
                hintStyle: TextStyle(color: Colors.grey[600], fontFamily: 'Poppins'),
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFFD6D588), width: 1.5),
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(fontFamily: 'Poppins')))
                    : getFilteredData().isEmpty
                        ? Center(child: Text(l10n.translate('data_not_found'), style: const TextStyle(fontFamily: 'Poppins')))
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: getFilteredData().length,
                            itemBuilder: (context, index) {
                              final item = getFilteredData()[index];
                              final imageUrl = _getImageUrl(item['gambar_url']);
                              
                              String namaRambu = (currentLang == 'en') 
                                  ? (item['nama_en'] ?? item['nama'] ?? 'No Name')
                                  : (item['nama'] ?? 'Tanpa Nama');

                              return GestureDetector(
                                onTap: () => _navigateToDetail(context, item),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: imageUrl.isNotEmpty
                                              ? Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (ctx, err, stack) =>
                                                      const Icon(Icons.broken_image, color: Colors.grey),
                                                )
                                              : const Icon(Icons.image, color: Colors.grey),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: const BorderRadius.only(
                                              bottomLeft: Radius.circular(12),
                                              bottomRight: Radius.circular(12),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                namaRambu,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.2,
                                                  color: Colors.black87,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
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