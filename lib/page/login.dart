import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/create_password_dialog.dart';
import '../components/password_forget.dart';
import '../hooks/firebase_auth.dart';
import 'beranda.dart';

class LoginPage extends StatefulWidget {
  final String? initialEmail;
  const LoginPage({super.key, this.initialEmail});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0F1015);
  static const Color inputBg = Color(0xFF151821);
  static const Color inputBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF2026);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8E95A2);
  static const Color textDim = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.initialEmail ?? 'sugeng@gmail.com',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userData = await _authService.signInWithEmailPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;

        final nama = userData?['nama_lengkap'] ?? _emailController.text;
        final role = userData?['role'] ?? 'Pengguna';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF143322),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF22C55E), width: 1),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Berhasil masuk sebagai $nama ($role)',
                    style: const TextStyle(
                      color: textWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Pindah ke halaman Beranda (FR02)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BerandaPage(userData: userData),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String errorMessage = 'Terjadi kesalahan saat masuk.';
        if (e.code == 'user-not-found') {
          errorMessage = 'Pengguna dengan email ini tidak ditemukan.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Kata sandi salah. Silakan coba lagi.';
        } else if (e.code == 'invalid-credential') {
          errorMessage = 'Email atau kata sandi tidak sesuai.';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'Akun ini telah dinonaktifkan.';
        } else if (e.code == 'too-many-requests') {
          errorMessage = 'Terlalu banyak percobaan gagal. Silakan coba nanti.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF3B1517),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: accentRed, width: 1),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: accentRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: textWhite),
                  ),
                ),
              ],
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF3B1517),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: accentRed, width: 1),
            ),
            content: Text(
              'Gagal masuk: $e',
              style: const TextStyle(color: textWhite),
            ),
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final userData = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (userData != null) {
        final nama = userData['nama_lengkap'] ?? 'Pengguna';
        final role = userData['role'] ?? 'Kasir';
        final email = userData['email'] ?? '';

        // Cek apakah akun Google ini sudah memiliki password native
        final hasPassword = await _authService.userHasPassword();

        if (!hasPassword && mounted) {
          // Minta pengguna membuat password baru dengan aturan validasi
          final created = await CreatePasswordDialog.show(
            context,
            email: email,
            isChangePassword: false,
          );

          if (created != true) {
            // Batal buat password -> batalkan login
            await _authService.signOut();
            return;
          }
          userData['has_password'] = true;
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF143322),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF22C55E), width: 1),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Berhasil masuk Google: $nama ($role)',
                    style: const TextStyle(
                      color: textWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Pindah ke halaman Beranda (FR02)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BerandaPage(userData: userData),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF3B1517),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: accentRed, width: 1),
          ),
          content: Text(
            'Gagal login dengan Google: $e',
            style: const TextStyle(color: textWhite),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // --- 1. HEADER BRANDING (Logo + MotoManage + Tagline) ---
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF13151D),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: accentRed, width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.two_wheeler_rounded,
                              color: accentRed,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MotoManage: \nZalzabila Motor',
                              style: TextStyle(
                                color: textWhite,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Sistem Manajemen Bengkel',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),

                    // --- 2. HEADING (Masuk ke Akun) ---
                    const Text(
                      'Masuk ke Akun',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Silakan masukkan password akun bengkel Anda',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- 3. INPUT EMAIL ---
                    const Text(
                      'Email',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: textWhite, fontSize: 14),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'sugeng@motomanage.id',
                        hintStyle: const TextStyle(color: textDim, fontSize: 13.5),
                        prefixIcon: const Icon(
                          Icons.mail_outline_rounded,
                          color: textDim,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: inputBorder, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: accentRed, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.redAccent, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // --- 4. INPUT KATA SANDI ---
                    const Text(
                      'Kata Sandi',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: textWhite, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '••••••••••',
                        hintStyle: const TextStyle(color: textDim, fontSize: 16),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: textDim,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: textDim,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: inputBorder, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: accentRed, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.redAccent, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kata sandi tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Kata sandi minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // --- 5. LUPA KATA SANDI? ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () async {
                          final resetEmail = await PasswordForgetDialog.show(
                            context,
                            initialEmail: _emailController.text,
                          );
                          if (!mounted) return;
                          if (resetEmail != null) {
                            _emailController.text = resetEmail;
                            _passwordController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF143322),
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  'Password berhasil diperbarui! Silakan masuk dengan password baru Anda.',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            'Lupa kata sandi?',
                            style: TextStyle(
                              color: accentRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // --- 6. TOMBOL MASUK (Primary Button) ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentRed,
                          foregroundColor: textWhite,
                          elevation: 0,
                          disabledBackgroundColor: const Color(0x80FF2026),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(textWhite),
                                ),
                              )
                            : const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // --- 7. DIVIDER "atau" ---
                    const Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: inputBorder,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'atau',
                            style: TextStyle(
                              color: textDim,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: inputBorder,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- 8. TOMBOL LOGIN GOOGLE ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _handleGoogleLogin,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: inputBg,
                          foregroundColor: textWhite,
                          side: const BorderSide(color: inputBorder, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GoogleIconWidget(size: 22),
                            SizedBox(width: 12),
                            Text(
                              'Lanjutkan dengan Google',
                              style: TextStyle(
                                color: textWhite,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget logo Google dengan CustomPainter presisi tinggi sesuai brand guideline Google
class GoogleIconWidget extends StatelessWidget {
  final double size;
  const GoogleIconWidget({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(size * 0.16),
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Blue Path (#4285F4)
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20.0)
      ..lineTo(24.0, 20.0)
      ..lineTo(24.0, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
      ..lineTo(39.89, 42.2)
      ..cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Green Path (#34A853)
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(24.0, 48.0)
      ..cubicTo(30.48, 48.0, 35.93, 45.87, 39.89, 42.2)
      ..lineTo(32.16, 36.2)
      ..cubicTo(30.01, 37.65, 27.24, 38.5, 24.0, 38.5)
      ..cubicTo(17.74, 38.5, 12.43, 34.28, 10.53, 28.59)
      ..lineTo(2.55, 34.78)
      ..cubicTo(6.51, 42.62, 14.62, 48.0, 24.0, 48.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Yellow Path (#FBBC05)
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24.0)
      ..cubicTo(9.77, 22.4, 10.05, 20.86, 10.53, 19.41)
      ..lineTo(2.55, 13.22)
      ..cubicTo(0.92, 16.46, 0.0, 20.12, 0.0, 24.0)
      ..cubicTo(0.0, 27.88, 0.92, 31.54, 2.55, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 4. Red Path (#EA4335)
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(24.0, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.9, 2.38, 30.47, 0.0, 24.0, 0.0)
      ..cubicTo(14.62, 0.0, 6.51, 5.38, 2.55, 13.22)
      ..lineTo(10.53, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24.0, 9.5)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
