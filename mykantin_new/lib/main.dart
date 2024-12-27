// main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'screens/auth/login_page.dart';
import 'screens/home/home_page.dart';
import 'screens/admin/admin_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB_2km0eqUubOzO4IGo4qA1f-vMdR6lSgU",
        appId: "1:594388138097:android:a4f033ffd7061db40003d0",
        messagingSenderId: "594388138097",
        projectId: "mykantin-b6980",
        databaseURL: "https://mykantin-b6980-default-rtdb.asia-southeast1.firebasedatabase.app",
        storageBucket: "mykantin-b6980.appspot.com",
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            User? user = snapshot.data;

            return FutureBuilder<DataSnapshot>(
              future: FirebaseDatabase.instance
                  .ref('users/${user!.uid}')
                  .get()
                  .timeout(const Duration(seconds: 15)),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (userSnapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Failed to load user data.',
                            style: TextStyle(fontSize: 18, color: Colors.red),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const MyApp()),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (userSnapshot.hasData && userSnapshot.data!.value != null) {
                  var userData = userSnapshot.data!.value as Map<dynamic, dynamic>;
                  var role = userData['role'];

                  if (role == 'admin') {
                    return const AdminPage();
                  } else {
                    return const MyHomePage();
                  }
                } else {
                  return const Scaffold(
                    body: Center(
                      child: Text(
                        'User data not found or role not assigned.',
                        style: TextStyle(fontSize: 20, color: Colors.red),
                      ),
                    ),
                  );
                }
              },
            );
          }

          return const LoginPage();
        },
      ),
    );
  }
}
