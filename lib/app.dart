import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/habit.dart';
import 'services/habit_repository.dart';
import 'services/reminders.dart';
import 'ui/records_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/setup_screen.dart';
import 'ui/theme.dart';
import 'ui/today_screen.dart';

class MainichiApp extends StatelessWidget {
  const MainichiApp({
    super.key,
    required this.repository,
    required this.reminders,
  });
  final HabitRepository repository;
  final ReminderService reminders;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'まいにち — 小さな一歩を、毎日に。',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    locale: const Locale('ja'),
    supportedLocales: const [Locale('ja')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => Container(
      color: const Color(0xFFEDF1F7),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ClipRect(child: child!),
      ),
    ),
    home: _HabitHome(repository: repository, reminders: reminders),
  );
}

class _HabitHome extends StatefulWidget {
  const _HabitHome({required this.repository, required this.reminders});
  final HabitRepository repository;
  final ReminderService reminders;
  @override
  State<_HabitHome> createState() => _HabitHomeState();
}

class _HabitHomeState extends State<_HabitHome> with WidgetsBindingObserver {
  Habit? _habit;
  bool _loading = true, _loadFailed = false, _busy = false;
  int _tab = 0;
  DateTime _now = DateTime.now();
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _scheduleMidnight();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _now = DateTime.now());
      _scheduleMidnight();
      if (_habit != null && !_busy) unawaited(_refreshReminder(_habit!));
    }
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      next.difference(now) + const Duration(seconds: 1),
      () {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
        _scheduleMidnight();
      },
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final habit = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _habit = habit;
        _loading = false;
      });
      if (habit != null) unawaited(_refreshReminder(habit));
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _refreshReminder(Habit habit) async {
    if (!widget.reminders.supported) return;
    try {
      final notice = await widget.reminders.configure(habit);
      if (notice != null) _message(notice);
    } catch (_) {
      _message('通知を設定できませんでした。設定画面で保存し直してください。');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 4)),
    );
  }

  Future<bool> _save(Habit habit, {bool settings = false}) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await widget.repository.save(habit);
      if (!mounted) return false;
      setState(() {
        _habit = habit;
        _now = DateTime.now();
      });
      if (settings) {
        try {
          final notice = await widget.reminders.configure(
            habit,
            requestPermission: habit.notificationsEnabled,
          );
          _message(notice == null ? '設定を保存しました。' : '設定を保存しました。$notice');
        } catch (_) {
          _message('設定は保存しましたが、通知の設定に失敗しました。もう一度保存してください。');
        }
      }
      return true;
    } catch (_) {
      _message('保存できませんでした。空き容量などを確認し、もう一度お試しください。');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(DateTime day) async {
    if (_busy || _habit == null) return;
    final wasDone = _habit!.isDone(day);
    try {
      final next = _habit!.toggleDate(day, DateTime.now());
      if (await _save(next)) {
        unawaited(HapticFeedback.lightImpact());
        _message(wasDone ? '記録を取り消しました。' : '実行を記録しました。今日の一歩、おつかれさま！');
      }
    } on ArgumentError {
      _message('この日付には記録できません。');
    }
  }

  Future<void> _completeToday() async {
    final today = DateTime.now();
    if (_habit!.isDone(today)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('今日の記録を取り消しますか？'),
          content: const Text('あとからもう一度記録できます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('戻る'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('取り消す'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await _toggle(today);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadFailed) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const IconBubble(Icons.cloud_off_outlined, size: 70),
                const SizedBox(height: 20),
                const Text(
                  '記録を読み込めませんでした',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text(
                  '保存済みのデータは変更していません。\nもう一度お試しください。',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: '再読み込み', onPressed: _load),
              ],
            ),
          ),
        ),
      );
    }
    if (_habit == null) {
      return SetupScreen(
        busy: _busy,
        onStart: (habit) async {
          await _save(habit, settings: true);
        },
      );
    }
    final habit = _habit!;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: switch (_tab) {
          0 => TodayScreen(
            habit: habit,
            now: _now,
            busy: _busy,
            onComplete: _completeToday,
            onEdit: () => setState(() => _tab = 2),
          ),
          1 => RecordsScreen(
            habit: habit,
            now: _now,
            busy: _busy,
            onToggle: _toggle,
          ),
          _ => SettingsScreen(
            habit: habit,
            busy: _busy,
            notificationsSupported: widget.reminders.supported,
            onSave: (draft) => _save(
              draft.copyWith(completedDates: _habit!.completedDates),
              settings: true,
            ),
            onRecords: () => setState(() => _tab = 1),
            onTest: (draft) async {
              try {
                _message(await widget.reminders.test(draft));
              } catch (_) {
                _message('テスト通知を送信できませんでした。端末の通知設定を確認してください。');
              }
            },
          ),
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: border)),
        ),
        child: NavigationBar(
          height: 72,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: paleBlue,
          selectedIndex: _tab,
          onDestinationSelected: (index) {
            if (!_busy) setState(() => _tab = index);
          },
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.normal,
              color: states.contains(WidgetState.selected) ? blue : muted,
            ),
          ),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: muted),
              selectedIcon: Icon(Icons.home_rounded, color: blue),
              label: '今日',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded, color: muted),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: blue),
              label: '記録',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: muted),
              selectedIcon: Icon(Icons.settings_rounded, color: blue),
              label: '設定',
            ),
          ],
        ),
      ),
    );
  }
}
