// lib/screens/order_history_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../services/order_service.dart';
import '../services/review_service.dart';
import 'login_screen.dart';
import 'review_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final Stream<User?> _authStream = FirebaseAuth.instance.authStateChanges();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: _authStream,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasData && userSnapshot.data != null) {
            final user = userSnapshot.data!;
            return StreamBuilder<List<Order>>(
              stream: OrderService().getOrdersStream(user.uid),
              builder: (context, orderSnapshot) {
                if (orderSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (orderSnapshot.hasError) {
                  return Center(child: Text('Error: ${orderSnapshot.error}'));
                }
                final orders = orderSnapshot.data ?? [];
                if (orders.isEmpty) {
                  return _buildEmptyHistory();
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return OrderHistoryCard(order: orders[index], userId: user.uid);
                    },
                  ),
                );
              },
            );
          }

          return _buildLoginPrompt();
        },
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Riwayat Pesanan',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Semua transaksimu akan muncul di sini.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Silakan Login Terlebih Dahulu',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda perlu masuk untuk melihat riwayat pesanan.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('Ke Halaman Login'),
          ),
        ],
      ),
    );
  }
}

class OrderHistoryCard extends StatefulWidget {
  final Order order;
  final String userId;
  const OrderHistoryCard({super.key, required this.order, required this.userId});

  @override
  State<OrderHistoryCard> createState() => _OrderHistoryCardState();
}

class _OrderHistoryCardState extends State<OrderHistoryCard> {
  // Pemanggilan yang benar: Buat instance dari kelas
  final ReviewService _reviewService = ReviewService();
  Map<String, bool> _reviewStatus = {};

  @override
  void initState() {
    super.initState();
    _checkReviewStatus();
  }

  void _checkReviewStatus() async {
    for (var product in widget.order.products) {
      bool hasReviewed = await _reviewService.hasUserReviewedProduct(product.id, widget.userId);
      if (mounted) {
        setState(() {
          _reviewStatus[product.id] = hasReviewed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('d MMMM champignons, HH:mm', 'id_ID');
    const bool isOrderCompleted = true;
    const String statusText = 'Selesai';
    final Color statusColor = Colors.green.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormatter.format(widget.order.orderDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...widget.order.products.map((product) {
              final bool hasBeenReviewed = _reviewStatus[product.id] ?? false;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(product.images.first, width: 60, height: 60, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOrderCompleted && !hasBeenReviewed)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          // Pemanggilan yang benar: Gunakan nama kelasnya
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ReviewScreen(product: product)),
                          );
                          _checkReviewStatus();
                        },
                        child: const Text('Beri Ulasan'),
                      ),
                    ),
                  if (hasBeenReviewed)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text('Terimakasih anda Telah Memberikan Ulasan', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Pembayaran', style: TextStyle(color: Colors.grey[700])),
                Text(
                  currencyFormatter.format(widget.order.grandTotal),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}