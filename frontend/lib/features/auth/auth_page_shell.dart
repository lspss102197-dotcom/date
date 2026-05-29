import 'package:flutter/material.dart';

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    required this.title,
    required this.subtitle,
    required this.primaryAction,
    required this.secondaryAction,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
    required this.form,
    super.key,
  });

  final String title;
  final String subtitle;
  final String primaryAction;
  final String secondaryAction;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 680;
                      final brand = _AuthBrand(
                        title: title,
                        subtitle: subtitle,
                      );
                      final fields = _AuthActions(
                        primaryAction: primaryAction,
                        secondaryAction: secondaryAction,
                        onPrimaryAction: onPrimaryAction,
                        onSecondaryAction: onSecondaryAction,
                        form: form,
                      );

                      if (!wide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [brand, const SizedBox(height: 36), fields],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: brand),
                          const SizedBox(width: 56),
                          Expanded(child: fields),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBrand extends StatelessWidget {
  const _AuthBrand({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CarbonTripMark(),
        const SizedBox(height: 28),
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Text(subtitle, style: textTheme.bodyLarge),
      ],
    );
  }
}

class _CarbonTripMark extends StatelessWidget {
  const _CarbonTripMark();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.directions_walk_rounded,
            color: colorScheme.onPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Carbon Trip',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _AuthActions extends StatelessWidget {
  const _AuthActions({
    required this.primaryAction,
    required this.secondaryAction,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
    required this.form,
  });

  final String primaryAction;
  final String secondaryAction;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        form,
        const SizedBox(height: 30),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            TextButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryAction),
            ),
            FilledButton(
              onPressed: onPrimaryAction,
              child: Text(primaryAction),
            ),
          ],
        ),
      ],
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
  final requiredError = validateRequired(value, '電子郵件');
  if (requiredError != null) {
    return requiredError;
  }

  final email = value!.trim();
  if (!email.contains('@') || !email.contains('.')) {
    return '請輸入有效的電子郵件';
  }

  return null;
}

String? validatePassword(String? value) {
  final requiredError = validateRequired(value, '密碼');
  if (requiredError != null) {
    return requiredError;
  }

  if (value!.length < 6) {
    return '密碼至少需要 6 個字元';
  }

  return null;
}
