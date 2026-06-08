import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'auth_page_shell.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({required this.onAuthenticated, super.key});

  final VoidCallback onAuthenticated;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      title: '登入',
      subtitle: '使用您的 Carbon Trip 帳戶繼續',
      primaryAction: '下一步',
      secondaryAction: '建立帳戶',
      isSubmitting: _isSubmitting,
      onPrimaryAction: _submit,
      onSecondaryAction: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                RegisterScreen(onAuthenticated: widget.onAuthenticated),
          ),
        );
      },
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
              controller: _passwordController,
              autofillHints: const [AutofillHints.password],
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
              textInputAction: TextInputAction.done,
              validator: validatePassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Align(
<<<<<<< Updated upstream
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () {}, child: const Text('忘記密碼？')),
=======
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: ecoPrimary,
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('忘記密碼？'),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                const Text(
                  '還沒有註冊帳號嗎？',
                  style: TextStyle(
                    color: Color(0xFF263A37),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: _isSubmitting ? null : _openRegister,
                  style: TextButton.styleFrom(
                    foregroundColor: ecoPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('點我註冊'),
                ),
              ],
>>>>>>> Stashed changes
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
          .login(
            username: _usernameController.text,
            password: _passwordController.text,
          );

      if (mounted) {
        widget.onAuthenticated();
      }
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
    _passwordController.dispose();
    super.dispose();
  }
}
