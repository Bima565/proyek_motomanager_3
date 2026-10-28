import 'package:flutter/material.dart';

/// Modal dialog kalender custom tema gelap MotoManage.
/// Fitur:
/// - Pilihan tanggal per hari (grid 7 hari, bahasa Indonesia: Min, Sen, Sel, Rab, Kam, Jum, Sab)
/// - Tampilan timpa pop-up untuk Bulan (12 bulan grid) dan Tahun (dinamis sesuai tahun sekarang)
/// - Tombol Today, OK, Cancel
class CustomCalendarDialog extends StatefulWidget {
  final DateTime initialDate;

  const CustomCalendarDialog({
    super.key,
    required this.initialDate,
  });

  /// Helper statis untuk memanggil dialog kalender secara ringkas:
  /// ```dart
  /// final selected = await CustomCalendarDialog.show(context, initialDate: _startDate);
  /// if (selected != null) { ... }
  /// ```
  static Future<DateTime?> show(BuildContext context, {required DateTime initialDate}) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => CustomCalendarDialog(initialDate: initialDate),
    );
  }

  @override
  State<CustomCalendarDialog> createState() => _CustomCalendarDialogState();
}

class _CustomCalendarDialogState extends State<CustomCalendarDialog> {
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF6B7280);
  static const Color inputBg = Color(0xFF0E1015);

  late DateTime _tempDate;
  late DateTime _viewMonth;
  String _viewMode = 'day'; // 'day' | 'month' | 'year'

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _tempDate = widget.initialDate;
    _viewMonth = DateTime(_tempDate.year, _tempDate.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_viewMonth.year, _viewMonth.month);
    final firstDayOffset = DateTime(_viewMonth.year, _viewMonth.month, 1).weekday % 7;

    final int currentYear = DateTime.now().year;
    final List<int> yearsList = List.generate(36, (i) => (currentYear - 10) + i);

    return Dialog(
      backgroundColor: cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: cardBorder, width: 1),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 345),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header Bulan, Tahun & Navigasi
            Row(
              children: [
                // Tombol Timpa Pop-up Pilih Bulan
                InkWell(
                  onTap: () {
                    setState(() {
                      _viewMode = (_viewMode == 'month') ? 'day' : 'month';
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _viewMode == 'month' ? accentRed.withValues(alpha: 0.2) : cardBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _viewMode == 'month' ? accentRed : cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _monthNames[_viewMonth.month - 1],
                          style: TextStyle(
                            color: _viewMode == 'month' ? accentRed : textWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _viewMode == 'month' ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                          color: _viewMode == 'month' ? accentRed : textMuted,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Tombol Timpa Pop-up Pilih Tahun
                InkWell(
                  onTap: () {
                    setState(() {
                      _viewMode = (_viewMode == 'year') ? 'day' : 'year';
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _viewMode == 'year' ? accentRed.withValues(alpha: 0.2) : cardBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _viewMode == 'year' ? accentRed : cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_viewMonth.year}',
                          style: TextStyle(
                            color: _viewMode == 'year' ? accentRed : textWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _viewMode == 'year' ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                          color: _viewMode == 'year' ? accentRed : textMuted,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Tombol Navigasi Prev & Next Bulan (Hanya saat mode kalender hari)
                if (_viewMode == 'day') ...[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
                      });
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2333),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cardBorder),
                      ),
                      child: const Center(
                        child: Icon(Icons.chevron_left_rounded, color: textWhite, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
                      });
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2333),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cardBorder),
                      ),
                      child: const Center(
                        child: Icon(Icons.chevron_right_rounded, color: textWhite, size: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // 2. Body Dialog Kalender
            if (_viewMode == 'month') ...[
              // Grid 12 Bulan
              SizedBox(
                height: 230,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final isCurrentMonth = (index + 1) == _viewMonth.month;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _viewMonth = DateTime(_viewMonth.year, index + 1, 1);
                          _viewMode = 'day';
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrentMonth ? const Color(0xFF007BFF) : inputBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrentMonth ? const Color(0xFF007BFF) : cardBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _monthNames[index],
                            style: TextStyle(
                              color: isCurrentMonth ? textWhite : const Color(0xFFCBD5E1),
                              fontSize: 12,
                              fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (_viewMode == 'year') ...[
              // Grid Pilihan Tahun Dinamis
              SizedBox(
                height: 230,
                child: GridView.builder(
                  itemCount: yearsList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final year = yearsList[index];
                    final isCurrentYear = year == _viewMonth.year;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _viewMonth = DateTime(year, _viewMonth.month, 1);
                          _viewMode = 'day';
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrentYear ? const Color(0xFF007BFF) : inputBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrentYear ? const Color(0xFF007BFF) : cardBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$year',
                            style: TextStyle(
                              color: isCurrentYear ? textWhite : const Color(0xFFCBD5E1),
                              fontSize: 13,
                              fontWeight: isCurrentYear ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              // Grid Hari Kalender (Bahasa Indonesia)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Text('Min', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('Sen', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('Sel', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('Rab', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('Kam', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('Jum', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('Sab', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 42,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final dayNumber = index - firstDayOffset + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox();
                  }

                  final currentCalDate = DateTime(_viewMonth.year, _viewMonth.month, dayNumber);
                  final isSelected = currentCalDate.year == _tempDate.year &&
                      currentCalDate.month == _tempDate.month &&
                      currentCalDate.day == _tempDate.day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _tempDate = currentCalDate;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF007BFF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: isSelected ? textWhite : const Color(0xFFCBD5E1),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),

            // 3. Footer Action (Today, OK, Cancel)
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _tempDate = now;
                      _viewMonth = DateTime(now.year, now.month, 1);
                      _viewMode = 'day';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: textWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: const Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _tempDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: textWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: const Text('OK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF475569),
                    foregroundColor: textWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
