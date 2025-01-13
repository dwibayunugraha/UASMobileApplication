import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart'; // Paket suara
import 'package:lottie/lottie.dart'; // Paket animasi
import 'screens/auth/login_page.dart';
import 'screens/admin/admin_page.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAHbcFaHjY-LXknguuSz489PcrUFqyqhj4",
        appId: "1:323941923576:android:22ed2d48c8f9c514f3190d",
        messagingSenderId: "323941923576",
        projectId: "kantinku-5b541",
        databaseURL: "https://kantinku-5b541-default-rtdb.asia-southeast1.firebasedatabase.app",
        storageBucket: "kantinku-5b541.firebasestorage.app",
      ),
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyKantin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: Colors.red,
          secondary: Colors.redAccent,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: const SplashScreen(), // SplashScreen sebagai halaman pertama
      routes: {
        '/login': (context) => const LoginPage(),
        '/admin': (context) => const AdminDashboard(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playSplashSound();
    _navigateToLogin();
  }

  Future<void> _playSplashSound() async {
    // Pastikan Anda menambahkan file suara ke folder `assets/sounds/` dan mendaftarkan di pubspec.yaml
    await _audioPlayer.play(AssetSource('sounds/splash_sound.mp3'));
  }

  void _navigateToLogin() {
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animasi Lottie
            Lottie.asset(
              'assets/animations/splash_animation.json', // Tambahkan file animasi JSON di folder assets
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              'Kantinku',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
