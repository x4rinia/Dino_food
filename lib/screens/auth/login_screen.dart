import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Anmeldung fehlgeschlagen.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Header
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryLight.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '🦕',
                        style: TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Dino_food',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Gemeinsame Einkaufsliste für deinen Haushalt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 36),

                  if (!SupabaseConfig.isConfigured)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.accentYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentYellow, width: 1),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: AppTheme.textDark, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Hinweis: Supabase-Zugangsdaten in .env noch nicht hinterlegt. Die App startet im Vorschau-/Demo-Modus.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitte E-Mail eingeben';
                      }
                      if (!value.contains('@')) {
                        return 'Ungültige E-Mail-Adresse';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte Passwort eingeben';
                      }
                      if (value.length < 6) {
                        return 'Mindestens 6 Zeichen erforderlich';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Anmelden',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Link to Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Noch kein Konto?',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Jetzt registrieren',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
      ),
    );
  }
}
