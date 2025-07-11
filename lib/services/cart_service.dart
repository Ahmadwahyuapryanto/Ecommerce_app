// lib/services/cart_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class CartService {
  final _firestore = FirebaseFirestore.instance;

  // Helper untuk mendapatkan user ID yang sedang login
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // Mendapatkan referensi ke koleksi 'cart' di dalam dokumen user
  CollectionReference<Product> _getCartCollection() {
    final userId = _userId;
    if (userId == null) throw Exception('Pengguna belum login.');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .withConverter<Product>(
      fromFirestore: (snapshot, _) => Product.fromJson(snapshot.data()!),
      toFirestore: (product, _) => product.toJson(),
    );
  }

  // Menambahkan atau mengupdate produk di keranjang
  Future<String> addToCart(Product product, int quantity) async {
    final cartCollection = _getCartCollection();

    // Cek batas maksimal 10 produk
    final currentCart = await cartCollection.get();
    // Cek apakah produk sudah ada sebelum mengecek batas
    final docRef = cartCollection.doc(product.id);
    final doc = await docRef.get();

    if (currentCart.docs.length >= 10 && !doc.exists) {
      return "Batas maksimal 10 produk berbeda di keranjang telah tercapai.";
    }

    if (doc.exists) {
      // Jika produk sudah ada, tambahkan jumlahnya
      await docRef.update({'quantity': FieldValue.increment(quantity)});
    } else {
      // Jika produk belum ada, tambahkan sebagai dokumen baru
      await docRef.set(product.copyWith(quantity: quantity));
    }
    return "${product.name} ditambahkan ke keranjang.";
  }

  // Mendapatkan stream dari keranjang belanja user
  Stream<List<Product>> getCartStream() {
    final userId = _userId;
    if (userId == null) return Stream.value([]); // Kembalikan stream kosong jika user belum login
    return _getCartCollection().snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  // Menghapus produk dari keranjang
  Future<void> removeFromCart(String productId) async {
    await _getCartCollection().doc(productId).delete();
  }

  // Mengupdate jumlah produk di keranjang
  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (newQuantity > 0) {
      await _getCartCollection().doc(productId).update({'quantity': newQuantity});
    } else {
      // Hapus item jika jumlahnya 0 atau kurang
      await removeFromCart(productId);
    }
  }

  // Menghapus semua item di keranjang (setelah checkout)
  Future<void> clearCart() async {
    final cartCollection = _getCartCollection();
    final snapshot = await cartCollection.get();

    // Batch delete untuk efisiensi
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}