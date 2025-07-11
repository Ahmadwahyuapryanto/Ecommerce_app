// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Alias untuk menghindari konflik nama

import '../services/auth_service.dart'; //
import 'home_screen.dart'; //
import 'register_screen.dart'; //

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userCtrl = TextEditingController(); //
  final passCtrl = TextEditingController(); //
  final AuthService _auth = AuthService(); //
  bool _isLoading = false; //
  bool _isPasswordVisible = false; //

  Future<void> login() async {
    if (userCtrl.text.isEmpty || passCtrl.text.isEmpty) { //
      if (mounted) { //
        ScaffoldMessenger.of(context).showSnackBar( //
          const SnackBar(content: Text('Email dan password tidak boleh kosong')), // Mengubah pesan ke 'Email'
        );
      }
      return;
    }

    setState(() => _isLoading = true); //

    // Gunakan layanan otentikasi Firebase
    final firebase_auth.User? user = await _auth.login(userCtrl.text, passCtrl.text); //

    setState(() => _isLoading = false); //

    if (mounted) { //
      if (user != null) { //
        // Jika login berhasil, navigasi ke HomeScreen
        // Data pengguna seperti email, uid, dll., dapat diakses melalui objek 'user' dari Firebase
        Navigator.of(context).pushAndRemoveUntil( //
          MaterialPageRoute(builder: (_) => const HomeScreen()), //
              (route) => false, //
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar( //
          const SnackBar(content: Text('Email atau password salah. Silakan coba lagi.')), // Mengubah pesan
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0), //
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, //
              crossAxisAlignment: CrossAxisAlignment.stretch, //
              children: [
                Icon(Icons.lock_person_outlined, size: 80, color: Theme.of(context).colorScheme.secondary), //
                const SizedBox(height: 16), //
                Text('Welcome Back!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium), //
                const SizedBox(height: 8), //
                Text('Silakan masuk untuk melanjutkan', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])), //
                const SizedBox(height: 40), //
                TextField(
                  controller: userCtrl, //
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.person_outline)), // Mengubah label ke 'Email'
                  textInputAction: TextInputAction.next, //
                ),
                const SizedBox(height: 16), //
                TextField(
                  controller: passCtrl, //
                  obscureText: !_isPasswordVisible, //
                  decoration: InputDecoration(
                    labelText: 'Password', //
                    prefixIcon: const Icon(Icons.lock_outline), //
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined), //
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible), //
                    ),
                  ),
                  onEditingComplete: login, //
                ),
                const SizedBox(height: 24), //
                ElevatedButton(
                  onPressed: _isLoading ? null : login, //
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), //
                  child: _isLoading //
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) //
                      : const Text('Login'), //
                ),
                const SizedBox(height: 24), //
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, //
                  children: [
                    Text('Belum punya akun?', style: TextStyle(color: Colors.grey[600])), //
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), //
                      child: const Text('Daftar Sekarang'), //
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}