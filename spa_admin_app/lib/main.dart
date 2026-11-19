import 'package:flutter/material.dart';
import 'app.dart';
import 'core/preferences/staff_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StaffPreferences.init();
  runApp(const SpaAdminApp());
}
