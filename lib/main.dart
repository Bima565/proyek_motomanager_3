import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'page/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase dengan konfigurasi multi-platform (Android, Web, dll.)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Mengatur warna status bar sistem agar serasi dengan dark background MotoManage
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F1015),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MotoManageApp());
}

class MotoManageApp extends StatelessWidget {
  const MotoManageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoManage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1015),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2026),
          surface: Color(0xFF151821),
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
      ),
      home: const LoginPage(),
    );
  }
}
