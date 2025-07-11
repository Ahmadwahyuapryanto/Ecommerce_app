// lib/services/order_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as model; // Beri alias 'model' untuk menghindari konflik

class OrderService {
  final _ordersCollection = FirebaseFirestore.instance.collection('orders');

  // Membuat pesanan baru di Firestore
  Future<void> createOrder(model.Order order) async { // Gunakan model.Order
    await _ordersCollection.add(order.toJson());
  }

  // Mengambil riwayat pesanan sebagai stream
  Stream<List<model.Order>> getOrdersStream(String userId) { // Gunakan model.Order
    return _ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => model.Order.fromFirestore(doc)).toList()); // Gunakan model.Order
  }

  // Fungsi fetchOrders yang lama (jika masih diperlukan, jika tidak bisa dihapus)
  Future<List<model.Order>> fetchOrders(String userId) async { // Gunakan model.Order
    final snapshot = await _ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => model.Order.fromFirestore(doc)).toList();
  }
}