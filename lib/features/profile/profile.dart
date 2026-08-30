import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/scope.dart';
import '../../widgets/ai_settings.dart';
import '../../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateRefresher(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                TopBar(title: t(context, 'profile'), showProfile: false),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _editProfile(context),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: state.avatarPath == null
                                  ? AppColors.aiGradient
                                  : null,
                              color: state.avatarPath == null
                                  ? null
                                  : AppColors.surfaceAlt,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.border, width: 2),
                              ),
                            child: ClipOval(
                              child: state.avatarPath != null
                                  ? Image.file(
                                      File(state.avatarPath!),
                                      cacheWidth: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _initial(state),
                                    )
                                  : _initial(state),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                gradient: AppColors.fabGradient,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.bg, width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(state.userName, style: AppText.sectionHeading),
                    ],
                  ),
                ),

                                _section(context, 'preferences'),
                _row(context, Icons.palette_outlined, t(context, 'appearance'),
                    () => _appearance(context)),
                _row(context, Icons.language_rounded, t(context, 'language'),
                    () => _language(context)),
                _row(context, Icons.key_rounded, t(context, 'aiConnectionL'),
                    () => showAiSettingsSheet(context)),

                _section(context, 'security'),
                _toggleRow(context, Icons.lock_outline_rounded,
                    t(context, 'appLock'), state.appLockEnabled, (v) async {
                  await state.setAppLock(v);
                  if (v) state.lockNow();
                }),
                _toggleRow(
                    context,
                    Icons.fingerprint_rounded,
                    t(context, 'biometrics'),
                    state.biometricsEnabled,
                    (v) => _toggleBiometrics(context, state, v)),

                const SizedBox(height: 24),
                Center(
                  child: Text('Auvia · v1.2.0',
                      style: AppText.caption
                          .copyWith(color: AppColors.textFaint)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _initial(AppState state) {
    return Center(
      child: Text(
        state.userName.isEmpty ? 'A' : state.userName[0].toUpperCase(),
        style: AppText.pageTitle.copyWith(fontSize: 32, color: Colors.white),
      ),
    );
  }

  Future<void> _toggleBiometrics(
      BuildContext context, AppState state, bool want) async {
    if (!want) {
      await state.setBiometrics(false);
      return;
    }
    try {
      final localAuth = LocalAuthentication();
      final ok = await localAuth.authenticate(
        localizedReason: 'Verify your biometrics to enable App Lock',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (ok) {
        await state.setBiometrics(true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${t(context, 'biometrics')} ✓')));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(t(context, 'verifyIdentity'))));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t(context, 'verifyIdentity'))));
      }
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    final state = AppScope.of(context);
    final nameCtrl = TextEditingController(text: state.userName);
    String? newAvatar = state.avatarPath;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t(context, 'editProfile'), style: AppText.sectionHeading),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    try {
                      final x = await ImagePicker()
                          .pickImage(source: ImageSource.gallery);
                      if (x != null) setSheet(() => newAvatar = x.path);
                    } catch (_) {}
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: newAvatar == null
                              ? AppColors.aiGradient
                              : null,
                          color:
                              newAvatar == null ? null : AppColors.surfaceAlt,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.border, width: 2),
                        ),
                        child: ClipOval(
                          child: newAvatar != null
                              ? Image.file(File(newAvatar!),
                                  cacheWidth: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.person_rounded,
                                          color: Colors.white, size: 34))
                              : const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 34),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.surface, width: 2),
                          ),
                          child: Icon(Icons.photo_camera_rounded,
                              color: AppColors.textPrimary, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(t(context, 'changePhoto'),
                    style: AppText.caption.copyWith(fontSize: 11.5)),
              ),
              const SizedBox(height: 18),
              Text(t(context, 'nameL'), style: AppText.label),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                style: AppText.bodyStrong,
                decoration: const InputDecoration(hintText: 'Your name'),
              ),
              const SizedBox(height: 14),
              const SizedBox(height: 20),
              PrimaryButton(
                label: t(context, 'saveProfile'),
                icon: Icons.check_rounded,
                onTap: () {
                  state.updateProfile(
                    name: nameCtrl.text,
                    avatar: newAvatar ?? '',
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(t(context, 'profileUpdated'))));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _appearance(BuildContext context) {
    final state = AppScope.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t(context, 'appearance'), style: AppText.sectionHeading),
              const SizedBox(height: 10),
              ...palettes.keys.map((key) {
                final p = palettes[key]!;
                final selected = state.themeKey == key;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 42,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: p.bg,
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(7)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: p.accent,
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(7)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Text(themeNames[key] ?? key,
                      style: AppText.bodyStrong),
                  trailing: selected
                      ? Icon(Icons.check_rounded, color: AppColors.accentSoft)
                      : null,
                  onTap: () {
                    state.setTheme(key);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _language(BuildContext context) {
    final state = AppScope.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t(context, 'language'), style: AppText.sectionHeading),
              const SizedBox(height: 6),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: languageNames.keys.map((code) {
                    final selected = state.langCode == code;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Text(
                        code.toUpperCase(),
                        style: AppText.label.copyWith(
                            color: selected
                                ? AppColors.accentSoft
                                : AppColors.textFaint),
                      ),
                      title: Text(languageNames[code]!,
                          style: AppText.bodyStrong),
                      trailing: selected
                          ? Icon(Icons.check_rounded,
                              color: AppColors.accentSoft)
                          : null,
                      onTap: () {
                        state.setLang(code);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String key) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t(context, key).toUpperCase(),
              style: AppText.label.copyWith(
                  fontSize: 11.5,
                  letterSpacing: 1.2,
                  color: AppColors.textFaint)),
          const SizedBox(height: 4),
          Container(height: 1, color: AppColors.borderSoft),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label,
      VoidCallback onTap) {
    return _rowBase(
      icon: icon,
      label: label,
      onTap: onTap,
      trailing:
          Icon(Icons.chevron_right_rounded, color: AppColors.textFaint),
    );
  }

  Widget _toggleRow(BuildContext context, IconData icon, String label,
      bool value, ValueChanged<bool>? onChanged) {
    return _rowBase(
      icon: icon,
      label: label,
      onTap: onChanged == null
          ? null
          : () {
              onChanged(!value);
            },
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accentSoft,
      ),
    );
  }

  Widget _rowBase({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentSoft, size: 22),
      title: Text(label, style: AppText.cardTitle),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

}
