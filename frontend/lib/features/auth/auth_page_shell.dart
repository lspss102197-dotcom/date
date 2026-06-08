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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
<<<<<<< Updated upstream
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
=======
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
>>>>>>> Stashed changes
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
                        onPrimaryAction: isSubmitting ? null : onPrimaryAction,
                        onSecondaryAction: isSubmitting
                            ? null
                            : onSecondaryAction,
                        form: form,
                        isSubmitting: isSubmitting,
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
    required this.isSubmitting,
  });

  final String primaryAction;
  final String secondaryAction;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final Widget form;
  final bool isSubmitting;

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
              child: isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(primaryAction),
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

String? validateUsername(String? value) {
  final requiredError = validateRequired(value, '使用者名稱');
  if (requiredError != null) {
    return requiredError;
  }

  final username = value!.trim();
  if (username.length < 3 || username.length > 20) {
    return '使用者名稱需為 3 到 20 個字元';
  }

  return null;
}

String? validatePassword(String? value) {
  final requiredError = validateRequired(value, '密碼');
  if (requiredError != null) {
    return requiredError;
  }

  if (value!.length < 8) {
    return '密碼至少需要 8 個字元';
  }

  return null;
}
