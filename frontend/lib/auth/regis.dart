import 'package:flutter/material.dart';
import 'dart:async'; 
import '../services/api_service.dart';

// --- Custom Clipper ---
class ConvexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
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

  // --- POP-UP SUKSES ---
  void _showSuccessDialog(String message) {
    // Cek Bahasa
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFFD6D588), size: 64),
              const SizedBox(height: 16),
              
              Text(
                isEnglish ? "Registration Successful" : "Pendaftaran Berhasil",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                message,
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

    // --- TIMER 2 DETIK LALU PINDAH KE LOGIN ---
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(); 
        Navigator.pushReplacementNamed(context, '/login'); 
      }
    });
  }

  void _handleRegistration() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final nama = _nameController.text.trim();
      final username = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await ApiService.register(
        username,
        password,
        namaLengkap: nama,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        final data = result['data'];
        if (mounted) {
          // Default message bilingual logic
          String welcomeMessage = data['message'] ?? (isEnglish 
              ? "Welcome, $username!" 
              : "Selamat datang, $username!");
          _showSuccessDialog(welcomeMessage);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? (isEnglish ? "Registration failed!" : "Pendaftaran gagal!")),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double headerHeight = screenSize.height * 0.35;
    
    // --- DETEKSI BAHASA ---
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SizedBox(
        width: double.infinity,
        height: screenSize.height,
        child: Stack(
          children: [
            // --- HEADER BACKGROUND ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: ClipPath(
                clipper: ConvexClipper(),
                child: Container(
                  color: const Color(0xFFD6D588),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/logo_rambuid.png',
                          height: 80,
                          width: 80,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isEnglish ? "Register Account" : "Daftar Akun",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        isEnglish ? "Please register to start" : "Silakan mendaftar untuk memulai",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF555555),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- FORM CONTENT ---
            Positioned(
              top: headerHeight - 20,
              left: 0,
              right: 0,
              bottom: 0,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // NAMA
                        _buildLabel(isEnglish ? "FULL NAME" : "NAMA LENGKAP"),
                        const SizedBox(height: 5),
                        _buildTextField(
                          controller: _nameController,
                          hint: isEnglish ? "Your Full Name" : "Nama Lengkap Anda",
                          validationMsg: isEnglish ? "Required" : "Wajib diisi",
                        ),

                        const SizedBox(height: 15),

                        // EMAIL
                        _buildLabel("EMAIL"),
                        const SizedBox(height: 5),
                        _buildTextField(
                          controller: _emailController,
                          hint: isEnglish ? "Active Email" : "Email Aktif",
                          isEmail: true,
                          validationMsg: isEnglish ? "Required" : "Wajib diisi",
                        ),

                        const SizedBox(height: 15),

                        // PASSWORD
                        _buildLabel(isEnglish ? "PASSWORD" : "KATA SANDI"),
                        const SizedBox(height: 5),
                        _buildPasswordField(
                          controller: _passwordController,
                          hint: isEnglish ? "Min. 6 characters" : "Minimal 6 karakter",
                          isObscure: _obscurePassword,
                          onToggle: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          validationMsg: isEnglish ? "Required" : "Wajib diisi",
                        ),

                        const SizedBox(height: 15),

                        // CONFIRM PASSWORD
                        _buildLabel(isEnglish ? "CONFIRM PASSWORD" : "KONFIRMASI SANDI"),
                        const SizedBox(height: 5),
                        _buildPasswordField(
                          controller: _confirmController,
                          hint: isEnglish ? "Repeat password" : "Ulangi kata sandi",
                          isObscure: _obscureConfirmPassword,
                          onToggle: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          isConfirm: true,
                          validationMsg: isEnglish ? "Required" : "Wajib diisi",
                        ),

                        const SizedBox(height: 30),

                        // LINK LOGIN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isEnglish ? "Already have an account? " : "Sudah punya akun? ",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/login'),
                              child: Text(
                                isEnglish ? "LOGIN" : "MASUK",
                                style: const TextStyle(
                                  color: Color(0xFFD6D588),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black87,
                                    ),
                                  )
                                : Text(
                                    isEnglish ? "REGISTER" : "DAFTAR",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),
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
  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
          fontFamily: 'Poppins',
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String validationMsg,
    bool isEmail = false,
  }) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: _inputDecoration(hint),
      validator: (value) {
        if (value == null || value.isEmpty) return validationMsg;
        if (isEmail) {
          if (!value.contains('@')) return isEnglish ? "Invalid email format" : "Format email salah";
          List<String> parts = value.split('@');
          String usernamePart = parts[0];
          if (usernamePart.length < 6) {
            return isEnglish ? "Email username must be min. 6 chars" : "Username email (sebelum @) min. 6 karakter";
          }
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isObscure,
    required VoidCallback onToggle,
    required String validationMsg,
    bool isConfirm = false,
  }) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: _inputDecoration(hint).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return validationMsg;
        if (!isConfirm && value.length < 6) return isEnglish ? "Min. 6 characters" : "Min. 6 karakter";
        if (isConfirm && value != _passwordController.text) {
          return isEnglish ? "Passwords do not match" : "Sandi tidak cocok";
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: Colors.grey,
        fontSize: 13,
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ), 
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD6D588), width: 2),
      ),
    );
  }
}