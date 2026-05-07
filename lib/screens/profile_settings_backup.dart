import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  late User? _user;
  final UserService _userService = UserService();
  bool _isLoadingProfilePicture = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _user?.photoURL != null
                          ? NetworkImage(_user!.photoURL!)
                          : null,
                      child: _user?.photoURL == null
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
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
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile settings feature')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Account Settings'),
                ),
              ),
            ],
          ),
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

      setState(() {
        _isLoadingProfilePicture = true;
      });

      debugPrint('📤 Uploading to Firebase Storage...');
      final downloadUrl = await _userService.uploadProfilePicture(pickedFile);

      if (downloadUrl != null) {
        debugPrint('✅ Upload successful: $downloadUrl');
        await _user?.reload();
        if (mounted) {
          setState(() {
            _isLoadingProfilePicture = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
            ),
          );
        }
      } else {
        debugPrint('❌ Upload failed - returned null');
        if (mounted) {
          setState(() {
            _isLoadingProfilePicture = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload profile picture')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfilePicture = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
