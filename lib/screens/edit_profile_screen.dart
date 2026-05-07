import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../core/language_provider.dart';
import '../services/user_service.dart';
import '../core/localization/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  bool _loading = false;
  bool _isLoadingProfilePicture = false;
  final UserService _userService = UserService();
  String? _profilePictureUrl;
  Uint8List? _profilePictureBytes;

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
    _usernameController.text = user.displayName ?? '';
    _profilePictureUrl = user.photoURL;
    _profilePictureBytes = null;

    try {
      final doc = await _fs.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        _nameController.text = (data['name'] ?? '').toString();
        _phoneController.text = (data['phone'] ?? '').toString();
        _bioController.text = (data['bio'] ?? '').toString();
        _usernameController.text = (data['username'] ?? user.displayName ?? '')
            .toString();
        _profilePictureUrl = (data['profilePictureUrl'] ?? user.photoURL)
            ?.toString();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // ignore load errors — user can still edit email
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _user;
    if (user == null) return;

    final loc = AppLocalizations.of(context);

    final newName = _nameController.text.trim();
    final newUsername = _usernameController.text.trim();
    final newPhone = _phoneController.text.trim();
    final newBio = _bioController.text.trim();
    final newEmail = _emailController.text.trim();

    setState(() => _loading = true);

    try {
      // Update display name in Firebase Auth
      if (newUsername != (user.displayName ?? '')) {
        await user.updateDisplayName(newUsername);
      }

      // Update Firestore profile fields
      await _fs.collection('users').doc(user.uid).set({
        'name': newName,
        'username': newUsername,
        'phone': newPhone,
        'bio': newBio,
        'updatedAt': FieldValue.serverTimestamp(),
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
            title: Text(loc.t('email_change_requested')),
            content: Text(loc.t('email_change_info')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.t('ok')),
              ),
            ],
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.t('profile_updated'))));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.t('failed_save_profile', params: {'error': e.toString()}),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setLanguage(String language) async {
    final languageProvider = LanguageInherited.of(context);
    await languageProvider.setLocaleByLanguageName(language);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          ).t('selected_language_changed', params: {'language': language}),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadProfilePicture() async {
    try {
      debugPrint('📸 Starting image picker...');
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (pickedFile == null) {
        debugPrint('❌ No image selected');
        return;
      }

      debugPrint('✅ Image selected: ${pickedFile.name}');

      final previewBytes = await pickedFile.readAsBytes();

      if (mounted) {
        setState(() {
          _profilePictureBytes = previewBytes;
        });
      }

      setState(() {
        _isLoadingProfilePicture = true;
      });

      debugPrint('📤 Uploading to Firebase Storage...');
      final downloadUrl = await _userService.uploadProfilePicture(pickedFile);

      if (downloadUrl != null) {
        debugPrint('✅ Upload successful: $downloadUrl');
        if (mounted) {
          setState(() {
            _profilePictureUrl = downloadUrl;
            _profilePictureBytes = null;
            _isLoadingProfilePicture = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).t('profile_picture_updated'),
              ),
            ),
          );
        }
      } else {
        debugPrint('❌ Upload failed - returned null');
        if (mounted) {
          setState(() {
            _profilePictureBytes = null;
            _isLoadingProfilePicture = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).t('failed_upload_profile_picture'),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) {
        setState(() {
          _profilePictureBytes = null;
          _isLoadingProfilePicture = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).t('error', params: {'error': e.toString()}),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final user = _user;
    if (user == null) return;
    final loc = AppLocalizations.of(context);

    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    if (!hasPasswordProvider) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('password_change_only_email_accounts'))),
      );
      return;
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.t('no_account_email_found'))));
      return;
    }

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    try {
      var isSubmitting = false;

      await showDialog<void>(
        context: context,
        barrierDismissible: !isSubmitting,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(loc.t('change_password')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: loc.t('current_password'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: loc.t('new_password'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: loc.t('confirm_new_password'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(loc.t('cancel')),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final currentPassword = currentPasswordController.text
                              .trim();
                          final newPassword = newPasswordController.text.trim();
                          final confirmPassword = confirmPasswordController.text
                              .trim();

                          if (currentPassword.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc.t('please_enter_current_password'),
                                ),
                              ),
                            );
                            return;
                          }

                          if (newPassword.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.t('new_password_min_6')),
                              ),
                            );
                            return;
                          }

                          if (newPassword != confirmPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.t('new_password_mismatch')),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            final credential = EmailAuthProvider.credential(
                              email: email,
                              password: currentPassword,
                            );

                            await user.reauthenticateWithCredential(credential);
                            await user.updatePassword(newPassword);

                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc.t('password_updated_successfully'),
                                ),
                              ),
                            );
                            Navigator.of(dialogContext).pop();
                          } on FirebaseAuthException catch (e) {
                            if (!dialogContext.mounted) return;

                            var message = loc.t('password_update_failed');
                            if (e.code == 'wrong-password' ||
                                e.code == 'invalid-credential') {
                              message = loc.t('current_password_incorrect');
                            } else if (e.code == 'weak-password') {
                              message = loc.t('choose_stronger_password');
                            } else if (e.code == 'requires-recent-login') {
                              message = loc.t('login_again_change_password');
                            }

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(SnackBar(content: Text(message)));
                          } catch (_) {
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(loc.t('password_update_failed')),
                              ),
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(loc.t('update_password')),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  int _bottomIndex = 3; // default selected 'Chats'
  static const List<String> _languages = <String>[
    'English',
    'Spanish',
    'Chinese (Mandarin)',
    'Hindi',
    'French',
  ];

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
    int badgeCount = 0,
  }) {
    final selected = _bottomIndex == index;
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurface.withValues(alpha: 0.6);

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
                          color: cs.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.onSecondary, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : badgeCount.toString(),
                            style: TextStyle(
                              color: cs.onSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
    final loc = AppLocalizations.of(context);
    final currentLanguage = LanguageInherited.of(context).codeToLanguageName();
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('edit_profile'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Picture
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profilePictureBytes != null
                            ? MemoryImage(_profilePictureBytes!)
                            : _profilePictureUrl != null
                            ? NetworkImage(_profilePictureUrl!)
                            : null,
                        child:
                            _profilePictureBytes == null &&
                                _profilePictureUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[600],
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isLoadingProfilePicture
                              ? null
                              : _pickAndUploadProfilePicture,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _isLoadingProfilePicture
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language),
                  title: Text(loc.t('language')),
                  subtitle: Text(currentLanguage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final selected = await showDialog<String>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(loc.t('select_language')),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView(
                            shrinkWrap: true,
                            children: _languages
                                .map(
                                  (language) => ListTile(
                                    leading: Icon(
                                      currentLanguage == language
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                    ),
                                    title: Text(language),
                                    onTap: () => Navigator.of(
                                      dialogContext,
                                    ).pop(language),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text(loc.t('cancel')),
                          ),
                        ],
                      ),
                    );

                    if (selected == null) return;
                    await _setLanguage(selected);
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: loc.t('full_name')),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? loc.t('please_enter_name')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: loc.t('username')),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return loc.t('please_enter_username');
                    }
                    if (v.trim().length < 3) {
                      return loc.t('username_min_3');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: loc.t('phone')),
                  keyboardType: TextInputType.phone,
                  validator: (v) => null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: loc.t('email')),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return loc.t('please_enter_email');
                    }
                    final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
                    if (!emailRegex.hasMatch(v)) {
                      return loc.t('enter_valid_email');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: loc.t('bio'),
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 200,
                  validator: (value) {
                    if (value != null && value.length > 200) {
                      return loc.t('bio_too_long');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showChangePasswordDialog,
                  icon: const Icon(Icons.lock_outline),
                  label: Text(loc.t('change_password')),
                ),
                const SizedBox(height: 20),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _save,
                        child: Text(loc.t('save')),
                      ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        height: 64,
        child: Row(
          children: [
            _buildBottomNavItem(
              icon: Icons.update,
              label: loc.t('updates'),
              index: 0,
            ),
            _buildBottomNavItem(
              icon: Icons.call,
              label: loc.t('calls'),
              index: 1,
            ),
            _buildBottomNavItem(
              icon: Icons.group,
              label: loc.t('communities'),
              index: 2,
            ),
            _buildBottomNavItem(
              icon: Icons.chat_bubble,
              label: loc.t('chats'),
              index: 3,
              badgeCount: 5,
            ),
            _buildBottomNavItem(
              icon: Icons.person,
              label: loc.t('you'),
              index: 4,
            ),
          ],
        ),
      ),
    );
  }
}
