import 'package:flutter/material.dart';
import '../services/api_service.dart';

// --- Model Data Pengguna ---
class UserData {
  int id;
  String username;
  String? alamat;

  UserData({required this.id, required this.username, this.alamat});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] is int 
          ? json['id'] 
          : int.tryParse(json['id'].toString()) ?? 0,
      username: json['username']?.toString() ?? 'Tanpa Nama',
      alamat: json['alamat']?.toString(),
    );
  }
}

class DataPenggunaView extends StatefulWidget {
  const DataPenggunaView({super.key});

  @override
  State<DataPenggunaView> createState() => _DataPenggunaViewState();
}

class _DataPenggunaViewState extends State<DataPenggunaView> {
  List<UserData> _usersList = [];
  List<UserData> _filteredUsersList = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getAllUsers();
      if (result['success'] == true) {
        final List<dynamic> usersData = result['data'] ?? [];
        
        setState(() {
          _usersList = usersData
              .map((user) {
                try {
                  return UserData.fromJson(user as Map<String, dynamic>);
                } catch (e) {
                  return null;
                }
              })
              .whereType<UserData>()
              .toList();
          _filteredUsersList = _usersList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat data pengguna';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsersList = _usersList.where((user) {
        return user.username.toLowerCase().contains(query) ||
            user.id.toString().contains(query) ||
            (user.alamat != null && user.alamat!.toLowerCase().contains(query));
      }).toList();
    });
  }

  void _refreshData() {
    _loadUsers();
  }

  Future<void> _hapusUser(UserData user) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengguna?'),
        content: Text('Anda yakin ingin menghapus data pengguna "${user.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _usersList.removeWhere((element) => element.id == user.id);
        _filterUsers();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengguna berhasil dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 800;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. JUDUL HEADER
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0), 
                  child: Text(
                    'Data Pengguna',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // 2. TOOLBAR
              isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCountBadge(),
                        _buildRefreshButton(),
                      ],
                    )
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: 300, child: _buildSearchBar()),
                    const Spacer(),
                    _buildCountBadge(),
                    const SizedBox(width: 12),
                    _buildRefreshButton(),
                  ],
                ),
              
              const SizedBox(height: 24),

              // 3. KONTEN UTAMA (TABEL)
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (_errorMessage != null)
                Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              else if (_filteredUsersList.isEmpty)
                Center(child: Text(_searchController.text.isEmpty ? 'Belum ada data' : 'Tidak ditemukan', style: TextStyle(color: Colors.grey[600])))
              else
                Column(
                  children: [
                    // --- HEADER TABEL (TETAP RATA TENGAH) ---
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(flex: 1, child: Center(child: Text('ID', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))),
                          // Header tetap Center agar rapi
                          const Expanded(flex: 3, child: Center(child: Text('NAMA', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))),
                          if (!isMobile) const Expanded(flex: 3, child: Center(child: Text('ALAMAT', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))),
                          if (!isMobile) const Expanded(flex: 2, child: Center(child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))),
                          const Expanded(flex: 1, child: Center(child: Text('AKSI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))),
                        ],
                      ),
                    ),

                    // --- ISI TABEL (DATA ROWS) ---
                    ..._filteredUsersList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final user = entry.value;
                      final isEven = index % 2 == 0;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isEven ? Colors.grey[50] : Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          children: [
                            // ID (Tetap Center)
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Text('#${user.id}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                                ),
                              ),
                            ),
                            
                            // NAMA (RATA KIRI / START)
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 24.0), // Padding agar tidak mepet kiri
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start, // Align kiri
                                  children: [
                                    Container(
                                      width: 32, height: 32,
                                      decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                                      child: Icon(Icons.person, size: 18, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                                          Text('Pengguna', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ALAMAT (RATA KIRI / START) - Desktop Only
                            if (!isMobile)
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 24.0), // Padding agar sejajar
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start, // Align kiri
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          user.alamat ?? '-',
                                          style: TextStyle(fontSize: 13, color: user.alamat != null ? Colors.black87 : Colors.grey[500]),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // STATUS (Tetap Center)
                            if (!isMobile)
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.green[200]!),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.circle, size: 8, color: Colors.green),
                                        SizedBox(width: 6),
                                        Text('Aktif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // AKSI (Tetap Center)
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: IconButton(
                                  onPressed: () => _hapusUser(user),
                                  icon: Icon(Icons.delete_outline, color: Colors.grey[700], size: 20),
                                  tooltip: 'Hapus',
                                  splashRadius: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper: Search Bar
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari pengguna...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                onPressed: () => _searchController.clear(),
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFDD835), width: 2)),
      ),
    );
  }

  // Widget Helper: Badge Jumlah
  Widget _buildCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            '${_filteredUsersList.length} ditampilkan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  // Widget Helper: Tombol Refresh
  Widget _buildRefreshButton() {
    return Tooltip(
      message: 'Refresh data',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _refreshData,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Icon(Icons.refresh, color: Colors.grey[700], size: 20),
          ),
        ),
      ),
    );
  }
}