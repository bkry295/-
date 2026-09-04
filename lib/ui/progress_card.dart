import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'theme.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.habit, required this.now});
  final Habit habit;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
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
        ],
      ),
    );
  }
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
