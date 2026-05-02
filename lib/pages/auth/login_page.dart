import 'package:bet_tracker_app/pages/auth/forgot_password_page.dart';
import 'package:bet_tracker_app/pages/auth/register_page.dart';
import 'package:bet_tracker_app/pages/home/widgets/home_common_widgets.dart';
import 'package:bet_tracker_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showMessage('E-posta ve şifre alanlarını doldur.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      _showMessage(result);
    }
  }

  Future<void> _googleLogin() async {
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final result = await AuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null && result != 'Google ile giriş iptal edildi.') {
      _showMessage(result);
    }
  }

  void _showMessage(String message) {
    showAppSnackBar(
      context,
      message,
      clearPrevious: true,
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(
      'https://onurerdil.github.io/bet_tracker_app/PRIVACY_POLICY',
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) return;

    if (!launched) {
      _showMessage('Gizlilik politikası açılamadı.');
    }
  }

  Future<void> _openAccountDeletionRequestEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'bettrackerapptr@gmail.com',
      queryParameters: {
        'subject': 'Bet Tracker Hesap ve Veri Silme Talebi',
        'body':
        'Merhaba,\n\n'
            'Bet Tracker hesabımın ve hesabıma bağlı verilerimin silinmesini talep ediyorum.\n\n'
            'Hesap e-posta adresim:\n\n'
            'Ek not:\n\n',
      },
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) return;

    if (!launched) {
      _showMessage('E-posta uygulaması açılamadı.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 430 : double.infinity,
            ),
            child: Card(
              color: const Color(0xFF161A23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.stacked_line_chart_rounded,
                      size: 56,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bet Tracker',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bahislerini takip et, disiplinini koru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Giriş Yap'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _googleLogin,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: const BorderSide(color: Color(0xFF2A3140)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text('Google ile Giriş Yap'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: const Text('Şifremi Unuttum'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Hesabın yok mu?'),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text('Kayıt Ol'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _openPrivacyPolicy,
                      icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                      label: const Text('Gizlilik Politikası'),
                    ),
                    TextButton.icon(
                      onPressed: _isLoading
                          ? null
                          : _openAccountDeletionRequestEmail,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Hesap ve Veri Silme Talebi'),
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