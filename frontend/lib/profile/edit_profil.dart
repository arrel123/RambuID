import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async'; // Diperlukan untuk Timer
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class EditProfilPage extends StatefulWidget {
  final int userId;
  final String initialNama;
  final String initialEmail;
  final String initialAlamat;
  final String? initialProfileImage;
  final String initialPassword;

  const EditProfilPage({
    super.key,
    required this.userId,
    this.initialNama = 'Pengguna',
    this.initialEmail = 'user@gmail.com',
    this.initialAlamat = 'Belum ada alamat',
    this.initialProfileImage,
    this.initialPassword = '••••••••',
  });

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  XFile? _selectedImage;
  String? _currentProfileImage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController.text = widget.initialNama;
    _emailController.text = widget.initialEmail;
    _alamatController.text = widget.initialAlamat;
    _currentProfileImage = widget.initialProfileImage;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- FUNGSI POP-UP SUKSES (STYLE HIJAU SERAGAM) ---
  void _showSuccessDialog(Map<String, dynamic> updatedData) {
    // Cek Bahasa
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa klik luar
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          // Shape Radius 16 (Sesuai Riwayat & Login)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // Padding 24 (Sesuai Riwayat & Login)
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Icon Checklis Solid & Warna HIJAU TEMA
              const Icon(
                Icons.check_circle, // Gunakan yang solid
                color: Color(0xFFD6D588), // Warna Hijau Tema RambuID
                size: 64, // Ukuran Besar
              ),
              const SizedBox(height: 16),
              
              // 2. Judul Besar (Bilingual)
              Text(
                isEnglish ? 'Saved Successfully' : 'Berhasil Disimpan',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              // 3. Subtitle (Bilingual)
              Text(
                isEnglish ? 'Redirecting back to profile...' : 'Mengarahkan kembali ke profil...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
      },
    );

    // Timer 2 Detik: Tutup Pop-up -> Kembali ke Halaman Sebelumnya
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // 1. Hilangkan Pop-up
        Navigator.of(context).pop(); 
        
        // 2. Kembali ke menu sebelumnya membawa data baru
        Navigator.pop(context, updatedData);
      }
    });
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    
    // Validasi Input
    if (_namaController.text.trim().isEmpty) {
      _showSnackBar(l10n.nameRequired, Colors.red);
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showSnackBar(l10n.emailRequired, Colors.red);
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showSnackBar(l10n.emailInvalid, Colors.red);
      return;
    }

    if (_alamatController.text.trim().isEmpty) {
      _showSnackBar(l10n.addressRequired, Colors.red);
      return;
    }

    // Validasi Password
    if (_passwordController.text.trim().isNotEmpty ||
        _confirmPasswordController.text.trim().isNotEmpty) {
      if (_passwordController.text.trim().isEmpty) {
        _showSnackBar(l10n.passwordRequired, Colors.red);
        return;
      }

      if (_passwordController.text.trim().length < 6) {
        _showSnackBar(l10n.passwordMin, Colors.red);
        return;
      }

      if (_passwordController.text.trim() !=
          _confirmPasswordController.text.trim()) {
        _showSnackBar(l10n.passwordNotMatch, Colors.red);
        return;
      }
    }

    // Mulai Loading
    setState(() {
      _isLoading = true;
    });

    // Panggil API
    final result = await ApiService.updateUserProfile(
      userId: widget.userId,
      namaLengkap: _namaController.text.trim(),
      username: _emailController.text.trim(),
      alamat: _alamatController.text.trim(),
      password: _passwordController.text.trim().isNotEmpty
          ? _passwordController.text.trim()
          : null,
      profileImage: _selectedImage,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      final data = result['data'];
      
      // Siapkan data untuk dikirim balik
      final updatedData = {
        'nama': data['nama_lengkap'] ?? _namaController.text.trim(),
        'email': data['username'] ?? _emailController.text.trim(),
        'alamat': data['alamat'] ?? _alamatController.text.trim(),
        'password': _passwordController.text.trim(),
        'profileImage': data['profile_image'],
      };

      if (mounted) {
        // TAMPILKAN POP-UP HIJAU
        _showSuccessDialog(updatedData);
      }
    } else {
      // Jika Gagal, tetap pakai SnackBar Merah
      _showSnackBar(result['message'] ?? l10n.profileUpdateFailed, Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
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
                  Expanded(
                    child: Text(
                      l10n.editProfile,
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile Picture with Edit Button
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _selectedImage != null
                                ? (kIsWeb
                                    ? Image.network(
                                        _selectedImage!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_selectedImage!.path),
                                        fit: BoxFit.cover,
                                      ))
                                : (_currentProfileImage != null &&
                                        _currentProfileImage!.isNotEmpty
                                    ? Image.network(
                                        '${ApiService.baseUrl}$_currentProfileImage',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.grey[400],
                                          );
                                        },
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey[400],
                                      )),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImagePickerDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD6D588),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Form Fields
                    _buildTextField(
                      label: l10n.name,
                      controller: _namaController,
                      maxLines: 1,
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      label: l10n.email,
                      controller: _emailController,
                      maxLines: 1,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      label: l10n.address,
                      controller: _alamatController,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 20),

                    _buildPasswordField(
                      label: l10n.newPassword,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onToggleObscure: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    _buildPasswordField(
                      label: l10n.confirmPassword,
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      onToggleObscure: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD6D588),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: const Color(0xFFCCCCCC),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black87,
                                  ),
                                ),
                              )
                            : Text(
                                l10n.save.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
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
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required int maxLines,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFD6D588),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFD6D588),
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _showImagePickerDialog() {
    final l10n = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    l10n.chooseProfilePhoto,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFFD6D588),
                  ),
                  title: Text(l10n.takeFromCamera),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color(0xFFD6D588),
                  ),
                  title: Text(l10n.chooseFromGallery),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                if (_selectedImage != null || _currentProfileImage != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: Text(l10n.removePhoto),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                        _currentProfileImage = null;
                      });
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    final l10n = AppLocalizations.of(context);
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(l10n.cameraError, Colors.red);
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final l10n = AppLocalizations.of(context);
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(l10n.galleryError, Colors.red);
      }
    }
  }
}