import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme.dart';
import '../neon_sync_service.dart';

class MasterPasswordModal extends StatefulWidget {
  final String email;
  final String userName;
  final String? userId;
  final bool isSetupMode; // true = setting up initial password, false = verifying existing
  final VoidCallback onAuthenticated;

  const MasterPasswordModal({
    super.key,
    required this.email,
    required this.userName,
    this.userId,
    required this.isSetupMode,
    required this.onAuthenticated,
  });

  @override
  State<MasterPasswordModal> createState() => _MasterPasswordModalState();
}

class _MasterPasswordModalState extends State<MasterPasswordModal> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  bool _isLocked = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_isLocked) return;

    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }

    if (password.length < 4) {
      setState(() => _errorMessage = 'Password must be at least 4 characters');
      return;
    }

    if (widget.isSetupMode) {
      final confirm = _confirmController.text.trim();
      if (password != confirm) {
        setState(() => _errorMessage = 'Passwords do not match');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    if (widget.isSetupMode) {
      // Register Master Password
      final success = await NeonSyncService.setMasterPassword(
        email: widget.email,
        password: password,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        Navigator.of(context).pop();
        widget.onAuthenticated();
      } else {
        setState(() => _errorMessage = 'Failed to setup password. Please try again.');
      }
    } else {
      // Verify Master Password with Lockout Protection
      final result = await NeonSyncService.verifyMasterPassword(
        email: widget.email,
        password: password,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result['verified'] == true) {
        Navigator.of(context).pop();
        widget.onAuthenticated();
      } else {
        setState(() {
          _isLocked = result['locked'] == true;
          _errorMessage = result['error'] ?? 'Incorrect password. Access denied.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenHeight * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.pistachioMint, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryMatcha.withValues(alpha: 0.16),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Title (Clean without top icon)
                Text(
                  widget.isSetupMode ? 'Create Password' : 'Enter Password',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  widget.isSetupMode
                      ? 'Set a security password or PIN to protect your accounts and credentials.'
                      : 'Please enter your password to proceed for ${widget.email}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),

                // Error Message Banner (if any)
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.alertPersimmon.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.alertPersimmon.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.alertPersimmon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.alertPersimmon,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Input: Password
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.oatMilkBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderMuted),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLocked,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _isLocked ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.isSetupMode ? 'Create Password / PIN' : 'Enter Password',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) {
                      if (!widget.isSetupMode) _handleSubmit();
                    },
                  ),
                ),

                // Confirm Password Field (Only for Setup Mode)
                if (widget.isSetupMode) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.oatMilkBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderMuted),
                    ),
                    child: TextField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      enabled: !_isLocked,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Submit Button -> Clean "Save"
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || _isLocked) ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLocked ? AppColors.borderMuted : AppColors.primaryMatcha,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),

                // Cancel Button
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel & Sign Out',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
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
}
