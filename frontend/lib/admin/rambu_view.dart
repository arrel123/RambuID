import 'package:flutter/material.dart';

// --- Model Data Rambu ---
class Rambu {
  String imagePath;
  String nama;
  String jenis;
  String deskripsi;

  Rambu({
    required this.imagePath,
    required this.nama,
    required this.jenis,
    required this.deskripsi,
  });
}

class RambuView extends StatefulWidget {
  const RambuView({super.key});

  @override
  State<RambuView> createState() => _RambuViewState();
}

class _RambuViewState extends State<RambuView> {
  final List<Rambu> _rambuList = [
    Rambu(
      imagePath: 'assets/images/tikungan.png',
      nama: 'Tikungan Tajam',
      jenis: 'Peringatan',
      deskripsi: 'Rambu ini berfungsi untuk memberikan peringatan kepada pengemudi bahwa di depan mereka akan menemui tikungan yang sangat tajam ke arah kanan.',
    ),
    Rambu(
      imagePath: 'assets/images/dilarang_parkir.png',
      nama: 'Dilarang Parkir',
      jenis: 'Larangan',
      deskripsi: 'Rambu ini melarang pengendara untuk memarkir kendaraannya di area tertentu. Pengendara masih diperbolehkan untuk berhenti sementara di area ini, tetapi tidak boleh meninggalkan kendaraannya',
    ),
    Rambu(
      imagePath: 'assets/images/wajib_kiri.png',
      nama: 'Wajib Belok Kiri',
      jenis: 'Perintah',
      deskripsi: 'Rambu ini mengharuskan pengendara untuk belok kiri pada persimpangan atau titik tertentu. Pengendara tidak diperbolehkan untuk melanjutkan lurus atau belok ke arah lain selain kiri.',
    ),
    Rambu(
      imagePath: 'assets/images/petunjuk.jpg',
      nama: 'Petunjuk Arah',
      jenis: 'Petunjuk',
      deskripsi: 'Rambu ini memberikan informasi arah kepada pengendara mengenai lokasi atau tujuan tertentu, seperti nama jalan, jarak ke tempat tujuan, atau arah menuju fasilitas umum.',
    ),
  ];
  
  List<Rambu> _filteredRambuList = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredRambuList = _rambuList;
    _searchController.addListener(_filterRambu);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRambu() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRambuList = _rambuList.where((rambu) {
        return rambu.nama.toLowerCase().contains(query) ||
            rambu.jenis.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _tambahDataRambu() {
    showDialog(
      context: context,
      builder: (context) =>
          _RambuEditDialog(onSave: (Rambu newRambu) {
        setState(() {
          _rambuList.add(newRambu);
          _filterRambu();
        });
      }),
    );
  }

  void _editDataRambu(Rambu rambuToEdit) {
    showDialog(
      context: context,
      builder: (context) => _RambuEditDialog(
        rambu: rambuToEdit,
        onSave: (Rambu updatedRambu) {
          setState(() {
            int index = _rambuList.indexOf(rambuToEdit);
            if (index != -1) {
              _rambuList[index] = updatedRambu;
              _filterRambu();
            }
          });
        },
      ),
    );
  }

  void _hapusDataRambu(Rambu rambuToDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Rambu?'),
        content: Text('Anda yakin ingin menghapus "${rambuToDelete.nama}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              setState(() {
                _rambuList.remove(rambuToDelete);
                _filterRambu();
              });
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 650;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Rambu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Search Bar & Tombol Tambah
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
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 16),
                      _buildAddButton(),
                    ],
                  ),
            const SizedBox(height: 24),
            
            // Tabel Data dengan Custom Table
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    horizontalMargin: 24,
                    columnSpacing: 32,
                    headingRowHeight: 56,
                    dataRowHeight: 80,
                    headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                    dividerThickness: 1,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'GAMBAR',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'NAMA RAMBU',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'JENIS RAMBU',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 400,
                          child: Text(
                            'DESKRIPSI RAMBU',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'AKSI',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
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
                                child: Image.asset(
                                  rambu.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              rambu.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              rambu.jenis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              width: 400,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                rambu.deskripsi,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.grey[600],
                                    size: 22,
                                  ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFDD835), width: 2),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add, color: Colors.black, size: 20),
      label: const Text(
        'Tambah Data Rambu',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFDD835),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: _tambahDataRambu,
    );
  }
}

// --- DIALOG UNTUK TAMBAH/EDIT RAMBU ---
class _RambuEditDialog extends StatefulWidget {
  final Rambu? rambu;
  final Function(Rambu) onSave;

  const _RambuEditDialog({this.rambu, required this.onSave});

  @override
  State<_RambuEditDialog> createState() => _RambuEditDialogState();
}

class _RambuEditDialogState extends State<_RambuEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _jenisController;
  late TextEditingController _deskripsiController;
  late TextEditingController _imagePathController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.rambu?.nama ?? '');
    _jenisController = TextEditingController(text: widget.rambu?.jenis ?? '');
    _deskripsiController =
        TextEditingController(text: widget.rambu?.deskripsi ?? '');
    _imagePathController = TextEditingController(
        text: widget.rambu?.imagePath ?? 'assets/images/placeholder.png');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _jenisController.dispose();
    _deskripsiController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newRambu = Rambu(
        nama: _namaController.text,
        jenis: _jenisController.text,
        deskripsi: _deskripsiController.text,
        imagePath: _imagePathController.text,
      );
      widget.onSave(newRambu);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.rambu == null ? 'Tambah Rambu Baru' : 'Edit Rambu'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Rambu'),
                validator: (value) =>
                    value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _jenisController,
                decoration: const InputDecoration(labelText: 'Jenis Rambu'),
                validator: (value) =>
                    value!.isEmpty ? 'Jenis tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _imagePathController,
                decoration: const InputDecoration(
                    labelText: 'Path Gambar (cth: assets/images/nama.png)'),
                validator: (value) =>
                    value!.isEmpty ? 'Path gambar tidak boleh kosong' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFDD835),
            foregroundColor: Colors.black,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}