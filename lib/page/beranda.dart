import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../components/create_password_dialog.dart';
import '../components/moto_bottom_nav.dart';
import '../components/rupiah_formatter.dart';
import '../hooks/firebase_auth.dart';
import '../services/barang_service.dart';
import '../services/transaksi_service.dart';
import 'stok/data_barang.dart';
import 'kelola_stok_jasa.dart';
import 'laporan_pendapatan.dart';
import 'login.dart';
import 'mengelola_user.dart';
import 'profil.dart';
import 'riwayat_transaksi.dart';
import 'transaksi/nota_pembayaran.dart';
import 'transaksi/pengadaan_restock.dart';

class BerandaPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final int initialIndex;

  const BerandaPage({
    super.key,
    this.userData,
    this.initialIndex = 0,
  });

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _liveUserData;
  late int _currentNavIndex;
  bool _isForward = true;
  int? _tappedHourIndex;

  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentYellow = Color(0xFFEAB308);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialIndex;
    _loadLiveUserData();
    _checkPasswordStatus();
  }

  bool get _isSuperAdmin {
    final role = ((_liveUserData ?? widget.userData)?['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_-]'), '');
    return role == 'superadmin';
  }

  void _switchTab(int index) {
    if (index == _currentNavIndex) return;
    setState(() {
      _isForward = index > _currentNavIndex;
      _currentNavIndex = index;
    });
  }

  void _checkPasswordStatus() async {
    final bool initialDocHasPass = widget.userData?['has_password'] == true;
    final bool isDocExplicitlyNoPass = widget.userData?['has_password'] == false;
    final bool hasPass = !isDocExplicitlyNoPass && (initialDocHasPass || await _authService.userHasPassword());
    if (!hasPass && mounted) {
      final email = _liveUserData?['email'] ??
          widget.userData?['email'] ??
          _authService.currentUser?.email ??
          '';

      if (email.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final created = await CreatePasswordDialog.show(
            context,
            email: email,
            isChangePassword: false,
          );

          if (!mounted) return;

          if (created == true) {
            _loadLiveUserData();
          } else {
            // Jika user belum memiliki password dan membatalkan dialog, logout
            await _authService.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        });
      }
    }
  }

  void _loadLiveUserData() async {
    final profile = await _authService.getCurrentUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _liveUserData = profile;
      });
    }
  }

  String _getUserInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildActiveTab(bool isSuperAdmin, String initials, String username, String role, String email) {
    final effectiveData = _liveUserData ?? widget.userData;

    if (isSuperAdmin) {
      switch (_currentNavIndex) {
        case 0:
          return _buildBerandaContent(initials, username, role, email);
        case 1:
          return RiwayatTransaksiPage(
            userData: effectiveData,
            showBottomNav: false,
          );
        case 2:
          return KelolaStokJasaPage(
            userData: effectiveData,
            showBottomNav: false,
          );
        case 3:
          return LaporanPendapatanPage(
            userData: effectiveData,
            showBottomNav: false,
          );
        case 4:
          return MengelolaUserPage(
            userData: effectiveData,
            showBottomNav: false,
          );
        case 5:
        default:
          return ProfilPage(
            userData: effectiveData,
            showBottomNav: false,
          );
      }
    } else {
      switch (_currentNavIndex) {
        case 0:
          return _buildBerandaContent(initials, username, role, email);
        case 1:
          return RiwayatTransaksiPage(
            userData: effectiveData,
            showBottomNav: false,
          );
        case 2:
          return KelolaStokJasaPage(
            userData: effectiveData,
            showBottomNav: false,
          );
        case 3:
          return LaporanPendapatanPage(
            userData: effectiveData,
            showBottomNav: false,
          );
        case 4:
        default:
          return ProfilPage(
            userData: effectiveData,
            showBottomNav: false,
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    final String email = _liveUserData?['email'] ??
        widget.userData?['email'] ??
        currentUser?.email ??
        '-';
    final String username = _liveUserData?['nama_lengkap'] ??
        widget.userData?['nama_lengkap'] ??
        currentUser?.displayName ??
        'Pengguna';
    final String role = _liveUserData?['role'] ?? widget.userData?['role'] ?? 'Kasir';
    final String initials = _getUserInitials(username);
    final isSuperAdmin = _isSuperAdmin;

    return Scaffold(
      backgroundColor: bgDark,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            children: <Widget>[
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final bool isIncoming = child.key == ValueKey(_currentNavIndex);
          final begin = Offset(
            isIncoming
                ? (_isForward ? 1.0 : -1.0)
                : (_isForward ? -1.0 : 1.0),
            0.0,
          );
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: Offset.zero).animate(animation),
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentNavIndex),
          child: _buildActiveTab(isSuperAdmin, initials, username, role, email),
        ),
      ),
      bottomNavigationBar: MotoBottomNav(
        currentIndex: _currentNavIndex,
        userData: _liveUserData ?? widget.userData,
        onTabSelected: _switchTab,
      ),
    );
  }

  // --- HELPER FORMAT TANGGAL & ANGKA RINGKAS ---

  String _formatTodayBadge(DateTime dt) {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sept',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${hari[dt.weekday - 1]}, ${dt.day} ${bulan[dt.month - 1]}';
  }

  static String formatCompactAxis(int val) {
    if (val <= 0) return '0';
    if (val >= 1000000) {
      final jt = val / 1000000.0;
      return (jt == jt.roundToDouble())
          ? '${jt.toInt()}jt'
          : '${jt.toStringAsFixed(1)}jt';
    }
    if (val >= 1000) {
      final k = val / 1000.0;
      return (k == k.roundToDouble())
          ? '${k.toInt()}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return val.toString();
  }

  String _formatCompactRp(int val) {
    if (val <= 0) return 'Rp 0';
    return 'Rp ${formatCompactAxis(val)}';
  }

  int _computeNiceStep(int maxVal) {
    if (maxVal <= 0) return 50000;
    if (maxVal <= 15000) return 5000;
    final raw = maxVal / 3.0;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toInt();
    final norm = raw / magnitude;
    if (norm <= 1.0) return magnitude;
    if (norm <= 2.0) return 2 * magnitude;
    if (norm <= 2.5) return (2.5 * magnitude).round();
    if (norm <= 5.0) return 5 * magnitude;
    return 10 * magnitude;
  }

  List<_HourBucket> _buildTodayHourBuckets(List<TransaksiPenjualanModel> todayTrx) {
    if (todayTrx.isEmpty) {
      return List.generate(10, (i) {
        final h = 8 + i;
        final hStr = h.toString().padLeft(2, '0');
        return _HourBucket(
          label: hStr,
          rangeLabel: '$hStr:00 WIB',
          servis: 0,
          barang: 0,
          omzet: 0,
          trxCount: 0,
        );
      });
    }

    int minH = 23;
    int maxH = 0;
    for (final t in todayTrx) {
      if (t.dateTime.hour < minH) minH = t.dateTime.hour;
      if (t.dateTime.hour > maxH) maxH = t.dateTime.hour;
    }

    int startH = math.min(8, minH);
    int endH = math.max(17, maxH);
    final int span = endH - startH + 1;
    final int step = span <= 12 ? 1 : 2;
    if (step == 2 && (endH - startH) % 2 == 0) {
      endH = math.min(23, endH + 1);
    }

    final List<_HourBucket> buckets = [];
    for (int h = startH; h <= endH; h += step) {
      final int bucketEnd = math.min(24, h + step);
      int sSum = 0;
      int pSum = 0;
      int oSum = 0;
      int count = 0;

      for (final t in todayTrx) {
        if (t.dateTime.hour >= h && t.dateTime.hour < bucketEnd) {
          count++;
          int itemTotal = 0;
          for (final item in t.items) {
            final bool isJasa = item.isService == true ||
                item.category.toLowerCase().contains('jasa') ||
                item.category.toLowerCase().contains('servis');
            final int sub = item.price * item.quantity;
            itemTotal += sub;
            if (isJasa) {
              sSum += sub;
            } else {
              pSum += sub;
            }
          }
          oSum += t.totalBayar > 0 ? t.totalBayar : itemTotal;
        }
      }

      final hStr = h.toString().padLeft(2, '0');
      final endStr = (bucketEnd - 1).toString().padLeft(2, '0');
      buckets.add(
        _HourBucket(
          label: hStr,
          rangeLabel: step == 1 ? '$hStr:00 WIB' : '$hStr:00 - $endStr:59 WIB',
          servis: sSum,
          barang: pSum,
          omzet: oSum,
          trxCount: count,
        ),
      );
    }
    return buckets;
  }

  // --- WIDGET KOMPONEN ---

  Widget _buildBerandaContent(String initials, String username, String role, String email) {
    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          TransaksiService().transactionsNotifier,
          BarangService().barangsNotifier,
        ]),
        builder: (context, _) {
          final now = DateTime.now();
          final allTrx = TransaksiService().transactions;
          final validTrx = allTrx
              .where((t) => t.status.toLowerCase() != 'batal')
              .toList();

          final todayTrx = validTrx.where((t) {
            return t.dateTime.year == now.year &&
                t.dateTime.month == now.month &&
                t.dateTime.day == now.day;
          }).toList();

          int todayOmzet = 0;
          int todayServis = 0;
          int todayBarang = 0;

          for (final t in todayTrx) {
            int trxItemSum = 0;
            for (final item in t.items) {
              final bool isJasa = item.isService == true ||
                  item.category.toLowerCase().contains('jasa') ||
                  item.category.toLowerCase().contains('servis');
              final int sub = item.price * item.quantity;
              trxItemSum += sub;
              if (isJasa) {
                todayServis += sub;
              } else {
                todayBarang += sub;
              }
            }
            todayOmzet += t.totalBayar > 0 ? t.totalBayar : trxItemSum;
          }

          final yesterday = DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 1));
          final int yesterdayOmzet = validTrx
              .where((t) =>
                  t.dateTime.year == yesterday.year &&
                  t.dateTime.month == yesterday.month &&
                  t.dateTime.day == yesterday.day)
              .fold<int>(0, (sum, t) => sum + t.totalBayar);

          final buckets = _buildTodayHourBuckets(todayTrx);

          final allBarangs = BarangService().barangs;
          final lowStockItems = allBarangs
              .where((b) => b.stock <= 5)
              .toList()
            ..sort((a, b) => a.stock.compareTo(b.stock));

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(initials, username, role, email),
                const SizedBox(height: 20),
                _buildOmzetCard(
                  todayOmzet: todayOmzet,
                  todayTrxCount: todayTrx.length,
                  yesterdayOmzet: yesterdayOmzet,
                ),
                const SizedBox(height: 16),
                _buildChartCard(
                  now: now,
                  hasTodayTransactions: todayTrx.isNotEmpty && todayOmzet > 0,
                  todayOmzet: todayOmzet,
                  todayServis: todayServis,
                  todayBarang: todayBarang,
                  buckets: buckets,
                ),
                const SizedBox(height: 24),
                _buildStokMenipisSection(lowStockItems, allBarangs.isEmpty),
                const SizedBox(height: 24),
                _buildTransaksiTerakhirSection(validTrx, now),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String initials, String username, String role, String email) {
    return Row(
      children: [
        // Lingkaran Avatar dengan Border Merah
        GestureDetector(
          onTap: () => _switchTab(_isSuperAdmin ? 5 : 4),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgDark,
              shape: BoxShape.circle,
              border: Border.all(color: accentRed, width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Nama dan Role Badge (Responsif)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  color: textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentRed, width: 1),
                ),
                child: Text(
                  role,
                  style: const TextStyle(
                    color: accentRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOmzetCard({
    required int todayOmzet,
    required int todayTrxCount,
    required int yesterdayOmzet,
  }) {
    final bool hasTrx = todayTrxCount > 0 && todayOmzet > 0;
    String? diffBadge;
    bool isDiffPositive = true;
    if (hasTrx && yesterdayOmzet > 0) {
      final double pct = ((todayOmzet - yesterdayOmzet) / yesterdayOmzet) * 100;
      isDiffPositive = pct >= 0;
      final String sign = isDiffPositive ? '+' : '';
      diffBadge = '$sign${pct.toStringAsFixed(0)}% vs kemarin';
    }

    return GestureDetector(
      onTap: () => _switchTab(3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardBg,
              hasTrx ? const Color(0xFF13221C) : const Color(0xFF141822),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasTrx
                ? accentGreen.withValues(alpha: 0.35)
                : cardBorder,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Omzet Hari Ini',
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatRupiah(todayOmzet),
              style: TextStyle(
                color: hasTrx ? textWhite : textMuted,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasTrx
                        ? const Color(0xFF0F2B1D)
                        : const Color(0xFF1A1E2B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasTrx
                          ? const Color(0xFF166534)
                          : cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasTrx
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        size: 12,
                        color: hasTrx ? accentGreen : textDim,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hasTrx
                            ? '$todayTrxCount Transaksi Hari Ini'
                            : 'Belum ada transaksi hari ini',
                        style: TextStyle(
                          color: hasTrx ? accentGreen : textDim,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (diffBadge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDiffPositive
                          ? accentGreen.withValues(alpha: 0.12)
                          : accentRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      diffBadge,
                      style: TextStyle(
                        color: isDiffPositive ? accentGreen : accentRed,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required DateTime now,
    required bool hasTodayTransactions,
    required int todayOmzet,
    required int todayServis,
    required int todayBarang,
    required List<_HourBucket> buckets,
  }) {
    int maxBucketOmzet = 0;
    int peakIndex = -1;
    for (int i = 0; i < buckets.length; i++) {
      if (buckets[i].omzet > maxBucketOmzet) {
        maxBucketOmzet = buckets[i].omzet;
        peakIndex = i;
      }
    }

    final int yStep = _computeNiceStep(maxBucketOmzet);
    final int yMax = yStep * 3;

    final int? safeTappedIndex = (_tappedHourIndex != null &&
            _tappedHourIndex! >= 0 &&
            _tappedHourIndex! < buckets.length &&
            hasTodayTransactions)
        ? _tappedHourIndex
        : null;

    final int? activeHighlightIndex =
        hasTodayTransactions ? (safeTappedIndex ?? (peakIndex >= 0 ? peakIndex : null)) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Atas: Judul, Badge Tanggal Real-Time, Tombol Detail
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Grafik Omzet Hari Ini',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentRed.withValues(alpha: 0.6), width: 1),
                ),
                child: Text(
                  _formatTodayBadge(now),
                  style: const TextStyle(
                    color: accentRed,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _switchTab(3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2333),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Detail ›',
                    style: TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Baris Legend Dinamis: Omzet, Servis & Barang
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildLegendItem(
                color: accentGreen,
                label: 'Omzet (${_formatCompactRp(todayOmzet)})',
              ),
              _buildLegendItem(
                color: accentRed,
                label: 'Servis (${_formatCompactRp(todayServis)})',
              ),
              _buildLegendItem(
                color: accentBlue,
                label: 'Barang (${_formatCompactRp(todayBarang)})',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Line Chart Area (Interaktif saat ada transaksi, kosong bersih saat tidak ada transaksi)
          LayoutBuilder(
            builder: (context, constraints) {
              const double leftGutter = 36.0;
              const double rightGutter = 10.0;
              final double usableWidth =
                  math.max(1.0, constraints.maxWidth - leftGutter - rightGutter);
              final double stepX = buckets.length > 1
                  ? usableWidth / (buckets.length - 1)
                  : usableWidth;

              void handleChartTouch(Offset localPos) {
                if (!hasTodayTransactions || buckets.isEmpty) return;
                final int idx =
                    ((localPos.dx - leftGutter + stepX / 2) / stepX).floor();
                if (idx >= 0 && idx < buckets.length) {
                  setState(() {
                    _tappedHourIndex = idx;
                  });
                }
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: hasTodayTransactions
                    ? (details) {
                        final int idx =
                            ((details.localPosition.dx - leftGutter + stepX / 2) / stepX)
                                .floor();
                        if (idx >= 0 && idx < buckets.length) {
                          setState(() {
                            _tappedHourIndex =
                                (_tappedHourIndex == idx) ? null : idx;
                          });
                        }
                      }
                    : null,
                onHorizontalDragUpdate: hasTodayTransactions
                    ? (details) => handleChartTouch(details.localPosition)
                    : null,
                child: SizedBox(
                  height: 142,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _HourlyOmzetChartPainter(
                      buckets: buckets,
                      hasData: hasTodayTransactions,
                      yMax: yMax,
                      yStep: yStep,
                      highlightIndex: activeHighlightIndex,
                    ),
                  ),
                ),
              );
            },
          ),

          // Info Rincian Jam Terpilih / Puncak (Hanya muncul bila hari ini ada transaksi)
          if (hasTodayTransactions && activeHighlightIndex != null) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final b = buckets[activeHighlightIndex];
                final bool isManualTap = safeTappedIndex != null;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101926),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isManualTap
                            ? Icons.touch_app_rounded
                            : Icons.trending_up_rounded,
                        color: accentGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '${b.rangeLabel} • Omzet ${formatRupiah(b.omzet)} (Servis ${formatRupiah(b.servis)} • Barang ${formatRupiah(b.barang)})',
                          style: const TextStyle(
                            color: textWhite,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isManualTap)
                        GestureDetector(
                          onTap: () => setState(() => _tappedHourIndex = null),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.close_rounded,
                              color: textDim,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStokMenipisSection(List<BarangModel> lowStockItems, bool isCatalogEmpty) {
    final previewItems = lowStockItems.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Stok Menipis',
              style: TextStyle(
                color: textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DataBarangPage(
                      userData: _liveUserData ?? widget.userData,
                    ),
                  ),
                );
              },
              child: Text(
                'Semua (${lowStockItems.length}) >',
                style: const TextStyle(
                  color: accentRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (previewItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentGreen.withValues(alpha: 0.14),
                    border: Border.all(color: accentGreen.withValues(alpha: 0.6)),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: accentGreen,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCatalogEmpty
                            ? 'Belum ada master data barang'
                            : 'Semua stok barang aman',
                        style: const TextStyle(
                          color: textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCatalogEmpty
                            ? 'Tambahkan barang lewat menu Stok atau Pengadaan'
                            : 'Tidak ada barang dengan sisa stok ≤ 5 pcs',
                        style: const TextStyle(
                          color: textDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(previewItems.length, (idx) {
            final item = previewItems[idx];
            final unitLower = item.unit.isNotEmpty ? item.unit.toLowerCase() : 'pcs';
            final sub = item.stock <= 0
                ? 'Stok habis (0 $unitLower) • ${item.category}'
                : 'Sisa ${item.stock} $unitLower • ${item.category}';
            return Padding(
              padding: EdgeInsets.only(
                bottom: idx == previewItems.length - 1 ? 0 : 10,
              ),
              child: _buildStokItem(
                title: item.name,
                subtitle: sub,
                isCritical: item.isCritical,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStokItem({
    required String title,
    required String subtitle,
    required bool isCritical,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCritical
                  ? accentRed.withValues(alpha: 0.15)
                  : accentYellow.withValues(alpha: 0.15),
              border: Border.all(
                color: isCritical ? accentRed : accentYellow,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '!',
                style: TextStyle(
                  color: isCritical ? accentRed : accentYellow,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: textDim,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PengadaanRestockPage(
                    userData: _liveUserData ?? widget.userData,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isCritical ? accentRed : const Color(0xFF1D2333),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Restock',
                style: TextStyle(
                  color: isCritical ? textWhite : const Color(0xFFE2E8F0),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaksiTerakhirSection(
    List<TransaksiPenjualanModel> validTrx,
    DateTime now,
  ) {
    final recentList = validTrx.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi Terakhir',
              style: TextStyle(
                color: textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () => _switchTab(1),
              child: const Text(
                'Riwayat >',
                style: TextStyle(
                  color: accentRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (recentList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191D2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: textDim,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Belum ada transaksi penjualan',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Transaksi kasir terbaru akan otomatis tampil di sini',
                        style: TextStyle(
                          color: textDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(recentList.length, (idx) {
            final trx = recentList[idx];
            final bool isToday = trx.dateTime.year == now.year &&
                trx.dateTime.month == now.month &&
                trx.dateTime.day == now.day;
            final String hh = trx.dateTime.hour.toString().padLeft(2, '0');
            final String mm = trx.dateTime.minute.toString().padLeft(2, '0');
            final String timeLabel = isToday
                ? 'Hari ini, $hh:$mm • ${trx.paymentMethod}'
                : '${trx.dateFormatted} $hh:$mm • ${trx.paymentMethod}';

            String mainTitle;
            if (trx.vehicleInfo.trim().isNotEmpty) {
              mainTitle = trx.customerName.trim().isNotEmpty
                  ? '${trx.vehicleInfo} • ${trx.customerName}'
                  : trx.vehicleInfo;
            } else if (trx.customerName.trim().isNotEmpty) {
              mainTitle = trx.customerName;
            } else {
              mainTitle = trx.code;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: idx == recentList.length - 1 ? 0 : 10,
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotaPembayaranPage(
                        transaksi: trx,
                        userData: _liveUserData ?? widget.userData,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF191D2A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.two_wheeler_rounded,
                            color: accentRed,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mainTitle,
                              style: const TextStyle(
                                color: textWhite,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeLabel,
                              style: const TextStyle(
                                color: textDim,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatRupiah(trx.totalBayar),
                        style: const TextStyle(
                          color: accentGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _HourBucket {
  final String label;
  final String rangeLabel;
  final int servis;
  final int barang;
  final int omzet;
  final int trxCount;

  const _HourBucket({
    required this.label,
    required this.rangeLabel,
    required this.servis,
    required this.barang,
    required this.omzet,
    required this.trxCount,
  });
}

/// CustomPainter Dinamis untuk Grafik Omzet, Servis & Barang Harian di Beranda
class _HourlyOmzetChartPainter extends CustomPainter {
  final List<_HourBucket> buckets;
  final bool hasData;
  final int yMax;
  final int yStep;
  final int? highlightIndex;

  _HourlyOmzetChartPainter({
    required this.buckets,
    required this.hasData,
    required this.yMax,
    required this.yStep,
    required this.highlightIndex,
  });

  Path _buildSmoothMonotonicPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final dx = (p1.dx - p0.dx) * 0.42;
      path.cubicTo(
        p0.dx + dx,
        p0.dy,
        p1.dx - dx,
        p1.dy,
        p1.dx,
        p1.dy,
      );
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty) return;

    const double leftGutter = 36.0;
    const double rightGutter = 10.0;
    const double bottomGutter = 20.0;
    const double topGutter = 24.0;

    final double chartWidth = math.max(1.0, size.width - leftGutter - rightGutter);
    final double chartHeight = math.max(1.0, size.height - bottomGutter - topGutter);
    final double bottomY = topGutter + chartHeight;

    final List<String> yLabels = hasData
        ? [
            _BerandaPageState.formatCompactAxis(yStep * 3),
            _BerandaPageState.formatCompactAxis(yStep * 2),
            _BerandaPageState.formatCompactAxis(yStep),
            '0',
          ]
        : ['150k', '100k', '50k', '0'];

    const textStyle = TextStyle(
      color: Color(0xFF64748B),
      fontSize: 8.5,
      fontWeight: FontWeight.w500,
    );

    // 1. Gambar Y-Axis Labels & Garis Grid Horizontal
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2433)
      ..strokeWidth = 1.0;

    for (int i = 0; i < yLabels.length; i++) {
      final double y = topGutter + (chartHeight / (yLabels.length - 1)) * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: yLabels[i],
          style: hasData
              ? textStyle
              : textStyle.copyWith(
                  color: i == yLabels.length - 1
                      ? const Color(0xFF64748B)
                      : const Color(0xFF334155),
                ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(leftGutter - textPainter.width - 6, y - textPainter.height / 2),
      );

      canvas.drawLine(
        Offset(leftGutter, y),
        Offset(size.width - rightGutter, y),
        gridPaint,
      );
    }

    final double stepX =
        buckets.length > 1 ? chartWidth / (buckets.length - 1) : chartWidth;

    // 2. Gambar Label Jam X-Axis
    for (int i = 0; i < buckets.length; i++) {
      final double x = leftGutter + i * stepX;
      final bool isHighlighted = hasData && highlightIndex == i;
      final xPainter = TextPainter(
        text: TextSpan(
          text: buckets[i].label,
          style: textStyle.copyWith(
            color: isHighlighted
                ? const Color(0xFF22C55E)
                : const Color(0xFF64748B),
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      xPainter.paint(
        canvas,
        Offset(x - xPainter.width / 2, size.height - bottomGutter + 4),
      );
    }

    // 3. Jika Hari Ini Belum Ada Transaksi -> Chart Kosong Tanpa Value Palsu
    if (!hasData || yMax <= 0) {
      final zeroLinePaint = Paint()
        ..color = const Color(0xFF2B3348)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(leftGutter, bottomY),
        Offset(size.width - rightGutter, bottomY),
        zeroLinePaint,
      );

      const emptyText = 'Belum ada omzet hari ini';
      final emptyPainter = TextPainter(
        text: const TextSpan(
          text: emptyText,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double pillW = emptyPainter.width + 24;
      final double pillH = emptyPainter.height + 12;
      final Offset center = Offset(
        leftGutter + chartWidth / 2,
        topGutter + chartHeight / 2,
      );
      final RRect pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: pillW, height: pillH),
        const Radius.circular(20),
      );

      canvas.drawRRect(
        pillRect,
        Paint()..color = const Color(0xFF10131B).withValues(alpha: 0.92),
      );
      canvas.drawRRect(
        pillRect,
        Paint()
          ..color = const Color(0xFF222634)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      emptyPainter.paint(
        canvas,
        Offset(
          center.dx - emptyPainter.width / 2,
          center.dy - emptyPainter.height / 2,
        ),
      );
      return;
    }

    // 4. Hitung Titik Koordinat Data Riil (Omzet, Servis, Barang)
    final omzetPoints = <Offset>[];
    final servisPoints = <Offset>[];
    final barangPoints = <Offset>[];

    for (int i = 0; i < buckets.length; i++) {
      final double x = leftGutter + i * stepX;
      final double rOmzet = (buckets[i].omzet / yMax).clamp(0.0, 1.0);
      final double rServis = (buckets[i].servis / yMax).clamp(0.0, 1.0);
      final double rBarang = (buckets[i].barang / yMax).clamp(0.0, 1.0);

      omzetPoints.add(Offset(x, topGutter + (1.0 - rOmzet) * chartHeight));
      servisPoints.add(Offset(x, topGutter + (1.0 - rServis) * chartHeight));
      barangPoints.add(Offset(x, topGutter + (1.0 - rBarang) * chartHeight));
    }

    // 5. Gradient Area di bawah Garis Omzet
    final omzetCurve = _buildSmoothMonotonicPath(omzetPoints);
    final fillPath = Path.from(omzetCurve)
      ..lineTo(omzetPoints.last.dx, bottomY)
      ..lineTo(omzetPoints.first.dx, bottomY)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF22C55E).withValues(alpha: 0.26),
          const Color(0xFF22C55E).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(leftGutter, topGutter, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // 6. Garis Putus-Putus Vertikal pada Jam Aktif / Puncak
    if (highlightIndex != null &&
        highlightIndex! >= 0 &&
        highlightIndex! < omzetPoints.length) {
      final activePt = omzetPoints[highlightIndex!];
      final dashPaint = Paint()
        ..color = const Color(0xFF22C55E).withValues(alpha: 0.65)
        ..strokeWidth = 1.1;

      double curY = activePt.dy;
      while (curY < bottomY) {
        canvas.drawLine(
          Offset(activePt.dx, curY),
          Offset(activePt.dx, (curY + 3.0).clamp(topGutter, bottomY)),
          dashPaint,
        );
        curY += 6.0;
      }
    }

    // 7. Gambar Garis Barang (Biru) & Servis (Merah) & Omzet (Hijau)
    canvas.drawPath(
      _buildSmoothMonotonicPath(barangPoints),
      Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.9)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );

    canvas.drawPath(
      _buildSmoothMonotonicPath(servisPoints),
      Paint()
        ..color = const Color(0xFFFF1E27).withValues(alpha: 0.9)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );

    canvas.drawPath(
      omzetCurve,
      Paint()
        ..color = const Color(0xFF22C55E)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke,
    );

    // 8. Gambar Titik Node pada Jam yang Memiliki Nilai (atau Titik Terpilih)
    final whitePaint = Paint()..color = Colors.white;
    final greenPaint = Paint()..color = const Color(0xFF22C55E);
    final redPaint = Paint()..color = const Color(0xFFFF1E27);
    final bluePaint = Paint()..color = const Color(0xFF3B82F6);

    for (int i = 0; i < buckets.length; i++) {
      final bool isHi = highlightIndex == i;
      final bool hasBucketVal = buckets[i].omzet > 0;

      if (buckets[i].barang > 0 || isHi) {
        canvas.drawCircle(barangPoints[i], isHi ? 3.5 : 2.8, bluePaint);
        canvas.drawCircle(barangPoints[i], 1.4, whitePaint);
      }
      if (buckets[i].servis > 0 || isHi) {
        canvas.drawCircle(servisPoints[i], isHi ? 3.5 : 2.8, redPaint);
        canvas.drawCircle(servisPoints[i], 1.4, whitePaint);
      }
      if (hasBucketVal || isHi) {
        if (isHi) {
          canvas.drawCircle(
            omzetPoints[i],
            7.0,
            Paint()..color = const Color(0xFF22C55E).withValues(alpha: 0.22),
          );
        }
        canvas.drawCircle(omzetPoints[i], isHi ? 4.2 : 3.4, greenPaint);
        canvas.drawCircle(omzetPoints[i], 1.8, whitePaint);
      }
    }

    // 9. Badge Nominal Omzet di Atas Titik Puncak / Terpilih
    if (highlightIndex != null &&
        highlightIndex! >= 0 &&
        highlightIndex! < buckets.length) {
      final activePt = omzetPoints[highlightIndex!];
      final int activeOmzet = buckets[highlightIndex!].omzet;
      final String badgeText = _BerandaPageState.formatCompactAxis(activeOmzet);

      final badgePainter = TextPainter(
        text: TextSpan(
          text: badgeText,
          style: const TextStyle(
            color: Color(0xFF22C55E),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double badgeW = math.max(30.0, badgePainter.width + 12);
      const double badgeH = 16.0;
      final double clampedX = activePt.dx.clamp(
        leftGutter + badgeW / 2,
        size.width - rightGutter - badgeW / 2,
      );
      final double clampedY =
          (activePt.dy - 14).clamp(badgeH / 2 + 1, bottomY - badgeH / 2 - 4);

      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(clampedX, clampedY),
          width: badgeW,
          height: badgeH,
        ),
        const Radius.circular(5),
      );

      canvas.drawRRect(badgeRect, Paint()..color = const Color(0xFF0F291E));
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..color = const Color(0xFF22C55E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      badgePainter.paint(
        canvas,
        Offset(
          clampedX - badgePainter.width / 2,
          clampedY - badgePainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyOmzetChartPainter oldDelegate) {
    return oldDelegate.hasData != hasData ||
        oldDelegate.yMax != yMax ||
        oldDelegate.highlightIndex != highlightIndex ||
        oldDelegate.buckets != buckets;
  }
}
