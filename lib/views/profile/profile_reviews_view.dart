import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/auth/get_user_model.dart';
import 'package:intl/intl.dart';

class ProfileReviewsView extends StatelessWidget {
  const ProfileReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Değerlendirmeler'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: AppTheme.safePoppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            tabs: const [
              Tab(text: "Geri Bildirimler"),
              Tab(text: "Değerlendirmelerim"),
            ],
          ),
        ),
        body: Consumer<AuthViewModel>(
          builder: (context, authVM, child) {
            final profile = authVM.userProfile;
            if (profile == null) {
              return const Center(child: Text("Değerlendirme bulunamadı."));
            }

            return TabBarView(
              children: [
                _ReviewsList(reviews: profile.reviews ?? [], isReceived: true),
                _ReviewsList(
                  reviews: profile.myReviews ?? [],
                  isReceived: false,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReviewsList extends StatelessWidget {
  final List<Review> reviews;
  final bool isReceived;

  const _ReviewsList({required this.reviews, required this.isReceived});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isReceived
                  ? "Henüz bir geri bildirim almadınız."
                  : "Henüz bir değerlendirme yapmadınız.",
              style: AppTheme.safePoppins(
                fontSize: 15,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return _ReviewCard(review: review, isReceived: isReceived);
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final bool isReceived;

  const _ReviewCard({required this.review, required this.isReceived});

  @override
  Widget build(BuildContext context) {
    final String? name = isReceived ? review.reviewerName : review.revieweeName;
    final String? image = isReceived
        ? review.reviewerImage
        : review.revieweeImage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.background,
                backgroundImage: (image != null && image.isNotEmpty)
                    ? NetworkImage(image)
                    : null,
                child: (image == null || image.isEmpty)
                    ? Text(
                        (name?.isNotEmpty == true ? name![0] : "U")
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? "Kullanıcı",
                      style: AppTheme.safePoppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(review.reviewDate),
                      style: AppTheme.safePoppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${review.rating}",
                      style: AppTheme.safePoppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: AppTheme.safePoppins(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
