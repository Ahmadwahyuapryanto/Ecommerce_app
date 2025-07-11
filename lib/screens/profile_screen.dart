// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. Import Firebase Auth

import '../services/auth_service.dart'; // Import AuthService untuk logout
import 'login_screen.dart';
import 'manage_product_screen.dart'; // Import halaman kelola produk

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService(); // Instance dari AuthService
  User? _user; // 2. State untuk menampung objek User dari Firebase

  // State untuk menampung data pengguna
  String _displayName = 'Guest';
  String _email = 'guest@example.com';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 3. Fungsi untuk mengambil data pengguna dari Firebase
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    // Ambil pengguna yang sedang login
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        _user = currentUser;
        // Gunakan displayName jika ada, jika tidak, gunakan bagian lokal dari email
        _displayName = _user?.displayName ?? _user?.email?.split('@')[0] ?? 'Pengguna';
        _email = _user?.email ?? 'Tidak ada email';
      });
    }
    setState(() => _isLoading = false);
  }

  // 4. Fungsi untuk proses logout menggunakan Firebase
  Future<void> _logout() async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmLogout == true) {
      // Panggil metode logout dari AuthService
      await _auth.logout();

      if (mounted) {
        // Navigasi ke halaman Login dan hapus semua halaman sebelumnya
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  // Helper widget untuk membuat setiap baris menu
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: TextStyle(color: color)),
      trailing:
      onTap != null ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          children: [
            // --- BAGIAN HEADER PROFIL ---
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  // Tampilkan foto profil jika ada, jika tidak, tampilkan inisial
                  backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
                  child: (_user?.photoURL == null)
                      ? Text(
                    _displayName.isNotEmpty ? _displayName.substring(0, 1).toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  _displayName, // Gunakan displayName dari state
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _email, // Gunakan email dari state
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- BAGIAN MENU ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.person_outline,
                      title: 'Edit Profil',
                      onTap: () { /* TODO: Navigasi ke halaman edit profil */ },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildMenuTile(
                      icon: Icons.location_on_outlined,
                      title: 'Alamat Pengiriman',
                      onTap: () { /* TODO: Navigasi ke halaman alamat */ },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildMenuTile(
                      icon: Icons.credit_card_outlined,
                      title: 'Metode Pembayaran',
                      onTap: () { /* TODO: Navigasi ke halaman pembayaran */ },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildMenuTile(
                      icon: Icons.settings_outlined,
                      title: 'Pengaturan',
                      onTap: () { /* TODO: Navigasi ke halaman pengaturan */ },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16), // Tambahkan divider
                    _buildMenuTile(
                      icon: Icons.store_outlined, // Icon untuk kelola produk
                      title: 'Kelola Produk',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ManageProductScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- BAGIAN LOGOUT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: _buildMenuTile(
                  icon: Icons.logout,
                  title: 'Keluar (Logout)',
                  onTap: _logout, // Panggil fungsi logout yang sudah diperbarui
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}