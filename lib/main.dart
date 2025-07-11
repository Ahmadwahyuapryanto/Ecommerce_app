import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// 2. Ubah main menjadi async
void main() async {
  // 3. Pastikan Flutter siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDruh9Xjq6GNdlGJcUuRbwNfY9881NZbDo",
        authDomain: "ecommerceapp-e1664.firebaseapp.com",
        projectId: "ecommerceapp-e1664",
        storageBucket: "ecommerceapp-e1664.firebasestorage.app",
        messagingSenderId: "735801297736",
        appId: "1:735801297736:web:ec890b3282fe2e07d8c17d",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  await initializeDateFormatting('id_ID', null);

  runApp(MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("loggedIn") ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi E-Commerce',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[200],
        colorScheme: ColorScheme.light(
          primary: Colors.grey[900]!,
          secondary: Colors.grey[700]!,
          surface: Colors.grey[50]!,
          background: Colors.white,
          error: Colors.red.shade700,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
          onBackground: Colors.black,
          onError: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          elevation: 0.5,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
          titleSmall: TextStyle(fontSize: 16, color: Colors.black54),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
          labelLarge: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[900],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[900],
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[900]!, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[400]!),
          ),
          margin: EdgeInsets.zero,
        ),
      ),
      home: FirebaseAuth.instance.currentUser != null ? HomeScreen() : LoginScreen(),
      // future: isLoggedIn(),
      // builder: (context, snapshot) {
      //   if (!snapshot.hasData) {
      //     return Scaffold(
      //       body: Center(
      //         child: Column(
      //           mainAxisAlignment: MainAxisAlignment.center,
      //           children: [
      //             CircularProgressIndicator(color: Colors.grey[900]),
      //             const SizedBox(height: 10),
      //             Text('Memuat...', style: Theme.of(context).textTheme.titleSmall),
      //           ],
      //         ),
      //       ),
      //     );
      //   }
      //   return snapshot.data! ? const HomeScreen() : const LoginScreen();
      // },

    );
  }
}