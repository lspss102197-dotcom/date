import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'auth_page_shell.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({required this.onAuthenticated, super.key});

  final VoidCallback onAuthenticated;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      title: '建立帳戶',
      subtitle: '開始記錄旅程與碳排成果',
      primaryAction: '下一步',
      secondaryAction: '登入',
      isSubmitting: _isSubmitting,
      onPrimaryAction: _submit,
      onSecondaryAction: () => Navigator.of(context).pop(),
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _usernameController,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: '使用者名稱',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: validateUsername,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _emailController,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: '電子郵件',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: validateEmail,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _passwordController,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: '密碼',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? '顯示密碼' : '隱藏密碼',
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
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: validatePassword,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _confirmPasswordController,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: '確認密碼',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmPassword ? '顯示密碼' : '隱藏密碼',
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              validator: _validateConfirmPassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _validateConfirmPassword(String? value) {
    final requiredError = validateRequired(value, '確認密碼');
    if (requiredError != null) {
      return requiredError;
    }

    if (value != _passwordController.text) {
      return '兩次輸入的密碼不一致';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .register(
            username: _usernameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
      widget.onAuthenticated();
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
