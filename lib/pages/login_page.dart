import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/browser_url_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final auth = AuthService();
  Future<Map<String, dynamic>>? exchange;

  @override
  void initState() {
    super.initState();
    final code = Uri.base.queryParameters['code'];
    final state = Uri.base.queryParameters['state'];
    if (code != null && state != null) {
      final redirect = Uri.parse(auth.redirectUri);
      exchange = auth.exchangeCode(code, redirect, codeVerifier: state);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = exchange;
    return AppScaffold(
      body: SizedBox(
        height: 420,
        child: Center(
          child: result != null
              ? FutureBuilder<Map<String, dynamic>>(
                  future: result,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) return const CircularProgressIndicator();
                    if (snapshot.hasError) return const Text('Unable to sign in. Please try again.');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        clearAuthCallbackUrl();
                        Navigator.pushReplacementNamed(
                          context,
                          AuthService.isQueen ? '/queen' : '/customer',
                        );
                      }
                    });
                    return const Text('You are signed in to the hive.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
                  },
                )
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Join the hive', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  const Text('Sign in securely with FrenzyBees.'),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Sign in',
                    onPressed: () async {
                      try {
                        final redirect = Uri.parse(auth.redirectUri);
                        await launchUrl(auth.getLoginUri(redirect), webOnlyWindowName: '_self');
                      } on StateError catch (error) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
                      }
                    },
                  ),
                ]),
        ),
      ),
    );
  }
}
