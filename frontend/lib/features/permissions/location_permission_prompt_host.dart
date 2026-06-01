import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_preferences.dart';
import '../trips/current_location_provider.dart';

class LocationPermissionPromptHost extends ConsumerStatefulWidget {
  const LocationPermissionPromptHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LocationPermissionPromptHost> createState() =>
      _LocationPermissionPromptHostState();
}

class _LocationPermissionPromptHostState
    extends ConsumerState<LocationPermissionPromptHost>
    with WidgetsBindingObserver {
  bool _isChecking = false;
  bool _hasCheckedThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPrompt();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndPrompt();
    }
  }

  Future<void> _checkAndPrompt() async {
    if (_isChecking || !mounted) {
      return;
    }

    _isChecking = true;
    final preferences = ref.read(appPreferencesProvider);
    final locationService = ref.read(currentLocationServiceProvider);

    try {
      final hasSeenPrompt = await preferences.hasSeenLocationPermissionPrompt();
      final status = await locationService.checkAccessStatus();

      if (!mounted) {
        return;
      }

      if (status == LocationAccessStatus.ready) {
        _hasCheckedThisSession = true;
        return;
      }

      if (_hasCheckedThisSession && hasSeenPrompt) {
        return;
      }

      _hasCheckedThisSession = true;
      await preferences.markLocationPermissionPromptSeen();
      await _handleStatus(status);
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _handleStatus(LocationAccessStatus status) async {
    final locationService = ref.read(currentLocationServiceProvider);

    switch (status) {
      case LocationAccessStatus.ready:
        return;
      case LocationAccessStatus.denied:
        await locationService.requestAccess();
      case LocationAccessStatus.serviceDisabled:
      case LocationAccessStatus.deniedForever:
        await _showSettingsPrompt(status);
    }
  }

  Future<void> _showSettingsPrompt(LocationAccessStatus status) async {
    if (!mounted) {
      return;
    }

    final action = await showDialog<_LocationPermissionAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _LocationPermissionDialog(status: status);
      },
    );

    if (!mounted ||
        action == null ||
        action == _LocationPermissionAction.later) {
      return;
    }

    final locationService = ref.read(currentLocationServiceProvider);
    switch (action) {
      case _LocationPermissionAction.openLocationSettings:
        await locationService.openLocationSettings();
      case _LocationPermissionAction.openAppSettings:
        await locationService.openAppSettings();
      case _LocationPermissionAction.later:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class _LocationPermissionDialog extends StatelessWidget {
  const _LocationPermissionDialog({required this.status});

  final LocationAccessStatus status;

  @override
  Widget build(BuildContext context) {
    final config = _LocationPermissionDialogConfig.forStatus(status);

    return AlertDialog(
      title: Text(config.title),
      content: Text(config.message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_LocationPermissionAction.later);
          },
          child: const Text('稍後'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(config.primaryAction);
          },
          child: Text(config.primaryLabel),
        ),
      ],
    );
  }
}

class _LocationPermissionDialogConfig {
  const _LocationPermissionDialogConfig({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.primaryAction,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final _LocationPermissionAction primaryAction;

  factory _LocationPermissionDialogConfig.forStatus(
    LocationAccessStatus status,
  ) {
    return switch (status) {
      LocationAccessStatus.ready => const _LocationPermissionDialogConfig(
        title: '定位已啟用',
        message: 'Carbon Trip 可以記錄旅程位置。',
        primaryLabel: '完成',
        primaryAction: _LocationPermissionAction.later,
      ),
      LocationAccessStatus.serviceDisabled =>
        const _LocationPermissionDialogConfig(
          title: '開啟定位服務',
          message: 'Carbon Trip 需要定位服務來記錄通勤路線與目前位置。請先開啟裝置定位。',
          primaryLabel: '開啟設定',
          primaryAction: _LocationPermissionAction.openLocationSettings,
        ),
      LocationAccessStatus.denied => const _LocationPermissionDialogConfig(
        title: '允許定位權限',
        message: 'Carbon Trip 需要使用定位權限，才能在旅程中記錄路線並顯示目前位置。',
        primaryLabel: '稍後',
        primaryAction: _LocationPermissionAction.later,
      ),
      LocationAccessStatus.deniedForever =>
        const _LocationPermissionDialogConfig(
          title: '重新允許定位',
          message: '定位權限目前已關閉。請到系統設定中允許 Carbon Trip 使用定位。',
          primaryLabel: '開啟設定',
          primaryAction: _LocationPermissionAction.openAppSettings,
        ),
    };
  }
}

enum _LocationPermissionAction { later, openLocationSettings, openAppSettings }
