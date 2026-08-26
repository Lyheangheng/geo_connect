import 'package:flutter/material.dart';
import 'package:geo_connect/core/theme/app_theme.dart';
import 'package:geo_connect/providers/auth_provider.dart';
import 'package:geo_connect/widgets/custom_button.dart';
import 'package:geo_connect/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? email;

  const OtpVerificationScreen({super.key, this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final otp = _otpController.text.trim();

      final success = await authProvider.verifyOtp(otp);

      if (success && mounted) {
        // Return to root route where AuthWrapperScreen presents MainShellScreen (Dashboard)
        Navigator.popUntil(context, (route) => route.isFirst);
      } else if (!success && mounted) {
        final error = authProvider.errorMessage ?? 'OTP verification failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleResendOtp() async {
    setState(() {
      _isResending = true;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resendOtp();

    if (!mounted) return;
    setState(() {
      _isResending = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new OTP has been sent to your email.'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final error = authProvider.errorMessage ?? 'Failed to resend OTP. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final targetEmail = widget.email ?? authProvider.pendingEmail ?? 'your email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    size: 38,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Enter Verification Code',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a 6-digit OTP code to\n$targetEmail',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.subtextColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                CustomTextField(
                  controller: _otpController,
                  hintText: '6-Digit OTP Code',
                  prefixIcon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().length != 6) {
                      return 'Please enter a valid 6-digit OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: 'Verify Email & Continue',
                  isLoading: authProvider.isLoading,
                  icon: Icons.check_circle_outline,
                  onPressed: _handleVerify,
                ),
                const SizedBox(height: 20),

                TextButton.icon(
                  onPressed: _isResending ? null : _handleResendOtp,
                  icon: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryAccent,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(
                    _isResending ? 'Resending OTP...' : 'Resend OTP Code',
                    style: const TextStyle(color: AppTheme.primaryAccent),
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
