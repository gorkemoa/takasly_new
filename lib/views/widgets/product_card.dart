import 'package:flutter/material.dart';
import '../../models/products/product_models.dart';
import '../../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavoritePressed,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    bool isFavorite = product.isFavorite ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.borderRadius,
          border: product.isSponsor == true
              ? Border.all(
                  color: const Color.fromARGB(255, 255, 215, 0),
                  width: 2,
                )
              : Border.all(color: Colors.black.withOpacity(0.2)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: AppTheme.borderRadius.topLeft,
                      topRight: AppTheme.borderRadius.topRight,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.0, // Square image
                      child: product.productImage != null
                          ? Image.network(
                              product.productImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: Colors.grey[100]),
                            )
                          : Container(color: Colors.grey[100]),
                    ),
                  ),
                ),
                // Edit Action (Top Left)
                if (onEdit != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),

                // Engagement & Delete Actions (Top Right)
                if (onFavoritePressed != null || onDelete != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onFavoritePressed != null)
                          GestureDetector(
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
                                    : Icons.favorite_border,
                                size: 18,
                                color: isFavorite
                                    ? AppTheme.error
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                        if (onDelete != null) ...[
                          if (onFavoritePressed != null)
                            const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
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
