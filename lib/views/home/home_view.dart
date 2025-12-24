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

import '../events/events_view.dart';
import '../profile/profile_view.dart';

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
      // ProductViewModel init happens after token sync in didChangeDependencies or we call it here?
      // Better to let didChangeDependencies handle the token set and fetch.
      // But if token is null (guest), we still want to fetch.
      // So we call init() here, and if token comes later, it refreshes.
      context.read<ProductViewModel>().init();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final authVM = context.watch<AuthViewModel>();
      final productVM = context.read<ProductViewModel>();

      if (productVM.userToken != authVM.user?.token) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          productVM.setUserToken(authVM.user?.token);
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
      body: SafeArea(
        child: _selectedIndex == 4
            ? const ProfileView()
            : _selectedIndex != 0
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
                      await productViewModel.fetchProducts(isRefresh: true);
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
                                          padding: const EdgeInsets.all(4),
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
                                        borderRadius: BorderRadius.circular(30),
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
                                    itemCount: homeViewModel.categories.isEmpty
                                        ? 1
                                        : homeViewModel.categories.length +
                                              1, // +1 for 'Tümü'
                                    separatorBuilder: (c, i) =>
                                        const SizedBox(width: 0),
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        // 'Tümü' (All) Static Item
                                        return GestureDetector(
                                          onTap: () {
                                            productViewModel.filterByCategory(
                                              null,
                                            );
                                          },
                                          child: SizedBox(
                                            width: 60,
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primary,
                                                    shape: BoxShape.circle,
                                                    boxShadow:
                                                        AppTheme.cardShadow,
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
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      final category =
                                          homeViewModel.categories[index - 1];
                                      return CategoryCard(
                                        category: category,
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

                        // Product Grid
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
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio:
                                        0.65, // Adjust for card height
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                if (index >= productViewModel.products.length)
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
                                                productId: product.productID!,
                                              ),
                                            ),
                                      ),
                                    );
                                  },
                                );
                              }, childCount: productViewModel.products.length),
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
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Consumer<HomeViewModel>(
                builder: (context, homeVM, child) {
                  return Column(
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filtrele',
                              style: AppTheme.safePoppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20.0),
                          children: [
                            Text(
                              'Sıralama',
                              style: AppTheme.safePoppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildSortChip(homeVM, 'default', 'Varsayılan'),
                                _buildSortChip(homeVM, 'newest', 'En Yeni'),
                                _buildSortChip(homeVM, 'oldest', 'En Eski'),
                                _buildSortChip(
                                  homeVM,
                                  'location',
                                  'Konuma Göre',
                                ),
                                _buildSortChip(homeVM, 'popular', 'Popüler'),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Text(
                              'Kategori',
                              style: AppTheme.safePoppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                _showCategorySelector(context, homeVM);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      homeVM.selectedCategory?.catName ??
                                          'Kategori Seç',
                                      style: AppTheme.safePoppins(
                                        color: homeVM.selectedCategory != null
                                            ? AppTheme.textPrimary
                                            : AppTheme.textSecondary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Text(
                              'Konum',
                              style: AppTheme.safePoppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: homeVM.selectedCity?.cityNo,
                                        hint: const Text("İl"),
                                        isExpanded: true,
                                        items: homeVM.cities.map((city) {
                                          return DropdownMenuItem<int>(
                                            value: city.cityNo,
                                            child: Text(
                                              city.cityName ?? "",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (cityNo) {
                                          if (cityNo != null) {
                                            final city = homeVM.cities
                                                .firstWhere(
                                                  (c) => c.cityNo == cityNo,
                                                );
                                            homeVM.setSelectedCity(city);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value:
                                            homeVM.selectedDistrict?.districtNo,
                                        hint: const Text("İlçe"),
                                        isExpanded: true,
                                        disabledHint: const Text("Önce İl"),
                                        items: homeVM.districts.isEmpty
                                            ? null
                                            : homeVM.districts.map((district) {
                                                return DropdownMenuItem<int>(
                                                  value: district.districtNo,
                                                  child: Text(
                                                    district.districtName ?? "",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }).toList(),
                                        onChanged: homeVM.districts.isEmpty
                                            ? null
                                            : (districtNo) {
                                                if (districtNo != null) {
                                                  final district = homeVM
                                                      .districts
                                                      .firstWhere(
                                                        (d) =>
                                                            d.districtNo ==
                                                            districtNo,
                                                      );
                                                  homeVM.setSelectedDistrict(
                                                    district,
                                                  );
                                                }
                                              },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            if (homeVM.conditions.isNotEmpty) ...[
                              Text(
                                'Ürün Durumu',
                                style: AppTheme.safePoppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: homeVM.conditions.map((condition) {
                                  final isSelected = homeVM.selectedConditionIds
                                      .contains(condition.id);
                                  return FilterChip(
                                    label: Text(condition.name ?? ''),
                                    selected: isSelected,
                                    onSelected: (bool selected) {
                                      if (condition.id != null) {
                                        homeVM.toggleCondition(condition.id!);
                                      }
                                    },
                                    selectedColor: AppTheme.primary.withOpacity(
                                      0.2,
                                    ),
                                    checkmarkColor: AppTheme.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : Colors.black87,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  homeVM.clearFilters();
                                  context
                                      .read<ProductViewModel>()
                                      .updateAllFilters(
                                        sortType: 'default',
                                        categoryID: 0,
                                        conditionIDs: [],
                                        cityID: 0,
                                        districtID: 0,
                                      );
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Temizle',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final cityId =
                                      homeVM.selectedCity?.cityNo ?? 0;
                                  final districtId =
                                      homeVM.selectedDistrict?.districtNo ?? 0;
                                  final sortType = homeVM.sortType;
                                  final catId =
                                      homeVM.selectedCategory?.catID ?? 0;
                                  final conds = homeVM.selectedConditionIds;

                                  context
                                      .read<ProductViewModel>()
                                      .updateAllFilters(
                                        sortType: sortType,
                                        categoryID: catId,
                                        conditionIDs: conds,
                                        cityID: cityId,
                                        districtID: districtId,
                                      );
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Sonuçları Göster',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(HomeViewModel homeVM, String type, String label) {
    final isSelected = homeVM.sortType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          homeVM.setSortType(type);
        }
      },
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }

  void _showCategorySelector(BuildContext context, HomeViewModel homeVM) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              builder: (context, scrollController) {
                return Consumer<HomeViewModel>(
                  builder: (context, vm, child) {
                    final listToShow = (vm.selectedCategory == null)
                        ? vm.categories
                        : vm.subCategories;
                    return Column(
                      children: [
                        AppBar(
                          title: Text(
                            vm.selectedCategory?.catName ?? 'Kategoriler',
                          ),
                          leading: IconButton(
                            icon: Icon(
                              vm.selectedCategory == null
                                  ? Icons.close
                                  : Icons.arrow_back,
                            ),
                            onPressed: () {
                              if (vm.selectedCategory == null) {
                                Navigator.pop(context);
                              } else {
                                vm.setSelectedCategory(null);
                              }
                            },
                          ),
                          automaticallyImplyLeading: false,
                        ),
                        Expanded(
                          child:
                              listToShow.isEmpty && vm.selectedCategory != null
                              ? const Center(
                                  child: Text("Alt kategori bulunamadı"),
                                )
                              : ListView.builder(
                                  itemCount: listToShow.length,
                                  itemBuilder: (context, index) {
                                    final cat = listToShow[index];
                                    return ListTile(
                                      title: Text(cat.catName),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        vm.setSelectedCategory(cat);
                                      },
                                    );
                                  },
                                ),
                        ),
                        if (vm.selectedCategory != null)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("Bu Kategoriyi Seç"),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
