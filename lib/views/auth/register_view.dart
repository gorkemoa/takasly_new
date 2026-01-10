import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../home/home_view.dart';
import 'code_verification_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _policyAccepted = true;
  bool _kvkkAccepted = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hesap Oluşturun',
                  style: AppTheme.safePoppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hemen aramıza katılın ve takasa başlayın!',
                  style: AppTheme.safePoppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                // Name Fields
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _firstNameController,
                        label: 'Ad',
                        hint: 'Adınız',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        label: 'Soyad',
                        hint: 'Soyadınız',
                        icon: Icons.person_outline,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: 'E-posta',
                  hint: 'ornek@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Telefon',
                  hint: '0 (5XX) XXX XX XX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _passwordController,
                  label: 'Şifre',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Checkboxes
                _buildCheckbox(
                  value: _policyAccepted,
                  onChanged: (v) => setState(() => _policyAccepted = v!),
                  text: 'Kullanıcı sözleşmesini okudum ve kabul ediyorum.',
                  onTapText: () => _showContractDialog(4, 'Üyelik Sözleşmesi'),
                ),
                _buildCheckbox(
                  value: _kvkkAccepted,
                  onChanged: (v) => setState(() => _kvkkAccepted = v!),
                  text: 'KVKK aydınlatma metnini okudum ve kabul ediyorum.',
                  onTapText: () =>
                      _showContractDialog(3, 'KVKK Aydınlatma Metni'),
                ),

                const SizedBox(height: 24),

                if (authViewModel.state == AuthState.error &&
                    authViewModel.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authViewModel.errorMessage!,
                            style: AppTheme.safePoppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authViewModel.state == AuthState.busy
                        ? null
                        : () async {
                            await authViewModel.register(
                              firstName: _firstNameController.text.trim(),
                              lastName: _lastNameController.text.trim(),
                              email: _emailController.text.trim(),
                              phone: _phoneController.text.trim(),
                              password: _passwordController.text,
                              policy: _policyAccepted,
                              kvkk: _kvkkAccepted,
                            );

                            if (context.mounted &&
                                authViewModel.state == AuthState.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Kayıt Başarılı! Kod Gönderildi.',
                                  ),
                                ),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CodeVerificationView(),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: authViewModel.state == AuthState.busy
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Kayıt Ol',
                            style: AppTheme.safePoppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Social Login Options
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'veya',
                        style: AppTheme.safePoppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await authViewModel.signInWithGoogle();
                          if (context.mounted &&
                              authViewModel.state == AuthState.success) {
                            _handleLoginSuccess(context);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.g_mobiledata, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'Google',
                              style: AppTheme.safePoppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await authViewModel.signInWithApple();
                          if (context.mounted &&
                              authViewModel.state == AuthState.success) {
                            _handleLoginSuccess(context);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.apple, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'Apple',
                              style: AppTheme.safePoppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLoginSuccess(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeView()),
      (route) => false,
    );
  }

  Future<void> _showContractDialog(int id, String title) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final contract = await authViewModel.getContract(id);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      if (contract != null) {
        final content = contract.desc ?? '';

        if (!context.mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              title,
              style: AppTheme.safePoppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: AppTheme.textPrimary,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(child: Html(data: content)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sözleşme yüklenemedi: $e')));
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.safePoppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization:
              (keyboardType == TextInputType.emailAddress ||
                  keyboardType == TextInputType.phone ||
                  obscureText)
              ? TextCapitalization.none
              : TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
    VoidCallback? onTapText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onTapText,
            child: Text(
              text,
              style:
                  AppTheme.safePoppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: onTapText != null
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ).copyWith(
                    decoration: onTapText != null
                        ? TextDecoration.underline
                        : null,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
