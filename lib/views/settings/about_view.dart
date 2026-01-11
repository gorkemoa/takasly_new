import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text("Hakkımızda")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo placeholder or actual logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Image.asset(
                'assets/takaslylogo.png',
                height: 80,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.swap_horizontal_circle_outlined,
                  size: 80,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Takasly",
              style: AppTheme.safePoppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Takasın En Kolay Yolu",
              style: AppTheme.safePoppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            _buildAboutCard(
              title: "Biz Kimiz?",
              description:
                  "Takasly, kullanılmayan eşyaların değerini yeniden bulduğu, sürdürülebilir bir gelecek için kurulmuş modern bir takas platformudur. Amacımız, para kullanmadan ihtiyaçlarınızı karşılamanızı sağlamak ve eşyaların ömrünü uzatarak çevreye katkıda bulunmaktır.",
              icon: Icons.people_outline_rounded,
            ),
            const SizedBox(height: 16),
            _buildAboutCard(
              title: "Misyonumuz",
              description:
                  "Tüketim kültürünü değiştirmek ve paylaşım ekonomisini herkese ulaştırmak. Güvenli, hızlı ve kullanıcı dostu bir arayüzle takas deneyimini dijital dünyaya en iyi şekilde taşımak.",
              icon: Icons.lightbulb_outline_rounded,
            ),
            const SizedBox(height: 16),
            _buildAboutCard(
              title: "Neden Takasly?",
              description:
                  "• Tamamen ücretsiz takas imkanı\n• Güvenli kullanıcı profilleri\n• Kolay ilan oluşturma ve yönetme\n• Yakınındaki takas fırsatlarını görme",
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: 48),
            Text(
              "Versiyon 2.0.0",
              style: AppTheme.safePoppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "© 2026 Takasly. Tüm hakları saklıdır.",
              style: AppTheme.safePoppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTheme.safePoppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTheme.safePoppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
