import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'neon_sync_service.dart';
import 'services/biometric_service.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  bool _isChecking = true;
  bool _showLockedState = false;
  Map<String, String?> _profile = {};

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    try {
      final hasSession = await BiometricService.hasActiveSession();
      if (!hasSession) {
        _goToLogin();
        return;
      }

      final profile = await BiometricService.getStoredUserProfile();
      final token = profile['token'];
      final email = profile['email'];

      if (token == null || email == null) {
        _goToLogin();
        return;
      }

      _profile = profile;

      // Check device biometrics / PIN availability
      final isAvailable = await BiometricService.isDeviceSecurityAvailable();
      if (isAvailable) {
        _promptBiometricUnlock();
      } else {
        // No lockscreen setup or unsupported; directly enter or fallback to login
        _unlockVault();
      }
    } catch (e) {
      debugPrint('AuthGate error: $e');
      _goToLogin();
    }
  }

  Future<void> _promptBiometricUnlock() async {
    setState(() {
      _isChecking = false;
      _showLockedState = false;
    });

    final authenticated = await BiometricService.authenticateWithDeviceSecurity(
      reason: 'Unlock PassKeep with your Fingerprint, Face, or PIN',
    );

    if (authenticated) {
      _unlockVault();
    } else {
      if (!mounted) return;
      setState(() {
        _showLockedState = true;
      });
    }
  }

  void _unlockVault() {
    final token = _profile['token'];
    if (token != null) {
      NeonSyncService.setSessionToken(token);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          userName: _profile['name'] ?? 'Vault User',
          userEmail: _profile['email'] ?? '',
          userId: _profile['userId'],
        ),
      ),
    );
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: AppColors.oatMilkBg,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMatcha),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_showLockedState) {
      return Scaffold(
        backgroundColor: AppColors.oatMilkBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.primaryMatcha.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.lock,
                      size: 36,
                      color: AppColors.primaryMatcha,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PassKeep is Locked',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _profile['email'] ?? 'Vault is secured',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMatcha,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _promptBiometricUnlock,
                      icon: const Icon(LucideIcons.fingerprint, size: 20),
                      label: const Text(
                        'Unlock with Fingerprint / PIN',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _goToLogin,
                    child: const Text(
                      'Switch Account or Re-login',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const Scaffold(backgroundColor: AppColors.oatMilkBg);
  }
}

