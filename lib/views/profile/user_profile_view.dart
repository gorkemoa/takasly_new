import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../models/profile/profile_detail_model.dart';
import '../../models/products/product_models.dart' as pm;
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../home/home_view.dart';
import '../widgets/product_card.dart';
import '../products/product_detail_view.dart';

class UserProfileView extends StatefulWidget {
  final int userId;
  final bool isByType;

  const UserProfileView({
    super.key,
    required this.userId,
    this.isByType = false,
  });

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      final userToken = authVM.user?.token;

      Provider.of<ProfileViewModel>(
        context,
        listen: false,
      ).getProfileDetail(widget.userId, userToken);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  pm.Product _mapProfileProductToProduct(ProfileProduct profileProduct) {
    return pm.Product(
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
      categoryList: profileProduct.categoryList
          ?.map((c) => pm.Category(catID: c.catID, catName: c.catName))
          .toList(),
    );
  }

  void _showReportDialog() {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          "Kullanıcıyı Raporla",
          style: AppTheme.safePoppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            hintText: "Raporlama sebebinizi yazın...",
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            filled: true,
            fillColor: Colors.grey[50],
            hintStyle: AppTheme.safePoppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "İptal",
              style: AppTheme.safePoppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              elevation: 0,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final authVM = context.read<AuthViewModel>();
              final profileVM = context.read<ProfileViewModel>();

              if (authVM.user?.token != null) {
                final success = await profileVM.reportUser(
                  userToken: authVM.user!.token,
                  reportedUserID: widget.userId,
                  reason: reason,
                  step: "user",
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? "Kullanıcı raporlandı." : "Hata oluştu.",
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              "Gönder",
              style: AppTheme.safePoppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          "Kullanıcıyı Engelle",
          style: AppTheme.safePoppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          "Bu kullanıcıyı engellemek istediğinize emin misiniz?",
          style: AppTheme.safePoppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "İptal",
              style: AppTheme.safePoppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              elevation: 0,
            ),
            onPressed: () async {
              final authVM = context.read<AuthViewModel>();
              final profileVM = context.read<ProfileViewModel>();

              if (authVM.user?.token != null) {
                final success = await profileVM.blockUser(
                  userToken: authVM.user!.token,
                  blockedUserID: widget.userId,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    context.read<ProductViewModel>().fetchProducts(
                      isRefresh: true,
                    );
                    context.read<HomeViewModel>().init();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeView()),
                      (route) => false,
                    );
                  }
                }
              }
            },
            child: Text(
              "Engelle",
              style: AppTheme.safePoppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        final profile = viewModel.profileDetail;
        final isBusy = viewModel.state == ProfileState.busy;
        final isError = viewModel.state == ProfileState.error;
        final authVM = Provider.of<AuthViewModel>(context, listen: false);
        final isCurrentUser = authVM.user?.userID == widget.userId;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: AppTheme.background),
            title: Text(
              isCurrentUser ? "Profilim" : (profile?.userFullname ?? "Profil"),
              style: AppTheme.safePoppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.background,
              ),
            ),
            centerTitle: true,
            actions: [
              if (!isCurrentUser && profile != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'report') _showReportDialog();
                    if (value == 'block') _showBlockConfirmDialog();
                  },
                  itemBuilder: (context) {
                    final isAdmin =
                        profile.isAdmin == true ||
                        (profile.userFullname?.toLowerCase().contains(
                              "takasly destek",
                            ) ??
                            false);
                    return [
                      if (!isAdmin) ...[
                        PopupMenuItem(
                          value: 'report',
                          child: Text(
                            "Bildir",
                            style: AppTheme.safePoppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Text(
                            "Engelle",
                            style: AppTheme.safePoppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ];
                  },
                ),
            ],
          ),
          body: isBusy
              ? const Center(child: CircularProgressIndicator())
              : isError || profile == null
              ? Center(
                  child: Text(
                    viewModel.errorMessage ?? 'Hata oluştu',
                    style: AppTheme.safePoppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(profile),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF5F5F5),
                            ),
                            _buildStats(profile),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF5F5F5),
                            ),
                          ],
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            controller: _tabController,
                            indicatorColor: AppTheme.primary,
                            indicatorWeight: 3,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: AppTheme.primary,
                            unselectedLabelColor: AppTheme.textSecondary,
                            dividerHeight: 0,
                            labelStyle: AppTheme.safePoppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                            unselectedLabelStyle: AppTheme.safePoppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                            tabs: [
                              Tab(
                                text:
                                    "İlanlar (${profile.products?.length ?? 0})",
                              ),
                              Tab(
                                text:
                                    "Yorumlar (${profile.reviews?.length ?? 0})",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProductsGrid(profile),
                      _buildReviewsList(profile),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader(ProfileDetailModel profile) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: ClipOval(
              child:
                  (profile.userImage != null && profile.userImage!.isNotEmpty)
                  ? Image.network(profile.userImage!, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        (profile.userFullname?.isNotEmpty == true
                                ? profile.userFullname![0]
                                : "U")
                            .toUpperCase(),
                        style: AppTheme.safePoppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.userFullname ?? '-',
                  style: AppTheme.safePoppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${profile.memberSince ?? '-'}",
                  style: AppTheme.safePoppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (profile.isApproved == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Onaylı Hesap",
                          style: AppTheme.safePoppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (profile.isAdmin == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.admin_panel_settings,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "YÖNETİCİ",
                            style: AppTheme.safePoppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ProfileDetailModel profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(profile.products?.length.toString() ?? "0", "İlan"),
          _buildVerticalDivider(),
          _buildStatItem(profile.totalReviews?.toString() ?? "0", "Yorum"),
          _buildVerticalDivider(),
          _buildRatingItem(profile.averageRating ?? 0),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.safePoppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTheme.safePoppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingItem(int rating) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              rating.toString(),
              style: AppTheme.safePoppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          "Puan",
          style: AppTheme.safePoppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[200]);
  }

  Widget _buildProductsGrid(ProfileDetailModel profile) {
    final products = profile.products;
    if (products == null || products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Henüz bir ürün bulunmuyor.",
            style: AppTheme.safePoppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = _mapProfileProductToProduct(products[index]);
        return ProductCard(
          product: product,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProductDetailView(productId: product.productID!),
              ),
            );
            if (context.mounted) {
              final authVM = Provider.of<AuthViewModel>(context, listen: false);
              final userToken = authVM.user?.token;

              Provider.of<ProfileViewModel>(
                context,
                listen: false,
              ).getProfileDetail(widget.userId, userToken);
            }
          },
        );
      },
    );
  }

  Widget _buildReviewsList(ProfileDetailModel profile) {
    final reviews = profile.reviews;
    if (reviews == null || reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Henüz değerlendirme bulunmuyor.",
            style: AppTheme.safePoppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: reviews.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 32, color: Color(0xFFEEEEEE)),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[100],
                  backgroundImage:
                      (review.reviewerImage != null &&
                          review.reviewerImage!.isNotEmpty)
                      ? NetworkImage(review.reviewerImage!)
                      : null,
                  child:
                      (review.reviewerImage == null ||
                          review.reviewerImage!.isEmpty)
                      ? Icon(Icons.person, size: 16, color: Colors.grey[400])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName ?? '-',
                        style: AppTheme.safePoppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        review.reviewDate ?? '',
                        style: AppTheme.safePoppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 14,
                      color: i < (review.rating ?? 0)
                          ? Colors.amber
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  review.comment!,
                  style: AppTheme.safePoppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
