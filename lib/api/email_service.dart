import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class SendOtpResult {
  final bool success;
  final String message;

  SendOtpResult({required this.success, required this.message});
}

class EmailService {
  static String? _brevoSenderEmail;
  static String? _brevoApiKey;

  /// Membaca konfigurasi dari .env atau compile-time environment
  static Future<void> _loadConfig() async {
    if (_brevoApiKey != null && _brevoApiKey!.isNotEmpty) return;

    // 1. Cek dari compile-time environment
    const envBrevoSender = String.fromEnvironment('BREVO_SENDER_EMAIL');
    const envBrevoKey = String.fromEnvironment('BREVO_API_KEY');

    if (envBrevoSender.isNotEmpty) _brevoSenderEmail = envBrevoSender;
    if (envBrevoKey.isNotEmpty) _brevoApiKey = envBrevoKey;

    // 2. Baca dari file .env lokal via asset
    try {
      final content = await rootBundle.loadString('.env');
      for (final line in content.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('BREVO_SENDER_EMAIL=')) {
          _brevoSenderEmail =
              trimmed.substring('BREVO_SENDER_EMAIL='.length).trim();
        } else if (trimmed.startsWith('BREVO_API_KEY=')) {
          _brevoApiKey = trimmed.substring('BREVO_API_KEY='.length).trim();
        }
      }
    } catch (e) {
      debugPrint('EmailService: Gagal membaca file .env via rootBundle: $e');
    }

    // Fallback default sender
    _brevoSenderEmail ??= 'bimaprawira92@gmail.com';
  }

  /// Kirim kode OTP 5 digit langsung ke email tujuan via Brevo REST API
  static Future<SendOtpResult> sendOtpCode({
    required String targetEmail,
    required String otpCode,
  }) async {
    await _loadConfig();

    if (_brevoApiKey == null || _brevoApiKey!.isEmpty) {
      return SendOtpResult(
        success: false,
        message: 'Brevo API Key belum dikonfigurasi',
      );
    }

    final senderEmail = _brevoSenderEmail ?? 'bimaprawira92@gmail.com';

    try {
      debugPrint('EmailService: Mengirim via Brevo REST API ke $targetEmail...');
      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'api-key': _brevoApiKey!,
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({
          'sender': {
            'name': 'MotoManage',
            'email': senderEmail,
          },
          'to': [
            {'email': targetEmail}
          ],
          'subject': 'Kode Verifikasi Reset Password - MotoManage',
          'htmlContent': '''
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
        }),
      );

      debugPrint(
          'EmailService: Brevo response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return SendOtpResult(
          success: true,
          message: 'Kode berhasil dikirim ke $targetEmail',
        );
      } else {
        return SendOtpResult(
          success: false,
          message: 'Brevo (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('EmailService: Brevo API gagal: $e');
      return SendOtpResult(
        success: false,
        message: 'Koneksi error: $e',
      );
    }
  }
}
