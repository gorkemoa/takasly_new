import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'profile_edit_view.dart';
import 'change_password_view.dart';
import 'contact_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          "Ayarlar",
          style: AppTheme.safePoppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.background,
          ),
        ),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: AppTheme.background),
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            _buildSettingsSection(
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: "Profili Düzenle",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileEditView(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
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
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              children: [
                _buildSettingsItem(
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
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.delete_outline_rounded,
                  title: "Hesabı Sil",
                  textColor: AppTheme.error,
                  iconColor: AppTheme.error,
                  onTap: () =>
                      _showDeleteConfirmationSequence(context, authViewModel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem(
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppTheme.primary, size: 24),
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
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade300,
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
      indent: 60,
      endIndent: 0,
      color: Colors.grey.shade100,
    );
  }

  void _showDeleteConfirmationSequence(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    _showFirstConfirmation(context, authViewModel);
  }

  void _showFirstConfirmation(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Hesabı Sil",
          style: AppTheme.safePoppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          "Hesabınızı silmek istediğinize emin misiniz?",
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
              "Vazgeç",
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
              _showSecondConfirmation(context, authViewModel);
            },
            child: Text(
              "Devam Et",
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

  void _showSecondConfirmation(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Emin misiniz?",
          style: AppTheme.safePoppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          "Bu işlem geri alınamaz ve tüm verileriniz kalıcı olarak silinecektir.",
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
              "Vazgeç",
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
              _showThirdConfirmation(context, authViewModel);
            },
            child: Text(
              "Anladım, Devam Et",
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

  void _showThirdConfirmation(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Son Onay",
          style: AppTheme.safePoppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          "Hesabınızı kalıcı olarak silmeyi onaylıyor musunuz?",
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
              "Vazgeç",
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
              authViewModel.deleteAccount();
            },
            child: Text(
              "HESABI SİL",
              style: AppTheme.safePoppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
