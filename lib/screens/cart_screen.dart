// lib/screens/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../services/cart_service.dart'; // Ganti SharedPreferences dengan CartService
import '../services/order_service.dart';
import '../utils/notification_helper.dart';
import '../widgets/success_dialog.dart';

class ShippingService {
  final String id;
  final String name;
  final double cost;
  final String description;

  ShippingService({
    required this.id,
    required this.name,
    required this.cost,
    this.description = '',
  });

  @override
  bool operator ==(Object other) => other is ShippingService && id == other.id;
  @override
  int get hashCode => id.hashCode;

  static List<ShippingService> get availableServices => [
    ShippingService(id: 'jne_reg', name: 'JNE Reguler', cost: 15000.0, description: '2-4 hari kerja'),
    ShippingService(id: 'pos_kilat', name: 'POS Kilat Khusus', cost: 18000.0, description: '1-3 hari kerja'),
    ShippingService(id: 'gosend', name: 'GoSend Same Day', cost: 25000.0, description: 'Tiba di hari yang sama'),
  ];
}

class CartScreen extends StatefulWidget {
  final VoidCallback? onCartChanged;
  const CartScreen({super.key, this.onCartChanged});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  late ShippingService _selectedShippingService;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _selectedShippingService = ShippingService.availableServices.first;
  }

  Future<void> _checkout(List<Product> cart) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final double subtotal = cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
        final double grandTotal = subtotal + _selectedShippingService.cost;
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

      final double subtotal = cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
      final double grandTotal = subtotal + _selectedShippingService.cost;

      final newOrder = Order(
        id: '', // Firestore akan generate ID
        userId: userId,
        products: List.from(cart),
        grandTotal: grandTotal,
        shippingService: _selectedShippingService.name,
        orderDate: DateTime.now(),
      );

      await _orderService.createOrder(newOrder);
      await _cartService.clearCart(); // Hapus keranjang dari Firestore

      widget.onCartChanged?.call();

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const SuccessDialog(message: "Pembayaran Berhasil"),
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) NotificationHelper.show(context, message: 'Checkout gagal: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Handle di atas
            Container(
              height: 24,
              width: double.infinity,
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Keranjang Belanja', style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 10),
            // Gunakan StreamBuilder untuk menampilkan data keranjang
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _cartService.getCartStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyCart();
                  }
                  final cart = snapshot.data!;
                  return _buildCartContent(cart);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Keranjang Anda kosong', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Ayo temukan produk favorit Anda!', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.store),
            label: const Text('Belanja Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(List<Product> cart) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final double subtotal = cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
    final double grandTotal = subtotal + _selectedShippingService.cost;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cart.length,
            padding: const EdgeInsets.only(top: 8),
            itemBuilder: (_, i) {
              final p = cart[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(p.images.first, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(currencyFormatter.format(p.price), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(onPressed: () => _cartService.updateQuantity(p.id, p.quantity - 1), icon: const Icon(Icons.remove_circle_outline, size: 22)),
                                Text('${p.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(onPressed: () => _cartService.updateQuantity(p.id, p.quantity + 1), icon: const Icon(Icons.add_circle_outline, size: 22)),
                              ],
                            )
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 28),
                        onPressed: () => _cartService.removeFromCart(p.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Jasa Pengiriman:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<ShippingService>(
                value: _selectedShippingService,
                isExpanded: true,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                onChanged: (ShippingService? newValue) => setState(() => _selectedShippingService = newValue!),
                items: ShippingService.availableServices.map((service) => DropdownMenuItem<ShippingService>(
                  value: service,
                  child: Text('${service.name} - ${currencyFormatter.format(service.cost)}'),
                )).toList(),
              ),
              const SizedBox(height: 20),
              _buildSummaryRow('Subtotal:', currencyFormatter.format(subtotal)),
              const SizedBox(height: 8),
              _buildSummaryRow('Biaya Pengiriman:', currencyFormatter.format(_selectedShippingService.cost)),
              const Divider(height: 30),
              _buildSummaryRow('Total:', currencyFormatter.format(grandTotal), isTotal: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCheckingOut || cart.isEmpty ? null : () => _checkout(cart),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isCheckingOut ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Bayar Sekarang'),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isTotal ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) : textTheme.bodyMedium),
        Text(value, style: isTotal ? textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold) : textTheme.titleMedium),
      ],
    );
  }
}