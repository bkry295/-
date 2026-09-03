import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onStart, required this.busy});
  final Future<void> Function(Habit) onStart;
  final bool busy;
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _form = GlobalKey<FormState>();
  final _goal = TextEditingController(text: '英語を話せるようになる');
  final _action = TextEditingController(text: '英単語を10個覚える');
  final _goalFocus = FocusNode();
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  @override
  void dispose() {
    _goal.dispose();
    _action.dispose();
    _goalFocus.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _time,
      initialEntryMode: TimePickerEntryMode.input,
      helpText: '毎日の通知時刻',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time != null && mounted) setState(() => _time = time);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.spa_rounded, size: 20, color: blue),
                              SizedBox(width: 7),
                              Text(
                                'まいにち',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          IconButton.outlined(
                            onPressed: widget.busy
                                ? null
                                : () => _goalFocus.requestFocus(),
                            tooltip: '目標を編集',
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: blue,
                              size: 21,
                            ),
                            style: IconButton.styleFrom(
                              side: const BorderSide(color: border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const IconBubble(Icons.spa_rounded, size: 76),
                      const SizedBox(height: 22),
                      const Text(
                        '小さな一歩を、毎日に。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .4,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        '毎日続けることを1つ決めましょう',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                  SurfaceCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _FieldLabel(Icons.track_changes_rounded, '目標'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _goal,
                          focusNode: _goalFocus,
                          enabled: !widget.busy,
                          maxLength: 60,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'なりたい自分をイメージ',
                            counterText: '',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? '目標を入力してください'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        const _FieldLabel(
                          Icons.format_list_bulleted_rounded,
                          '毎日やること',
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _action,
                          enabled: !widget.busy,
                          maxLength: 60,
                          decoration: const InputDecoration(
                            hintText: '無理なく続けられること',
                            counterText: '',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? '毎日やることを入力してください'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        const _FieldLabel(
                          Icons.notifications_none_rounded,
                          '通知時刻',
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: widget.busy ? null : _pickTime,
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: const InputDecoration(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 21),
                                ),
                                const Icon(
                                  Icons.schedule_rounded,
                                  color: blue,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 11),
                        const Text(
                          '毎日この時間に、続けることを思い出す\n通知をお届けします。',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'この内容ではじめる',
                        busy: widget.busy,
                        onPressed: () {
                          if (!_form.currentState!.validate()) return;
                          FocusScope.of(context).unfocus();
                          widget.onStart(
                            Habit(
                              goal: _goal.text.trim(),
                              action: _action.text.trim(),
                              startedAt: calendarDate(DateTime.now()),
                              hour: _time.hour,
                              minute: _time.minute,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'あとで変更できます',
                        style: TextStyle(fontSize: 12, color: blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: blue, size: 23),
      const SizedBox(width: 10),
      Text(
        label,
        style: const TextStyle(
          color: blue,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
