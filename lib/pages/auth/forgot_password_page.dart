import 'package:bet_tracker_app/pages/home/widgets/home_common_widgets.dart';
import 'package:bet_tracker_app/services/auth_service.dart';
import 'package:bet_tracker_app/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.trim().isEmpty) {
      showAppSnackBar(context, 'E-posta adresini gir.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.resetPassword(_emailController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      showAppSnackBar(context, result);
      return;
    }

    showAppSnackBar(
      context,
      'Şifre sıfırlama bağlantısı gönderildi.',
      clearPrevious: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifre Sıfırla'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              color: AppColors.surface,
              elevation: 0,
              shape: AppStyles.cardShape(radius: AppRadius.xl),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      icon: Icons.lock_reset,
                      title: 'Şifremi Unuttum',
                      subtitle:
                      'E-posta adresini gir, sana sıfırlama bağlantısı gönderelim.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      child: _isLoading
                          ? const ButtonLoadingIndicator()
                          : const ButtonIconLabel(
                        icon: Icons.send_outlined,
                        label: 'Bağlantı Gönder',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}