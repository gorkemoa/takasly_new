import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_view.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/add_product_viewmodel.dart';
import '../../models/general_models.dart';
import '../../models/products/product_models.dart' show Category;

class AddProductView extends HookWidget {
  const AddProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddProductViewModel()..init(),
      child: const _AddProductViewBody(),
    );
  }
}

class _AddProductViewBody extends HookWidget {
  const _AddProductViewBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AddProductViewModel>(context);
    final pageController = usePageController();
    final currentStep = useState(0);

    // Listen to error messages
    useEffect(() {
      if (viewModel.errorMessage != null) {
        Future.microtask(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(viewModel.errorMessage!)),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
          viewModel.errorMessage = null;
        });
      }
      return null;
    }, [viewModel.errorMessage]);

    void nextStep() {
      if (currentStep.value < 3) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutQuart,
        );
      }
    }

    void previousStep() {
      if (currentStep.value > 0) {
        pageController.previousPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutQuart,
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: viewModel.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Veriler Hazırlanıyor...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      _ModernAppBar(currentStep: currentStep.value),
                      _ProgressIndicator(currentStep: currentStep.value),
                      Expanded(
                        child: PageView(
                          controller: pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) => currentStep.value = index,
                          children: [
                            _Step1Content(viewModel: viewModel),
                            _Step2Content(viewModel: viewModel),
                            _Step3Content(viewModel: viewModel),
                            _Step4Content(viewModel: viewModel),
                          ],
                        ),
                      ),
                      _BottomActionBar(
                        currentStep: currentStep.value,
                        onBack: previousStep,
                        onForward: () async {
                          if (currentStep.value < 3) {
                            nextStep();
                          } else {
                            await _handleSubmission(context, viewModel);
                          }
                        },
                        isLastStep: currentStep.value == 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _handleSubmission(
    BuildContext context,
    AddProductViewModel viewModel,
  ) async {
    // ... (logic remains same as per submission handling)
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    int? userId;
    final dynamic rawUserId = prefs.get('userID');
    if (rawUserId is int)
      userId = rawUserId;
    else if (rawUserId is String)
      userId = int.tryParse(rawUserId);

    if (token != null && userId != null) {
      final success = await viewModel.submitProduct(token, userId);
      if (success && context.mounted) {
        Navigator.pop(context, true);
      }
    } else {
      if (context.mounted) {
        final bool? loggedIn = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
        if (loggedIn == true && context.mounted) {
          await _handleSubmission(context, viewModel);
        }
      }
    }
  }
}

class _ModernAppBar extends StatelessWidget {
  final int currentStep;
  const _ModernAppBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Colors.black87,
          ),
          Text(
            _getStepTitle(currentStep),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 40), // Placeholder to center
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Genel Bilgiler';
      case 1:
        return 'Ürün Detayları';
      case 2:
        return 'Görsel & Açıklama';
      case 3:
        return 'Onay ve Yayın';
      default:
        return 'İlan Oluştur';
    }
  }
}

class _ProgressIndicator extends StatelessWidget {
  final int currentStep;
  const _ProgressIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(4, (index) {
          final isPast = index < currentStep;
          final isCurrent = index == currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
              decoration: BoxDecoration(
                color: isCurrent || isPast
                    ? AppTheme.primary
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Modern stepper removed in favor of progress bar and individual step visual cues.

class _Step1Content extends StatelessWidget {
  final AddProductViewModel viewModel;
  const _Step1Content({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Kategori ve Başlık',
            subtitle:
                'Ürününüzün bulunabilirliğini artırmak için en doğru kategoriyi seçin.',
          ),
          const SizedBox(height: 32),
          _CustomTextField(
            controller: viewModel.titleController,
            label: 'İlan Başlığı',
            hint: ' Apple iPhone 14 Pro Max (256 GB)',
          ),
          const SizedBox(height: 24),
          _CategoryFullSelector<Category>(
            label: 'Kategori Seçimi',
            value: viewModel.selectedCategory,
            items: viewModel.categories,
            onChanged: (val) => viewModel.setSelectedCategory(val),
            itemLabel: (c) => c.catName ?? '',
            onTap: () => _openCategoryPicker(context, viewModel),
          ),
          if (viewModel.selectedCategory != null)
            _SelectedCategoryPath(viewModel: viewModel),
        ],
      ),
    );
  }

  Future<void> _openCategoryPicker(
    BuildContext context,
    AddProductViewModel viewModel,
  ) async {
    await _showLevelPicker(
      context,
      'Kategori Seçin',
      viewModel.categories,
      (item) => viewModel.setSelectedCategory(item),
      0,
      viewModel,
    );
    // Path already updated in viewmodel via callbacks
  }

  Future<Category?> _showLevelPicker(
    BuildContext context,
    String title,
    List<Category> items,
    Future<bool> Function(Category) onSelect,
    int level,
    AddProductViewModel viewModel,
  ) async {
    return await Navigator.push<Category>(
      context,
      MaterialPageRoute(
        builder: (context) => _CategoryPickerView<Category>(
          title: title,
          items: items,
          itemLabel: (c) => c.catName ?? '',
          onSelected: (item) async {
            final hasMore = await onSelect(item);
            if (hasMore && context.mounted) {
              final nextLevelItems = level == 0
                  ? viewModel.categoryLevels[0]
                  : viewModel.categoryLevels[level];

              final finalResult = await _showLevelPicker(
                context,
                'Alt Kategori Seçin',
                nextLevelItems,
                (sub) => viewModel.onSubCategoryChanged(level, sub),
                level + 1,
                viewModel,
              );

              if (finalResult != null && context.mounted) {
                // Someone deeper made a final choice, bubble it up
                Navigator.pop(context, finalResult);
                return true;
              }
              // If finalResult is null, user just backed out of sub-level,
              // stay in the current level picker.
              return true;
            }

            // Final leaf selection!
            if (context.mounted) {
              Navigator.pop(context, item);
            }
            return true;
          },
        ),
      ),
    );
  }
}

class _SelectedCategoryPath extends StatelessWidget {
  final AddProductViewModel viewModel;
  const _SelectedCategoryPath({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    List<String> path = [];
    if (viewModel.selectedCategory != null) {
      path.add(viewModel.selectedCategory?.catName ?? '');
    }
    for (var sub in viewModel.selectedSubCategories) {
      if (sub != null) path.add(sub.catName ?? '');
    }

    if (path.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'SEÇİLEN KATEGORİ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.black45,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (int i = 0; i < path.length; i++) ...[
                _PathChip(label: path[i], isLast: i == path.length - 1),
                if (i < path.length - 1)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.grey[300],
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PathChip extends StatelessWidget {
  final String label;
  final bool isLast;
  const _PathChip({required this.label, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLast ? AppTheme.primary.withOpacity(0.08) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLast ? AppTheme.primary.withOpacity(0.2) : Colors.grey[200]!,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
          color: isLast ? AppTheme.primary : Colors.black54,
        ),
      ),
    );
  }
}

class _CategoryFullSelector<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;
  final String Function(T) itemLabel;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _CategoryFullSelector({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          GestureDetector(
            onTap: isDisabled
                ? null
                : (onTap ?? () => _startSimplePicker(context)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? itemLabel(value as T) : 'Seçiniz',
                      style: TextStyle(
                        fontSize: 15,
                        color: hasValue ? Colors.black87 : Colors.grey[400],
                        fontWeight: hasValue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSimplePicker(BuildContext context) async {
    final T? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CategoryPickerView<T>(
          title: label,
          items: items,
          itemLabel: itemLabel,
        ),
      ),
    );
    if (result != null) onChanged(result);
  }
}

class _CategoryPickerView<T> extends HookWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemLabel;
  final Future<bool> Function(T)? onSelected;

  const _CategoryPickerView({
    required this.title,
    required this.items,
    required this.itemLabel,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final isPageLoading = useState(false);

    final filteredItems = items.where((item) {
      final labelStr = itemLabel(item).toLowerCase();
      return labelStr.contains(searchQuery.value.toLowerCase());
    }).toList();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: true,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (val) => searchQuery.value = val,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Kanal veya kategori ara...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    icon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.only(top: 12, bottom: 32),
            itemCount: filteredItems.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[50], indent: 64),
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.label_important_outline_rounded,
                      color: AppTheme.primary.withOpacity(0.6),
                      size: 18,
                    ),
                  ),
                ),
                title: Text(
                  itemLabel(item),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[300],
                  size: 24,
                ),
                onTap: () async {
                  if (onSelected != null) {
                    isPageLoading.value = true;
                    // The onSelected callback now handles the sub-navigation
                    await onSelected!(item);
                    isPageLoading.value = false;
                  } else {
                    Navigator.pop(context, item);
                  }
                },
              );
            },
          ),
        ),
        if (isPageLoading.value)
          Container(
            color: Colors.black.withOpacity(0.1),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          ),
      ],
    );
  }
}

class _Step2Content extends StatelessWidget {
  final AddProductViewModel viewModel;
  const _Step2Content({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Kullanım Durumu',
            subtitle:
                'Ürünün mevcut kondisyonunu doğru yansıtarak güven inşa edin.',
          ),
          const SizedBox(height: 24),
          _ConditionGrid(viewModel: viewModel),
          const SizedBox(height: 40),
          _SectionHeader(
            title: 'Takas Tercihleri',
            subtitle:
                'Bu ürün karşılığında ilgilenebileceğiniz ürünleri veya kategorileri belirtin.',
          ),
          const SizedBox(height: 24),
          _CustomTextField(
            controller: viewModel.tradeForController,
            label: 'Takas Etmek İstediğim Ürünler',
            hint: 'Örn: MacBook Air M2, PlaySation 5 veya dengi...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _ConditionGrid extends StatelessWidget {
  final AddProductViewModel viewModel;
  const _ConditionGrid({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: viewModel.conditions.map((condition) {
        final isSelected = viewModel.selectedCondition?.id == condition.id;
        return GestureDetector(
          onTap: () => viewModel.setSelectedCondition(condition),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppTheme.primary.withOpacity(0.2)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey[400],
                ),
                const SizedBox(width: 10),
                Text(
                  condition.name ?? '',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Step3Content extends StatelessWidget {
  final AddProductViewModel viewModel;
  const _Step3Content({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Medya ve İçerik',
            subtitle:
                'Profesyonel görseller ve detaylı bir açıklama, ilan başarısını doğrudan etkiler.',
          ),
          const SizedBox(height: 24),
          _ImageGrid(viewModel: viewModel),
          const SizedBox(height: 40),
          _CustomTextField(
            controller: viewModel.descController,
            label: 'Ürün Açıklaması',
            hint:
                'Ürünün kullanım geçmişi, teknik özellikleri ve varsa kusurları hakkında bilgi veriniz...',
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}

class _Step4Content extends StatelessWidget {
  final AddProductViewModel viewModel;
  const _Step4Content({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Konum Bilgisi',
            subtitle:
                'Güvenli takas süreci için ürünün bulunduğu bölgeyi seçin.',
          ),
          const SizedBox(height: 24),
          _LocationSelector(viewModel: viewModel),
          const SizedBox(height: 24),
          _IOSStyleSelector<City>(
            value: viewModel.selectedCity,
            items: viewModel.cities,
            label: 'Şehir',
            onChanged: viewModel.onCityChanged,
            itemLabel: (c) => c.cityName ?? '',
          ),
          const SizedBox(height: 16),
          _IOSStyleSelector<District>(
            value: viewModel.selectedDistrict,
            items: viewModel.districts,
            label: 'İlçe',
            isLoading: viewModel.isDistrictsLoading,
            onChanged: viewModel.setSelectedDistrict,
            itemLabel: (d) => d.districtName ?? '',
            isDisabled: viewModel.selectedCity == null,
          ),
          const SizedBox(height: 32),
          _SectionHeader(
            title: 'İletişim Ayarları',
            subtitle: 'Gizliliğinizi önemsiyoruz.',
          ),
          const SizedBox(height: 16),
          _ContactPreferenceCard(viewModel: viewModel),
          const SizedBox(height: 24),
          _SafetyReminder(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ContactPreferenceCard extends StatelessWidget {
  final AddProductViewModel viewModel;

  const _ContactPreferenceCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Numaramı Göster',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: const Text(
              'Teklif verenler profilinden sana ulaşabilsin.',
              style: TextStyle(fontSize: 12),
            ),
            value: viewModel.isShowContact,
            onChanged: viewModel.setShowContact,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}

class _SafetyReminder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Takasly topluluğu için güven önemlidir. Lütfen dürüst açıklamalar yapın ve güvenli alanlarda buluşun.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24, // Increased size
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 15, // Increased size for readability
            color: Colors.grey[600],
            height: 1.3,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _IOSStyleSelector<T> extends HookWidget {
  final T? value;
  final List<T> items;
  final String label;
  final void Function(T?) onChanged;
  final String Function(T) itemLabel;
  final bool isLoading;
  final bool isDisabled;

  const _IOSStyleSelector({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    required this.itemLabel,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.black54,
                letterSpacing: 0.1,
              ),
            ),
          ),
          GestureDetector(
            onTap: (isLoading || isDisabled)
                ? null
                : () => _showPicker(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  if (!isDisabled)
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(hasValue ? 0.05 : 0),
                      blurRadius: 15,
                      spreadRadius: -5,
                    ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 4,
                      decoration: BoxDecoration(
                        color: isDisabled
                            ? Colors.grey[200]
                            : (hasValue ? AppTheme.primary : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        isDisabled
                            ? 'Lütfen önce Şehir seçiniz'
                            : (hasValue
                                  ? itemLabel(value as T)
                                  : '$label Seçiniz'),
                        style: TextStyle(
                          fontSize: 15,
                          color: hasValue ? Colors.black87 : Colors.grey[400],
                          fontWeight: hasValue
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.expand_more_rounded,
                        color: hasValue ? AppTheme.primary : Colors.grey[400],
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SearchablePicker<T>(
        label: label,
        items: items,
        value: value,
        itemLabel: itemLabel,
        onChanged: onChanged,
      ),
    );
  }
}

class _SearchablePicker<T> extends HookWidget {
  final String label;
  final List<T> items;
  final T? value;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  const _SearchablePicker({
    required this.label,
    required this.items,
    required this.value,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');

    final filteredItems = items.where((item) {
      final labelStr = itemLabel(item).toLowerCase();
      return labelStr.contains(searchQuery.value.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FBFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (val) => searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  icon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final isSelected = value == item;
                return _SelectionItem(
                  title: itemLabel(item),
                  isSelected: isSelected,
                  onTap: () {
                    onChanged(item);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 22,
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[300],
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.black54,
              letterSpacing: 0.1,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Takasly Special Accent Bar
                Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(
                  width: 14,
                ), // Increased from 14 for better alignment
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: maxLines,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final AddProductViewModel viewModel;
  const _ImageGrid({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (viewModel.selectedImages.isEmpty)
          _BigImagePlaceholder(
            onTap: () => _AddMoreImagesButton(
              viewModel: viewModel,
            )._showImageSourcePicker(context),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: viewModel.selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == viewModel.selectedImages.length) {
                  return _SmallAddButton(viewModel: viewModel);
                }
                return _ImageThumbnail(
                  file: viewModel.selectedImages[index],
                  isCover: index == 0,
                  onDelete: () => viewModel.removeImage(index),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _BigImagePlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _BigImagePlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                color: AppTheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Görsel Ekleyerek İlanını Parlat',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'En az 3 fotoğraf öneriyoruz.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallAddButton extends StatelessWidget {
  final AddProductViewModel viewModel;
  const _SmallAddButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _AddMoreImagesButton(
        viewModel: viewModel,
      )._showImageSourcePicker(context),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 30),
      ),
    );
  }
}

class _AddMoreImagesButton extends StatelessWidget {
  final AddProductViewModel viewModel;

  const _AddMoreImagesButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSourcePicker(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              color: AppTheme.primary,
              size: 32,
            ),
            const SizedBox(height: 4),
            const Text(
              'Ekle',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Görsel Kaynağı Seçin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      label: 'Galeri',
                      icon: Icons.photo_library_rounded,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(ctx);
                        viewModel.pickImages();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SourceButton(
                      label: 'Kamera',
                      icon: Icons.camera_alt_rounded,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleCameraMultiple(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCameraMultiple(BuildContext context) async {
    bool keepGoing = true;
    while (keepGoing) {
      final bool added = await viewModel.pickFromCamera();
      if (!added) break;

      if (!context.mounted) return;

      final bool? continueCapturing = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Görsel Eklendi'),
          content: const Text('Bir başka fotoğraf daha çekmek ister misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tamam', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Evet, Çek'),
            ),
          ],
        ),
      );

      if (continueCapturing != true) keepGoing = false;
    }
  }
}

class _SourceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final File file;
  final bool isCover;
  final VoidCallback onDelete;

  const _ImageThumbnail({
    required this.file,
    required this.isCover,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 100,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCover ? AppTheme.primary : Colors.grey[200]!,
              width: isCover ? 2 : 1,
            ),
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
          ),
        ),
        if (isCover)
          Positioned(
            bottom: 4,
            left: 0,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: const Text(
                'KAPAK',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          top: -4,
          right: 6,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 10, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationSelector extends StatelessWidget {
  final AddProductViewModel viewModel;

  const _LocationSelector({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = viewModel.productLat != null;

    return GestureDetector(
      onTap: viewModel.isLocationLoading
          ? null
          : viewModel.fetchCurrentLocation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasLocation
              ? AppTheme.primary.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasLocation ? AppTheme.primary : Colors.grey[200]!,
            width: hasLocation ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasLocation ? AppTheme.primary : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.my_location_rounded,
                color: hasLocation ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLocation ? 'Konum Algılandı' : 'Anlık Konumumu Al',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: hasLocation ? AppTheme.primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasLocation
                        ? 'Harita koordinatları başarıyla kaydedildi.'
                        : 'Daha hızlı takas için konum paylaşın.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (viewModel.isLocationLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else if (hasLocation)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final int currentStep;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final bool isLastStep;

  const _BottomActionBar({
    required this.currentStep,
    required this.onBack,
    required this.onForward,
    required this.isLastStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        16 + MediaQuery.of(context).padding.bottom,
      ),
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
          if (currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Geri',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onForward,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: AppTheme.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isLastStep ? 'Hemen Yayınla' : 'Sonraki Adım',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
