import 'package:flutter/material.dart';

const ecoPrimary = Color(0xFF007D68);
const ecoAccent = Color(0xFF30D1C0);
const ecoBlue = Color(0xFF0A61D8);
const ecoText = Color(0xFF071328);
const ecoMuted = Color(0xFF6F7F7B);
const ecoField = Color(0xFFF1F6FA);
const ecoBorder = Color(0xFFB6CBC7);

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    required this.title,
    required this.subtitle,
    required this.primaryAction,
    required this.secondaryAction,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
    required this.form,
    this.isSubmitting = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final String primaryAction;
  final String secondaryAction;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;
  final Widget form;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = (constraints.maxWidth - 56)
                .clamp(0.0, 640.0)
                .toDouble();

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _EcoLogo(),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: ecoPrimary,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF263A37),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 24),
                          DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                32,
                                30,
                                32,
                                28,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  form,
                                  const SizedBox(height: 20),
                                  FilledButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : onPrimaryAction,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: ecoPrimary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: ecoPrimary
                                          .withValues(alpha: 0.55),
                                      minimumSize: const Size.fromHeight(56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    child: isSubmitting
                                        ? const SizedBox.square(
                                            dimension: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(primaryAction),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextButton(
                            onPressed: isSubmitting ? null : onSecondaryAction,
                            child: Text(secondaryAction),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EcoLogo extends StatelessWidget {
  const _EcoLogo();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircleAvatar(
        radius: 41,
        backgroundColor: ecoAccent,
        child: Icon(Icons.eco_outlined, color: ecoPrimary, size: 42),
      ),
    );
  }
}

String? validateRequired(String? value, String label) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter $label';
  }

  return null;
}

String? validateEmail(String? value) {
  final requiredError = validateRequired(value, 'email');
  if (requiredError != null) {
    return requiredError;
  }

  final email = value!.trim();
  if (!email.contains('@') || !email.contains('.')) {
    return 'Please enter a valid email';
  }

  return null;
}

String? validateUsername(String? value) {
  final requiredError = validateRequired(value, 'username');
  if (requiredError != null) {
    return requiredError;
  }

  final username = value!.trim();
  if (username.length < 3 || username.length > 20) {
    return 'Username must be 3 to 20 characters';
  }

  return null;
}

String? validatePassword(String? value) {
  final requiredError = validateRequired(value, 'password');
  if (requiredError != null) {
    return requiredError;
  }

  if (value!.length < 8) {
    return 'Password must be at least 8 characters';
  }

  return null;
}
