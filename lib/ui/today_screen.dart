import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'theme.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.habit,
    required this.now,
    required this.busy,
    required this.onComplete,
  });
  final Habit habit;
  final DateTime now;
  final bool busy;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final done = habit.isDone(now);
    return Scaffold(
      appBar: AppBar(title: const Text('今日のやること')),
      body: PageBody(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 18, top: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${now.month}月${now.day}日（${['月', '火', '水', '木', '金', '土', '日'][now.weekday - 1]}）',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                Text(
                  'はじめて ${habit.elapsedDays(now)} 日目',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconBubble(
                      done ? Icons.check_rounded : Icons.track_changes_rounded,
                      size: 49,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        habit.action,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: muted,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        habit.notificationsEnabled
                            ? '毎日 ${habit.timeLabel} に通知'
                            : '通知はオフ',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 13),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: done
                      ? Column(
                          key: const ValueKey('done'),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: paleBlue,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: blue),
                                  SizedBox(width: 9),
                                  Flexible(
                                    child: Text(
                                      '今日もできました！',
                                      style: TextStyle(
                                        color: blue,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: busy ? null : onComplete,
                              child: const Text(
                                '記録を取り消す',
                                style: TextStyle(fontSize: 11, color: muted),
                              ),
                            ),
                          ],
                        )
                      : PrimaryButton(
                          key: const ValueKey('complete'),
                          label: '今日の実行を完了',
                          icon: Icons.check_circle_outline_rounded,
                          busy: busy,
                          onPressed: onComplete,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 21),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.spa_outlined, size: 15, color: muted),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  done ? '今日の一歩が、明日の自分につながる。' : '完璧よりも、今日の小さな一歩。',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
