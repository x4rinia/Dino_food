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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUp(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
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

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Benutzername',
                      hintText: 'z.B. DinoChef oder Xarinia',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitte gib einen Benutzernamen ein';
                      }
                      if (value.trim().length < 2) {
                        return 'Mindestens 2 Zeichen erforderlich';
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
                              'Account erstellen',
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
