// lib/widgets/product_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

import '../models/product.dart';
import '../services/review_service.dart';
import '../services/cart_service.dart'; // Import CartService
import '../screens/detail_screen.dart';
import '../utils/custom_page_route.dart';
import '../utils/notification_helper.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final Function(GlobalKey, Widget) onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final GlobalKey _buttonKey = GlobalKey();
  final ReviewService _reviewService = ReviewService();
  final CartService _cartService = CartService();

  void _showQuantitySelector(BuildContext context) {
    // Cek apakah user sudah login sebelum menampilkan bottom sheet
    if (FirebaseAuth.instance.currentUser == null) {
      NotificationHelper.show(context, message: 'Silakan login terlebih dahulu', type: NotificationType.error);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuantitySelectorSheet(
        product: widget.product,
        onAddToCart: (int quantity) {
          _handleAddToCart(quantity);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _handleAddToCart(int quantity) async {
    try {
      final message = await _cartService.addToCart(widget.product, quantity);

      if (mounted) NotificationHelper.show(context, message: message, type: NotificationType.success);

      final image = Image.network(widget.product.images.first, fit: BoxFit.cover);
      widget.onAddToCart(_buttonKey, image);

    } catch (e) {
      if (mounted) NotificationHelper.show(context, message: 'Gagal menambahkan produk: ${e.toString()}', type: NotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI tidak berubah)
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2.0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            FadePageRoute(
              builder: (context) => DetailScreen(
                product: widget.product,
                onCartChanged: () {},
                cartItemCount: 0, // Ini bisa disesuaikan lagi jika perlu
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: "product_image_${widget.product.id}_0",
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Image.network(
                      widget.product.images.first,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40)),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),
                          StreamBuilder<Map<String, dynamic>>(
                            stream: _reviewService.getProductRatingStream(widget.product.id),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || (snapshot.data!['count'] == 0)) {
                                return const SizedBox.shrink();
                              }

                              final ratingData = snapshot.data!;
                              final double averageRating = ratingData['average'];
                              final int reviewCount = ratingData['count'];

                              return Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    averageRating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('($reviewCount)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            currencyFormatter.format(widget.product.price),
                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          key: _buttonKey,
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => _showQuantitySelector(context),
                            icon: Icon(Icons.add_shopping_cart, color: colorScheme.onPrimary, size: 16),
                            padding: EdgeInsets.zero,
                            tooltip: 'Tambah ke Keranjang',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuantitySelectorSheet extends StatefulWidget {
  final Product product;
  final Function(int) onAddToCart;

  const QuantitySelectorSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<QuantitySelectorSheet> createState() => _QuantitySelectorSheetState();
}

class _QuantitySelectorSheetState extends State<QuantitySelectorSheet> {
  int _quantity = 1;

  void _increment() => setState(() => _quantity++);
  void _decrement() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final total = widget.product.price * _quantity;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Masukkan Jumlah', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(widget.product.images.first, width: 70, height: 70, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 2),
                    const SizedBox(height: 4),
                    Text(currencyFormatter.format(widget.product.price), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: _decrement, icon: const Icon(Icons.remove_circle_outline)),
              const SizedBox(width: 16),
              Text('$_quantity', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(width: 16),
              IconButton(onPressed: _increment, icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => widget.onAddToCart(_quantity),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Tambahkan ke Keranjang (${currencyFormatter.format(total)})'),
          ),
        ],
      ),
    );
  }
}