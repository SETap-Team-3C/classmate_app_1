import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import 'call_screen.dart';

class CallContactsScreen extends StatelessWidget {
  const CallContactsScreen({super.key});

  String _readStringField(
    Map<String, dynamic>? data,
    String key, [
    String fallback = '',
  ]) {
    final value = data?[key];
    return value == null ? fallback : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final currentUserId = auth.currentUser?.uid;
    final loc = AppLocalizations.of(context);

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('select_contact_to_call'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(loc.t('no_users_available')));
          }

          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUserId)
              .toList();

          if (users.isEmpty) {
            return Center(child: Text(loc.t('no_users_to_call')));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>?;
              final userName = _readStringField(data, 'name', loc.t('unknown_user'));
              final userEmail = _readStringField(data, 'email');
              final userPhone = _readStringField(data, 'phone');

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: CircleAvatar(
                  child: Text(userName.isNotEmpty ? userName[0] : '?'),
                ),
                title: Text(userName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (userEmail.isNotEmpty) Text(userEmail),
                    const SizedBox(height: 2),
                    Text(
                      userPhone.isNotEmpty ? userPhone : loc.t('no_phone_number_added'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.phone,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Call $userName',
                  onPressed: userPhone.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<CallScreen>(
                              builder: (context) => CallScreen(
                                userName: userName,
                                userPhone: userPhone,
                              ),
                            ),
                          );
                        },
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<CallScreen>(
                      builder: (context) => CallScreen(
                        userName: userName,
                        userPhone: userPhone.isEmpty ? null : userPhone,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
