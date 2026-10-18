import 'dart:math';

import 'package:flutter/material.dart';

import '../main.dart';

class FinanceTrendChart extends StatefulWidget {
  const FinanceTrendChart({super.key, required this.store});
  final BrainStore store;

  @override
  State<FinanceTrendChart> createState() => _FinanceTrendChartState();
}

class _FinanceTrendChartState extends State<FinanceTrendChart> {
  int _daysRange = 7; // 7 or 30

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: _daysRange - 1));

    // Group transactions by day
    final Map<int, double> dailyIncome = {};
    final Map<int, double> dailyExpense = {};

    for (int i = 0; i < _daysRange; i++) {
      dailyIncome[i] = 0.0;
      dailyExpense[i] = 0.0;
    }

    for (final t in widget.store.transactions) {
      final tDate = t.date;
      final diffDays = now
          .difference(DateTime(tDate.year, tDate.month, tDate.day))
          .inDays;
      if (diffDays >= 0 && diffDays < _daysRange) {
        final bucketIndex = _daysRange - 1 - diffDays;
        if (t.income) {
          dailyIncome[bucketIndex] =
              (dailyIncome[bucketIndex] ?? 0.0) + t.amount;
        } else {
          dailyExpense[bucketIndex] =
              (dailyExpense[bucketIndex] ?? 0.0) + t.amount;
        }
      }
    }

    final totalIncomeInRange = dailyIncome.values.fold(
      0.0,
      (sum, v) => sum + v,
    );
    final totalExpenseInRange = dailyExpense.values.fold(
      0.0,
      (sum, v) => sum + v,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tren Arus Kas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pemasukan vs Pengeluaran ($_daysRange Hari Terakhir)',
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Range Toggle Chips
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 7,
                      label: Text('7 Hari', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: 30,
                      label: Text('30 Hari', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {_daysRange},
                  onSelectionChanged: (val) {
                    setState(() => _daysRange = val.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mini summary row
            Row(
              children: [
                _buildSummaryBadge(
                  'Masuk: ${money(totalIncomeInRange)}',
                  green,
                  greenLight,
                ),
                const SizedBox(width: 8),
                _buildSummaryBadge(
                  'Keluar: ${money(totalExpenseInRange)}',
                  coral,
                  coralLight,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Custom Chart Canvas
            SizedBox(
              height: 160,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendChartPainter(
                  dailyIncome: dailyIncome,
                  dailyExpense: dailyExpense,
                  daysCount: _daysRange,
                  startDate: startDate,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Pemasukan', green),
                const SizedBox(width: 20),
                _buildLegendItem('Pengeluaran', coral),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.dailyIncome,
    required this.dailyExpense,
    required this.daysCount,
    required this.startDate,
  });

  final Map<int, double> dailyIncome;
  final Map<int, double> dailyExpense;
  final int daysCount;
  final DateTime startDate;

  @override
  void paint(Canvas canvas, Size size) {
    final double paddingLeft = 10;
    final double paddingRight = 10;
    final double paddingTop = 15;
    final double paddingBottom = 25;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Determine max value for scaling
    double maxVal = 100000; // minimum baseline
    for (final val in dailyIncome.values) {
      if (val > maxVal) maxVal = val;
    }
    for (final val in dailyExpense.values) {
      if (val > maxVal) maxVal = val;
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE0E5E2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 3; i++) {
      final y = paddingTop + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );
    }

    // Bar drawing
    final slotWidth = chartWidth / daysCount;
    final barWidth = max(2.0, min(12.0, (slotWidth - 4) / 2));

    final incomePaint = Paint()
      ..color = green
      ..style = PaintingStyle.fill;

    final expensePaint = Paint()
      ..color = coral
      ..style = PaintingStyle.fill;

    for (int i = 0; i < daysCount; i++) {
      final centerX = paddingLeft + (i * slotWidth) + (slotWidth / 2);
      final income = dailyIncome[i] ?? 0.0;
      final expense = dailyExpense[i] ?? 0.0;

      final incomeHeight = (income / maxVal) * chartHeight;
      final expenseHeight = (expense / maxVal) * chartHeight;

      // Draw Income Bar (Left of center)
      if (incomeHeight > 0) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - barWidth - 1,
            paddingTop + chartHeight - incomeHeight,
            barWidth,
            incomeHeight,
          ),
          const Radius.circular(2),
        );
        canvas.drawRRect(rect, incomePaint);
      }

      // Draw Expense Bar (Right of center)
      if (expenseHeight > 0) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX + 1,
            paddingTop + chartHeight - expenseHeight,
            barWidth,
            expenseHeight,
          ),
          const Radius.circular(2),
        );
        canvas.drawRRect(rect, expensePaint);
      }

      // Draw day label if appropriate interval
      final shouldDrawLabel =
          daysCount == 7 || i % 5 == 0 || i == daysCount - 1;
      if (shouldDrawLabel) {
        final dayDate = startDate.add(Duration(days: i));
        final labelText = '${dayDate.day}/${dayDate.month}';
        final textSpan = TextSpan(
          text: labelText,
          style: const TextStyle(
            color: muted,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(centerX - (textPainter.width / 2), size.height - 18),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.daysCount != daysCount ||
        oldDelegate.dailyIncome != dailyIncome ||
        oldDelegate.dailyExpense != dailyExpense;
  }
}
