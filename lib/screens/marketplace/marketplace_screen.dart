import 'package:flutter/material.dart';

import '../../models/marketplace_product.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import '../../widgets/smart_image_view.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<MarketplaceProduct> _allProducts = [];
  List<MarketplaceProduct> _myProducts = [];
  bool _loading = true;
  Object? _error;
  String _selectedCategory = 'semua';

  static const List<Map<String, String>> _categories = [
    {'value': 'semua', 'label': 'Semua'},
    {'value': 'buku', 'label': '📚 Buku Kuliah'},
    {'value': 'merchandise', 'label': '🎨 Merchandise'},
    {'value': 'elektronik', 'label': '💻 Elektronik'},
    {'value': 'fashion', 'label': '👕 Fashion'},
    {'value': 'makanan', 'label': '🍱 Makanan'},
    {'value': 'jasa', 'label': '💼 Jasa/Proofread'},
    {'value': 'lainnya', 'label': '📦 Lainnya'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final queryParams = <String, String>{
        if (_searchController.text.trim().isNotEmpty) 'search': _searchController.text.trim(),
        if (_selectedCategory != 'semua') 'category': _selectedCategory,
      };

      final uri = Uri(path: '/marketplace-products', queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final futures = await Future.wait([
        ApiClient.instance.get(uri.toString()),
        ApiClient.instance.get('/my-marketplace-products'),
      ]);

      final allRes = futures[0];
      final myRes = futures[1];

      final allList = (allRes is Map<String, dynamic> && allRes['data'] is List)
          ? (allRes['data'] as List).map((p) => MarketplaceProduct.fromJson(p as Map<String, dynamic>)).toList()
          : <MarketplaceProduct>[];

      final myList = (myRes is List)
          ? myRes.map((p) => MarketplaceProduct.fromJson(p as Map<String, dynamic>)).toList()
          : <MarketplaceProduct>[];

      if (mounted) {
        setState(() {
          _allProducts = allList;
          _myProducts = myList;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openAddProduct() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toko Mahasiswa/i', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('FIB UNDIP · Preloved & Jual-Beli Kampus', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront, size: 18),
                  const SizedBox(width: 6),
                  const Text('Katalog Toko'),
                  if (_allProducts.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_allProducts.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 18),
                  const SizedBox(width: 6),
                  const Text('Jualan Saya'),
                  if (_myProducts.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_myProducts.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const GlobalBottomNavBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProduct,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Jual Barang'),
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error.toString(), onRetry: _load)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCatalogTab(),
                    _buildMyProductsTab(),
                  ],
                ),
    );
  }

  Widget _buildCatalogTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          // Search & Filter Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari buku kuliah, merchandise, jasa...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _load();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                  const SizedBox(height: 10),

                  // Category Chips
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSelected = _selectedCategory == cat['value'];
                        return FilterChip(
                          selected: isSelected,
                          label: Text(
                            cat['label']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (selected) {
                            setState(() => _selectedCategory = cat['value']!);
                            _load();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product Grid
          if (_allProducts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_outlined, size: 56, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum Ada Barang di Toko Mahasiswa/i',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Jadilah yang pertama menjual buku kuliah, kamus, atau merchandise di kampus!',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _openAddProduct,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Pasang Jualan Pertama'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.64,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _allProducts[index];
                    return _buildProductCard(product);
                  },
                  childCount: _allProducts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyProductsTab() {
    if (_myProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 56, color: Color(0xFF047857)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Anda Belum Memasang Jualan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Punya modul kuliah bekas, buku sastra, atau merchandise? Jual sekarang kepada teman kampus.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _openAddProduct,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Jual Barang Sekarang'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF047857)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        itemCount: _myProducts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final product = _myProducts[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: InkWell(
              onTap: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                );
                if (changed == true) _load();
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade100,
                        child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                            ? SmartImageView(imageUrl: product.imageUrl!, fit: BoxFit.cover)
                            : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: product.isSold ? Colors.red.shade100 : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  product.isSold ? 'TERJUAL' : 'TERSEDIA',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: product.isSold ? Colors.red.shade800 : Colors.green.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  product.categoryLabel,
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.formattedPrice,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(MarketplaceProduct product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
          );
          if (changed == true) _load();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image & Status Badge
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? SmartImageView(imageUrl: product.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            child: const Center(
                              child: Icon(Icons.shopping_bag_outlined, size: 36, color: AppColors.primary),
                            ),
                          ),
                  ),
                  if (product.isSold)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'TERJUAL',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.conditionLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Information
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Color(0xFF047857),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          product.user?.name.isNotEmpty == true ? product.user!.name[0].toUpperCase() : 'M',
                          style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          product.user?.name ?? 'Mahasiswa',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (product.location != null && product.location!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 10, color: Color(0xFFE11D48)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            product.location!,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
