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

  String get _encouragement {
    final streak = habit.streak(now);
    if (streak <= 1) return '最初の一歩、おつかれさま！';
    if (streak < 7) return '継続$streak日目！ 今日も積み重ねました。';
    return '継続$streak日目！ すばらしい習慣です。';
  }

  @override
  Widget build(BuildContext context) {
    final done = habit.isDone(now);
    final diameter = (MediaQuery.sizeOf(context).width - 76).clamp(
      220.0,
      286.0,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('今日のやること')),
      body: PageBody(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
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
          const SizedBox(height: 25),
          Center(
            child: _RecordCircle(
              diameter: diameter,
              action: habit.action,
              done: done,
              busy: busy,
              onTap: done || busy ? null : onComplete,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: muted,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                habit.notificationsEnabled
                    ? '毎日 ${habit.timeLabel} に通知'
                    : '通知はオフ',
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 28),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: .96, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: done
                ? _Encouragement(
                    key: const ValueKey('encouragement'),
                    message: _encouragement,
                    busy: busy,
                    onUndo: onComplete,
                  )
                : const _BeforeRecordHint(key: ValueKey('before-record')),
          ),
        ],
      ),
    );
  }
}

class _RecordCircle extends StatelessWidget {
  const _RecordCircle({
    required this.diameter,
    required this.action,
    required this.done,
    required this.busy,
    required this.onTap,
  });

  final double diameter;
  final String action;
  final bool done;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: !done,
    enabled: !done && !busy,
    label: done ? '今日の分は記録済み' : '今日の分を記録する',
    child: SizedBox.square(
      dimension: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: done ? 1 : 0),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 11,
                strokeCap: StrokeCap.round,
                backgroundColor: const Color(0xFFDDECFB),
                color: blue,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  splashColor: blue.withValues(alpha: .10),
                  highlightColor: blue.withValues(alpha: .04),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: busy
                              ? const SizedBox.square(
                                  key: ValueKey('busy'),
                                  dimension: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                )
                              : Icon(
                                  done
                                      ? Icons.check_circle_rounded
                                      : Icons.touch_app_outlined,
                                  key: ValueKey(done),
                                  color: blue,
                                  size: 33,
                                ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          action,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          done ? '今日の記録済み' : '中央をタップして記録',
                          style: TextStyle(
                            fontSize: 11,
                            color: done ? blue : muted,
                            fontWeight: done
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BeforeRecordHint extends StatelessWidget {
  const _BeforeRecordHint({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.spa_outlined, size: 16, color: muted),
      SizedBox(width: 8),
      Flexible(
        child: Text(
          '完璧よりも、今日の小さな一歩。',
          style: TextStyle(color: muted, fontSize: 11),
        ),
      ),
    ],
  );
}

class _Encouragement extends StatelessWidget {
  const _Encouragement({
    super.key,
    required this.message,
    required this.busy,
    required this.onUndo,
  });

  final String message;
  final bool busy;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const IconBubble(Icons.spa_rounded, size: 48),
          const SizedBox(width: 11),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              decoration: BoxDecoration(
                color: paleBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: blue.withValues(alpha: .08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今日もできました！',
                    style: TextStyle(
                      color: blue,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 12, color: ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      TextButton(
        onPressed: busy ? null : onUndo,
        child: const Text(
          '記録を取り消す',
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ),
    ],
  );
}
