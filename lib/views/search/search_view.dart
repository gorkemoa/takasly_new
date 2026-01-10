import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../viewmodels/search_viewmodel.dart';
import '../../viewmodels/product_detail_viewmodel.dart'; // For navigation to details
import '../../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../products/product_detail_view.dart';
import '../../models/search/popular_category_model.dart';
import 'widgets/search_filter_bottom_sheet.dart';
import '../widgets/ads/banner_ad_widget.dart';
import '../auth/login_view.dart';
import '../../viewmodels/auth_viewmodel.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchViewModel>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchViewModel>().loadMore();
    }
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.read<SearchViewModel>().search(query);
    }
  }

  void _showFilterBottomSheet() {
    final viewModel = context.read<SearchViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const SearchFilterBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<SearchViewModel>(
        builder: (context, viewModel, child) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. Header Section
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Bar with Back Button and Title
                          SizedBox(
                            height: 44,
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  left: 0,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  'Ürün Ara',
                                  style: AppTheme.safePoppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Unified Modern Search Bar
                          Container(
                            height: 55, // Fixed comfortable height
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Leading Search Icon
                                const Padding(
                                  padding: EdgeInsets.only(left: 16, right: 12),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: AppTheme.primary,
                                    size: 24,
                                  ),
                                ),

                                // Search Input Field
                                Expanded(
                                  child:
                                      ValueListenableBuilder<TextEditingValue>(
                                        valueListenable: _searchController,
                                        builder: (context, value, child) {
                                          return TextField(
                                            controller: _searchController,
                                            textInputAction:
                                                TextInputAction.search,
                                            onSubmitted: (val) {
                                              FocusScope.of(context).unfocus();
                                              _performSearch(val);
                                            },
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            style: AppTheme.safePoppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimary,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Neye ihtiyacın var?',
                                              hintStyle: AppTheme.safePoppins(
                                                color: Colors.grey.shade400,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              filled: false,
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                              suffixIcon: value.text.isNotEmpty
                                                  ? GestureDetector(
                                                      onTap: () {
                                                        _searchController
                                                            .clear();
                                                        context
                                                            .read<
                                                              SearchViewModel
                                                            >()
                                                            .clearSearch();
                                                      },
                                                      child: Icon(
                                                        Icons.cancel_rounded,
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                        size: 20,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          );
                                        },
                                      ),
                                ),

                                // Vertical Setup Divider
                                Container(
                                  height: 24,
                                  width: 1.5,
                                  color: Colors.grey.shade100,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),

                                // Filter Button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _showFilterBottomSheet,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.tune_rounded,
                                        color: AppTheme.textSecondary,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),

                                // Search Action Button
                                Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Material(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        _performSearch(_searchController.text);
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: const SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
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
                ),
              ),

              // 2. Logic & Content
              if (viewModel.isLoading && viewModel.products.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                    ),
                  ),
                )
              else if (viewModel.errorMessage != null)
                SliverFillRemaining(
                  child: _buildEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: "Bir Sorun Oluştu",
                    subtitle: viewModel.errorMessage!,
                    color: Colors.redAccent,
                  ),
                )
              else if (viewModel.products.isEmpty) ...[
                if (_searchController.text.isEmpty &&
                    viewModel.popularCategories.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Text(
                        "Popüler Kategoriler",
                        style: AppTheme.safePoppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _buildPopularCategoryItem(
                          viewModel.popularCategories[index],
                        );
                      }, childCount: viewModel.popularCategories.length),
                    ),
                  ),
                ] else
                  SliverFillRemaining(
                    child: _buildEmptyState(
                      icon: _searchController.text.isEmpty
                          ? Icons.manage_search_rounded
                          : Icons.search_off_rounded,
                      title: _searchController.text.isEmpty
                          ? "Keşfetmeye Hazır mısın?"
                          : "Sonuç Bulunamadı",
                      subtitle: _searchController.text.isEmpty
                          ? "Aradığın her şeyi burada bulabilirsin."
                          : "'${_searchController.text}' için uygun sonuç bulamadık.",
                    ),
                  ),
              ] else ...[
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (viewModel.currentCategoryName != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Kategori: ${viewModel.currentCategoryName}",
                                      style: AppTheme.safePoppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        context
                                            .read<SearchViewModel>()
                                            .clearSearch();
                                        _searchController.clear();
                                      },
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: Text(
                          "${viewModel.totalItems} Sonuç Bulundu",
                          style: AppTheme.safePoppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                        final int bannersBefore = (index + 1) ~/ kCycleSize;
                        final int productRowsBefore = index - bannersBefore;
                        final int startProductIndex = productRowsBefore * 2;

                        if (startProductIndex >= viewModel.products.length) {
                          return null;
                        }

                        final firstProduct =
                            viewModel.products[startProductIndex];
                        final secondProduct =
                            (startProductIndex + 1 < viewModel.products.length)
                            ? viewModel.products[startProductIndex + 1]
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
                                                      firstProduct.productID!,
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
                                      if (firstProduct.productID != null) {
                                        viewModel.toggleFavorite(
                                          firstProduct.productID!,
                                        );
                                      }
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
                                                        productId: secondProduct
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
                                            if (secondProduct.productID !=
                                                null) {
                                              viewModel.toggleFavorite(
                                                secondProduct.productID!,
                                              );
                                            }
                                          },
                                        ),
                                      )
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: (() {
                        final productCount = viewModel.products.length;
                        final rowCount = (productCount / 2).ceil();
                        final bannerCount = rowCount ~/ 2;
                        return rowCount + bannerCount;
                      })(),
                    ),
                  ),
                ),
                if (viewModel.isLoadMoreRunning)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPopularCategoryItem(PopularCategory category) {
    return InkWell(
      onTap: () {
        context.read<SearchViewModel>().searchByCategory(
          category.catID,
          category.catName,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: category.catImage.toLowerCase().endsWith('.svg')
                  ? SvgPicture.network(
                      category.catImage,
                      placeholderBuilder: (context) => const SizedBox.shrink(),
                    )
                  : Image.network(category.catImage),
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Text(
                category.catName,
                style: AppTheme.safePoppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            // Product count chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${category.productCount}",
                style: AppTheme.safePoppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = AppTheme.textSecondary,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: color.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                color: AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
