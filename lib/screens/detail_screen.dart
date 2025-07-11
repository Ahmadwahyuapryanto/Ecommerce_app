// lib/screens/detail_screen.dart

import 'package:ecommerce_app/models/order.dart';
import 'package:ecommerce_app/services/order_service.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:ecommerce_app/widgets/success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';
import '../models/review.dart';
import '../services/cart_service.dart';
import '../services/review_service.dart';
import '../utils/notification_helper.dart';
import 'cart_screen.dart';

class DetailScreen extends StatefulWidget {
  final Product product;
  final VoidCallback onCartChanged;
  final int cartItemCount;

  const DetailScreen({
    super.key,
    required this.product,
    required this.onCartChanged,
    required this.cartItemCount,
  });

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<Widget> _flyingParticles = [];
  final GlobalKey _cartIconKey = GlobalKey();
  final GlobalKey _addToCartButtonKey = GlobalKey();

  late final PageController _pageController;
  int _currentPage = 0;
  bool _isCheckingOut = false;

  final ReviewService _reviewService = ReviewService();
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _flyingParticles.clear());
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showQuantitySelector({required bool isBuyNow}) {
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
          Navigator.pop(context);
          if (isBuyNow) {
            _buyNow(quantity);
          } else {
            _handleAddToCart(quantity);
          }
        },
      ),
    );
  }

  Future<void> _handleAddToCart(int quantity) async {
    try {
      final message = await _cartService.addToCart(widget.product, quantity);
      if (mounted) {
        NotificationHelper.show(context, message: message, type: NotificationType.success);
        _runAnimation();
      }
    } catch (e) {
      if (mounted) NotificationHelper.show(context, message: 'Gagal: ${e.toString()}', type: NotificationType.error);
    }
  }

  Future<void> _buyNow(int quantity) async {
    final shippingService = ShippingService.availableServices.first;
    final productWithQuantity = widget.product.copyWith(quantity: quantity);
    final grandTotal = (productWithQuantity.price * productWithQuantity.quantity) + shippingService.cost;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pembayaran'),
          content: Text('Anda akan membayar sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(grandTotal)}. Lanjutkan?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Bayar')),
          ],
        );
      },
    );

    if (confirm != true) return;
    setState(() => _isCheckingOut = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User tidak ditemukan. Silakan login ulang.");

      final newOrder = Order(
        id: '', // Firestore akan generate ID
        userId: userId,
        products: [productWithQuantity],
        grandTotal: grandTotal,
        shippingService: shippingService.name,
        orderDate: DateTime.now(),
      );

      await _orderService.createOrder(newOrder);
      widget.onCartChanged?.call();

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const SuccessDialog(message: "Pembayaran Berhasil"),
        );
      }
    } catch (e) {
      if (mounted) NotificationHelper.show(context, message: 'Checkout gagal: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }


  void _navigateToCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: CartScreen (onCartChanged: widget.onCartChanged),
            );
          },
        );
      },
    );
  }

  void _runAnimation() {
    final RenderBox buttonRenderBox = _addToCartButtonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox cartRenderBox = _cartIconKey.currentContext!.findRenderObject() as RenderBox;
    final startPosition = buttonRenderBox.localToGlobal(Offset.zero);
    final endPosition = cartRenderBox.localToGlobal(Offset.zero);
    setState(() {
      _flyingParticles.add(
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final position = CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            );
            final double top = startPosition.dy + (endPosition.dy - startPosition.dy) * position.value;
            final double left = startPosition.dx + (endPosition.dx - startPosition.dx) * position.value;

            return Positioned(
              top: top,
              left: left,
              child: child!,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ),
            child: Icon(Icons.shopping_cart, color: Theme.of(context).colorScheme.onPrimary, size: 16),
          ),
        ),
      );
    });
    _animationController.forward(from: 0.0);
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 48),
          Text(
            'Ulasan Produk',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Review>>(
            stream: _reviewService.getReviewsForProduct(widget.product.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('Belum ada ulasan untuk produk ini.'),
                  ),
                );
              }

              final reviews = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(review.userName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Row(
                              children: List.generate(5, (starIndex) => Icon(
                                starIndex < review.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d MMMM yyyy').format(review.createdAt.toDate()),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(review.comment, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  Share.share('Cek produk keren ini: ${widget.product.name}!');
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: StreamBuilder<List<Product>>(
                stream: _cartService.getCartStream(),
                builder: (context, snapshot) {
                  final cartItemCount = snapshot.data?.length ?? 0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        key: _cartIconKey,
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: _navigateToCart,
                      ),
                      if (cartItemCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$cartItemCount',
                              style: TextStyle(color: Theme.of(context).colorScheme.onError, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
              ],
              border: Border(top: BorderSide(color: Colors.grey.shade200))
          ),
          child: Row(
            children: [
              // Tombol Beli Sekarang
              Expanded(
                child: OutlinedButton(
                  onPressed: _isCheckingOut ? null : () => _showQuantitySelector(isBuyNow: true),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                  child: _isCheckingOut
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Beli Sekarang'),
                ),
              ),
              const SizedBox(width: 12),
              // Tombol Tambah ke Keranjang
              Expanded(
                child: ElevatedButton.icon(
                  key: _addToCartButtonKey,
                  onPressed: () => _showQuantitySelector(isBuyNow: false),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Keranjang'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.product.images.length,
                      onPageChanged: (int page) => setState(() => _currentPage = page),
                      itemBuilder: (context, index) {
                        return Hero(
                          tag: "product_image_${widget.product.id}_$index",
                          child: Image.network(widget.product.images[index], fit: BoxFit.cover),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(widget.product.images.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(widget.product.price),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      // Menggunakan deskripsi dari produk atau menampilkan pesan default
                      widget.product.description ?? 'Tidak ada deskripsi untuk produk ini.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
              _buildReviewsSection(),
              const SizedBox(height: 100),
            ],
          ),
          ..._flyingParticles,
        ],
      ),
    );
  }
}