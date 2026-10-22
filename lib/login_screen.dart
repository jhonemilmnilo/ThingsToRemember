import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'theme.dart';
import 'home_screen.dart';
import 'neon_sync_service.dart';

import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // 🚀 Force fresh account selection every time (No-Cache)
      await _googleSignIn.signOut();

      // Native Android Google Account Picker
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (account != null) {
        // 🐘 Direct Neon Postgres Database Sync via Cloudflare Worker
        final syncedUser = await NeonSyncService.syncUser(
          email: account.email,
          name: account.displayName,
          provider: 'google',
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: account.displayName ?? 'Jhon Emil',
              userEmail: account.email,
              userId: syncedUser?['id'],
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.alertPersimmon,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sign in error: $error',
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oatMilkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // 🍵 Branding Container (Matcha Padlock with Pistachio & Sage borders)
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.pistachioMint, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryMatcha.withValues(alpha: 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title & Subtitle with high-contrast forest text
              const Text(
                'PassKeep',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.pistachioMint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Your serene, high-security space',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.primaryMatcha,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Safeguard life\'s passwords, accounts & sensitive secrets.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const Spacer(flex: 3),

              // 🚀 Google-Only 1-Tap Login Card (Pill shape with Sage Matcha border & Deep Matcha accents)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardSurface,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.sageMatcha, width: 1.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(29),
                    ),
                    elevation: 2,
                    shadowColor: AppColors.primaryMatcha.withValues(alpha: 0.15),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryMatcha,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Clean Google 'G' Mark
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.pistachioMint.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF4285F4),
                                    fontFamily: 'sans-serif',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 26),

              // Trust & Security Badge (Pistachio Pill Container)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.pistachioMint.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderMuted, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      size: 16,
                      color: AppColors.primaryMatcha,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Protected by End-to-End Encryption',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryMatcha.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
