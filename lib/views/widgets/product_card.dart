import 'package:flutter/material.dart';
import '../../models/products/product_models.dart';
import '../../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritePressed;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    bool isFavorite = product.isFavorite ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5), // Radius 10
          border: Border.all(
            color: Colors.grey.withOpacity(0.4),
          ), // Border opacity 0.3
          // Slight shadow like the image
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5), // Radius 10
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.0, // Square image
                    child: product.productImage != null
                        ? Image.network(
                            product.productImage!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey[100]),
                          )
                        : Container(color: Colors.grey[100]),
                  ),
                ),
                // Top Right Badge (Favorite)
                Positioned(
                  top: 8, // Tighter spacing
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavoritePressed,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border, // Toggle icon
                        size: 18,
                        color: isFavorite
                            ? AppTheme.error
                            : Colors.grey[400], // Toggle color
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10), // Tighter padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category (Green/Primary)
                        Text(
                          product.categoryTitle ?? 'Kategori',
                          style: AppTheme.safePoppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4), // Better spacing
                        // Title
                        Text(
                          product.productTitle ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.safePoppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    // Location (Bottom)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${product.cityTitle?.toUpperCase() ?? ''} / ${product.districtTitle?.toUpperCase() ?? ''}', // UPPERCASE
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.safePoppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
