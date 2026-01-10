import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/home_viewmodel.dart';
import '../../../../viewmodels/product_viewmodel.dart';
import '../../../../theme/app_theme.dart';
import '../../widgets/category_selection_view.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Consumer<HomeViewModel>(
            builder: (context, homeVM, child) {
              return Column(
                children: [
                  // Header & Handle Area
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Filtrele',
                                style: AppTheme.safePoppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildSectionTitle('Sıralama'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildSortOption(
                              homeVM,
                              'default',
                              'Önerilen',
                              Icons.star_border,
                            ),
                            _buildSortOption(
                              homeVM,
                              'newest',
                              'En Yeni',
                              Icons.access_time,
                            ),
                            _buildSortOption(
                              homeVM,
                              'popular',
                              'Popüler',
                              Icons.trending_up,
                            ),
                            _buildSortOption(
                              homeVM,
                              'location',
                              'Yakınımda',
                              Icons.location_on_outlined,
                            ),
                            _buildSortOption(
                              homeVM,
                              'oldest',
                              'En Eski',
                              Icons.history,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('Kategori'),
                        const SizedBox(height: 12),
                        _buildCategorySelector(context, homeVM),

                        const SizedBox(height: 24),
                        _buildSectionTitle('Konum'),
                        const SizedBox(height: 12),
                        _buildLocationSelector(context, homeVM),

                        const SizedBox(height: 24),
                        if (homeVM.conditions.isNotEmpty) ...[
                          _buildSectionTitle('Ürün Durumu'),
                          const SizedBox(height: 12),
                          _buildConditionSelector(homeVM),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),

                  // Footer Buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              homeVM.clearFilters();
                              // Apply clear immediately or let user click apply?
                              // Usually clear resets UI, then they click Apply.
                              // But previous implementation cleared and applied.
                              // Let's just clear internal state, user must click apply to fetch.
                              // Or maybe better user experience:
                              // Clear resets UI state.
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Temizle',
                              style: AppTheme.safePoppins(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              final cityId = homeVM.selectedCity?.cityNo ?? 0;
                              final districtId =
                                  homeVM.selectedDistrict?.districtNo ?? 0;
                              final sortType = homeVM.sortType;
                              final catId = homeVM.selectedCategory?.catID ?? 0;
                              final conds = homeVM.selectedConditionIds;

                              // Show a snackbar or some feedback if fetching location
                              final productVM = context
                                  .read<ProductViewModel>();

                              await productVM.updateAllFilters(
                                sortType: sortType,
                                categoryID: catId,
                                conditionIDs: conds,
                                cityID: cityId,
                                districtID: districtId,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Sonuçları Göster',
                              style: AppTheme.safePoppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.safePoppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildSortOption(
    HomeViewModel vm,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = vm.sortType == value;
    return InkWell(
      onTap: () => vm.setSortType(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.safePoppins(
                color: isSelected ? Colors.white : Colors.grey[800]!,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context, HomeViewModel vm) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategorySelectionView(
              allowAnyLevel: true,
              onCategorySelected: (category, path) {
                vm.setCategoryPath(category, path);
              },
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Icon(
                Icons.grid_view_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seçilen Kategori',
                    style: AppTheme.safePoppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vm.selectedCategory?.catName ?? 'Tüm Kategoriler',
                    style: AppTheme.safePoppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector(BuildContext context, HomeViewModel vm) {
    return Column(
      children: [
        // City Selector
        GestureDetector(
          onTap: () {
            int selectedIndex = 0;
            if (vm.selectedCity != null) {
              selectedIndex = vm.cities.indexWhere(
                (c) => c.cityNo == vm.selectedCity!.cityNo,
              );
              if (selectedIndex == -1) selectedIndex = 0;
            }

            _showPicker(
              context,
              title: 'İl Seç',
              items: vm.cities.map((e) => e.cityName ?? '').toList(),
              initialIndex: selectedIndex,
              onSelectedItemChanged: (index) {
                if (index >= 0 && index < vm.cities.length) {
                  vm.setSelectedCity(vm.cities[index]);
                }
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vm.selectedCity?.cityName ?? "İl Seçiniz",
                  style: AppTheme.safePoppins(
                    color: vm.selectedCity != null
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // District Selector
        GestureDetector(
          onTap: () {
            if (vm.cities.isEmpty || vm.selectedCity == null) return;

            int selectedIndex = 0;
            if (vm.selectedDistrict != null) {
              selectedIndex = vm.districts.indexWhere(
                (d) => d.districtNo == vm.selectedDistrict!.districtNo,
              );
              if (selectedIndex == -1) selectedIndex = 0;
            }

            _showPicker(
              context,
              title: 'İlçe Seç',
              items: vm.districts.map((e) => e.districtName ?? '').toList(),
              initialIndex: selectedIndex,
              onSelectedItemChanged: (index) {
                if (index >= 0 && index < vm.districts.length) {
                  vm.setSelectedDistrict(vm.districts[index]);
                }
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: vm.districts.isEmpty ? Colors.grey[50] : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vm.selectedDistrict?.districtName ??
                      (vm.selectedCity == null
                          ? "Önce İl Seçiniz"
                          : "İlçe Seçiniz"),
                  style: AppTheme.safePoppins(
                    color: vm.selectedDistrict != null
                        ? AppTheme.textPrimary
                        : Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(
    BuildContext context, {
    required List<String> items,
    required ValueChanged<int> onSelectedItemChanged,
    int initialIndex = 0,
    String title = '', // Default empty title
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        int tempIndex = initialIndex;
        // Ensure index is within bounds
        if (tempIndex < 0 || tempIndex >= items.length) {
          tempIndex = 0;
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 300,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Buttons Row with Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "İptal",
                            style: AppTheme.safePoppins(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          title,
                          style: AppTheme.safePoppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            onSelectedItemChanged(tempIndex);
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Seç",
                            style: AppTheme.safePoppins(
                              color: AppTheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: tempIndex,
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        tempIndex = index;
                      },
                      children: items
                          .map(
                            (item) => Center(
                              child: Text(
                                item,
                                style: AppTheme.safePoppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConditionSelector(HomeViewModel vm) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: vm.conditions.map((condition) {
        final isSelected = vm.selectedConditionIds.contains(condition.id);
        return FilterChip(
          label: Text(condition.name ?? ''),
          selected: isSelected,
          onSelected: (bool selected) {
            if (condition.id != null) {
              vm.toggleCondition(condition.id!);
            }
          },
          backgroundColor: Colors.white,
          selectedColor: AppTheme.primary.withOpacity(0.1),
          checkmarkColor: AppTheme.primary,
          side: BorderSide(
            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
          ),
          labelStyle: AppTheme.safePoppins(
            color: isSelected ? AppTheme.primary : Colors.grey[700]!,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        );
      }).toList(),
    );
  }
}
