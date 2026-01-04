import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// --- Custom Clipper ---
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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserCredentials(); 
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIKA REMEMBER ME ---
  Future<void> _loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      }
    });
  }

  // --- DIALOG SUKSES ---
  void _showSuccessDialog(bool isAdmin, int userId, String username) {
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
                isEnglish ? 'Login Successful' : 'Login Berhasil', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins')
              ),
              const SizedBox(height: 8),
              Text(
                isEnglish 
                    ? (isAdmin ? 'Welcome, Admin!' : 'Welcome, $username!')
                    : (isAdmin ? 'Selamat datang, Admin!' : 'Selamat datang, $username!'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
              ),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(); 
        if (isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin/dashboard_view');
        } else {
          Navigator.pushReplacementNamed(
            context, 
            '/home',
            arguments: {'userId': userId, 'username': username},
          );
        }
      }
    });
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
              top: 0, left: 0, right: 0, height: headerHeight,
              child: ClipPath(
                clipper: ConvexClipper(),
                child: Container(
                  color: const Color(0xFFD6D588),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Image.asset('assets/images/logo_rambuid.png', height: 80, width: 80),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isEnglish ? 'Welcome' : 'Selamat Datang', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))
                      ),
                      Text(
                        isEnglish ? 'To RambuID' : 'Di RambuID', 
                        style: const TextStyle(fontSize: 16, color: Color(0xFF555555))
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- FORM SECTION ---
            Positioned(
              top: headerHeight - 20, left: 0, right: 0, bottom: 0,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      
                      // --- INPUTS ---
                      _buildLabel('EMAIL'),
                      const SizedBox(height: 8),
                      _buildTextField(controller: _emailController, hint: 'user@gmail.com', icon: Icons.email_outlined),
                      
                      const SizedBox(height: 20),
                      
                      _buildLabel(isEnglish ? 'PASSWORD' : 'KATA SANDI'),
                      const SizedBox(height: 8),
                      _buildTextField(controller: _passwordController, hint: '••••••••••', icon: Icons.lock_outline, isPassword: true),

                      // --- INGAT SAYA ---
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24, height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: const Color(0xFFD6D588),
                                onChanged: (val) => setState(() => _rememberMe = val!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEnglish ? 'Remember me' : 'Ingat saya', 
                              style: const TextStyle(color: Colors.grey)
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40), 

                      // --- LINK DAFTAR ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isEnglish ? 'Don\'t have an account? ' : 'Belum punya akun? ',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/register'),
                            child: Text(
                              isEnglish ? 'Register Now!' : 'Daftar Sekarang!',
                              style: const TextStyle(
                                color: Color(0xFFD6D588),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),

                      // --- TOMBOL MASUK ---
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD6D588),
                            foregroundColor: const Color(0xFF2C3E50),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                              : Text(
                                  isEnglish ? 'LOGIN' : 'MASUK', 
                                  style: const TextStyle(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold, 
                                    letterSpacing: 1
                                  )
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Widget Helpers ---
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true, fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD6D588), width: 2)),
        suffixIcon: isPassword
            ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))
            : null,
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1));

  Future<void> _handleLogin() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEnglish ? 'Email and password are required' : 'Email dan password wajib diisi'), 
          backgroundColor: Colors.red
        )
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.login(email, password);
    
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }

    setState(() => _isLoading = false);

    if (result['success']) {
      dynamic data = result['data'];
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          data = data['data']; 
        } else if (data.containsKey('user')) {
          data = data['user'];
        }
      }

      int userId = 0;
      if (data['user_id'] != null) {
        userId = (data['user_id'] is int) ? data['user_id'] : int.parse(data['user_id'].toString());
      } else if (data['id'] != null) {
        userId = (data['id'] is int) ? data['id'] : int.parse(data['id'].toString());
      }
      
      final username = data['username'] ?? 'User';
      final isAdmin = ['admin@rambuid.com', 'admin@gmail.com'].contains(email.toLowerCase());
      
      if (mounted) _showSuccessDialog(isAdmin, userId, username);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? (isEnglish ? 'Login Failed' : 'Login Gagal')), 
            backgroundColor: Colors.red
          )
        );
      }
    }
  }
}