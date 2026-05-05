import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Terms of Service', style: tt.titleLarge)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'Terms & Conditions\n\n'
            'By using this app, you agree to the following:\n\n'
            '- You will use the app in a lawful and respectful manner\n'
            '- You will not misuse, hack, or disrupt the service\n'
            '- You are responsible for the content you share\n'
            '- We may update or modify the app at any time\n'
            '- We are not responsible for any data loss or misuse caused by user actions\n\n'
            'We reserve the right to suspend accounts that violate these terms.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}
