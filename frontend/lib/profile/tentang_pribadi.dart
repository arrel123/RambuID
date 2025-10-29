import 'package:flutter/material.dart';
import 'edit_profil.dart';

class TentangPribadiPage extends StatefulWidget {
  final String initialNama;
  final String initialEmail;
  final String initialAlamat;

  const TentangPribadiPage({
    super.key,
    this.initialNama = 'Andika Dwi',
    this.initialEmail = 'rezzy123@gmail.com',
    this.initialAlamat = 'Batam center',
  });

  @override
  State<TentangPribadiPage> createState() => _TentangPribadiPageState();
}

class _TentangPribadiPageState extends State<TentangPribadiPage> {
  late String _namaLengkap;
  late String _email;
  late String _alamat;

  @override
  void initState() {
    super.initState();
    _namaLengkap = widget.initialNama;
    _email = widget.initialEmail;
    _alamat = widget.initialAlamat;
  }

  void _updateProfile(String nama, String email, String alamat) {
    setState(() {
      _namaLengkap = nama;
      _email = email;
      _alamat = alamat;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  // Back Button
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  const Expanded(
                    child: Text(
                      'Tentang Pribadi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Edit Button
                  TextButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilPage(
                            initialNama: _namaLengkap,
                            initialEmail: _email,
                            initialAlamat: _alamat,
                          ),
                        ),
                      );

                      if (result != null && result is Map<String, dynamic>) {
                        _updateProfile(
                          result['nama'] as String,
                          result['email'] as String,
                          result['alamat'] as String,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil berhasil disimpan!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'EDIT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile Picture
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: const DecorationImage(
                          image: AssetImage('assets/images/profile.png'),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Name
                    Text(
                      _namaLengkap,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Information Cards
                    _buildInfoCard(
                      icon: Icons.person_outline,
                      label: 'NAMA LENGKAP',
                      value: _namaLengkap,
                    ),

                    const SizedBox(height: 16),

                    _buildInfoCard(
                      icon: Icons.email_outlined,
                      label: 'EMAIL',
                      value: _email,
                    ),

                    const SizedBox(height: 16),

                    _buildInfoCard(
                      icon: Icons.location_on_outlined,
                      label: 'ALAMAT',
                      value: _alamat,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: Colors.black54),
          ),
          const SizedBox(width: 16),
          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
