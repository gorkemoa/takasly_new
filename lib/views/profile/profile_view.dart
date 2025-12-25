import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_view.dart';
import '../auth/register_view.dart';
import 'favorites_view.dart';
import 'my_ads_view.dart';
import 'my_trades_view.dart';
import 'profile_edit_view.dart';
import 'change_password_view.dart';
import 'settings_view.dart';
import 'contact_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.user != null) {
        authViewModel.getUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final isLoggedIn = authViewModel.user != null;

    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(context),
        body: SafeArea(child: _buildGuestProfile(context)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildProfileHeader(context, authViewModel),
            const SizedBox(height: 24),

            // Account Section
            _buildSectionTitle("Hesabım"),
            const SizedBox(height: 12),
            _buildMenuSection(
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.grid_view_rounded,
                  title: "İlanlarım",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyAdsView(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  context,
                  icon: Icons.favorite_border_rounded,
                  title: "Favorilerim",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesView(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.swap_horiz,
                  title: 'Takaslarım',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyTradesView(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_none_rounded,
                  title: "Bildirimler",
                  onTap: () {
                    // Navigate to Notifications
                  },
                ),
                _buildDivider(),
              ],
            ),
            const SizedBox(height: 24),

            // Support Section
            _buildSectionTitle("Destek"),
            const SizedBox(height: 12),
            _buildMenuSection(
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: "Ayarlar",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsView(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.lock_outline_rounded,
                  title: "Şifre Değiştir",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordView(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.support_agent_rounded,
                  title: "Bize Ulaşın",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactView(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: "Yardım Merkezi",
                  onTap: () {
                    // Navigate to Help
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: "Hakkımızda",
                  onTap: () {
                    // Navigate to About
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Logout
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  _showLogoutConfirmation(context, authViewModel);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
                label: Text(
                  "Çıkış Yap",
                  style: AppTheme.safePoppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Hesabım',
        style: AppTheme.safePoppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTheme.background,
        ),
      ),
      centerTitle: true,
      backgroundColor: AppTheme.primary,
      iconTheme: const IconThemeData(color: AppTheme.background),
      actionsIconTheme: const IconThemeData(color: AppTheme.background),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsView()),
            );
          },
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Text(
          title,
          style: AppTheme.safePoppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    final profile = authViewModel.userProfile;
    final isLoading = authViewModel.state == AuthState.busy;

    if (isLoading && profile == null) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.background,
              border: Border.all(color: Colors.grey.shade100, width: 2),
              image:
                  (profile?.profilePhoto != null &&
                      profile!.profilePhoto!.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(profile.profilePhoto!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child:
                (profile?.profilePhoto == null ||
                    profile!.profilePhoto!.isEmpty)
                ? Center(
                    child: Text(
                      (profile?.userFullname?.isNotEmpty == true
                              ? profile!.userFullname![0]
                              : "U")
                          .toUpperCase(),
                      style: AppTheme.safePoppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.userFullname ?? "Kullanıcı",
                  style: AppTheme.safePoppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (profile != null &&
                              profile.totalReviews != null &&
                              profile.totalReviews! > 0)
                          ? "${profile.averageRating} Puan (${profile.totalReviews} Değerlendirme)"
                          : "Yeni Kullanıcı",
                      style: AppTheme.safePoppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditView(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppTheme.primary, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.safePoppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? AppTheme.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFE0E0E0),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      endIndent: 0,
      color: Colors.grey.shade100,
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Hesabınıza Giriş Yapın',
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Takas yapmak, ilan vermek ve favorilerini yönetmek için giriş yapın.',
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginView()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                  shadowColor: AppTheme.primary.withOpacity(0.4),
                ),
                child: const Text('Giriş Yap'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterView(),
                    ),
                  );
                },
                child: const Text('Kayıt Ol'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Çıkış Yap',
          style: AppTheme.safePoppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
          style: AppTheme.safePoppins(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: AppTheme.safePoppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authViewModel.logout();
            },
            child: Text(
              'Çıkış Yap',
              style: AppTheme.safePoppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
