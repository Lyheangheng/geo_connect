import 'package:flutter/material.dart';
import 'package:geo_connect/core/theme/app_theme.dart';
import 'package:geo_connect/providers/auth_provider.dart';
import 'package:geo_connect/screens/login_screen.dart';
import 'package:geo_connect/screens/main_shell_screen.dart';
import 'package:geo_connect/screens/otp_verification_screen.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GeoConnectApp());
}

class GeoConnectApp extends StatelessWidget {
  const GeoConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'GeoConnect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapperScreen(),
      ),
    );
  }
}

class AuthWrapperScreen extends StatefulWidget {
  const AuthWrapperScreen({super.key});

  @override
  State<AuthWrapperScreen> createState() => _AuthWrapperScreenState();
}

class _AuthWrapperScreenState extends State<AuthWrapperScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    switch (authProvider.status) {
      case AuthStatus.authenticated:
        return const MainShellScreen();
      case AuthStatus.otpPending:
        return const OtpVerificationScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
