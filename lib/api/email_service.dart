import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class EmailService {
  static String? _cachedApiKey;

  /// Membaca API Key secara aman dari .env atau compile-time environment
  static Future<String> getApiKey() async {
    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      return _cachedApiKey!;
    }

    // 1. Cek dari compile-time environment variable (--dart-define)
    const envKey = String.fromEnvironment('RESEND_API_KEY');
    if (envKey.isNotEmpty) {
      _cachedApiKey = envKey;
      return envKey;
    }

    // 2. Baca dari file .env lokal via rootBundle asset
    try {
      final content = await rootBundle.loadString('.env');
      for (final line in content.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('RESEND_API_KEY=')) {
          final val = trimmed.substring('RESEND_API_KEY='.length).trim();
          if (val.isNotEmpty) {
            _cachedApiKey = val;
            return val;
          }
        }
      }
    } catch (_) {}

    return '';
  }

  /// Kirim kode OTP 5 digit langsung ke email tujuan
  static Future<bool> sendOtpCode({
    required String targetEmail,
    required String otpCode,
  }) async {
    final apiKey = await getApiKey();

    if (apiKey.isEmpty) {
      // Jika API key belum terisi di .env
      return false;
    }

    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('https://api.resend.com/emails'),
      );
      request.headers.set('Authorization', 'Bearer $apiKey');
      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'from': 'MotoManage <onboarding@resend.dev>',
        'to': [targetEmail],
        'subject': 'Kode Verifikasi Reset Password - MotoManage',
        'html': '''
          <div style="font-family: Arial, sans-serif; padding: 24px; background: #0F1015; color: #FFFFFF; border-radius: 12px; max-width: 480px;">
            <h2 style="color: #FF2026; margin-top: 0;">MotoManage</h2>
            <p style="color: #E5E7EB; font-size: 14px;">Halo,</p>
            <p style="color: #9CA3AF; font-size: 14px;">Kami menerima permintaan pengaturan ulang kata sandi untuk akun bengkel Anda. Masukkan kode 5-digit berikut ke aplikasi:</p>
            <div style="background: #151821; border: 1px solid #222634; border-radius: 8px; padding: 18px; text-align: center; margin: 20px 0;">
              <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #FF2026;">$otpCode</span>
            </div>
            <p style="color: #6B7280; font-size: 12px; margin-bottom: 0;">Kode ini berlaku selama 15 menit. Jika bukan Anda yang meminta, abaikan pesan ini.</p>
          </div>
        ''',
      });

      request.write(body);
      final response = await request.close();
      client.close();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
