import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/views/products/product_detail_view.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/product_detail_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/product_card.dart';
import '../notifications/notifications_view.dart';
import '../widgets/custom_bottom_nav.dart';
import 'widgets/filter_bottom_sheet.dart';

import '../events/events_view.dart';
import '../profile/profile_view.dart';
import '../profile/my_trades_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Bottom Nav Index
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Fetch Data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().init();
      // ProductViewModel init happens after token sync in didChangeDependencies
      // We removed the unconditional init() here to prevent guest-mode fetch race condition.
      // context.read<ProductViewModel>().init();
    });
  }

  bool _isInitDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitDone) return;

    try {
      final authVM = context.watch<AuthViewModel>();
      if (authVM.isAuthCheckComplete) {
        _isInitDone = true;
        final productVM = context.read<ProductViewModel>();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          bool isFirstInit = productVM.products.isEmpty && !productVM.isLoading;

          // Sync token.
          // If this is the first initialization, DO NOT refresh immediately.
          // Let init() called below handle the fetch after getting location.
          productVM.setUserToken(authVM.user?.token, refresh: !isFirstInit);

          // If products are not loaded yet, call init() which handles Location + Fetch
          if (isFirstInit) {
            productVM.init();
          }
        });
      }
    } catch (e) {
      // In case providers are not ready
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductViewModel>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background, // Light/White background
      extendBody: true,
      body: _selectedIndex == 4
          ? const ProfileView()
          : _selectedIndex == 3
          ? const MyTradesView(showBackButton: false)
          : SafeArea(
              child: _selectedIndex != 0
                  ? Center(
                      child: Text(
                        "Sayfa $_selectedIndex Yapım Aşamasında",
                        style: AppTheme.safePoppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : Consumer2<HomeViewModel, ProductViewModel>(
                      builder: (context, homeViewModel, productViewModel, child) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            await productViewModel.fetchProducts(
                              isRefresh: true,
                            );
                          },
                          color: AppTheme.primary,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              // Header - Logo, Buttons
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                    vertical: 10.0,
                                  ),
                                  child: Row(
                                    children: [
                                      // Logo
                                      if (homeViewModel.logos?.logo != null)
                                        Image.network(
                                          homeViewModel.logos!.logo!,
                                          height: 50, // Adjust height
                                          errorBuilder: (c, e, s) => const Text(
                                            'Takasly',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        )
                                      else
                                        const Text(
                                          'Takasly',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                            color: AppTheme.primary,
                                          ),
                                        ),

                                      const Spacer(),

                                      // Activities Button
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const EventsView(),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.celebration,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'ETKİNLİKLER',
                                                style: AppTheme.safePoppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Notification Icon
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const NotificationsView(),
                                            ),
                                          );
                                        },
                                        child: Stack(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                              child: const Icon(
                                                Icons.notifications_none,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.red,
                                                ),
                                                child: const Text(
                                                  '1',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Search Bar
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          decoration: InputDecoration(
                                            hintText: 'Ürün ara...',
                                            prefixIcon: const Icon(
                                              Icons.search,
                                              color: Colors.grey,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 0,
                                                ),
                                          ),
                                          onChanged: (val) {
                                            // Search debouncing could be added here
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () {
                                          _showFilterBottomSheet(context);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF424242,
                                            ), // Dark Grey for filter bg
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.filter_list,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Categories
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 90,
                                  child: homeViewModel.isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : ListView.separated(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          scrollDirection: Axis.horizontal,
                                          itemCount:
                                              homeViewModel.categories.isEmpty
                                              ? 1
                                              : homeViewModel
                                                        .categories
                                                        .length +
                                                    1, // +1 for 'Tümü'
                                          separatorBuilder: (c, i) =>
                                              const SizedBox(width: 0),
                                          itemBuilder: (context, index) {
                                            if (index == 0) {
                                              // 'Tümü' (All) Static Item
                                              return GestureDetector(
                                                onTap: () {
                                                  productViewModel
                                                      .filterByCategory(null);
                                                },
                                                child: SizedBox(
                                                  width: 60,
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                              color: AppTheme
                                                                  .primary,
                                                              shape: BoxShape
                                                                  .circle,
                                                              boxShadow: AppTheme
                                                                  .cardShadow,
                                                            ),
                                                        child: const Icon(
                                                          Icons.grid_view,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Tümü',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            AppTheme.safePoppins(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: AppTheme
                                                                  .textPrimary,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }
                                            final category = homeViewModel
                                                .categories[index - 1];
                                            return CategoryCard(
                                              category: category,
                                              onTap: () {
                                                productViewModel
                                                    .filterByCategory(
                                                      category.catID,
                                                    );
                                              },
                                            );
                                          },
                                        ),
                                ),
                              ),

                              // Product Grid
                              if (productViewModel.isLoading &&
                                  productViewModel.products.isEmpty)
                                const SliverFillRemaining(
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (productViewModel.errorMessage != null &&
                                  productViewModel.products.isEmpty)
                                SliverFillRemaining(
                                  child: Center(
                                    child: Text(productViewModel.errorMessage!),
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.all(16),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio:
                                              0.65, // Adjust for card height
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                        ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        if (index >=
                                            productViewModel.products.length)
                                          return null;
                                        final product =
                                            productViewModel.products[index];
                                        return ProductCard(
                                          product: product,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChangeNotifierProvider(
                                                      create: (_) =>
                                                          ProductDetailViewModel(),
                                                      child: ProductDetailView(
                                                        productId:
                                                            product.productID!,
                                                      ),
                                                    ),
                                              ),
                                            );
                                          },
                                          onFavoritePressed: () {
                                            productViewModel.toggleFavorite(
                                              product,
                                            );
                                          },
                                        );
                                      },
                                      childCount:
                                          productViewModel.products.length,
                                    ),
                                  ),
                                ),

                              // Loading More Indicator
                              if (productViewModel.isLoadMoreRunning)
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 100),
                              ), // Bottom padding
                            ],
                          ),
                        );
                      },
                    ),
            ),
      // Bottom Navigation Bar (Visual only for now matching design)
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }
}
