import 'dart:math' as math;

import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/text/app_text_provider.dart';
import 'package:flutter/material.dart';

class CategoryWheelChart extends StatelessWidget {
  const CategoryWheelChart({
    super.key,
    required this.categoryTotals,
  });

  final List<CategoryExpenseTotal> categoryTotals;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final chartData = categoryTotals.where((item) => item.total > 0).toList();
    final total = chartData.fold<double>(0, (sum, item) => sum + item.total);

    if (chartData.isEmpty || total <= 0) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(text.noWheelData),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: 180,
            child: CustomPaint(
              painter: _WheelPainter(chartData),
              child: Center(
                child: Text(
                  total.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: chartData
                .map(
                  (entry) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(entry.category.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(text.wheelLegendLabel(entry.category.name, entry.total)),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.data);

  final List<CategoryExpenseTotal> data;

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<double>(0, (sum, item) => sum + item.total);
    if (total <= 0) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;
    for (final item in data) {
      final sweep = 2 * math.pi * (item.total / total);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = Color(item.category.color);
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }

    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.45, holePaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
