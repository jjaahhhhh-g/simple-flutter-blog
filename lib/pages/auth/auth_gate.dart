import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../blogs/home_screen.dart';
import 'login_screen.dart';
import '../profile/profile_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session == null) {
          return const LoginScreen();
        }

        final userMetadata = session.user.userMetadata;
        final bool hasProfile = userMetadata?['has_profile'] ?? false;

        if (!hasProfile) {
          return const ProfileScreen(isSetupMode: true);
        }

        return const HomeScreen();
      },
    );
  }
}