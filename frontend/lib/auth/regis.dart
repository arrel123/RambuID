import 'package:flutter/material.dart';
import '../services/api_service.dart';

// --- Custom Clipper (Sama seperti Login) ---
class ConvexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2, size.height,
      size.width, size.height - 50
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class RegisPage extends StatefulWidget {
  const RegisPage({super.key});

  @override
  State<RegisPage> createState() => _RegisPageState();
}

class _RegisPageState extends State<RegisPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final nama = _nameController.text.trim();
      final username = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await ApiService.register(username, password, namaLengkap: nama);

      setState(() => _isLoading = false);

      if (result['success']) {
        final data = result['data'];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Pendaftaran berhasil!"), backgroundColor: const Color(0xFF8B9C4A)),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? "Pendaftaran gagal!"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    // Header sedikit lebih kecil di halaman daftar karena formnya lebih panjang
    final double headerHeight = screenSize.height * 0.30; 

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // Kunci Layout agar tidak naik saat keyboard muncul
      body: SizedBox(
        width: double.infinity,
        height: screenSize.height,
        child: Stack(
          children: [
            // --- HEADER BACKGROUND ---
            Positioned(
              top: 0, left: 0, right: 0, height: headerHeight,
              child: ClipPath(
                clipper: ConvexClipper(),
                child: Container(
                  color: const Color(0xFFD6D588),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/logo_rambuid.png', height: 70, width: 70),
                      const SizedBox(height: 8),
                      const Text(
                        "Daftar Akun",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontFamily: 'Poppins'),
                      ),
                      const Text(
                        "Silakan mendaftar untuk memulai",
                        style: TextStyle(fontSize: 14, color: Color(0xFF555555), fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- FORM CONTENT ---
            Positioned(
              top: headerHeight - 10, left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // NAMA
                      _buildLabel("NAMA LENGKAP"),
                      const SizedBox(height: 5),
                      _buildTextField(controller: _nameController, hint: "Nama Lengkap Anda"),
                      
                      const SizedBox(height: 15),

                      // EMAIL
                      _buildLabel("EMAIL"),
                      const SizedBox(height: 5),
                      _buildTextField(controller: _emailController, hint: "Email Aktif", isEmail: true),

                      const SizedBox(height: 15),

                      // PASSWORD
                      _buildLabel("KATA SANDI"),
                      const SizedBox(height: 5),
                      _buildPasswordField(controller: _passwordController, hint: "Minimal 6 karakter", isObscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),

                      const SizedBox(height: 15),

                      // CONFIRM PASSWORD
                      _buildLabel("KONFIRMASI SANDI"),
                      const SizedBox(height: 5),
                      _buildPasswordField(
                        controller: _confirmController, 
                        hint: "Ulangi kata sandi", 
                        isObscure: _obscureConfirmPassword, 
                        onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        isConfirm: true
                      ),

                      const Spacer(), // Mendorong tombol ke bawah

                      // LINK LOGIN (DI ATAS TOMBOL)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Sudah punya akun? ", style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Poppins')),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/login'),
                            child: const Text(
                              "MASUK",
                              style: TextStyle(
                                color: Color(0xFFD6D588),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                // decoration: TextDecoration.underline, // Garis bawah dihapus
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),

                      // TOMBOL DAFTAR
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD6D588),
                            foregroundColor: const Color(0xFF2C3E50),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                              : const Text("DAFTAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: 'Poppins')),
                        ),
                      ),

                      SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5, fontFamily: 'Poppins'));

  Widget _buildTextField({required TextEditingController controller, required String hint, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: _inputDecoration(hint),
      validator: (value) {
        if (value == null || value.isEmpty) return "Wajib diisi";
        if (isEmail && !value.contains('@')) return "Email tidak valid";
        return null;
      },
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required String hint, required bool isObscure, required VoidCallback onToggle, bool isConfirm = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: _inputDecoration(hint).copyWith(
        suffixIcon: IconButton(
          icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: onToggle,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Wajib diisi";
        if (!isConfirm && value.length < 6) return "Min. 6 karakter";
        if (isConfirm && value != _passwordController.text) return "Sandi tidak cocok";
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 13),
      filled: true, fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Sedikit lebih tipis dari login karena field lebih banyak
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD6D588), width: 2)),
    );
  }
}
