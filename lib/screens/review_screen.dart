// lib/screens/review_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../utils/notification_helper.dart';

class ReviewScreen extends StatefulWidget {
  final Product product;
  const ReviewScreen({super.key, required this.product});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  final ReviewService _reviewService = ReviewService();

  void _submitReview() async {
    if (_rating == 0) {
      NotificationHelper.show(context, message: 'Mohon berikan rating bintang terlebih dahulu.', type: NotificationType.error);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      NotificationHelper.show(context, message: 'Anda harus login untuk memberi ulasan.', type: NotificationType.error);
      setState(() => _isSubmitting = false);
      return;
    }

    // Membuat objek ulasan dengan data yang benar
    final newReview = Review(
      productId: widget.product.id, // ID Produk diambil dari widget
      userId: user.uid,
      userName: user.displayName ?? user.email?.split('@')[0] ?? 'Anonim',
      rating: _rating,
      comment: _commentController.text,
      createdAt: Timestamp.now(),
    );

    try {
      await _reviewService.submitReview(newReview);

      if (!mounted) return;
      NotificationHelper.show(context, message: 'Terima kasih atas ulasan Anda!', type: NotificationType.success);
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      NotificationHelper.show(context, message: 'Gagal mengirim ulasan: ${e.toString()}', type: NotificationType.error);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI tidak berubah, jadi tidak perlu disalin ulang, pastikan logika _submitReview sudah benar)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beri Ulasan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.product.images.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Beri ulasan untuk produk:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Rating Anda',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Tulis Komentar Anda',
                  hintText: 'Bagaimana kualitas produknya? Apakah sesuai dengan ekspektasi Anda?',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Komentar tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReview,
                icon: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.send_outlined),
                label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Ulasan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}