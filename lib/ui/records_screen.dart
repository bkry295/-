import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'progress_card.dart';
import 'theme.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({
    super.key,
    required this.habit,
    required this.now,
    required this.busy,
    required this.onToggle,
  });
  final Habit habit;
  final DateTime now;
  final bool busy;
  final Future<void> Function(DateTime) onToggle;
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late DateTime _month = DateTime.utc(widget.now.year, widget.now.month);

  Future<void> _selectDay(DateTime day) async {
    final done = widget.habit.isDone(day);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${day.month}月${day.day}日の記録',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(widget.habit.action),
              const SizedBox(height: 8),
              Text(
                done ? 'この日は実行済みです。' : 'この日に実行したことを記録できます。',
                style: const TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: done ? 'この日の記録を取り消す' : 'この日の実行を記録',
                icon: done ? Icons.undo_rounded : Icons.check_rounded,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) await widget.onToggle(day);
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final startMonth = DateTime.utc(
      habit.startedAt.year,
      habit.startedAt.month,
    );
    final currentMonth = DateTime.utc(widget.now.year, widget.now.month);
    final firstOffset = _month.weekday % 7;
    final days = DateTime.utc(_month.year, _month.month + 1, 0).day;
    final cellCount = ((firstOffset + days) / 7).ceil() * 7;
    final monthlyTotal = habit.completedDates
        .where(
          (key) =>
              key.startsWith(
                '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
              ) &&
              key.compareTo(dateKey(widget.now)) <= 0,
        )
        .length;
    return Scaffold(
      appBar: AppBar(title: const Text('記録')),
      body: PageBody(
        children: [
          const SizedBox(height: 8),
          ProgressCard(habit: habit, now: widget.now),
          const SizedBox(height: 20),
          SurfaceCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: '前の月',
                      onPressed: _month.isAfter(startMonth)
                          ? () => setState(
                              () => _month = DateTime.utc(
                                _month.year,
                                _month.month - 1,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      '${_month.year}年 ${_month.month}月',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      tooltip: '次の月',
                      onPressed: _month.isBefore(currentMonth)
                          ? () => setState(
                              () => _month = DateTime.utc(
                                _month.year,
                                _month.month + 1,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['日', '月', '火', '水', '木', '金', '土']
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 0,
                  ),
                  itemCount: cellCount,
                  itemBuilder: (context, index) {
                    final dayNumber = index - firstOffset + 1;
                    if (dayNumber < 1 || dayNumber > days) {
                      return const SizedBox.shrink();
                    }
                    final day = DateTime.utc(
                      _month.year,
                      _month.month,
                      dayNumber,
                    );
                    final enabled =
                        !day.isBefore(calendarDate(habit.startedAt)) &&
                        !day.isAfter(calendarDate(widget.now));
                    final done = habit.isDone(day);
                    final today = dateKey(day) == dateKey(widget.now);
                    final connectsToPrevious =
                        done &&
                        habit.isDone(day.subtract(const Duration(days: 1)));
                    final connectsToNext =
                        done && habit.isDone(day.add(const Duration(days: 1)));
                    final dayRadius = BorderRadius.horizontal(
                      left: Radius.circular(connectsToPrevious ? 0 : 12),
                      right: Radius.circular(connectsToNext ? 0 : 12),
                    );
                    return Semantics(
                      label:
                          '${_month.month}月$dayNumber日 ${done ? '実行済み' : '未記録'}',
                      button: enabled,
                      child: InkWell(
                        onTap: enabled && !widget.busy
                            ? () => _selectDay(day)
                            : null,
                        borderRadius: dayRadius,
                        child: Container(
                          key: ValueKey('calendar-day-${dateKey(day)}'),
                          decoration: BoxDecoration(
                            color: done
                                ? blue
                                : today
                                ? paleBlue
                                : Colors.transparent,
                            border: today
                                ? Border.all(color: blue, width: 1.3)
                                : null,
                            borderRadius: dayRadius,
                          ),
                          child: Center(
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: today || done
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: done
                                    ? Colors.white
                                    : enabled
                                    ? ink
                                    : const Color(0xFFCDD2DB),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: blue,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '今月 $monthlyTotal 回実行',
                      style: const TextStyle(
                        color: blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '日付をタップして編集',
                      style: TextStyle(color: muted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '連続日数は今日または昨日までの連続した記録です。\n達成率は開始日から今日までの日数に対する実行日数です。',
            style: TextStyle(fontSize: 10, color: muted),
          ),
          const SizedBox(height: 8),
          Text(
            '開始日：${habit.startedAt.year}年${habit.startedAt.month}月${habit.startedAt.day}日',
            style: const TextStyle(fontSize: 10, color: muted),
          ),
        ],
      ),
    );
  }
}
