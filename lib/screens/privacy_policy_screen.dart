import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Privacy Policy', style: tt.titleLarge)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            'We respect your privacy. This app collects only the information needed to provide its core features, such as user account details (like name, email, and profile information).\n\n'
            'We do not sell or share your personal data with third parties.\n\n'
            'Your data may be used to:\n\n'
            '- Create and manage your account\n'
            '- Enable messaging and communication features\n'
            '- Improve app performance and user experience\n\n'
            'We take reasonable steps to protect your data, but no system is 100% secure.\n\n'
            'By using this app, you agree to this privacy policy.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}
