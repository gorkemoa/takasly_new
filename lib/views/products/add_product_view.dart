import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/add_product_viewmodel.dart';
import '../../models/general_models.dart';
import '../../models/products/product_models.dart' show Category;

class AddProductView extends StatelessWidget {
  const AddProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddProductViewModel()..init(),
      child: const _AddProductViewBody(),
    );
  }
}

class _AddProductViewBody extends StatefulWidget {
  const _AddProductViewBody();

  @override
  State<_AddProductViewBody> createState() => _AddProductViewBodyState();
}

class _AddProductViewBodyState extends State<_AddProductViewBody> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AddProductViewModel>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewModel.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(viewModel.errorMessage!)));
        viewModel.errorMessage = null;
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ürün Yükle'),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    children: [
                      _buildStep1(viewModel),
                      _buildStep2(viewModel),
                      _buildStep3(viewModel),
                    ],
                  ),
                ),
                _buildBottomNavigation(viewModel),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          _buildStepCircle(0, 'Görsel'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Detay'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Konum'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? AppTheme.primary
                : Colors.grey[200],
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppTheme.primary : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    bool isPassed = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: isPassed ? AppTheme.primary : Colors.grey[200],
      ),
    );
  }

  Widget _buildStep1(AddProductViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Ürün Fotoğrafları', 'En az 1 fotoğraf ekleyin'),
          const SizedBox(height: 16),
          _buildImageReel(viewModel),
          const SizedBox(height: 32),
          _sectionTitle(
            'Temel Bilgiler',
            'Ürününüzü en iyi şekilde tanımlayın',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: viewModel.titleController,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Ürün Başlığı',
              hintText: 'Örn: iPhone 13 Pro Max',
              prefixIcon: Icon(
                Icons.title,
                color: AppTheme.primary.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: viewModel.descController,
            maxLines: 5,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Açıklama',
              hintText:
                  'Ürünün detaylarını, kullanım durumunu ve özelliklerini yazın...',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Icon(
                  Icons.description,
                  color: AppTheme.primary.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(AddProductViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Kategorizasyon',
            'Doğru alıcılara ulaşmak için kategori seçin',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Category>(
            value: viewModel.selectedCategory,
            decoration: InputDecoration(
              labelText: 'Kategori',
              prefixIcon: Icon(
                Icons.category,
                color: AppTheme.primary.withOpacity(0.7),
              ),
            ),
            items: viewModel.categories.map((c) {
              return DropdownMenuItem(value: c, child: Text(c.catName ?? ''));
            }).toList(),
            onChanged: (val) => viewModel.setSelectedCategory(val),
          ),
          // Dynamic Subcategories
          for (int i = 0; i < viewModel.categoryLevels.length; i++) ...[
            const SizedBox(height: 20),
            DropdownButtonFormField<Category>(
              // Ensure we don't access out of bounds if selectedSubCategories didn't sync yet (unlikely but safe)
              value: (i < viewModel.selectedSubCategories.length)
                  ? viewModel.selectedSubCategories[i]
                  : null,
              decoration: InputDecoration(
                labelText: 'Alt Kategori',
                prefixIcon: Icon(
                  Icons.subdirectory_arrow_right,
                  color: AppTheme.primary.withOpacity(0.7),
                ),
              ),
              items: viewModel.categoryLevels[i].map((c) {
                return DropdownMenuItem(value: c, child: Text(c.catName ?? ''));
              }).toList(),
              onChanged: (val) => viewModel.onSubCategoryChanged(i, val),
            ),
          ],
          const SizedBox(height: 20),
          DropdownButtonFormField<Condition>(
            value: viewModel.selectedCondition,
            decoration: InputDecoration(
              labelText: 'Ürün Durumu',
              prefixIcon: Icon(
                Icons.star_half,
                color: AppTheme.primary.withOpacity(0.7),
              ),
            ),
            items: viewModel.conditions.map((c) {
              return DropdownMenuItem(value: c, child: Text(c.name ?? ''));
            }).toList(),
            onChanged: (val) => viewModel.setSelectedCondition(val),
          ),
          const SizedBox(height: 32),
          _sectionTitle('Takas Tercihi', 'Ne ile takas etmek istersiniz?'),
          const SizedBox(height: 16),
          TextField(
            controller: viewModel.tradeForController,
            decoration: InputDecoration(
              labelText: 'Takas Edilecek Ürün',
              hintText: 'Örn: MacBook Air, Bisiklet...',
              prefixIcon: Icon(
                Icons.swap_horiz,
                color: AppTheme.primary.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(AddProductViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Konum Bilgileri',
            'Ürününüzün nerede olduğunu belirtin',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<City>(
            value: viewModel.selectedCity,
            decoration: InputDecoration(
              labelText: 'Şehir',
              prefixIcon: Icon(
                Icons.location_city,
                color: AppTheme.primary.withOpacity(0.7),
              ),
            ),
            items: viewModel.cities.map((c) {
              return DropdownMenuItem(value: c, child: Text(c.cityName ?? ''));
            }).toList(),
            onChanged: viewModel.onCityChanged,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<District>(
            value: viewModel.selectedDistrict,
            items: viewModel.districts.map((d) {
              return DropdownMenuItem(
                value: d,
                child: Text(d.districtName ?? ''),
              );
            }).toList(),
            onChanged: (val) => viewModel.setSelectedDistrict(val),
            decoration: InputDecoration(
              labelText: 'İlçe',
              prefixIcon: Icon(
                Icons.map,
                color: AppTheme.primary.withOpacity(0.7),
              ),
              suffixIcon: viewModel.isDistrictsLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onTap: viewModel.selectedCity == null
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Önce il seçiniz')),
                  )
                : null,
          ),
          const SizedBox(height: 32),
          _sectionTitle('Tam Konum', 'Harita üzerinde daha görünür olun'),
          const SizedBox(height: 16),
          InkWell(
            onTap: viewModel.isLocationLoading
                ? null
                : viewModel.fetchCurrentLocation,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: viewModel.productLat != null
                    ? AppTheme.primary.withOpacity(0.05)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: viewModel.productLat != null
                      ? AppTheme.primary.withOpacity(0.3)
                      : Colors.grey[200]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: viewModel.productLat != null
                          ? AppTheme.primary
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: viewModel.productLat != null
                          ? Colors.white
                          : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          viewModel.productLat != null
                              ? 'Konum Alındı'
                              : 'Konumunu Paylaş',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: viewModel.productLat != null
                                ? AppTheme.primary
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          viewModel.productLat != null
                              ? '${viewModel.productLat!.toStringAsFixed(4)}, ${viewModel.productLong!.toStringAsFixed(4)}'
                              : 'Daha hızlı takas için konum ekleyin',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (viewModel.isLocationLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (viewModel.productLat != null)
                    const Icon(Icons.check_circle, color: AppTheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _sectionTitle('Ek Seçenekler', 'Gizlilik ve iletişim ayarları'),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('İletişim bilgilerim görünsün'),
            subtitle: const Text(
              'Numaranız diğer kullanıcılar tarafından görülebilir',
            ),
            value: viewModel.isShowContact,
            activeColor: AppTheme.primary,
            onChanged: (val) => viewModel.setShowContact(val),
          ),
        ],
      ),
    );
  }

  Widget _buildImageReel(AddProductViewModel viewModel) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: viewModel.pickImages,
              child: Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: AppTheme.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fotoğraf Ekle',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final file = viewModel.selectedImages[index - 1];
          return Stack(
            children: [
              Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(file),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 20,
                child: GestureDetector(
                  onTap: () => viewModel.removeImage(index - 1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (index == 1)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Kapak Fotoğrafı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation(AddProductViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Geri'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _handleNextAction(viewModel),
              child: Text(_currentStep == 2 ? 'Yayınla' : 'Devam Et'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNextAction(AddProductViewModel viewModel) async {
    if (_currentStep < 2) {
      _nextStep();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      String? userIdStr = prefs.getString('userID');
      int? userId;

      if (userIdStr != null) {
        userId = int.tryParse(userIdStr);
      } else {
        userId = prefs.getInt('userID');
      }

      if (token != null && userId != null) {
        final success = await viewModel.submitProduct(token, userId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün başarıyla yüklendi!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oturum bilgisi bulunamadı.')),
          );
        }
      }
    }
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}
