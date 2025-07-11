// lib/models/review.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String? id;
  final String productId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final Timestamp createdAt;

  Review({
    this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return Review(
      id: doc.id,
      productId: data['productId'] ?? '', // Handle jika productId null di data lama
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonim',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // == PERBAIKAN UTAMA ADA DI SINI ==
  Map<String, dynamic> toJson() {
    return {
      'productId': productId, // Pastikan productId disertakan
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}