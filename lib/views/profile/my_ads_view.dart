import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../products/product_detail_view.dart';
import '../products/edit_product_view.dart';
import '../../models/profile/profile_detail_model.dart';
import '../widgets/product_card.dart';
import '../../models/products/product_models.dart' as prod;
import '../widgets/ads/banner_ad_widget.dart';

class MyAdsView extends StatefulWidget {
  const MyAdsView({super.key});

  @override
  State<MyAdsView> createState() => _MyAdsViewState();
}

class _MyAdsViewState extends State<MyAdsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      final userId = authVM.user?.userID;
      final userToken = authVM.user?.token;

      if (userId != null) {
        Provider.of<ProfileViewModel>(
          context,
          listen: false,
        ).getProfileDetail(userId, userToken);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        final profile = viewModel.profileDetail;
        final isBusy = viewModel.state == ProfileState.busy;
        final isError = viewModel.state == ProfileState.error;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: const Text('İlanlarım')),
          body: isBusy
              ? const Center(child: CircularProgressIndicator())
              : isError
              ? Center(
                  child: Text(
                    viewModel.errorMessage ?? 'Bir hata oluştu',
                    style: AppTheme.safePoppins(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              : (profile?.products == null || profile!.products!.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.grid_off_rounded,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Henüz hiç ilanınız yok.",
                        style: AppTheme.safePoppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildProductsGrid(profile.products!, viewModel),
          bottomNavigationBar: const BannerAdWidget(),
        );
      },
    );
  }

  Widget _buildProductsGrid(
    List<ProfileProduct> products,
    ProfileViewModel viewModel,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65, // Adjust for card height
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final profileProduct = products[index];

        // Map ProfileProduct to Product model expected by ProductCard
        final product = prod.Product(
          productID: profileProduct.productID,
          productTitle: profileProduct.productTitle,
          productDesc: profileProduct.productDesc,
          productImage: profileProduct.productImage,
          productCondition: profileProduct.productCondition,
          conditionID: profileProduct.conditionID,
          cityID: profileProduct.cityID,
          districtID: profileProduct.districtID,
          cityTitle: profileProduct.cityTitle,
          districtTitle: profileProduct.districtTitle,
          isFavorite: profileProduct.isFavorite,
          // Map categories if needed
          categoryList: profileProduct.categoryList
              ?.map((c) => prod.Category(catID: c.catID, catName: c.catName))
              .toList(),
        );

        return ProductCard(
          product: product,
          onTap: () {
            if (product.productID != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailView(productId: product.productID!),
                ),
              );
            }
          },
          onEdit: () async {
            if (product.productID != null) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductView(
                    productId: product.productID!,
                    product: product,
                  ),
                ),
              );

              if (result == true && context.mounted) {
                // Refresh list
                final authVM = Provider.of<AuthViewModel>(
                  context,
                  listen: false,
                );
                final userId = authVM.user?.userID;
                final userToken = authVM.user?.token;

                if (userId != null) {
                  Provider.of<ProfileViewModel>(
                    context,
                    listen: false,
                  ).getProfileDetail(userId, userToken);
                }
              }
            }
          },
          onDelete: () => _showDeleteConfirmation(context, viewModel, product),
          onSponsor: () => _showSponsorDialog(context, viewModel, product),
        );
      },
    );
  }

  Future<void> _showSponsorDialog(
    BuildContext context,
    ProfileViewModel viewModel,
    prod.Product product,
  ) async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final userToken = authVM.user?.token;

    if (userToken == null || product.productID == null) return;

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            const Text(
              'İlanını Öne Çıkar!',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ürününüzün daha fazla kişi tarafından görülmesini ister misiniz?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildFeatureRow(
              Icons.timer_outlined,
              '1 saat boyunca en üstte görünür.',
            ),
            _buildFeatureRow(
              Icons.trending_up_rounded,
              'Takas şansını 5 kat artırır.',
            ),
            _buildFeatureRow(
              Icons.videocam_outlined,
              'Sadece kısa bir video izleyerek!',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Daha Sonra',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Video İzle ve Öne Çıkar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (proceed == true) {
      await viewModel.showRewardedAdAndSponsor(
        userToken: userToken,
        productId: product.productID!,
        onSuccess: (message) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.amber[700],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onFailure: (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    }
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    ProfileViewModel viewModel,
    prod.Product product,
  ) async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final userToken = authVM.user?.token;
    final userId = authVM.user?.userID;

    if (userToken == null || userId == null || product.productID == null)
      return;

    // First confirmation
    final bool? firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('İlanı Sil'),
        content: const Text(
          'Bu ilanı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VAZGEÇ', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'EVET, SİL',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Second confirmation
    // ignore: use_build_context_synchronously
    if (!context.mounted) return;
    final bool? secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⚠️ SON UYARI'),
        content: const Text(
          'Gerçekten kararlı mısınız? İlanınız sistemden tamamen kaldırılacaktır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'HAYIR, VAZGEÇ',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'EVET, KESİN SİL',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (secondConfirm != true) return;

    final success = await viewModel.deleteProduct(
      userToken: userToken,
      userId: userId,
      productId: product.productID!,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İlan başarıyla silindi.')));
    }
  }
}
