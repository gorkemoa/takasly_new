import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/favorites_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/product_detail_viewmodel.dart';
import '../widgets/product_card.dart';
import '../products/product_detail_view.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FavoritesViewModel(),
      child: const _FavoritesViewContent(),
    );
  }
}

class _FavoritesViewContent extends StatefulWidget {
  const _FavoritesViewContent();

  @override
  State<_FavoritesViewContent> createState() => _FavoritesViewContentState();
}

class _FavoritesViewContentState extends State<_FavoritesViewContent> {
  bool _isInitDone = false;

  @override
  void initState() {
    super.initState();
    // Fetching handled in didChangeDependencies to wait for Auth Check
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitDone) return;

    final authVM = context.watch<AuthViewModel>();
    if (authVM.isAuthCheckComplete) {
      _isInitDone = true;
      if (authVM.user != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<FavoritesViewModel>().fetchFavorites(
            authVM.user!.userID,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Favorilerim',
          style: AppTheme.safePoppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.background,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppTheme.background,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<FavoritesViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Text(
                viewModel.errorMessage!,
                style: AppTheme.safePoppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.error,
                ),
              ),
            );
          }

          if (viewModel.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 64,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Favori Ürün Bulunamadı',
                    style: AppTheme.safePoppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Beğendiğiniz ürünleri favorilere ekleyerek burada görebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: AppTheme.safePoppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62, // Optimized for ProductCard
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: viewModel.favorites.length,
            itemBuilder: (context, index) {
              final product = viewModel.favorites[index];
              return ProductCard(
                product: product,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => ProductDetailViewModel(),
                        child: ProductDetailView(productId: product.productID!),
                      ),
                    ),
                  );
                },
                onFavoritePressed: () {
                  final authVM = context.read<AuthViewModel>();
                  if (authVM.user?.token != null) {
                    viewModel.removeFavorite(product, authVM.user!.token);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
