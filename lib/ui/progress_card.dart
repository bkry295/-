import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'theme.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.habit, required this.now});
  final Habit habit;
  final DateTime now;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('実行の記録', style: Theme.of(context).textTheme.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: paleBlue,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Text(
                '日々の積み重ね',
                style: TextStyle(
                  fontSize: 10,
                  color: blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Metric(
                icon: Icons.local_fire_department_outlined,
                label: '連続',
                value: habit.streak(now),
                unit: '日',
                caption: '連続で実行中',
              ),
            ),
            const _MetricDivider(),
            Expanded(
              child: _Metric(
                icon: Icons.calendar_month_outlined,
                label: '累計',
                value: habit.total(now),
                unit: '回',
                caption: 'これまでの実行',
              ),
            ),
            const _MetricDivider(),
            Expanded(
              child: _Metric(
                icon: Icons.emoji_events_outlined,
                label: '達成率',
                value: habit.rate(now),
                unit: '%',
                caption: '開始日から今日',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Semantics(
          label: '累計の実行回数 ${habit.total(now)}回。直近30日間の推移。',
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(painter: _ChartPainter(habit, now)),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Icon(Icons.circle, size: 8, color: blue),
            SizedBox(width: 7),
            Text('実行回数の推移（累計）', style: TextStyle(fontSize: 11, color: muted)),
          ],
        ),
        if (habit.total(now) == 0) ...[
          const SizedBox(height: 16),
          const Text(
            '最初の一歩を、ここから。\n実行を記録するとグラフが育ちます。',
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ],
    ),
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 65,
    margin: const EdgeInsets.only(top: 53),
    color: border,
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.caption,
  });
  final IconData icon;
  final String label, unit, caption;
  final int value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      IconBubble(icon, size: 40),
      const SizedBox(height: 9),
      Text(label, style: const TextStyle(fontSize: 12)),
      const SizedBox(height: 3),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$value',
                style: const TextStyle(
                  fontSize: 34,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          style: const TextStyle(color: blue),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        caption,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 9, color: muted),
      ),
    ],
  );
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.habit, this.now);
  final Habit habit;
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    final days = math.min(habit.elapsedDays(now), 30);
    final end = calendarDate(now);
    final start = end.subtract(Duration(days: days - 1));
    final completed = habit.completedDates.toList()..sort();
    var count = completed
        .where((key) => key.compareTo(dateKey(start)) < 0)
        .length;
    final values = <int>[];
    for (var i = 0; i < days; i++) {
      if (habit.isDone(start.add(Duration(days: i)))) count++;
      values.add(count);
    }
    final maxY = math.max(4, (habit.total(now) / 4).ceil() * 4);
    final plot = Rect.fromLTRB(27, 9, size.width - 7, size.height - 27);
    final gridPaint = Paint()
      ..color = border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = plot.bottom - plot.height * i / 4;
      for (var x = plot.left; x < plot.right; x += 7) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 3, plot.right), y),
          gridPaint,
        );
      }
      _text(
        canvas,
        '${maxY * i ~/ 4}',
        Offset(plot.left - 7, y - 6),
        right: true,
      );
    }
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, gridPaint);
    final points = List.generate(
      values.length,
      (i) => Offset(
      days == 1 ? plot.left : plot.left + plot.width * i / (days - 1),
        plot.bottom - plot.height * values[i] / maxY,
      ),
    );
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    if (points.length > 1) {
      final area = Path.from(line)
        ..lineTo(plot.right, plot.bottom)
        ..lineTo(plot.left, plot.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [blue.withValues(alpha: .20), blue.withValues(alpha: .01)],
          ).createShader(plot),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round,
      );
    }
    for (var i = 0; i < points.length; i++) {
      if (i % math.max(1, days ~/ 12) == 0 || i == days - 1) {
        canvas.drawCircle(points[i], 3.2, Paint()..color = blue);
      }
    }
    canvas.drawCircle(
      points.last,
      6,
      Paint()
        ..color = blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final labels = days == 1
        ? [0]
        : <int>{0, (days - 1) ~/ 2, days - 1}.toList();
    for (final index in labels) {
      final date = start.add(Duration(days: index));
      final x = days == 1
          ? plot.left
          : plot.left + plot.width * index / (days - 1);
      _text(
        canvas,
        '${date.month}/${date.day}',
        Offset(x, plot.bottom + 10),
        right: days > 1 && index == days - 1,
        center: index != 0 && index != days - 1,
      );
    }
  }

  void _text(
    Canvas canvas,
    String value,
    Offset point, {
    bool right = false,
    bool center = false,
  }) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(color: muted, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(
      canvas,
      point.translate(
        right
            ? -text.width
            : center
            ? -text.width / 2
            : 0,
        0,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.habit != habit || dateKey(oldDelegate.now) != dateKey(now);
}
