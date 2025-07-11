// lib/models/order.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';

class Order {
  final String id;
  final String userId;
  final List<Product> products;
  final double grandTotal;
  final String shippingService;
  final DateTime orderDate;

  Order({
    required this.id,
    required this.userId,
    required this.products,
    required this.grandTotal,
    required this.shippingService,
    required this.orderDate,
  });

  // Factory baru untuk data dari Firestore
  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> json = doc.data()!;
    return Order(
      id: doc.id,
      userId: json['userId'],
      products: List<Product>.from(json['products'].map((p) => Product.fromJson(p))),
      grandTotal: (json['grandTotal'] as num).toDouble(),
      shippingService: json['shippingService'],
      orderDate: (json['orderDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'products': products.map((p) => p.toJson()).toList(),
      'grandTotal': grandTotal,
      'shippingService': shippingService,
      'orderDate': Timestamp.fromDate(orderDate), // Gunakan Timestamp Firestore
    };
  }
}