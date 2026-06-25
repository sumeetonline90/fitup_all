import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/error/failures.dart';
import '../../../../shared/widgets/fitup_logo.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../providers/auth_providers.dart';

/// Email / password + Google sign-in — Stitch onboarding layout.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      await ref.read(authNotifierProvider.notifier).signInWithEmail(
            _emailController.text,
            _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      final Object? err = ref.read(authNotifierProvider).error;
      if (err != null) {
        final String msg = err is AuthFailure
            ? (err.message ?? 'Something went wrong.')
            : 'Something went wrong.';
        _showError(msg);
      }
    } catch (e) {
      final String msg = e is AuthFailure
          ? (e.message ?? 'Something went wrong.')
          : 'Something went wrong.';
      _showError(msg);
    }
  }

  Future<void> _google() async {
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      if (!mounted) {
        return;
      }
      final Object? err = ref.read(authNotifierProvider).error;
      if (err != null) {
        final String msg = err is AuthFailure
            ? (err.message ?? 'Something went wrong.')
            : 'Something went wrong.';
        _showError(msg);
      }
    } catch (e) {
      final String msg = e is AuthFailure
          ? (e.message ?? 'Something went wrong.')
          : 'Something went wrong.';
      _showError(msg);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> authAsync = ref.watch(authNotifierProvider);
    final bool loading = authAsync.isLoading;

    ref.listen(authNotifierProvider, (AsyncValue<void>? previous, AsyncValue<void> next) {
      next.whenOrNull(
        error: (Object err, _) {
          final String msg = err is AuthFailure
              ? (err.message ?? 'Something went wrong.')
              : 'Something went wrong.';
          _showError(msg);
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 24),
                const Center(
                  child: FitupLogo(size: 100),
                ),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: 'Welcome to ',
                        style: AppTextStyles.h1,
                      ),
                      TextSpan(
                        text: 'Fitup',
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your complete health companion',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.alternate_email, color: AppColors.primary),
                  ),
                  validator: (String? v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                  ),
                  validator: (String? v) {
                    if (v == null || v.isEmpty) {
                      return 'Enter password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: NeonButton(
                    label: loading ? 'Signing in…' : 'Sign In',
                    onPressed: loading ? null : _submit,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: loading ? null : _google,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: BorderSide(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(48),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _googleGIcon(),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      children: <InlineSpan>[
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Register',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _googleGIcon() {
  return Container(
    width: 22,
    height: 22,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
    ),
    alignment: Alignment.center,
    child: Text(
      'G',
      style: AppTextStyles.labelSmall.copyWith(
        color: Colors.black87,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
