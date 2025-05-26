import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/note.dart';
import 'screens/login_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  
  await StorageService.initialize();
  
  runApp(const SecureNotesApp());
}

class SecureNotesApp extends StatefulWidget {
  const SecureNotesApp({super.key});

  @override
  State<SecureNotesApp> createState() => _SecureNotesAppState();
}

class _SecureNotesAppState extends State<SecureNotesApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light 
          ? ThemeMode.dark 
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure NoteBlock',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      home: LoginScreen(onThemeToggle: _toggleTheme),
    );
  }
}