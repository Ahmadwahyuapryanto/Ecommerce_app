// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'notification_screen.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart'; // Import CartService
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  late final Stream<List<Product>> _productsStream;
  late final Stream<List<Product>> _cartStream;

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  String _selectedCategory = 'Semua Kategori';
  List<String> _categories = ['Semua Kategori'];
  int _bottomNavIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final GlobalKey _cartKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _animation;

  late final PageController _bannerController;
  Timer? _bannerTimer;
  final List<String> _bannerImages = [
    'assets/banners/banner1.png',
    'assets/banners/banner2.png',
    'assets/banners/banner3.png',
  ];

  @override
  void initState() {
    super.initState();
    _productsStream = _productService.getProductsStream();
    _cartStream = _cartService.getCartStream();
    _bannerController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startBannerTimer());
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_bannerController.hasClients) return;
      int nextPage = _bannerController.page!.round() + 1;
      if (nextPage >= _bannerImages.length) nextPage = 0;
      _bannerController.animateToPage(nextPage, duration: const Duration(milliseconds: 400), curve: Curves.easeIn);
    });
  }

  void _updateCategoriesAndFilter(List<Product> products) {
    if (!mounted) return;
    _allProducts = products;
    final newCategories = products.map((p) => p.category).toSet().toList();
    if (newCategories.toSet().difference(_categories.toSet()).isNotEmpty || _categories.toSet().difference(newCategories.toSet()).isNotEmpty) {
      setState(() {
        _categories = ['Semua Kategori', ...newCategories];
      });
    }
    _applyFilters();
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
    _applyFilters();
  }

  void _applyFilters() {
    if (!mounted) return;
    List<Product> tempProducts = List.from(_allProducts);
    if (_selectedCategory != 'Semua Kategori') {
      tempProducts = tempProducts.where((p) => p.category == _selectedCategory).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempProducts = tempProducts.where((p) => p.name.toLowerCase().contains(query)).toList();
    }
    setState(() => _filteredProducts = tempProducts);
  }

  void _showCart() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8, minChildSize: 0.4, maxChildSize: 0.9,
        builder: (_, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: CartScreen(onCartChanged: () {}),
        ),
      ),
    );
  }

  void _runFlyToCartAnimation(GlobalKey widgetKey, Widget image) async {
    if (!mounted) return;
    final RenderBox renderBox = widgetKey.currentContext!.findRenderObject() as RenderBox;
    final startPosition = renderBox.localToGlobal(Offset.zero);
    final RenderBox cartRenderBox = _cartKey.currentContext!.findRenderObject() as RenderBox;
    final endPosition = cartRenderBox.localToGlobal(Offset.zero);

    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final double top = startPosition.dy + (endPosition.dy - startPosition.dy) * _animation.value;
        final double left = startPosition.dx + (endPosition.dx - startPosition.dx) * _animation.value;
        return Positioned(
          top: top, left: left,
          child: Opacity(
            opacity: 1.0 - _animation.value,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(height: 40, width: 40, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: image)),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.reset();
    _animationController.forward();
    _animation.addListener(() {
      if(mounted) _overlayEntry?.markNeedsBuild();
    });
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      key: const ValueKey('normal_app_bar'),
      leading: Center(
        child: StreamBuilder<List<Product>>(
          stream: _cartStream,
          builder: (context, snapshot) {
            final cartItemCount = snapshot.data?.length ?? 0;
            return Stack(
              key: _cartKey,
              alignment: Alignment.center,
              children: [
                IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: _showCart, tooltip: 'Keranjang Belanja'),
                if (cartItemCount > 0)
                  Positioned(
                    right: 4, top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$cartItemCount', style: TextStyle(color: Theme.of(context).colorScheme.onError, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      title: Text('KEYWORD', style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _isSearching = true)),
        const SizedBox(width: 8),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      key: const ValueKey('search_app_bar'),
      leading: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() {
        _isSearching = false;
        _searchController.clear();
      })),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Cari produk...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey)),
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildHomePageContent() {
    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting && _allProducts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if(mounted) _updateCategoriesAndFilter(products);
        });

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isSearching) _buildPromoBanner(),
                if (!_isSearching) _buildCategoryChips(),
                _buildSectionHeader(_isSearching ? 'Hasil Pencarian' : 'Produk Pilihan'),
                _buildProductGrid(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomePageContent(),
      const OrderHistoryScreen(),
      const NotificationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final offsetAnimation = Tween<Offset>(begin: const Offset(0.0, -0.5), end: Offset.zero).animate(animation);
            return FadeTransition(opacity: animation, child: SlideTransition(position: offsetAnimation, child: child));
          },
          child: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
        ),
      ),
      body: IndexedStack(index: _bottomNavIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[500],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Notifikasi'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    // --- PERUBAHAN UTAMA DI SINI ---
    // Jangan tampilkan loading jika daftar banner kosong, cukup sembunyikan saja.
    if (_bannerImages.isEmpty) {
      return const SizedBox.shrink(); // Return widget kosong
    }

    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Container(
        margin: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            PageView.builder(
              controller: _bannerController,
              itemCount: _bannerImages.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    _bannerImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Cetak pesan error ke console untuk debugging
                      print('Error loading banner image: ${_bannerImages[index]}');
                      print('Error details: $error');
                      // Tampilkan UI pengganti jika gambar gagal dimuat
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      );
                    },
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_bannerImages.length, (index) {
                    return AnimatedBuilder(
                      animation: _bannerController,
                      builder: (context, child) {
                        double selectedness = 1.0;
                        // Cek _bannerController.hasClients sebelum mengakses .page
                        if (_bannerController.hasClients) {
                          double page = _bannerController.page ?? _bannerController.initialPage.toDouble();
                          selectedness = (page - index).abs().clamp(0.0, 1.0);
                        } else {
                          // Default value jika controller belum siap
                          selectedness = (index == 0) ? 0.0 : 1.0;
                        }
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          height: 8,
                          width: selectedness == 0 ? 24 : 8,
                          decoration: BoxDecoration(
                            color: selectedness == 0 ? Colors.white : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        padding: const EdgeInsets.only(left: 16.0),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () => _selectCategory(category),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.grey[900] : Colors.white,
                foregroundColor: isSelected ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                elevation: isSelected ? 2 : 0,
              ),
              child: Text(category),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProductGrid() {
    if (_allProducts.isEmpty && _filteredProducts.isEmpty) {
      return const Center(heightFactor: 5, child: Text("Tidak ada produk yang tersedia."));
    }
    if (_filteredProducts.isEmpty) {
      return const Center(heightFactor: 5, child: Text('Produk tidak ditemukan.'));
    }

    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.58,
        ),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 2,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: ProductCard(
                  key: ValueKey(product.id),
                  product: product,
                  onAddToCart: _runFlyToCartAnimation,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}