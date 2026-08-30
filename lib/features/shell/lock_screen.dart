import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/scope.dart';
import '../../widgets/common.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _checking = false;
  String? _error;
  bool _canBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final localAuth = LocalAuthentication();
      final can = await localAuth.canCheckBiometrics;
      final enrolled = await localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _canBiometrics = can && enrolled);
      }
    } catch (_) {
      if (mounted) setState(() => _canBiometrics = false);
    }
  }

  Future<void> _authenticate() async {
    if (_checking) return;
    final state = AppScope.of(context);
    if (!state.biometricsEnabled || !_canBiometrics) {
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final localAuth = LocalAuthentication();
      final ok = await localAuth.authenticate(
        localizedReason: 'Unlock Auvia to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      if (ok) {
        state.unlockSession();
      } else {
        setState(() {
          _checking = false;
          _error = 'Authentication failed. Try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = 'Biometrics unavailable. Unlock from Profile if the problem persists.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final needsBiometrics = state.biometricsEnabled && _canBiometrics;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppColors.aiGradient,
                    borderRadius: BorderRadius.circular(28),
                    ),
                  child: Icon(
                    needsBiometrics
                        ? Icons.fingerprint_rounded
                        : Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 28),
                Text(t(context, 'lockedTitle'), style: AppText.pageTitle.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                Text(
                  needsBiometrics
                      ? t(context, 'verifyIdentity')
                      : t(context, 'appLockedMsg'),
                  textAlign: TextAlign.center,
                  style: AppText.body,
                ),
                const SizedBox(height: 32),
                if (_checking)
                  CircularProgressIndicator(color: AppColors.accent)
                else
                  PrimaryButton(
                    label: needsBiometrics ? t(context, 'authenticate') : t(context, 'unlockA'),
                    icon: needsBiometrics
                        ? Icons.fingerprint_rounded
                        : Icons.lock_open_rounded,
                    onTap: needsBiometrics
                        ? _authenticate
                        : () => AppScope.of(context).unlockSession(),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
