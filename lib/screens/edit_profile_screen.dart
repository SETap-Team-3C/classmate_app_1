import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _loading = false;

  User? get _user => FirebaseAuth.instance.currentUser;
  FirebaseFirestore get _fs => FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _user;
    if (user == null) return;

    _emailController.text = user.email ?? '';

    try {
      final doc = await _fs.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        _nameController.text = (data['name'] ?? '').toString();
        _phoneController.text = (data['phone'] ?? '').toString();
      }
    } catch (_) {
      // ignore load errors — user can still edit email
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _user;
    if (user == null) return;

    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();
    final newEmail = _emailController.text.trim();

    setState(() => _loading = true);

    try {
      // Update Firestore profile fields
      await _fs.collection('users').doc(user.uid).set({
        'name': newName,
        'phone': newPhone,
      }, SetOptions(merge: true));

      // Update auth email if changed
      if (newEmail.isNotEmpty && newEmail != (user.email ?? '')) {
        // The current firebase_auth version in this project does not expose
        // a compatible `updateEmail` method for the `User` type on all
        // platforms. Instead of calling the unavailable API (which caused
        // compile errors), save the requested email to Firestore as
        // `pendingEmail` and instruct the user to re-authenticate and
        // perform the email change from account settings or re-login.
        await _fs.collection('users').doc(user.uid).set({
          'pendingEmail': newEmail,
        }, SetOptions(merge: true));

        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email change requested'),
            content: const Text(
                'We saved your requested email. To complete an email change you may need to re-authenticate (sign out and sign in) or perform the change from your account settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  int _bottomIndex = 3; // default selected 'Chats'

  Widget _buildBottomNavItem({required IconData icon, required String label, required int index, int badgeCount = 0}) {
    final selected = _bottomIndex == index;
    final color = selected ? Theme.of(context).colorScheme.primary : Colors.grey[600];

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _bottomIndex = index);
          // Optionally navigate when tapped. For now just update selection.
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : badgeCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone number'),
                keyboardType: TextInputType.phone,
                validator: (v) => null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter an email';
                  final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
                  if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        height: 64,
        child: Row(
          children: [
            _buildBottomNavItem(icon: Icons.update, label: 'Updates', index: 0),
            _buildBottomNavItem(icon: Icons.call, label: 'Calls', index: 1),
            _buildBottomNavItem(icon: Icons.group, label: 'Communities', index: 2),
            _buildBottomNavItem(icon: Icons.chat_bubble, label: 'Chats', index: 3, badgeCount: 5),
            _buildBottomNavItem(icon: Icons.person, label: 'You', index: 4),
          ],
        ),
      ),
    );
  }
}
