// lib/services/review_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewService {
  final _reviewsCollection = FirebaseFirestore.instance.collection('reviews');

  // Mengirim ulasan baru ke Firestore
  Future<void> submitReview(Review review) async {
    try {
      await _reviewsCollection.add(review.toJson());
    } catch (e) {
      throw Exception('Gagal mengirim ulasan: $e');
    }
  }

  // Mengambil semua ulasan dari sebuah produk
  Stream<List<Review>> getReviewsForProduct(String productId) {
    return _reviewsCollection
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }

  // Mengecek apakah user sudah pernah review produk ini
  Future<bool> hasUserReviewedProduct(String productId, String userId) async {
    final querySnapshot = await _reviewsCollection
        .where('productId', isEqualTo: productId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // --- FUNGSI BARU UNTUK AKUMULASI RATING ---
  Stream<Map<String, dynamic>> getProductRatingStream(String productId) {
    return getReviewsForProduct(productId).map((reviews) {
      if (reviews.isEmpty) {
        return {'average': 0.0, 'count': 0};
      }

      double totalRating = reviews.fold(0, (sum, item) => sum + item.rating);
      double average = totalRating / reviews.length;

      return {'average': average, 'count': reviews.length};
    });
  }
}