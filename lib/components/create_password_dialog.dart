import 'package:flutter/material.dart';
import '../hooks/firebase_auth.dart';

class CreatePasswordDialog extends StatefulWidget {
  final String email;
  final bool isChangePassword;

  const CreatePasswordDialog({
    super.key,
    required this.email,
    this.isChangePassword = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String email,
    bool isChangePassword = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: isChangePassword, // Wajib diisi jika saat registrasi google
      builder: (context) => CreatePasswordDialog(
        email: email,
        isChangePassword: isChangePassword,
      ),
    );
  }

  @override
  State<CreatePasswordDialog> createState() => _CreatePasswordDialogState();
}

class _CreatePasswordDialogState extends State<CreatePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Status validasi realtime
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  static const Color bgDark = Color(0xFF151821);
  static const Color inputBg = Color(0xFF0F1015);
  static const Color inputBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF2026);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8E95A2);
  static const Color greenCheck = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordRules);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePasswordRules);
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _validatePasswordRules() {
    final text = _passwordController.text;
    setState(() {
      _hasMinLength = text.length >= 6;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(text);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(text);
      _hasNumber = RegExp(r'[0-9]').hasMatch(text);
      _hasSymbol = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(text);
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber;

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isPasswordValid) {
      setState(() {
        _errorMessage =
            'Password harus memiliki huruf besar, huruf kecil, angka, dan minimal 6 karakter.';
      });
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _errorMessage = 'Konfirmasi password tidak cocok.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.setAccountPassword(_passwordController.text.trim());
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal menyimpan password: $e';
        });
      }
    }
  }

  Widget _buildRuleItem({
    required String label,
    required bool isValid,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(
            isValid
                ? Icons.check_circle_rounded
                : (isOptional
                    ? Icons.radio_button_unchecked
                    : Icons.cancel_outlined),
            size: 16,
            color: isValid
                ? greenCheck
                : (isOptional ? textMuted : const Color(0xFF6B7280)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: isValid
                    ? textWhite
                    : (isOptional ? textMuted : const Color(0xFF9CA3AF)),
                fontWeight: isValid ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: bgDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: inputBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Icon & Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x22FF2026),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentRed.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: accentRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isChangePassword
                                ? 'Ubah Password Akun'
                                : 'Buat Password Akun',
                            style: const TextStyle(
                              color: textWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.email,
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 12.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  widget.isChangePassword
                      ? 'Masukkan password baru untuk akun Anda.'
                      : 'Akun Google Anda perlu membuat password agar dapat login langsung dengan email & password native.',
                  style: const TextStyle(color: textMuted, fontSize: 13),
                ),
                const SizedBox(height: 18),

                // Input Password Baru
                const Text(
                  'Password Baru',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: textWhite, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Minimal 6 karakter',
                    hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    filled: true,
                    fillColor: inputBg,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: accentRed, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Input Konfirmasi Password
                const Text(
                  'Konfirmasi Password',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: textWhite, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ulangi password baru',
                    hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                    filled: true,
                    fillColor: inputBg,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: accentRed, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Rules checklist box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: inputBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ketentuan Password:',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRuleItem(
                        label: 'Minimal 6 karakter',
                        isValid: _hasMinLength,
                      ),
                      _buildRuleItem(
                        label: 'Mengandung huruf besar (A-Z)',
                        isValid: _hasUppercase,
                      ),
                      _buildRuleItem(
                        label: 'Mengandung huruf kecil (a-z)',
                        isValid: _hasLowercase,
                      ),
                      _buildRuleItem(
                        label: 'Mengandung angka (0-9)',
                        isValid: _hasNumber,
                      ),
                      _buildRuleItem(
                        label: 'Simbol khusus (@, #, \$, dll) - Opsional',
                        isValid: _hasSymbol,
                        isOptional: true,
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: accentRed, fontSize: 12.5),
                  ),
                ],

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textMuted,
                          side: const BorderSide(color: inputBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentRed,
                          foregroundColor: textWhite,
                          elevation: 0,
                          disabledBackgroundColor:
                              accentRed.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(textWhite),
                                ),
                              )
                            : const Text(
                                'Simpan Password',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
