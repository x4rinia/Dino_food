import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _registeredNeedsConfirmation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );

    if (success && mounted) {
      if (authProvider.needsEmailConfirmation) {
        setState(() {
          _registeredNeedsConfirmation = true;
        });
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registrierung fehlgeschlagen.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.status == AuthStatus.loading;

    if (_registeredNeedsConfirmation) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registrierung')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('📧', style: TextStyle(fontSize: 44)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Fast geschafft! 🦕',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Wir haben einen Bestätigungslink an ${_emailController.text.trim()} gesendet.\n\nBitte bestätige deine E-Mail-Adresse. Danach kannst du dich bei Dino_food anmelden.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        authProvider.resetEmailConfirmationFlag();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Zum Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konto erstellen'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Willkommen bei Dino_food 🦕',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Erstelle dein Konto, um gemeinsame Einkaufslisten zu verwalten.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Display Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Dein Name / Spitzname',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitte Namen eingeben';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail-Adresse',
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
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: const InputDecoration(
                      labelText: 'Passwort wiederholen',
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwörter stimmen nicht überein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Register Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
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
                              'Registrieren',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
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
