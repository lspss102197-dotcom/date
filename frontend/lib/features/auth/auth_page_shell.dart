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
    required this.subtitle,
    required this.primaryAction,
    required this.secondaryPrompt,
    required this.secondaryAction,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
    required this.form,
    this.isSubmitting = false,
    this.showBackButton = false,
    this.onBack,
    this.showLogo = true,
    this.showBiometric = false,
    this.secondaryInsidePanel = false,
    super.key,
  });

  final String subtitle;
  final String primaryAction;
  final String secondaryPrompt;
  final String secondaryAction;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;
  final Widget form;
  final bool isSubmitting;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showLogo;
  final bool showBiometric;
  final bool secondaryInsidePanel;

  @override
  Widget build(BuildContext context) {
    final footer = secondaryPrompt.isEmpty && secondaryAction.isEmpty
        ? null
        : _AuthFooter(
            prompt: secondaryPrompt,
            action: secondaryAction,
            onPressed: isSubmitting ? null : onSecondaryAction,
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const ColoredBox(color: Color(0xFFF8FBFF), child: SizedBox.expand()),
          SafeArea(
            child: Stack(
              children: [
                if (showBackButton)
                  Positioned(
                    top: 16,
                    left: 20,
                    child: IconButton(
                      tooltip: '返回',
                      icon: const Icon(Icons.arrow_back, size: 32),
                      color: const Color(0xFF263A37),
                      onPressed: isSubmitting
                          ? null
                          : onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const horizontalPadding = 28.0;
                    const verticalPadding = 14.0;
                    final contentWidth =
                        (constraints.maxWidth - horizontalPadding * 2)
                            .clamp(0.0, 640.0)
                            .toDouble();
                    final contentMinHeight =
                        (constraints.maxHeight - verticalPadding * 2)
                            .clamp(0.0, double.infinity)
                            .toDouble();

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: contentMinHeight,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: contentWidth,
                              ),
                              child: SizedBox(
                                width: contentWidth,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _AuthBrand(
                                      showLogo: showLogo,
                                      subtitle: subtitle,
                                    ),
                                    const SizedBox(height: 24),
                                    _AuthPanel(
                                      form: form,
                                      primaryAction: primaryAction,
                                      onPrimaryAction: isSubmitting
                                          ? null
                                          : onPrimaryAction,
                                      isSubmitting: isSubmitting,
                                      showBiometric: showBiometric,
                                      footer: secondaryInsidePanel
                                          ? footer
                                          : null,
                                    ),
                                    if (!secondaryInsidePanel &&
                                        footer != null) ...[
                                      const SizedBox(height: 20),
                                      footer,
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBrand extends StatelessWidget {
  const _AuthBrand({required this.showLogo, required this.subtitle});

  final bool showLogo;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showLogo) ...[const _EcoLogo(), const SizedBox(height: 18)],
        const Text(
          'EcoCommute',
          textAlign: TextAlign.center,
          style: TextStyle(
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
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _EcoLogo extends StatelessWidget {
  const _EcoLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: const BoxDecoration(color: ecoAccent, shape: BoxShape.circle),
      child: const Icon(Icons.eco_outlined, color: ecoPrimary, size: 42),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.form,
    required this.primaryAction,
    required this.onPrimaryAction,
    required this.isSubmitting,
    required this.showBiometric,
    this.footer,
  });

  final Widget form;
  final String primaryAction;
  final VoidCallback? onPrimaryAction;
  final bool isSubmitting;
  final bool showBiometric;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 30, 32, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            form,
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onPrimaryAction,
              style: FilledButton.styleFrom(
                backgroundColor: ecoPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ecoPrimary.withValues(alpha: 0.55),
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
            if (showBiometric) ...[
              const SizedBox(height: 24),
              const _BiometricDivider(),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    disabledForegroundColor: ecoPrimary,
                    disabledBackgroundColor: Colors.white,
                    minimumSize: const Size.square(70),
                    shape: const CircleBorder(),
                    side: const BorderSide(color: ecoBorder, width: 1.4),
                  ),
                  child: const Icon(Icons.fingerprint, size: 36),
                ),
              ),
            ],
            if (footer != null) ...[const SizedBox(height: 30), footer!],
          ],
        ),
      ),
    );
  }
}

class _BiometricDivider extends StatelessWidget {
  const _BiometricDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: ecoBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '使用生物辨識',
            style: TextStyle(color: Color(0xFF4B5F5B), fontSize: 18),
          ),
        ),
        Expanded(child: Divider(color: ecoBorder)),
      ],
    );
  }
}

class _AuthFooter extends StatelessWidget {
  const _AuthFooter({
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [
        Text(
          prompt,
          style: const TextStyle(
            color: Color(0xFF263A37),
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: ecoPrimary,
            textStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: Text(action),
        ),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.validator,
    this.autofillHints,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
    super.key,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ecoText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          autofillHints: autofillHints,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(fontSize: 20, color: ecoText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: ecoMuted,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: ecoBlue, size: 26),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: ecoField,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: _inputBorder(ecoBorder),
            enabledBorder: _inputBorder(ecoBorder),
            focusedBorder: _inputBorder(ecoPrimary, width: 2),
            errorBorder: _inputBorder(Colors.redAccent, width: 1.4),
            focusedErrorBorder: _inputBorder(Colors.redAccent, width: 2),
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1.4}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

String? validateRequired(String? value, String label) {
  if (value == null || value.trim().isEmpty) {
    return '請輸入$label';
  }

  return null;
}

String? validateEmail(String? value) {
  final requiredError = validateRequired(value, 'Email');
  if (requiredError != null) {
    return requiredError;
  }

  final email = value!.trim();
  if (!email.contains('@') || !email.contains('.')) {
    return '請輸入有效的 Email';
  }

  return null;
}

String? validateUsername(String? value) {
  final requiredError = validateRequired(value, '帳號');
  if (requiredError != null) {
    return requiredError;
  }

  final username = value!.trim();
  if (username.length < 3 || username.length > 20) {
    return '帳號長度需介於 3 到 20 個字';
  }

  return null;
}

String? validatePassword(String? value) {
  final requiredError = validateRequired(value, '密碼');
  if (requiredError != null) {
    return requiredError;
  }

  if (value!.length < 8) {
    return '密碼至少需要 8 個字';
  }

  return null;
}
