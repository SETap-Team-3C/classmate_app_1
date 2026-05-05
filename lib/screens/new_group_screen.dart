import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/theme_provider.dart';

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({Key? key, required this.themeProvider}) : super(key: key);

  final ThemeProvider themeProvider;

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selected = {};
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    final currentUser = _auth.currentUser;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }
    if (currentUser == null) return;

    final members = [_auth.currentUser!.uid, ..._selected.toList()];

    try {
      await _firestore.collection('groups').add({
        'name': name,
        'members': members,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser.uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('New Group')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Add members'),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                final users = docs
                    .where((d) => d.id != currentUser?.uid)
                    .map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return MapEntry(d.id, (data['name'] ?? 'User').toString());
                }).toList();

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final id = users[index].key;
                    final name = users[index].value;
                    final selected = _selected.contains(id);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(name),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _createGroup,
              child: const SizedBox(
                width: double.infinity,
                child: Center(child: Text('Create Group')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
