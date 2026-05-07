import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';

class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('communities'))),
      body: Center(child: Text(loc.t('communities_placeholder'))),
    );
  }
}
