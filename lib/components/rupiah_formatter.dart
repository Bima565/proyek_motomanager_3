/// Helper pemformat mata uang Rupiah standar MotoManage.
/// Contoh: `formatRupiah(45000)` -> `'Rp 45.000'`
String formatRupiah(int nominal) {
  final str = nominal.toString();
  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    buffer.write(str[i]);
    count++;
    if (count % 3 == 0 && i != 0) {
      buffer.write('.');
    }
  }
  return 'Rp ${buffer.toString().split('').reversed.join('')}';
}
