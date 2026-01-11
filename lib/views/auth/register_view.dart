import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../home/home_view.dart';
import 'code_verification_view.dart';

import '../../services/analytics_service.dart';

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
  void initState() {
    super.initState();
    AnalyticsService().logScreenView('Kayit Ol');
  }

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B), // Slate 800
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      'assets/logo/logo2.png',
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Titles - Center Aligned
                Text(
                  'Hemen Katıl',
                  textAlign: TextAlign.start,
                  style: AppTheme.safePoppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B), // Slate 800
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yeni takaslar keşfetmeye başlamak için kayıt ol.',
                  textAlign: TextAlign.start,
                  style: AppTheme.safePoppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B), // Slate 500
                  ),
                ),
                const SizedBox(height: 32),

                // Social Signup Section - MOVED TO TOP
                Text(
                  'Hızlı üye olun',
                  textAlign: TextAlign.center,
                  style: AppTheme.safePoppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B), // Slate 500
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        onPressed: () async {
                          await authViewModel.signInWithGoogle();
                          if (context.mounted &&
                              authViewModel.state == AuthState.success) {
                            _handleLoginSuccess(context);
                          }
                        },
                        iconPath: 'assets/icons/google.png',
                        label: 'Google',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSocialButton(
                        onPressed: () async {
                          await authViewModel.signInWithApple();
                          if (context.mounted &&
                              authViewModel.state == AuthState.success) {
                            _handleLoginSuccess(context);
                          }
                        },
                        iconData: Icons.apple,
                        label: 'Apple',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: Color(0xFFE2E8F0)), // Slate 200
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'veya e-posta ile',
                        style: AppTheme.safePoppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8), // Slate 400
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  ],
                ),
                const SizedBox(height: 24),

                // Name Fields
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _firstNameController,
                        label: 'Ad',
                        hint: 'Adınız',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        label: 'Soyad',
                        hint: 'Soyadınız',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  controller: _emailController,
                  label: 'E-posta',
                  hint: 'ornek@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Telefon',
                  hint: '0 (5XX) XXX XX XX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  controller: _passwordController,
                  label: 'Şifre',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: const Color(0xFF94A3B8),
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
                const SizedBox(height: 12),
                _buildCheckbox(
                  value: _kvkkAccepted,
                  onChanged: (v) => setState(() => _kvkkAccepted = v!),
                  text: 'KVKK aydınlatma metnini okudum ve kabul ediyorum.',
                  onTapText: () =>
                      _showContractDialog(3, 'KVKK Aydınlatma Metni'),
                ),

                const SizedBox(height: 32),

                if (authViewModel.state == AuthState.error &&
                    authViewModel.errorMessage != null)
                  _buildErrorBox(authViewModel.errorMessage!),

                // Register Button
                SizedBox(
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
                              authViewModel.resetState();
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
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

                const SizedBox(height: 48),
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
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                child: Text(
                  'Kapat',
                  style: AppTheme.safePoppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.primary,
                  ),
                ),
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
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155), // Slate 700
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
          style: AppTheme.safePoppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A), // Slate 900
          ),
          decoration: _buildInputDecoration(
            hint: hint,
            icon: icon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.safePoppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF94A3B8), // Slate 400
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC), // Slate 50
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.error.withOpacity(0.5),
          width: 1,
        ),
      ),
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
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onTapText,
            child: Text(
              text,
              style:
                  AppTheme.safePoppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: onTapText != null
                        ? AppTheme.primary
                        : const Color(0xFF64748B),
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

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    String? iconPath,
    IconData? iconData,
    required String label,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style:
          OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ).copyWith(
            overlayColor: WidgetStateProperty.all(
              AppTheme.primary.withOpacity(0.05),
            ),
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconPath != null)
            Image.asset(iconPath, height: 22)
          else if (iconData != null)
            Icon(iconData, size: 24, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.safePoppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Red 50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)), // Red 200
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTheme.safePoppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
