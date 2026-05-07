import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';

class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(title: Text(loc.t('communities'))),
      body: Center(child: Text(loc.t('communities_placeholder'))),
=======
      appBar: AppBar(title: const Text('Communities')),
      body: const Center(child: Text('Communities placeholder')),
>>>>>>> 14385910f59a87a61a685f73ad29ced2e0acaa28
    );
  }
}
