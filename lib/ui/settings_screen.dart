import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.habit,
    required this.busy,
    required this.onSave,
    required this.onTest,
    required this.onRecords,
    required this.notificationsSupported,
  });
  final Habit habit;
  final bool busy, notificationsSupported;
  final Future<bool> Function(Habit) onSave;
  final Future<void> Function(Habit) onTest;
  final VoidCallback onRecords;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Habit _draft = widget.habit;
  bool _testing = false;

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Preserve pending edits but keep completion records current after midnight/resume.
    _draft = _draft.copyWith(completedDates: widget.habit.completedDates);
  }

  Future<void> _editText({required bool goal}) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => _TextEditor(
        title: goal ? '目標を編集' : '毎日やることを編集',
        value: goal ? _draft.goal : _draft.action,
      ),
    );
    if (value != null && mounted) {
      setState(
        () => _draft = goal
            ? _draft.copyWith(goal: value)
            : _draft.copyWith(action: value),
      );
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _draft.hour, minute: _draft.minute),
      helpText: '毎日の通知時刻',
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      setState(
        () => _draft = _draft.copyWith(hour: time.hour, minute: time.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('設定')),
    body: PageBody(
      children: [
        const SizedBox(height: 8),
        _SettingTile(
          icon: Icons.track_changes_rounded,
          title: '目標',
          value: _draft.goal,
          onTap: widget.busy ? null : () => _editText(goal: true),
        ),
        const SizedBox(height: 15),
        _SettingTile(
          icon: Icons.event_available_outlined,
          title: '毎日やること',
          value: _draft.action,
          onTap: widget.busy ? null : () => _editText(goal: false),
        ),
        const SizedBox(height: 15),
        SurfaceCard(
          child: Column(
            children: [
              const Row(
                children: [
                  IconBubble(Icons.notifications_none_rounded, size: 43),
                  SizedBox(width: 14),
                  Text(
                    '通知',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text('通知を受け取る', style: TextStyle(fontSize: 14)),
                  ),
                  Switch.adaptive(
                    value: _draft.notificationsEnabled,
                    activeTrackColor: blue,
                    onChanged: widget.busy
                        ? null
                        : (value) => setState(
                            () => _draft = _draft.copyWith(
                              notificationsEnabled: value,
                            ),
                          ),
                  ),
                ],
              ),
              const Divider(height: 17),
              InkWell(
                onTap: widget.busy ? null : _pickTime,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('通知時間', style: TextStyle(fontSize: 14)),
                      ),
                      Text(
                        _draft.timeLabel,
                        style: const TextStyle(fontSize: 17, color: muted),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: muted,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 10),
              InkWell(
                onTap: widget.busy || _testing
                    ? null
                    : () async {
                        setState(() => _testing = true);
                        try {
                          await widget.onTest(_draft);
                        } finally {
                          if (mounted) setState(() => _testing = false);
                        }
                      },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.send_outlined, color: blue, size: 23),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _testing ? '送信中…' : '通知をテスト',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: muted,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              if (!widget.notificationsSupported) ...[
                const SizedBox(height: 14),
                const Text(
                  '通知はAndroid・iPhoneアプリで利用できます。',
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 15),
        _SettingTile(
          icon: Icons.bar_chart_rounded,
          title: '記録を確認',
          value: '過去の記録や統計を確認できます',
          subtitle: true,
          onTap: widget.onRecords,
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: '保存',
          busy: widget.busy,
          onPressed: () async {
            await widget.onSave(_draft);
          },
        ),
        const SizedBox(height: 12),
        const Text(
          '変更した内容は「保存」で反映されます',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: muted),
        ),
        const SizedBox(height: 22),
        const Text(
          'まいにち  ·  1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: muted, letterSpacing: 1),
        ),
      ],
    ),
  );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.subtitle = false,
  });
  final IconData icon;
  final String title, value;
  final VoidCallback? onTap;
  final bool subtitle;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      onTap: onTap,
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 20),
        child: Row(
          children: [
            IconBubble(icon, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: subtitle ? 15 : 12,
                      color: subtitle ? ink : muted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: subtitle ? 11 : 16,
                      fontWeight: subtitle
                          ? FontWeight.normal
                          : FontWeight.w700,
                      color: subtitle ? muted : ink,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded, color: muted, size: 24),
          ],
        ),
      ),
    ),
  );
}

class _TextEditor extends StatefulWidget {
  const _TextEditor({required this.title, required this.value});
  final String title, value;
  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late final _controller = TextEditingController(text: widget.value);
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        4,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            TextFormField(
              controller: _controller,
              autofocus: true,
              maxLength: 60,
              minLines: 1,
              maxLines: 3,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '内容を入力してください' : null,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: '変更する',
              onPressed: () {
                if (_form.currentState!.validate()) {
                  Navigator.pop(context, _controller.text.trim());
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
