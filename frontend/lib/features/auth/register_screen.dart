import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_page_shell.dart';
import 'auth_repository.dart';

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
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _hasEnoughChars => _passwordController.text.length >= 8;

  bool get _hasLettersAndNumbers {
    final password = _passwordController.text;
    return RegExp('[A-Za-z]').hasMatch(password) &&
        RegExp('[0-9]').hasMatch(password);
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refreshPasswordRequirements);
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      subtitle: '註冊帳戶開始累積你的減碳旅程',
      primaryAction: '註冊',
      secondaryPrompt: '已經有帳號了嗎？',
      secondaryAction: '返回登入',
      isSubmitting: _isSubmitting,
      showBackButton: true,
      showLogo: false,
      secondaryInsidePanel: true,
      onPrimaryAction: _submit,
      onSecondaryAction: () => Navigator.of(context).pop(),
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: '帳號',
              hint: '請輸入帳號',
              icon: Icons.person_outline,
              controller: _usernameController,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              validator: validateUsername,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              label: 'Email',
              hint: '請輸入 Email',
              icon: Icons.mail_outline,
              controller: _emailController,
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: validateEmail,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              label: '密碼',
              hint: '設定密碼',
              icon: Icons.lock_outline,
              controller: _passwordController,
              autofillHints: const [AutofillHints.newPassword],
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: validatePassword,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? '顯示密碼' : '隱藏密碼',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: ecoMuted,
                  size: 30,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 6),
            _PasswordRequirement(label: '至少 8 個字', isMet: _hasEnoughChars),
            const SizedBox(height: 4),
            _PasswordRequirement(
              label: '包含英文字母與數字',
              isMet: _hasLettersAndNumbers,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              label: '確認密碼',
              hint: '再次輸入密碼',
              icon: Icons.lock_reset_outlined,
              controller: _confirmPasswordController,
              autofillHints: const [AutofillHints.newPassword],
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: _validateConfirmPassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
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
      return '再次輸入的密碼不一致';
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
    _passwordController.removeListener(_refreshPasswordRequirements);
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _refreshPasswordRequirements() {
    setState(() {});
  }
}

class _PasswordRequirement extends StatelessWidget {
  const _PasswordRequirement({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          color: isMet ? ecoPrimary : ecoMuted,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: ecoMuted,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
