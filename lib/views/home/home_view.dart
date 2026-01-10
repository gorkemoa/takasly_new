import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/views/products/product_detail_view.dart';
import 'package:takasly/views/products/add_product_view.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/product_detail_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/ticket_viewmodel.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/product_card.dart';
import '../notifications/notifications_view.dart';
import '../widgets/custom_bottom_nav.dart';
import 'widgets/filter_bottom_sheet.dart';
import '../search/search_view.dart';
import '../../viewmodels/search_viewmodel.dart';

import '../events/events_view.dart';
import '../profile/profile_view.dart';
import '../profile/my_trades_view.dart';
import '../messages/tickets_view.dart';
import '../auth/login_view.dart';

import 'package:permission_handler/permission_handler.dart';
import '../widgets/ads/banner_ad_widget.dart';

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
    _requestNotificationPermissions();
    _scrollController.addListener(_onScroll);
    // Fetch Data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().init();
    });
  }

  Future<void> _requestNotificationPermissions() async {
    await Permission.notification.request();
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
          productVM.setUserToken(authVM.user?.token, refresh: !isFirstInit);

          // Fetch notifications if user is logged in
          if (authVM.user?.userID != null) {
            context.read<NotificationViewModel>().fetchNotifications(
              authVM.user!.userID,
            );
          }

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

  void _refreshCurrentPage(int index) {
    final authVM = context.read<AuthViewModel>();
    final token = authVM.user?.token;
    final userID = authVM.user?.userID;

    switch (index) {
      case 0: // Home
        context.read<ProductViewModel>().fetchProducts(isRefresh: true);
        context.read<HomeViewModel>().init(isRefresh: true);
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        break;
      case 1: // Messages
        if (token != null) {
          context.read<TicketViewModel>().fetchTickets(token, isRefresh: true);
        }
        break;
      case 3: // My Trades
        if (userID != null) {
          context.read<TradeViewModel>().getTrades(userID);
        }
        break;
      case 4: // Profile
        if (authVM.user != null) {
          authVM.getUser();
        }
        break;
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
          : _selectedIndex == 1
          ? const TicketsView()
          : SafeArea(
              child: Consumer2<HomeViewModel, ProductViewModel>(
                builder: (context, homeViewModel, productViewModel, child) {
                  return RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: () async {
                      final authVM = context.read<AuthViewModel>();
                      final notificationVM = context
                          .read<NotificationViewModel>();

                      await Future.wait([
                        productViewModel.fetchProducts(isRefresh: true),
                        homeViewModel.init(isRefresh: true),
                        if (authVM.user?.userID != null)
                          notificationVM.fetchNotifications(
                            authVM.user!.userID,
                          ),
                      ]);
                    },
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
                                      borderRadius: BorderRadius.circular(20),
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
                                  child: Consumer<NotificationViewModel>(
                                    builder: (context, notificationVM, child) {
                                      return Stack(
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
                                          if (notificationVM.unreadCount > 0)
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 16,
                                                      minHeight: 16,
                                                    ),
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.red,
                                                ),
                                                child: Text(
                                                  notificationVM.unreadCount > 9
                                                      ? '9+'
                                                      : notificationVM
                                                            .unreadCount
                                                            .toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
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
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ChangeNotifierProvider(
                                                create: (_) =>
                                                    SearchViewModel(),
                                                child: const SearchView(),
                                              ),
                                        ),
                                      );
                                    },
                                    child: AbsorbPointer(
                                      child: TextField(
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          hintText: 'Ürün ara...',
                                          prefixIcon: const Icon(
                                            Icons.search,
                                            color: Colors.grey,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 0,
                                              ),
                                        ),
                                      ),
                                    ),
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
                                      borderRadius: BorderRadius.circular(12),
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
                            height: 92,
                            child:
                                homeViewModel.categories.isEmpty &&
                                    homeViewModel.isCategoriesLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: homeViewModel.categories.isEmpty
                                        ? 1
                                        : homeViewModel.categories.length +
                                              1, // +1 for 'Tümü'
                                    separatorBuilder: (c, i) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        // 'Tümü' (All) Static Item
                                        final isAllSelected =
                                            productViewModel
                                                .selectedCategoryId ==
                                            0;
                                        return GestureDetector(
                                          onTap: () {
                                            productViewModel.filterByCategory(
                                              null,
                                            );
                                          },
                                          child: SizedBox(
                                            width: 70,
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.grid_view,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Tümü',
                                                  textAlign: TextAlign.center,
                                                  style: AppTheme.safePoppins(
                                                    fontSize: 10,
                                                    fontWeight: isAllSelected
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                    color: isAllSelected
                                                        ? AppTheme.primary
                                                        : AppTheme.textPrimary,
                                                  ),
                                                ),
                                                if (isAllSelected)
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    width: 4,
                                                    height: 4,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color:
                                                              AppTheme.primary,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      final category =
                                          homeViewModel.categories[index - 1];
                                      final isSelected =
                                          productViewModel.selectedCategoryId ==
                                          category.catID;
                                      return CategoryCard(
                                        category: category,
                                        isSelected: isSelected,
                                        onTap: () {
                                          productViewModel.filterByCategory(
                                            category.catID,
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ),

                        // Product List with Interspersed Banners
                        if (productViewModel.isLoading &&
                            productViewModel.products.isEmpty)
                          const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator()),
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
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  const int kCycleSize = 3; // Row, Row, Banner

                                  // Check if it's a Banner Slot
                                  if ((index + 1) % kCycleSize == 0) {
                                    return const Padding(
                                      padding: EdgeInsets.only(bottom: 16),
                                      child: BannerAdWidget(),
                                    );
                                  }

                                  // Calculate Product Row
                                  // How many banners before this index?
                                  final int bannersBefore =
                                      (index + 1) ~/ kCycleSize;
                                  // How many product rows (items in list that are not banners)
                                  final int productRowsBefore =
                                      index - bannersBefore;
                                  // First product index for this row
                                  final int startProductIndex =
                                      productRowsBefore * 2;

                                  if (startProductIndex >=
                                      productViewModel.products.length) {
                                    return null;
                                  }

                                  final firstProduct = productViewModel
                                      .products[startProductIndex];
                                  final secondProduct =
                                      (startProductIndex + 1 <
                                          productViewModel.products.length)
                                      ? productViewModel
                                            .products[startProductIndex + 1]
                                      : null;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: AspectRatio(
                                            aspectRatio: 0.65,
                                            child: ProductCard(
                                              product: firstProduct,
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
                                                                firstProduct
                                                                    .productID!,
                                                          ),
                                                        ),
                                                  ),
                                                );
                                              },
                                              onFavoritePressed: () {
                                                final authVM = context
                                                    .read<AuthViewModel>();
                                                if (authVM.user == null) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const LoginView(),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                productViewModel.toggleFavorite(
                                                  firstProduct,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: secondProduct != null
                                              ? AspectRatio(
                                                  aspectRatio: 0.65,
                                                  child: ProductCard(
                                                    product: secondProduct,
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
                                                                      secondProduct
                                                                          .productID!,
                                                                ),
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    onFavoritePressed: () {
                                                      final authVM = context
                                                          .read<
                                                            AuthViewModel
                                                          >();
                                                      if (authVM.user == null) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                const LoginView(),
                                                          ),
                                                        );
                                                        return;
                                                      }
                                                      productViewModel
                                                          .toggleFavorite(
                                                            secondProduct,
                                                          );
                                                    },
                                                  ),
                                                )
                                              : const SizedBox(), // Empty holder
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                // Count rough estimate: (Products / 2) + Banners
                                childCount: (() {
                                  final productCount =
                                      productViewModel.products.length;
                                  final rowCount = (productCount / 2).ceil();
                                  final bannerCount = rowCount ~/ 2;
                                  return rowCount + bannerCount;
                                })(),
                              ),
                            ),
                          ),

                        // Loading More Indicator
                        if (productViewModel.isLoadMoreRunning)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator()),
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
      // Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddProductView()),
            );
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
          _refreshCurrentPage(index);
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
