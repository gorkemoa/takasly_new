import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/home/home_models.dart';
import '../../theme/app_theme.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryCard({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: SvgPicture.network(
                category.catImage,
                placeholderBuilder: (context) =>
                    const CircularProgressIndicator(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.catName.length > 30
                  ? '${category.catName.substring(0, 30)}...'
                  : category.catName,
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
