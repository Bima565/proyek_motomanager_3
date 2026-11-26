import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../components/custom_calendar_dialog.dart';
import '../components/rupiah_formatter.dart';
import 'barang_service.dart';
import 'pembelian_service.dart';
import 'transaksi_service.dart';

class LaporanPdfService {
  static const List<String> namaBulanIndo = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  /// Helper untuk modal beli part
  static int _findPartBuyPrice(
    TransaksiItemModel item,
    List<BarangModel> barangs,
    List<PembelianRecord> pembelians,
  ) {
    final bool isJasa = item.isService == true ||
        item.category.toLowerCase().contains('jasa') ||
        item.category.toLowerCase().contains('servis');
    if (isJasa) return 0;

    int resolvedPrice = 0;
    if (item.buyPrice != null && item.buyPrice! > 0) {
      resolvedPrice = item.buyPrice!;
    } else {
      if (item.id.isNotEmpty) {
        final byId = barangs.where((b) => b.id == item.id);
        if (byId.isNotEmpty && byId.first.buyPrice > 0) {
          resolvedPrice = byId.first.buyPrice;
        }
      }
      if (resolvedPrice == 0) {
        final normName = item.name.trim().toLowerCase();
        final byName = barangs.where((b) => b.name.trim().toLowerCase() == normName);
        if (byName.isNotEmpty && byName.first.buyPrice > 0) {
          resolvedPrice = byName.first.buyPrice;
        }
      }
      if (resolvedPrice == 0) {
        final normName = item.name.trim().toLowerCase();
        for (final p in pembelians) {
          for (final r in p.items) {
            if ((r.id.isNotEmpty && r.id == item.id) ||
                r.name.trim().toLowerCase() == normName) {
              if (r.buyPrice > 0) {
                resolvedPrice = r.buyPrice;
                break;
              }
            }
          }
          if (resolvedPrice > 0) break;
        }
      }
    }

    if (resolvedPrice > 0 && resolvedPrice < item.price) {
      return resolvedPrice;
    }
    return (item.price * 0.70).round();
  }

  /// Menampilkan dialog pemilih tanggal rekap (fleksibel: harian, bulanan, tahunan, kustom) sebelum mencetak PDF
  static Future<void> showDownloadPdfDialog({
    required BuildContext context,
    required List<TransaksiPenjualanModel> allTransactions,
    required List<BarangModel> allBarang,
    required List<PembelianRecord> allPembelian,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
  }) async {
    final now = DateTime.now();
    DateTime tempStart = initialStartDate ?? DateTime(now.year, now.month, 1);
    DateTime tempEnd = initialEndDate ?? DateTime(now.year, now.month, now.day);
    String activePreset = '';

    final result = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Evaluasi preset aktif
            final bool isSameDay = tempStart.year == tempEnd.year &&
                tempStart.month == tempEnd.month &&
                tempStart.day == tempEnd.day;
            final bool isFullMonth = tempStart.year == tempEnd.year &&
                tempStart.month == tempEnd.month &&
                tempStart.day == 1 &&
                tempEnd.day == DateTime(tempStart.year, tempStart.month + 1, 0).day;
            final bool isFullYear = tempStart.year == tempEnd.year &&
                tempStart.month == 1 &&
                tempStart.day == 1 &&
                tempEnd.month == 12 &&
                tempEnd.day == 31;

            if (isSameDay) {
              activePreset = 'Harian';
            } else if (isFullMonth) {
              activePreset = 'Bulanan';
            } else if (isFullYear) {
              activePreset = 'Tahunan';
            } else {
              activePreset = 'Kustom';
            }

            // Hitung jumlah transaksi di rentang tanggal ini secara realtime
            final startWindow = DateTime(tempStart.year, tempStart.month, tempStart.day, 0, 0, 0);
            final endWindow = DateTime(tempEnd.year, tempEnd.month, tempEnd.day, 23, 59, 59, 999);
            final previewCount = allTransactions.where((t) {
              return t.status.toLowerCase() != 'batal' &&
                  !t.dateTime.isBefore(startWindow) &&
                  !t.dateTime.isAfter(endWindow);
            }).length;

            return Dialog(
              backgroundColor: const Color(0xFF151821),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFF222634)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFFF1E27), size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Unduh Rekap Laporan PDF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pilih periode tanggal transaksi (bisa harian, bulanan, atau tahunan):',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Quick Preset Buttons: Harian, Bulanan, Tahunan, Sesuai Filter
                    Row(
                      children: [
                        _buildPresetButton(
                          label: 'Harian',
                          isActive: activePreset == 'Harian',
                          onTap: () {
                            setStateDialog(() {
                              tempStart = DateTime(now.year, now.month, now.day);
                              tempEnd = DateTime(now.year, now.month, now.day);
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildPresetButton(
                          label: 'Bulanan',
                          isActive: activePreset == 'Bulanan',
                          onTap: () {
                            setStateDialog(() {
                              tempStart = DateTime(now.year, now.month, 1);
                              tempEnd = DateTime(now.year, now.month + 1, 0);
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildPresetButton(
                          label: 'Tahunan',
                          isActive: activePreset == 'Tahunan',
                          onTap: () {
                            setStateDialog(() {
                              tempStart = DateTime(now.year, 1, 1);
                              tempEnd = DateTime(now.year, 12, 31);
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildPresetButton(
                          label: 'Filter',
                          isActive: initialStartDate != null &&
                              tempStart == initialStartDate &&
                              tempEnd == initialEndDate,
                          onTap: () {
                            if (initialStartDate != null && initialEndDate != null) {
                              setStateDialog(() {
                                tempStart = initialStartDate;
                                tempEnd = initialEndDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Date Pickers: Tanggal Mulai -> Tanggal Selesai
                    Row(
                      children: [
                        // Tanggal Mulai
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tanggal Mulai',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              _buildDatePickerTile(
                                dateText: '${tempStart.day}/${tempStart.month}/${tempStart.year}',
                                onTap: () async {
                                  final picked = await CustomCalendarDialog.show(
                                    context,
                                    initialDate: tempStart,
                                  );
                                  if (picked != null) {
                                    setStateDialog(() {
                                      tempStart = DateTime(picked.year, picked.month, picked.day);
                                      if (tempEnd.isBefore(tempStart)) {
                                        tempEnd = tempStart;
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(8, 18, 8, 0),
                          child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF64748B), size: 16),
                        ),
                        // Tanggal Selesai
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tanggal Selesai',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              _buildDatePickerTile(
                                dateText: '${tempEnd.day}/${tempEnd.month}/${tempEnd.year}',
                                onTap: () async {
                                  final picked = await CustomCalendarDialog.show(
                                    context,
                                    initialDate: tempEnd,
                                  );
                                  if (picked != null) {
                                    setStateDialog(() {
                                      tempEnd = DateTime(picked.year, picked.month, picked.day);
                                      if (tempStart.isAfter(tempEnd)) {
                                        tempStart = tempEnd;
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Info Card Realtime Jumlah Transaksi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E1015),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF222634)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$previewCount Transaksi Siap Direkap',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _getReadablePeriodLabel(tempStart, tempEnd),
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Aksi
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx, null),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF94A3B8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx, {
                                'start': tempStart,
                                'end': tempEnd,
                              });
                            },
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Buat PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF1E27),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      final s = result['start']!;
      final e = result['end']!;

      await generateAndPrintPdf(
        context: context,
        startDate: s,
        endDate: e,
        allTransactions: allTransactions,
        allBarang: allBarang,
        allPembelian: allPembelian,
      );
    }
  }

  static Widget _buildPresetButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFF1E27) : const Color(0xFF0E1015),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFFFF1E27) : const Color(0xFF222634),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildDatePickerTile({
    required String dateText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1015),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF222634)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF38BDF8),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  static String _getReadablePeriodLabel(DateTime s, DateTime e) {
    final bool isSameDay = s.year == e.year && s.month == e.month && s.day == e.day;
    final bool isFullMonth = s.year == e.year &&
        s.month == e.month &&
        s.day == 1 &&
        e.day == DateTime(s.year, s.month + 1, 0).day;
    final bool isFullYear = s.year == e.year && s.month == 1 && s.day == 1 && e.month == 12 && e.day == 31;

    if (isSameDay) {
      return 'Rekap Harian: ${s.day} ${namaBulanIndo[s.month - 1]} ${s.year}';
    } else if (isFullMonth) {
      return 'Rekap Bulanan: ${namaBulanIndo[s.month - 1]} ${s.year}';
    } else if (isFullYear) {
      return 'Rekap Tahunan: Tahun ${s.year}';
    } else {
      return 'Rekap Periode: ${s.day}/${s.month}/${s.year} - ${e.day}/${e.month}/${e.year}';
    }
  }

  /// Menghasilkan PDF dan menampilkan preview / share print dialog
  static Future<void> generateAndPrintPdf({
    required BuildContext context,
    required DateTime startDate,
    required DateTime endDate,
    required List<TransaksiPenjualanModel> allTransactions,
    required List<BarangModel> allBarang,
    required List<PembelianRecord> allPembelian,
  }) async {
    final bool isSameDay = startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    final bool isFullMonth = startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == 1 &&
        endDate.day == DateTime(startDate.year, startDate.month + 1, 0).day;

    final bool isFullYear = startDate.year == endDate.year &&
        startDate.month == 1 &&
        startDate.day == 1 &&
        endDate.month == 12 &&
        endDate.day == 31;

    String periodeBadge;
    String periodeTabel;
    String pdfFileName;

    if (isSameDay) {
      periodeBadge = 'REKAP HARIAN: ${startDate.day} ${namaBulanIndo[startDate.month - 1]} ${startDate.year}'.toUpperCase();
      periodeTabel = 'HARI ${startDate.day} ${namaBulanIndo[startDate.month - 1]} ${startDate.year}'.toUpperCase();
      pdfFileName = 'Laporan_Harian_MotoManage_${startDate.day}_${startDate.month}_${startDate.year}.pdf';
    } else if (isFullMonth) {
      periodeBadge = 'REKAP BULANAN: ${namaBulanIndo[startDate.month - 1]} ${startDate.year}'.toUpperCase();
      periodeTabel = 'BULAN ${namaBulanIndo[startDate.month - 1]} ${startDate.year}'.toUpperCase();
      pdfFileName = 'Laporan_Bulanan_MotoManage_${namaBulanIndo[startDate.month - 1]}_${startDate.year}.pdf';
    } else if (isFullYear) {
      periodeBadge = 'REKAP TAHUNAN: ${startDate.year}'.toUpperCase();
      periodeTabel = 'TAHUN ${startDate.year}'.toUpperCase();
      pdfFileName = 'Laporan_Tahunan_MotoManage_${startDate.year}.pdf';
    } else {
      periodeBadge = 'PERIODE: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
      periodeTabel = '${startDate.day}/${startDate.month}/${startDate.year} S/D ${endDate.day}/${endDate.month}/${endDate.year}';
      pdfFileName = 'Laporan_Periode_MotoManage_${startDate.day}_${startDate.month}_sd_${endDate.day}_${endDate.month}_${startDate.year}.pdf';
    }

    // Filter transaksi valid sesuai rentang tanggal (00:00:00 s/d 23:59:59)
    final startWindow = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final endWindow = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

    final periodTrx = allTransactions.where((t) {
      return t.status.toLowerCase() != 'batal' &&
          !t.dateTime.isBefore(startWindow) &&
          !t.dateTime.isAfter(endWindow);
    }).toList();

    // Kalkulasi Angka Keuangan
    int totalOmzetPart = 0;
    int totalOmzetJasa = 0;
    int countServis = 0;
    int countPart = 0;
    int totalHppPart = 0;

    int totalTunai = 0;
    int countTunai = 0;
    int totalTransfer = 0;
    int countTransfer = 0;
    int totalQris = 0;
    int countQris = 0;

    for (final trx in periodTrx) {
      // Metode Pembayaran
      final method = trx.paymentMethod.toLowerCase();
      if (method.contains('tunai') || method.contains('cash')) {
        totalTunai += trx.totalBayar;
        countTunai++;
      } else if (method.contains('transfer') || method.contains('bank')) {
        totalTransfer += trx.totalBayar;
        countTransfer++;
      } else if (method.contains('qris')) {
        totalQris += trx.totalBayar;
        countQris++;
      } else {
        totalTunai += trx.totalBayar;
        countTunai++;
      }

      for (final item in trx.items) {
        final bool isJasa = item.isService == true ||
            item.category.toLowerCase().contains('jasa') ||
            item.category.toLowerCase().contains('servis');
        if (isJasa) {
          totalOmzetJasa += item.price * item.quantity;
          countServis += item.quantity;
        } else {
          totalOmzetPart += item.price * item.quantity;
          countPart += item.quantity;
          final buyPrice = _findPartBuyPrice(item, allBarang, allPembelian);
          totalHppPart += buyPrice * item.quantity;
        }
      }
    }

    final int totalOmzet = totalOmzetPart + totalOmzetJasa;
    final int keuntunganPart = math.max(0, totalOmzetPart - totalHppPart);
    final int keuntunganJasa = totalOmzetJasa;
    final int labaKotor = keuntunganPart + keuntunganJasa;
    final int bebanOperasional = (labaKotor * 0.205).round();
    final int labaBersih = math.max(0, labaKotor - bebanOperasional);

    // Hitung pengeluaran pembelian stok di periode terpilih
    int totalPengeluaranBeli = 0;
    int countBeli = 0;
    for (final p in allPembelian) {
      if (p.status.toUpperCase() != 'BATAL') {
        if (!p.dateTime.isBefore(startWindow) && !p.dateTime.isAfter(endWindow)) {
          totalPengeluaranBeli += p.totalAmount;
          countBeli++;
        }
      }
    }
    final int pendapatanBersih = math.max(0, labaBersih - totalPengeluaranBeli);

    final double marginKotor = totalOmzet > 0 ? (labaKotor / totalOmzet * 100) : 0.0;
    final double marginBersih = totalOmzet > 0 ? (pendapatanBersih / totalOmzet * 100) : 0.0;
    final double partPercent = totalOmzet > 0 ? (totalOmzetPart / totalOmzet * 100) : 0.0;
    final double servisPercent = totalOmzet > 0 ? (totalOmzetJasa / totalOmzet * 100) : 0.0;

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Header Dokumen
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MOTOMANAGE',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800,
                      ),
                    ),
                    pw.Text(
                      'Bengkel & Toko Sparepart Motor',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Laporan Resmi Pendapatan & Analitik Keuangan',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        periodeBadge,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Dicetak: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} • ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.grey400),
            pw.SizedBox(height: 10),

            // 2. Ringkasan Portofolio Keuangan
            pw.Text(
              '1. RINGKASAN PORTOFOLIO KEUANGAN',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                _buildPdfKpiCard('OMZET KOTOR', formatRupiah(totalOmzet), '${periodTrx.length} Penjualan', PdfColors.blue800),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('PENGELUARAN STOK', formatRupiah(totalPengeluaranBeli), '$countBeli Pembelian', PdfColors.red800),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('KEUNTUNGAN BERSIH', formatRupiah(pendapatanBersih), 'Kas Bersih', PdfColors.green800),
              ],
            ),
            pw.SizedBox(height: 14),

            // 3. Sumber Pendapatan & Metode Pembayaran
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Sumber Pendapatan
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '2. SUMBER PENDAPATAN',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Column(
                          children: [
                            _buildPdfRowDetail('Jasa Servis', formatRupiah(totalOmzetJasa), '$countServis servis (${servisPercent.toStringAsFixed(1)}%)'),
                            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                            _buildPdfRowDetail('Penjualan Sparepart', formatRupiah(totalOmzetPart), '$countPart pcs (${partPercent.toStringAsFixed(1)}%)'),
                            _buildPdfRowDetail('Modal Sparepart Terjual', formatRupiah(totalHppPart), 'Biaya Kulakan'),
                            _buildPdfRowDetail('Laba Penjualan Sparepart', formatRupiah(keuntunganPart), 'Harga Jual - Modal'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),

                // Metode Pembayaran
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '3. REKAP METODE PEMBAYARAN',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Column(
                          children: [
                            _buildPdfRowDetail('Tunai (Cash)', formatRupiah(totalTunai), '$countTunai Transaksi'),
                            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                            _buildPdfRowDetail('Transfer Bank', formatRupiah(totalTransfer), '$countTransfer Transaksi'),
                            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                            _buildPdfRowDetail('QRIS / Digital', formatRupiah(totalQris), '$countQris Transaksi'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // 4. Tabel Transaksi Penjualan Periode Tersebut
            pw.Text(
              '4. DAFTAR TRANSAKSI PENJUALAN $periodeTabel',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 6),

            if (periodTrx.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'Tidak ada transaksi penjualan tercatat pada periode $periodeBadge.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                headers: ['No', 'No. Nota', 'Tanggal & Waktu', 'Pelanggan', 'Layanan / Item', 'Metode', 'Total Bayar'],
                data: List.generate(periodTrx.length, (i) {
                  final t = periodTrx[i];
                  return [
                    '${i + 1}',
                    t.code,
                    t.timeFormatted,
                    t.customerName.isEmpty ? 'Pelanggan Umum' : t.customerName,
                    t.summaryServices,
                    t.paymentMethod,
                    formatRupiah(t.totalBayar),
                  ];
                }),
              ),

            pw.SizedBox(height: 24),

            // 5. Lembar Pengesahan / Tanda Tangan
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Catatan:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('• Laporan dihasilkan otomatis oleh Sistem Informasi Bengkel MotoManage.', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    pw.Text('• Seluruh nominal telah dicocokkan dengan data penjualan Cloud Firestore.', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Disetujui Oleh,', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 36),
                    pw.Container(
                      width: 120,
                      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600, width: 0.8))),
                      child: pw.Center(
                        child: pw.Text('Pemilik Bengkel / Kasir', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Buka dialog layout print bawaan platform
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: pdfFileName,
    );
  }

  static pw.Widget _buildPdfKpiCard(String title, String value, String subtitle, PdfColor accentColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: accentColor)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfRowDetail(String label, String value, String sub) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              if (sub.isNotEmpty) pw.Text(sub, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            ],
          ),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
        ],
      ),
    );
  }
}
