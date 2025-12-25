import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../products/product_detail_view.dart';
import '../../models/profile/profile_detail_model.dart';
import '../widgets/product_card.dart';
import '../../models/products/product_models.dart' as prod;

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
          appBar: AppBar(
            title: Text(
              'İlanlarım',
              style: AppTheme.safePoppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
          ),
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
              : _buildProductsGrid(profile.products!),
        );
      },
    );
  }

  Widget _buildProductsGrid(List<ProfileProduct> products) {
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
        );
      },
    );
  }
}
