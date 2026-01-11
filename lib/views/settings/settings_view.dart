import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../profile/profile_edit_view.dart';
import 'blocked_users_view.dart';
import 'change_password_view.dart';
import 'contact_view.dart';
import 'widgets/delete_account_dialogs.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';
import 'about_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text("Ayarlar")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            _buildSectionTitle("HESAP AYARLARI"),
            const SizedBox(height: 12),
            SettingsSection(
              children: [
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: "Profili Düzenle",
                  subtitle: "Kişisel bilgilerini ve fotoğrafını güncelle",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileEditView(),
                      ),
                    );
                    if (context.mounted) {
                      context.read<AuthViewModel>().getUser();
                    }
                  },
                ),
                _buildDivider(),
                SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: "Şifre Değiştir",
                  subtitle: "Hesap güvenliğini sağlamak için şifreni yenile",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordView(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                SettingsTile(
                  icon: Icons.block_flipped,
                  title: "Engellenen Kullanıcılar",
                  subtitle: "Görmek istemediğin kullanıcıları yönet",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BlockedUsersView(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle("BİZİ TAKİP EDİN"),
            const SizedBox(height: 12),
            SettingsSection(
              children: [
                SettingsTile(
                  icon: Icons.share_rounded,
                  title: "Uygulamayı Paylaş",
                  subtitle: "Arkadaşlarına tavsiye et, tanıtımımıza destek ol",
                  iconColor: Colors.blue,
                  iconBackgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () {
                    Share.share(
                      'Takasly ile takas yapmaya başla! https://takasly.tr',
                    );
                  },
                ),
                _buildDivider(),
                SettingsTile(
                  icon: Icons.camera_alt_outlined,
                  title: "Instagram'da Takip Et",
                  subtitle: "@takasly.tr",
                  iconColor: const Color(0xFFE1306C),
                  iconBackgroundColor: const Color(0xFFE1306C).withOpacity(0.1),
                  onTap: () async {
                    final Uri url = Uri.parse(
                      'https://www.instagram.com/takasly.tr',
                    );
                    if (!await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    )) {
                      throw Exception('Could not launch $url');
                    }
                  },
                ),
                _buildDivider(),
                SettingsTile(
                  icon: Icons.mail_outline_rounded,
                  title: "Destek ve Fikirler",
                  subtitle: "info@takasly.tr",
                  iconColor: Colors.amber.shade700,
                  iconBackgroundColor: Colors.amber.shade700.withOpacity(0.1),
                  onTap: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'info@takasly.tr',
                      query: 'subject=Destek ve Fikir Önerisi',
                    );
                    await launchUrl(emailLaunchUri);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle("DESTEK"),
            const SizedBox(height: 12),
            SettingsSection(
              children: [
                SettingsTile(
                  icon: Icons.support_agent_rounded,
                  title: "Bize Ulaşın",
                  subtitle: "Yardım ve taleplerin için bizimle iletişime geç",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactView(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: "Hakkımızda",
                  subtitle: "Takasly topluluğu ve misyonumuz hakkında",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutView(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle("TEHLİKELİ ALAN"),
            const SizedBox(height: 12),
            SettingsSection(
              children: [
                SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: "Hesabı Sil",
                  subtitle: "Hesabını ve tüm verilerini kalıcı olarak siler",
                  textColor: AppTheme.error,
                  iconColor: AppTheme.error,
                  iconBackgroundColor: AppTheme.error.withOpacity(0.1),
                  onTap: () =>
                      DeleteAccountDialogs.show(context, authViewModel),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              "Takasly v2.0.0",
              style: AppTheme.safePoppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "© 2026 Takasly. Tüm hakları saklıdır.",
              style: AppTheme.safePoppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 0,
      color: Colors.grey.shade100,
    );
  }
}
