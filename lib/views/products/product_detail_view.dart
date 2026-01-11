import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/product_detail_viewmodel.dart';
import '../../models/product_detail_model.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/ticket_viewmodel.dart';
import '../profile/user_profile_view.dart';
import 'widgets/offer_bottom_sheet.dart';
import '../widgets/ads/banner_ad_widget.dart';
import 'edit_product_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/analytics_service.dart';

class ProductDetailView extends StatefulWidget {
  final int productId;

  const ProductDetailView({super.key, required this.productId});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView('Urun Detay');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userToken = context.read<AuthViewModel>().user?.token;
      context.read<ProductDetailViewModel>().getProductDetail(
        widget.productId,
        userToken: userToken,
      );
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );
    final appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$lat,$lng");

    if (Platform.isAndroid) {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harita uygulaması açılamadı')),
        );
      }
    } else if (Platform.isIOS) {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Apple Maps'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (await canLaunchUrl(appleMapsUrl)) {
                      await launchUrl(appleMapsUrl);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: const Text('Google Maps'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (await canLaunchUrl(googleMapsUrl)) {
                      await launchUrl(googleMapsUrl);
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      }
    }
  }

  void _shareLocation(String title, double lat, double lng) {
    Share.share(
      'Bu ilana göz at: $title\nKonum: https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
  }

  void _shareProduct(ProductDetail product) {
    if (product.productTitle == null || product.productCode == null) return;

    String slug = product.productTitle!.toLowerCase();
    const turkishChars = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };

    turkishChars.forEach((key, value) {
      slug = slug.replaceAll(key, value);
    });

    slug = slug.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    slug = slug.trim().replaceAll(RegExp(r'\s+'), '-');
    slug = slug.replaceAll(RegExp(r'-+'), '-');

    String code = product.productCode!.replaceAll(
      RegExp(r'tks', caseSensitive: false),
      '',
    );

    final url = 'https://www.takasly.tr/ilan/$slug-$code';
    Share.share(url);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductDetailViewModel>(
      builder: (context, viewModel, child) {
        final product = viewModel.productDetail;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'İlan Detayı',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            backgroundColor: AppTheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  (product?.isFavorite ?? false)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: (product?.isFavorite ?? false)
                      ? Colors.red
                      : Colors.white,
                ),
                onPressed: () {
                  final userToken = context.read<AuthViewModel>().user?.token;
                  if (userToken != null) {
                    viewModel.toggleFavorite(userToken);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Favorilere eklemek için giriş yapmalısınız',
                        ),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: product == null
                    ? null
                    : () => _shareProduct(product),
              ),
            ],
          ),
          body: () {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              return Center(child: Text(viewModel.errorMessage!));
            }

            if (product == null) {
              return const Center(child: Text("Ürün bulunamadı"));
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageGallery(product),
                  const SizedBox(height: 16),
                  _buildTitleSection(product),
                  const SizedBox(height: 16),

                  _buildUserInfoCard(product),
                  const SizedBox(height: 16),

                  _buildPromoteSection(product),

                  _buildDescription(product),

                  const SizedBox(height: 56),

                  _buildAdDetailsTable(product),

                  const SizedBox(height: 46),

                  _buildLocationSection(product),
                  const SizedBox(height: 100),
                ],
              ),
            );
          }(),
          bottomNavigationBar: _buildBottomBar(product),
        );
      },
    );
  }

  void _showFullScreenImage(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) =>
            _FullScreenImageViewer(images: images, initialIndex: initialIndex),
      ),
    );
  }

  Widget _buildImageGallery(ProductDetail product) {
    final List<String> images = [];
    if (product.productImage != null && product.productImage!.isNotEmpty) {
      images.add(product.productImage!);
    }
    if (product.productGallery != null && product.productGallery!.isNotEmpty) {
      for (var img in product.productGallery!) {
        if (!images.contains(img)) {
          images.add(img);
        }
      }
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: images.isEmpty
              ? Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                )
              : PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _showFullScreenImage(images, index),
                      child: Hero(
                        tag: images[index],
                        child: Image.network(
                          images[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[200]),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? AppTheme.primary
                        : Colors.grey.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),
          ),
        // Image count badge
        if (images.length > 1)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleSection(ProductDetail product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.productTitle ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.error, size: 16),
              const SizedBox(width: 4),
              Text(
                '${product.cityTitle?.toUpperCase() ?? ''} / ${product.districtTitle?.toUpperCase() ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(ProductDetail product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kullanıcı Bilgileri",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                if (product.userID != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => ProfileViewModel(),
                        child: UserProfileView(userId: product.userID!),
                      ),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        (product.profilePhoto != null &&
                            product.profilePhoto!.isNotEmpty)
                        ? NetworkImage(product.profilePhoto!)
                        : null,
                    child:
                        (product.profilePhoto == null ||
                            product.profilePhoto!.isEmpty)
                        ? Text(
                            (product.userFullname ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.primary),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.userFullname ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${product.averageRating ?? 0.0} (${product.totalReviews ?? 0})",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdDetailsTable(ProductDetail product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "İlan Bilgileri",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildDetailRow("İlan Sahibi :", product.userFullname ?? '', true),
          _buildDetailRow("Durum :", product.productCondition ?? '', true),
          _buildDetailRow(
            "Kategori :",
            product.categoryList?.map((e) => e.catName).join(' > ') ?? '',
            true,
          ),
          _buildDetailRow("İlan Tarihi :", product.createdAt ?? '', true),
          _buildDetailRow(
            "Görüntülenme :",
            "Bu ilan ${product.proView?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0'} kere görüntülendi",
            true,
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  "İlan Kodu :",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
              Expanded(
                flex: 7,
                child: Row(
                  children: [
                    Text(
                      product.productCode ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (product.productCode != null) {
                          Clipboard.setData(
                            ClipboardData(text: product.productCode!),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('İlan kodu kopyalandı'),
                            ),
                          );
                        }
                      },
                      child: const Icon(
                        Icons.copy,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool addSeparator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ),
              Expanded(
                flex: 7,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          if (addSeparator) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          ],
        ],
      ),
    );
  }

  Widget _buildPromoteSection(ProductDetail product) {
    final authVM = context.read<AuthViewModel>();
    final isOwner = product.userID == authVM.user?.userID;

    if (!isOwner) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İlanını Öne Çıkar!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '1 saat boyunca zirvede kal.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handlePromote(product),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Video İzle ve Ücretsiz Öne Çıkar',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePromote(ProductDetail product) async {
    final authVM = context.read<AuthViewModel>();
    final profileVM = context.read<ProfileViewModel>();
    final userToken = authVM.user?.token;

    if (userToken == null || product.productID == null) return;

    await profileVM.showRewardedAdAndSponsor(
      userToken: userToken,
      productId: product.productID!,
      onSuccess: (message) {
        if (mounted) {
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
        if (mounted) {
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

  Widget _buildDescription(ProductDetail product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Açıklama",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            product.productDesc ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF424242),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(ProductDetail product) {
    // Default coordinates if parsing fails or null
    double lat = 39.9334; // Ankara default
    double lng = 32.8597;

    if (product.productLat != null && product.productLong != null) {
      try {
        lat = double.parse(product.productLat!);
        lng = double.parse(product.productLong!);
      } catch (e) {
        // Fallback to default
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Konum Bilgileri",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_city,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${product.cityTitle?.toUpperCase() ?? ''} / ${product.districtTitle?.toUpperCase() ?? ''}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Flutter Map Implementation
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 13.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none, // Static map
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.rivorya.takaslyapp',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openMap(lat, lng),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text("Yol Tarifi Al"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _shareLocation(product.productTitle ?? 'İlan', lat, lng),
                  icon: const Icon(Icons.share_location, size: 18),
                  label: const Text("Konumu Paylaş"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (product.userID != context.read<AuthViewModel>().user?.userID)
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.grey[600],
                ),
                label: Text(
                  "Bu ilanı şikayet et",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductDetail? product) {
    if (product == null) return const SizedBox.shrink();

    final authVM = context.read<AuthViewModel>();
    final isOwner =
        authVM.user?.userID != null && product.userID == authVM.user?.userID;

    final showCallButton =
        !isOwner &&
        product.isShowContact == true &&
        product.userPhone != null &&
        product.userPhone!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BannerAdWidget(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: AppTheme.cardShadow,
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (isOwner) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProductView(
                              productId: product.productID!,
                              product: product.toProduct(),
                            ),
                          ),
                        );
                        if (result == true && context.mounted) {
                          final userToken = context
                              .read<AuthViewModel>()
                              .user
                              ?.token;
                          context
                              .read<ProductDetailViewModel>()
                              .getProductDetail(
                                product.productID!,
                                userToken: userToken,
                              );
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Düzenle"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(
                          color: AppTheme.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: AppTheme.safePoppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDeleteProduct(
                        context,
                        context.read<ProductDetailViewModel>(),
                      ),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text("Sil"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: AppTheme.safePoppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  if (showCallButton) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _makePhoneCall(product.userPhone!),
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text("Ara"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: AppTheme.safePoppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showOfferBottomSheet(context, product),
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text("Mesaj"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: AppTheme.safePoppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showOfferBottomSheet(BuildContext context, ProductDetail product) {
    final authViewModel = context.read<AuthViewModel>();
    final userToken = authViewModel.user?.token;
    final myUserId = authViewModel.user?.userID;

    if (userToken == null || myUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj göndermek için giriş yapmalısınız'),
        ),
      );
      return;
    }

    if (product.userID == myUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendi ilanınıza mesaj gönderemezsiniz')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          height: MediaQuery.of(context).size.height * 0.85,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) =>
                    ProfileViewModel()..getProfileDetail(myUserId, userToken),
              ),
              ChangeNotifierProvider(create: (_) => TicketViewModel()),
            ],
            child: OfferBottomSheet(
              targetProduct: product,
              userToken: userToken,
              myUserId: myUserId,
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteProduct(
    BuildContext context,
    ProductDetailViewModel viewModel,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlanı Sil'),
        content: const Text(
          'Bu ilanı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VAZGEÇ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'SİL',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    int? userId;
    final dynamic rawUserId = prefs.get('userID');
    if (rawUserId is int) {
      userId = rawUserId;
    } else if (rawUserId is String) {
      userId = int.tryParse(rawUserId);
    }

    if (token != null && userId != null) {
      final success = await viewModel.deleteProduct(token, userId);
      if (success && context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('İlan başarıyla silindi')));
      }
    }
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _showUI = !_showUI;
                  });
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! > 300 ||
                      details.primaryVelocity! < -300) {
                    Navigator.of(context).pop();
                  }
                },
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: widget.images[index],
                      child: Image.network(
                        widget.images[index],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_showUI)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showUI ? 1.0 : 0.0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
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
}
