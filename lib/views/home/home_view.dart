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

import '../events/events_view.dart';
import '../profile/profile_view.dart';
import '../profile/profile_edit_view.dart';
import '../profile/my_trades_view.dart';
import '../messages/tickets_view.dart';
import '../auth/login_view.dart';

import 'package:permission_handler/permission_handler.dart';
import '../widgets/ads/banner_ad_widget.dart';

import 'package:takasly/services/analytics_service.dart';
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
  bool _hasShownProfileWarning = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView('Ana Sayfa');
    _requestNotificationPermissions();
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
      // Also check profile completion when auth is complete
      _checkProfileCompletion();
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
    // If we haven't loaded yet, or if it failed/empty, load now.
    if (productVM.products.isEmpty) {
      productVM.init();
    }

    _checkProfileCompletion();
  }

  void _checkProfileCompletion({bool force = false}) {
    if (_hasShownProfileWarning && !force) return;

    final authVM = context.read<AuthViewModel>();
    final profile = authVM.userProfile;

    if (profile != null) {
      final firstName = profile.userFirstname?.trim() ?? "";
      final lastName = profile.userLastname?.trim() ?? "";

      if (firstName.isEmpty || lastName.isEmpty) {
        _hasShownProfileWarning = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => PopScope(
              canPop: false,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Değerli Kullanıcımız 💚",
                        style: AppTheme.safePoppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  "Topluluğumuzda güvenli ve sağlıklı bir deneyim sunabilmek için ad ve soyad bilgilerine ihtiyaç duyuyoruz.",
                  style: AppTheme.safePoppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProfileEditView(isMandatory: true),
                          ),
                        );
                        // Back from edit: get fresh data
                        await authVM.getUser();
                        final fName =
                            authVM.userProfile?.userFirstname?.trim() ?? "";
                        final lName =
                            authVM.userProfile?.userLastname?.trim() ?? "";

                        if (fName.isNotEmpty && lName.isNotEmpty) {
                          // Success! Close the dialog and reset flag
                          if (context.mounted) Navigator.pop(context);
                          _hasShownProfileWarning = false;
                        }
                      },
                      child: const Text(
                        "PROFİLİ GÜNCELLE",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      }
    } else if (authVM.isAuthCheckComplete && authVM.user != null) {
      // If profile is null but user is logged in, profile might be loading.
      // Listen for changes once.
      void tempListener() {
        if (authVM.userProfile != null) {
          authVM.removeListener(tempListener);
          _checkProfileCompletion(force: force);
        }
      }

      authVM.addListener(tempListener);
    }
  }

  Future<void> _requestNotificationPermissions() async {
    await Permission.notification.request();
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
                                ? _buildCategorySkeleton()
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
                                            homeViewModel.clearFilters();
                                            productViewModel.clearAllFilters();
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
                                                      .read<ProductViewModel>()
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
