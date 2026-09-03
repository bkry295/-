import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/habit_repository.dart';
import 'services/reminders.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    MainichiApp(
      repository: LocalHabitRepository(),
      reminders: LocalReminderService(),
    ),
  );
}
