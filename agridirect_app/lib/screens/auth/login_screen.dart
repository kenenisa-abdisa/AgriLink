import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

import '../../providers/localization_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'buyer';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();

    try {
      if (_isSignUp) {
        final success = await authProvider.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
        );

        if (success && mounted) {
          debugPrint('Sign up successful for role: $_selectedRole');
          // No manual navigation needed, AuthWrapper handles it
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Welcome to AgriLink.'),
              backgroundColor: Color(0xFF1B6B3A),
            ),
          );
        }
      } else {
        debugPrint('Attempting login for: ${_emailController.text}');
        final success = await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (success) {
          debugPrint('Login successful');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
        if (errorMessage.toLowerCase().contains('already registered')) {
          errorMessage = 'This email is already registered.\nPlease Sign In, then go to your Profile to join as a Farmer.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocalizationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Language selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _languageButton('EN', 'en', t),
                      const Text(' | ', style: TextStyle(color: Colors.grey)),
                      _languageButton('አማ', 'am', t),
                      const Text(' | ', style: TextStyle(color: Colors.grey)),
                      _languageButton('OR', 'or', t),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Logo
                  const Icon(Icons.agriculture, size: 80, color: Color(0xFF1B6B3A)),
                  const SizedBox(height: 10),
                  Text(
                    t.translate('AgriLink Ethiopia'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B6B3A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.translate('Fresh · Local · Direct'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Name field (sign up only)
                  if (_isSignUp) ...[
                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Email is required';
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(val)) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone (sign up only)
                  if (_isSignUp) ...[
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      hint: '+251XXXXXXXXX',
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Phone is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Password
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Password is required';
                      if (val.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role selection (sign up only)
                  if (_isSignUp) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'I am a:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _roleRadio('Farmer', 'farmer', Icons.agriculture),
                        const SizedBox(width: 8),
                        _roleRadio('Consumer', 'buyer', Icons.person),
                        const SizedBox(width: 8),
                        _roleRadio('Business', 'business', Icons.business),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit button
                  const SizedBox(height: 8),
                  CustomButton(
                    text: _isSignUp ? t.translate('Sign Up') : t.translate('Sign In'),
                    onPressed: _authenticate,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Toggle sign in / sign up
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? t.translate('Already have an account? Sign In')
                          : t.translate('New to AgriLink? Sign Up'),
                      style: const TextStyle(color: Color(0xFF1B6B3A)),
                    ),
                  ),

                  if (_isSignUp) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () async {
                        final url = Uri.parse('https://accounts.google.com/signup');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Don\'t have an email? Create a Gmail Account'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        textStyle: const TextStyle(decoration: TextDecoration.underline, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageButton(String label, String code, LocalizationProvider t) {
    final isSelected = t.locale == code;
    return GestureDetector(
      onTap: () => t.setLocale(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B6B3A) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _roleRadio(String label, String value, IconData icon) {
    final isSelected = _selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1B6B3A).withValues(alpha: 0.1)
                : Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFF1B6B3A) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? const Color(0xFF1B6B3A)
                      : Colors.grey[600],
                  size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF1B6B3A)
                      : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
