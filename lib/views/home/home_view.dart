import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/general_models.dart';
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

import '../profile/profile_view.dart';
import '../profile/my_trades_view.dart';
import '../messages/tickets_view.dart';
import '../auth/login_view.dart';

import 'package:permission_handler/permission_handler.dart';
import '../../services/cache_service.dart';
import '../widgets/ads/banner_ad_widget.dart';

import 'package:takasly/services/analytics_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

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
    AnalyticsService().logScreenView('Ana Sayfa');
    _checkAndShowNotificationSoftPrompt();
    _scrollController.addListener(_onScroll);

    // Data fetching moved to RootView (Splash phase)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final homeVM = context.read<HomeViewModel>();
        // Show already loaded popups
        if (homeVM.popups.isNotEmpty) {
          _showPopups(homeVM.popups);
        }

        // Handle Product Initialization (Notifications, profile check etc.)
        final authVM = context.read<AuthViewModel>();
        if (authVM.isAuthCheckComplete) {
          _initProducts();
        } else {
          // Listen for auth completion
          authVM.addListener(_authListener);
        }
      }
    });
  }

  void _authListener() {
    if (!mounted) return;
    final authVM = context.read<AuthViewModel>();
    if (authVM.isAuthCheckComplete) {
      authVM.removeListener(_authListener);
      _initProducts();
    }
  }

  void _initProducts() {
    if (!mounted) return;
    final authVM = context.read<AuthViewModel>();
    final productVM = context.read<ProductViewModel>();

    // Set token
    productVM.setUserToken(authVM.user?.token, refresh: false);

    // Fetch notifications
    if (authVM.user?.userID != null) {
      context.read<NotificationViewModel>().fetchNotifications(
        authVM.user!.userID,
      );
    }

    // Fetch Products
    // Attempt to get location and sort by it by default
    Geolocator.getCurrentPosition()
        .then((position) {
          if (mounted) {
            productVM.updateLocation(position.latitude, position.longitude);
          }
        })
        .catchError((e) {
          // If location fails, fallback to standard init (default sort)
          if (productVM.products.isEmpty) {
            productVM.init();
          }
        });
  }

  Future<void> _checkAndShowNotificationSoftPrompt() async {
    final cache = CacheService();
    final shown = await cache.isNotificationPromptShown();
    if (shown) return;

    final status = await Permission.notification.status;
    if (status.isDenied ||
        status.isLimited ||
        status.isProvisional ||
        status.isRestricted) {
      // Logic handled, wait a bit for home to settle
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _showNotificationSoftPrompt();
      });
    }
  }

  void _showNotificationSoftPrompt() {
    showAdaptiveDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog.adaptive(
        title: const Text("Takasly"),
        content: const Text(
          "Yeni takas tekliflerinden, mesajlardan ve fırsatlardan haberdar olmak için bildirimlerinizi açmak ister misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await CacheService().setNotificationPromptShown();
            },
            child: const Text(
              "Daha Sonra",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await CacheService().setNotificationPromptShown();
              await Permission.notification.request();
            },
            child: const Text(
              "İzin Ver",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Logic moved to initState/_authListener
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
          : DefaultTabController(
              length: 2,
              initialIndex:
                  context.read<ProductViewModel>().sortType == 'location'
                  ? 1
                  : 0,
              child: SafeArea(
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
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                12,
                              ),
                              child: Row(
                                children: [
                                  // Logo
                                  if (homeViewModel.logos?.logo != null)
                                    Image.network(
                                      homeViewModel.logos!.logo!,
                                      height: 48, // Slightly cleaner height
                                      errorBuilder: (c, e, s) => Text(
                                        'Takasly',
                                        style: AppTheme.safePoppins(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      'Takasly',
                                      style: AppTheme.safePoppins(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                        color: AppTheme.primary,
                                      ),
                                    ),

                                  const Spacer(),

                                  // --- Premium Header Sorting Switcher ---
                                  Container(
                                    width:
                                        200, // Widened for more breathability
                                    height: 38,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F1F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TabBar(
                                      dividerColor: Colors.transparent,
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      indicator: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(9),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      onTap: (index) {
                                        if (index == 0) {
                                          productViewModel.updateAllFilters(
                                            sortType: 'default',
                                          );
                                        } else {
                                          productViewModel.updateAllFilters(
                                            sortType: 'location',
                                          );
                                        }
                                      },
                                      labelColor: AppTheme.primary,
                                      unselectedLabelColor: const Color(
                                        0xFF64748B,
                                      ),
                                      labelStyle: AppTheme.safePoppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                      unselectedLabelStyle:
                                          AppTheme.safePoppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF64748B),
                                          ),
                                      tabs: [
                                        Tab(
                                          child:
                                              productViewModel.sortType ==
                                                  'default'
                                              ? const Icon(
                                                  Icons.auto_awesome,
                                                  size: 20,
                                                )
                                              : const Text('En Yeniler'),
                                        ),
                                        Tab(
                                          child:
                                              productViewModel.sortType ==
                                                  'location'
                                              ? const Icon(
                                                  Icons.near_me_rounded,
                                                  size: 20,
                                                )
                                              : const Text('Yakınımda'),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),

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
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(9),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.04),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons
                                                    .notifications_none_rounded,
                                                color: AppTheme.textPrimary,
                                                size: 22,
                                              ),
                                            ),
                                            if (notificationVM.unreadCount > 0)
                                              Positioned(
                                                top: -2,
                                                right: -2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 16,
                                                        minHeight: 16,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppTheme.error,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    notificationVM.unreadCount >
                                                            9
                                                        ? '9+'
                                                        : notificationVM
                                                              .unreadCount
                                                              .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w800,
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
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.03,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.search_rounded,
                                              color: Color(0xFF94A3B8),
                                              size: 22,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Neye ihtiyacın var?',
                                              style: AppTheme.safePoppins(
                                                color: const Color(0xFF94A3B8),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
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
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primary.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.tune_rounded,
                                        color: Colors.white,
                                        size: 22,
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
                              height: 105,
                              child:
                                  homeViewModel.categories.isEmpty &&
                                      homeViewModel.isCategoriesLoading
                                  ? _buildCategorySkeleton()
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      scrollDirection: Axis.horizontal,
                                      itemCount:
                                          homeViewModel.categories.isEmpty
                                          ? 1
                                          : homeViewModel.categories.length + 1,
                                      separatorBuilder: (c, i) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        if (index == 0) {
                                          final isAllSelected =
                                              productViewModel
                                                  .selectedCategoryId ==
                                              0;
                                          return GestureDetector(
                                            onTap: () {
                                              homeViewModel.clearFilters();
                                              productViewModel
                                                  .clearAllFilters();
                                            },
                                            child: SizedBox(
                                              width: 70,
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: 44,
                                                    height: 44,
                                                    decoration: BoxDecoration(
                                                      color: isAllSelected
                                                          ? AppTheme.primary
                                                          : Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.05,
                                                              ),
                                                          blurRadius: 6,
                                                          offset: const Offset(
                                                            0,
                                                            3,
                                                          ),
                                                        ),
                                                      ],
                                                      border: isAllSelected
                                                          ? null
                                                          : Border.all(
                                                              color: Colors
                                                                  .grey
                                                                  .shade100,
                                                            ),
                                                    ),
                                                    child: Icon(
                                                      Icons.grid_view_rounded,
                                                      color: isAllSelected
                                                          ? Colors.white
                                                          : AppTheme.primary,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Tümü',
                                                    textAlign: TextAlign.center,
                                                    style: AppTheme.safePoppins(
                                                      fontSize: 11,
                                                      fontWeight: isAllSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w600,
                                                      color: isAllSelected
                                                          ? AppTheme.primary
                                                          : AppTheme
                                                                .textPrimary,
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
                                                            color: AppTheme
                                                                .primary,
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
                                            productViewModel
                                                .selectedCategoryId ==
                                            category.catID;
                                        return CategoryCard(
                                          category: category,
                                          isSelected: isSelected,
                                          onTap: () {
                                            homeViewModel.setSelectedCategory(
                                              category,
                                            );
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
                            _buildProductListSkeleton()
                          else if (productViewModel.errorMessage != null &&
                              productViewModel.products.isEmpty)
                            SliverFillRemaining(
                              child: Center(
                                child: Text(productViewModel.errorMessage!),
                              ),
                            )
                          else if (productViewModel.products.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(context),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    const int kCycleSize =
                                        3; // Row, Row, Banner

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
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: AspectRatio(
                                              aspectRatio: 0.65,
                                              child: ProductCard(
                                                product: firstProduct,
                                                onTap: () async {
                                                  await Navigator.push(
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
                                                  // Refresh products when returning from detail
                                                  if (context.mounted) {
                                                    context
                                                        .read<
                                                          ProductViewModel
                                                        >()
                                                        .fetchProducts(
                                                          isRefresh: true,
                                                        );
                                                  }
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
                                                  productViewModel
                                                      .toggleFavorite(
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
                                                      onTap: () async {
                                                        await Navigator.push(
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
                                                        // Refresh products when returning from detail
                                                        if (context.mounted) {
                                                          context
                                                              .read<
                                                                ProductViewModel
                                                              >()
                                                              .fetchProducts(
                                                                isRefresh: true,
                                                              );
                                                        }
                                                      },
                                                      onFavoritePressed: () {
                                                        final authVM = context
                                                            .read<
                                                              AuthViewModel
                                                            >();
                                                        if (authVM.user ==
                                                            null) {
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

  Future<void> _showPopups(List<Popup> popups) async {
    final homeViewModel = context.read<HomeViewModel>();

    for (final popup in popups) {
      if (!mounted) return;

      // Checkbox state for this specific popup
      bool doNotShowAgain = false;

      await showDialog(
        context: context,
        barrierDismissible: false, // Force user to use button
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                insetPadding: const EdgeInsets.all(5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (popup.popupImage != null &&
                          popup.popupImage!.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.network(
                            popup.popupImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (c, e, s) => const SizedBox(),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            // 'Do Not Show Again' Checkbox for Type 1
                            if (popup.popupView == 1)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    doNotShowAgain = !doNotShowAgain;
                                  });
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Checkbox(
                                      value: doNotShowAgain,
                                      activeColor: AppTheme.primary,
                                      onChanged: (val) {
                                        setState(() {
                                          doNotShowAgain = val ?? false;
                                        });
                                      },
                                    ),
                                    Text(
                                      'Bir daha gösterme',
                                      style: AppTheme.safePoppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      if (doNotShowAgain &&
                                          popup.popupID != null) {
                                        homeViewModel.hidePopup(popup.popupID!);
                                      }
                                      Navigator.pop(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppTheme.primary,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Kapat',
                                      style: TextStyle(color: AppTheme.primary),
                                    ),
                                  ),
                                ),
                                if (popup.popupLink != null &&
                                    popup.popupLink!.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final urlString = popup.popupLink!
                                            .trim();
                                        final uri = Uri.tryParse(urlString);
                                        if (uri != null) {
                                          try {
                                            await launchUrl(
                                              uri,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          } catch (e) {
                                            debugPrint("Launch error: $e");
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'DETAYA GİT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: AppTheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Henüz İlan Yok",
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Bu kategoride henüz ilan bulunmamaktadır. İlk ilanı sen eklemek ister misin?",
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                color: AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductView(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                "Hemen İlan Ekle",
                style: AppTheme.safePoppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductListSkeleton() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(child: _buildProductItemSkeleton()),
                const SizedBox(width: 16),
                Expanded(child: _buildProductItemSkeleton()),
              ],
            ),
          ),
          childCount: 3,
        ),
      ),
    );
  }

  Widget _buildProductItemSkeleton() {
    return AspectRatio(
      aspectRatio: 0.65,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.borderRadius,
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.vertical(
                    top: AppTheme.borderRadius.topLeft,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 60, height: 8, color: Colors.grey[100]),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: Colors.grey[100],
                  ),
                  const SizedBox(height: 4),
                  Container(width: 100, height: 12, color: Colors.grey[100]),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(width: 12, height: 12, color: Colors.grey[100]),
                      const SizedBox(width: 4),
                      Container(width: 80, height: 8, color: Colors.grey[100]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
