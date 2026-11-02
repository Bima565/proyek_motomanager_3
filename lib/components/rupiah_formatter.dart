import 'package:flutter/services.dart';

/// Helper pemformat angka dengan pemisah ribuan titik tanpa awalan Rp.
/// Contoh: `formatRibuan(45000)` -> `'45.000'`
String formatRibuan(int nominal) {
  if (nominal == 0) return '0';
  final isNegative = nominal < 0;
  final str = nominal.abs().toString();
  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    buffer.write(str[i]);
    count++;
    if (count % 3 == 0 && i != 0) {
      buffer.write('.');
    }
  }
  final res = buffer.toString().split('').reversed.join('');
  return isNegative ? '-$res' : res;
}

/// Helper pemformat mata uang Rupiah standar MotoManage.
/// Contoh: `formatRupiah(45000)` -> `'Rp 45.000'`
String formatRupiah(int nominal) {
  return 'Rp ${formatRibuan(nominal)}';
}

/// TextInputFormatter untuk memformat input angka secara real-time dengan titik ribuan.
/// Contoh: saat user mengetik 30000, teks otomatis menjadi 30.000.
class RibuanTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Jika user menekan backspace tepat pada pemisah titik (misal kursor setelah '.' di '3.000')
    if (oldValue.text.length - newValue.text.length == 1 &&
        oldValue.selection.isCollapsed &&
        oldValue.selection.end > 1 &&
        oldValue.text[oldValue.selection.end - 1] == '.') {
      final deletePos = oldValue.selection.end - 2;
      final adjustedText = oldValue.text.substring(0, deletePos) +
          oldValue.text.substring(oldValue.selection.end);
      final cleanDigits = adjustedText.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanDigits.isEmpty) {
        return const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
      final number = int.tryParse(cleanDigits) ?? 0;
      final formatted = formatRibuan(number);

      int digitsBefore = 0;
      for (int i = 0; i < deletePos; i++) {
        if (RegExp(r'[0-9]').hasMatch(oldValue.text[i])) {
          digitsBefore++;
        }
      }
      int newCursorPos = 0;
      int digitCount = 0;
      while (newCursorPos < formatted.length && digitCount < digitsBefore) {
        if (RegExp(r'[0-9]').hasMatch(formatted[newCursorPos])) {
          digitCount++;
        }
        newCursorPos++;
      }
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );
    }

    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Parse ke int untuk menghilangkan leading zeros (misal '05' -> 5)
    final number = int.tryParse(digits) ?? 0;
    final formatted = formatRibuan(number);

    // Hitung berapa banyak digit sebelum kursor pada newValue
    int digitsBeforeCursor = 0;
    for (int i = 0; i < newValue.selection.end && i < newValue.text.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    // Jika angka sebelumnya memiliki nol di depan dan dirampingkan (misal '05' -> '5')
    if (digits.length > 1 && digits.startsWith('0')) {
      final nonZeroDigits = number.toString();
      final diff = digits.length - nonZeroDigits.length;
      digitsBeforeCursor = (digitsBeforeCursor - diff).clamp(0, nonZeroDigits.length);
    }

    // Tentukan posisi kursor baru pada teks yang sudah diformat
    int newCursorPos = 0;
    int digitCount = 0;
    while (newCursorPos < formatted.length && digitCount < digitsBeforeCursor) {
      if (RegExp(r'[0-9]').hasMatch(formatted[newCursorPos])) {
        digitCount++;
      }
      newCursorPos++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}
