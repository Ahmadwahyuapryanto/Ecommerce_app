// lib/services/product_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final _firestore = FirebaseFirestore.instance;
  final CollectionReference _productCollection =
  FirebaseFirestore.instance.collection('products');

  // Mengambil produk sebagai stream untuk pembaruan real-time
  Stream<List<Product>> getProductsStream() {
    return _productCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  // Menambah produk baru
  Future<void> addProduct(Product product) {
    return _productCollection.add(product.toJson());
  }

  // Mengupdate produk yang ada
  Future<void> updateProduct(Product product) {
    // Pastikan ID produk tidak kosong sebelum melakukan update
    if (product.id.isEmpty) {
      throw Exception("Product ID tidak boleh kosong saat update.");
    }
    return _productCollection.doc(product.id).update(product.toJson());
  }

  // Menghapus produk
  Future<void> deleteProduct(String productId) {
    return _productCollection.doc(productId).delete();
  }
}