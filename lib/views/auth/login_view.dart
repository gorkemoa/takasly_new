import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'register_view.dart';
import 'forgot_password_view.dart';
import '../home/home_view.dart';
import '../../services/analytics_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView('Giris Yap');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          // Logo - Top Center
                          Center(
                            child: Hero(
                              tag: 'app_logo',
                              child: Image.asset(
                                'assets/logo/logo2.png',
                                height: 250,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // Titles - Center Aligned
                          Text(
                            'Giriş Yap',
                            textAlign: TextAlign.start,
                            style: AppTheme.safePoppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B), // Slate 800
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Takas dünyasına hoş geldiniz.',
                            textAlign: TextAlign.start,
                            style: AppTheme.safePoppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B), // Slate 500
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Social Login Section
                          Row(
                            children: [
                              Expanded(
                                child: _buildSocialButton(
                                  onPressed: () async {
                                    await authViewModel.signInWithGoogle();
                                    if (context.mounted &&
                                        authViewModel.state ==
                                            AuthState.success) {
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
                                        authViewModel.state ==
                                            AuthState.success) {
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
                                child: Divider(
                                  color: Color(0xFFE2E8F0),
                                ), // Slate 200
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'veya e-posta ile',
                                  style: AppTheme.safePoppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8), // Slate 400
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Color(0xFFE2E8F0)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Email Input - Filled Style
                          _buildLabel('E-posta'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTheme.safePoppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A), // Slate 900
                            ),
                            decoration: _buildInputDecoration(
                              hint: 'ornek@email.com',
                              icon: Icons.email_outlined,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Password Input - Filled Style
                          _buildLabel('Şifre'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: AppTheme.safePoppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: _buildInputDecoration(
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
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
                          ),

                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordView(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Şifremi Unuttum?',
                                style: AppTheme.safePoppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          if (authViewModel.state == AuthState.error &&
                              authViewModel.errorMessage != null)
                            _buildErrorBox(authViewModel.errorMessage!),

                          // Login Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: authViewModel.state == AuthState.busy
                                  ? null
                                  : () async {
                                      await authViewModel.login(
                                        _emailController.text.trim(),
                                        _passwordController.text,
                                      );

                                      if (context.mounted &&
                                          authViewModel.state ==
                                              AuthState.success) {
                                        _handleLoginSuccess(context);
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
                                      'Giriş Yap',
                                      style: AppTheme.safePoppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Register Link
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hesabınız yok mu?',
                      style: AppTheme.safePoppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterView(),
                          ),
                        );
                      },
                      child: Text(
                        'Kayıt Olun',
                        style: AppTheme.safePoppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: AppTheme.safePoppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF334155), // Slate 700
      ),
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

  void _handleLoginSuccess(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context, true);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeView()),
        (route) => false,
      );
    }
  }
}
