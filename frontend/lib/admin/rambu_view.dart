import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

// --- Model Data Rambu ---
class Rambu {
  final int id;
  final String nama;
  final String deskripsi;
  final String? imageUrl;
  final String kategori;

  Rambu({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.imageUrl,
    required this.kategori,
  });

  factory Rambu.fromJson(Map<String, dynamic> json) {
    String? getFullImageUrl(String? url) {
      if (url == null || url.isEmpty) return null;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
      final baseUrl = ApiService.baseUrl;
      final path = url.startsWith('/') ? url : '/$url';
      return '$baseUrl$path';
    }

    return Rambu(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      nama: json['nama']?.toString() ?? '-',
      deskripsi: json['deskripsi']?.toString() ?? '',
      imageUrl: getFullImageUrl(json['gambar_url']?.toString()),
      kategori: json['kategori']?.toString() ?? 'larangan',
    );
  }

  String get kategoriLabel {
    switch (kategori.toLowerCase()) {
      case 'larangan': return 'Larangan';
      case 'peringatan': return 'Peringatan';
      case 'petunjuk': return 'Petunjuk';
      case 'perintah': return 'Perintah';
      default: return kategori;
    }
  }

  Color get kategoriColor {
    switch (kategori.toLowerCase()) {
      case 'larangan': return Colors.red;
      case 'peringatan': return Colors.orange;
      case 'petunjuk': return Colors.blue;
      case 'perintah': return Colors.green;
      default: return Colors.grey;
    }
  }
}

class RambuView extends StatefulWidget {
  const RambuView({super.key});

  @override
  State<RambuView> createState() => _RambuViewState();
}

class _RambuViewState extends State<RambuView> {
  final List<Rambu> _rambuList = [];
  List<Rambu> _filteredRambuList = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRambu);
    _loadRambuList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRambuList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getRambuList();
    if (result['success'] == true) {
      final List<dynamic> data = result['data'] ?? [];
      final loaded = data
          .map((item) => Rambu.fromJson(item as Map<String, dynamic>))
          .toList();
      setState(() {
        _rambuList
          ..clear()
          ..addAll(loaded);
        _filteredRambuList = List.from(_rambuList);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Gagal memuat data rambu';
        _isLoading = false;
      });
    }
  }

  void _showSnack(String message, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color)
    );
  }

  void _filterRambu() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRambuList = _rambuList.where((rambu) {
        return rambu.nama.toLowerCase().contains(query) ||
            rambu.deskripsi.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _tambahDataRambu() async {
    final result = await showDialog<RambuFormResult>(
      context: context,
      builder: (context) => const _RambuEditDialog(),
    );

    if (result != null) {
      await _handleCreateRambu(result);
    }
  }

  Future<void> _editDataRambu(Rambu rambuToEdit) async {
    final result = await showDialog<RambuFormResult>(
      context: context,
      builder: (context) => _RambuEditDialog(rambuToEdit: rambuToEdit),
    );

    if (result != null) {
      await _handleUpdateRambu(rambuToEdit, result);
    }
  }

  Future<void> _handleCreateRambu(RambuFormResult result) async {
    if (result.imageFile == null) {
      _showSnack('Silakan pilih gambar terlebih dahulu', color: Colors.red);
      return;
    }

    final response = await ApiService.createRambu(
      nama: result.nama,
      deskripsi: result.deskripsi,
      kategori: result.kategori,
      gambar: result.imageFile!,
    );

    if (response['success'] == true) {
      _showSnack('Rambu berhasil ditambahkan');
      await _loadRambuList();
    } else {
      _showSnack(
        response['message'] ?? 'Gagal menambahkan rambu',
        color: Colors.red,
      );
    }
  }

  Future<void> _handleUpdateRambu(Rambu existing, RambuFormResult result) async {
    final response = await ApiService.updateRambu(
      id: existing.id,
      nama: result.nama,
      deskripsi: result.deskripsi,
      kategori: result.kategori,
      gambar: result.imageFile,
    );

    if (response['success'] == true) {
      _showSnack('Rambu berhasil diperbarui');
      await _loadRambuList();
    } else {
      _showSnack(
        response['message'] ?? 'Gagal memperbarui rambu',
        color: Colors.red,
      );
    }
  }

  Future<void> _hapusDataRambu(Rambu rambuToDelete) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Rambu?'),
        content: Text('Anda yakin ingin menghapus "${rambuToDelete.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final response = await ApiService.deleteRambu(rambuToDelete.id);
      if (response['success'] == true) {
        _showSnack('Rambu berhasil dihapus');
        await _loadRambuList();
      } else {
        _showSnack(
          response['message'] ?? 'Gagal menghapus rambu',
          color: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 650;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
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
              // --- JUDUL CENTER ---
              const Center(
                child: Text(
                  'Daftar Rambu',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // --- SEARCH BAR & TOMBOL TAMBAH ---
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        _buildAddButton(),
                      ],
                    )
                  : Row(
                      children: [
                        // Search bar dipendekkan (fixed width)
                        SizedBox(
                          width: 300, 
                          child: _buildSearchBar()
                        ),
                        // Spacer untuk mendorong tombol ke kanan
                        const Spacer(), 
                        _buildAddButton(),
                      ],
                    ),
              const SizedBox(height: 24),

              // --- TABEL DATA ---
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                              const SizedBox(height: 8),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[400])),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadRambuList,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : _filteredRambuList.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey, size: 32),
                              SizedBox(height: 8),
                              Text('Belum ada data rambu', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            horizontalMargin: 24,
                            columnSpacing: 32,
                            headingRowHeight: 56,
                            dataRowMinHeight: 72,
                            dataRowMaxHeight: 72,
                            headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                            dividerThickness: 1,
                            columns: const [
                              DataColumn(label: Center(child: Text('GAMBAR', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))),
                              DataColumn(label: Center(child: Text('NAMA RAMBU', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))),
                              DataColumn(label: Center(child: Text('KATEGORI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))),
                              DataColumn(label: SizedBox(width: 400, child: Center(child: Text('DESKRIPSI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))))),
                              DataColumn(label: Center(child: Text('AKSI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))),
                            ],
                            rows: _filteredRambuList.map((rambu) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[100],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: rambu.imageUrl != null && rambu.imageUrl!.isNotEmpty
                                            ? Image.network(
                                                rambu.imageUrl!,
                                                fit: BoxFit.contain, 
                                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                              )
                                            : const Icon(Icons.image_not_supported, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(rambu.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: rambu.kategoriColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: rambu.kategoriColor.withValues(alpha: 0.2), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(color: rambu.kategoriColor, shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(rambu.kategoriLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: rambu.kategoriColor)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      width: 400,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(rambu.deskripsi, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _editDataRambu(rambu),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFDD835),
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, color: Colors.grey[700], size: 22),
                                          onPressed: () => _hapusDataRambu(rambu),
                                          tooltip: 'Hapus',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Mencari...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFDD835), width: 2)),
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add, color: Colors.black, size: 20),
      label: const Text('Tambah Data Rambu', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFDD835),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _tambahDataRambu,
    );
  }
}

class _RambuEditDialog extends StatefulWidget {
  final Rambu? rambuToEdit;
  const _RambuEditDialog({this.rambuToEdit});

  @override
  State<_RambuEditDialog> createState() => _RambuEditDialogState();
}

class _RambuEditDialogState extends State<_RambuEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  Uint8List? _imageBytes;
  String? _imageName;
  XFile? _pickedImageFile;
  String _selectedKategori = 'larangan';

  final List<String> _kategoriList = ['larangan', 'peringatan', 'petunjuk', 'perintah'];
  final Map<String, String> _kategoriLabels = {
    'larangan': 'Larangan',
    'peringatan': 'Peringatan',
    'petunjuk': 'Petunjuk',
    'perintah': 'Perintah',
  };

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.rambuToEdit?.nama ?? '');
    _deskripsiController = TextEditingController(text: widget.rambuToEdit?.deskripsi ?? '');
    _selectedKategori = widget.rambuToEdit?.kategori ?? 'larangan';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (mounted) {
          setState(() {
            _pickedImageFile = pickedFile;
            _imageBytes = bytes;
            _imageName = pickedFile.name;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final bool isEditing = widget.rambuToEdit != null;
      if (!isEditing && _pickedImageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih gambar terlebih dahulu'), backgroundColor: Colors.red),
        );
        return;
      }

      Navigator.pop(
        context,
        RambuFormResult(
          nama: _namaController.text,
          deskripsi: _deskripsiController.text,
          kategori: _selectedKategori,
          imageFile: _pickedImageFile,
        ),
      );
    }
  }

  Color _getKategoriColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'larangan': return Colors.red;
      case 'peringatan': return Colors.orange;
      case 'petunjuk': return Colors.blue;
      case 'perintah': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.rambuToEdit != null;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 950, maxHeight: 800),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEditing ? 'Edit Data Rambu' : 'Tambah Rambu Baru', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(isEditing ? 'Perbarui informasi rambu yang sudah ada' : 'Lengkapi formulir di bawah untuk menambah rambu', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), splashRadius: 24),
                ],
              ),
            ),
            const Divider(height: 1),

            // CONTENT
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: isMobile
                      ? Column(
                          children: [
                            _buildImageSection(),
                            const SizedBox(height: 32),
                            _buildFormSection(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: _buildImageSection()),
                            const SizedBox(width: 40),
                            Expanded(flex: 6, child: _buildFormSection()),
                          ],
                        ),
                ),
              ),
            ),
            const Divider(height: 1),

            // FOOTER
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), foregroundColor: Colors.grey[700]),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD835),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(isEditing ? 'Simpan Perubahan' : 'Simpan Rambu', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gambar Visual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!, width: 2)),
          child: _imageBytes != null
              ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(_imageBytes!, fit: BoxFit.contain))
              : (widget.rambuToEdit?.imageUrl != null && widget.rambuToEdit!.imageUrl!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.rambuToEdit!.imageUrl!, 
                        fit: BoxFit.contain, 
                        errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('Belum ada gambar', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
                      ],
                    ),
        ),
        const SizedBox(height: 16),
        if (_imageName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green[200]!)),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(_imageName!, style: TextStyle(fontSize: 12, color: Colors.green[900]), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload_file),
            label: const Text('Pilih File Gambar'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.black87, side: const BorderSide(color: Colors.grey)),
          ),
        ),
        const SizedBox(height: 8),
        Text('* Format: JPG, PNG. Maksimal 2MB.', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informasi Detail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        _buildLabel('Nama Rambu'),
        TextFormField(
          controller: _namaController,
          decoration: _inputDecoration(hint: 'Contoh: Dilarang Parkir'),
          validator: (val) => val!.isEmpty ? 'Nama wajib diisi' : null,
        ),
        const SizedBox(height: 20),

        _buildLabel('Kategori'),
        DropdownButtonFormField<String>(
          initialValue: _selectedKategori,
          items: _kategoriList.map((kategori) {
            return DropdownMenuItem(
              value: kategori,
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _getKategoriColor(kategori), shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text(_kategoriLabels[kategori] ?? kategori),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedKategori = val);
          },
          decoration: _inputDecoration(),
        ),
        const SizedBox(height: 20),

        _buildLabel('Deskripsi Lengkap'),
        TextFormField(
          controller: _deskripsiController,
          maxLines: 5,
          decoration: _inputDecoration(hint: 'Jelaskan fungsi dan arti rambu ini...'),
          validator: (val) => val!.isEmpty ? 'Deskripsi wajib diisi' : null,
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)));
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFDD835), width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class RambuFormResult {
  final String nama;
  final String deskripsi;
  final String kategori;
  final XFile? imageFile;

  RambuFormResult({required this.nama, required this.deskripsi, required this.kategori, this.imageFile});
}