// lib/models/product.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

List<Product> productFromJson(String str) =>
    List<Product>.from(json.decode(str).map((x) => Product.fromJson(x)));

String productToJson(List<Product> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final List<String> images;
  final Rating rating;
  final String? description;
  final int quantity; // Field kuantitas ditambahkan

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.images,
    required this.rating,
    this.description,
    this.quantity = 1, // Default kuantitas adalah 1
  });

  // Factory untuk membuat produk dengan kuantitas baru
  Product copyWith({int? quantity, String? description}) {
    return Product(
      id: id,
      name: name,
      price: price,
      category: category,
      images: images,
      rating: rating,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json["id"]?.toString() ?? '',
    name: json["name"] ?? 'Nama tidak tersedia',
    price: (json["price"] as num? ?? 0).toDouble(),
    category: json["category"] ?? 'Tanpa Kategori',
    images: json["images"] != null ? List<String>.from(json["images"].map((x) => x)) : [],
    rating: json["rating"] != null ? Rating.fromJson(json["rating"]) : Rating(rate: 0, count: 0),
    description: json["description"],
    quantity: json["quantity"] ?? 1, // Baca kuantitas dari JSON
  );

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> json = doc.data() ?? {};
    return Product(
      id: doc.id,
      name: json["name"] ?? 'Nama tidak tersedia',
      price: (json["price"] as num? ?? 0).toDouble(),
      category: json["category"] ?? 'Tanpa Kategori',
      images: json["images"] != null ? List<String>.from(json["images"].map((x) => x)) : [],
      rating: json["rating"] != null ? Rating.fromJson(json["rating"]) : Rating(rate: 0, count: 0),
      description: json["description"], // Mengambil deskripsi dari Firestore
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "price": price,
    "category": category,
    "images": List<dynamic>.from(images.map((x) => x)),
    "rating": rating.toJson(),
    "description": description,
    "quantity": quantity, // Simpan kuantitas ke JSON
  };
}

class Rating {
  final double rate;
  final int count;

  Rating({
    required this.rate,
    required this.count,
  });

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
    rate: (json["rate"] as num? ?? 0).toDouble(),
    count: json["count"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "rate": rate,
    "count": count,
  };
}