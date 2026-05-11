import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/hashtag_service.dart';
import '../core/localization/app_localizations.dart';

class PostCreationWidget extends StatefulWidget {
  const PostCreationWidget({
    super.key,
    required this.feedType,
    this.auth,
    this.firestore,
    this.storage,
  });

  final String feedType;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final FirebaseStorage? storage;

  @override
  State<PostCreationWidget> createState() => _PostCreationWidgetState();
}

class _PostCreationWidgetState extends State<PostCreationWidget> {
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final HashtagService _hashtagService = HashtagService();
  bool _isPosting = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => widget.storage ?? FirebaseStorage.instance;

  String get _collectionName => 'posts_${widget.feedType}';

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1800,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  Future<String> _uploadPostImage(XFile image, String userId) async {
    final bytes = await image.readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final ref = _storage.ref().child('post_images/$userId/$fileName');
    final metadata = SettableMetadata(
      contentType: image.mimeType ?? 'image/jpeg',
    );
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  Future<void> _createPost() async {
    final user = _auth.currentUser;
    final text = _postController.text.trim();

    if (user == null) return;
    if (text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add text or a photo before posting.')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      String imageUrl = '';
      if (_selectedImage != null) {
        imageUrl = await _uploadPostImage(_selectedImage!, user.uid);
      }

      // Extract hashtags from post text
      final hashtags = HashtagService.extractHashtags(text);

      final postRef = await _firestore.collection(_collectionName).add({
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'User',
        'userPhotoUrl': user.photoURL ?? '',
        'text': text,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'commentCount': 0,
        'isPinned': false,
        'pinnedAt': null,
        'hashtags': hashtags.toList(),
      });

      // Record hashtags for trending/search
      if (hashtags.isNotEmpty) {
        await _hashtagService.recordHashtags(
          postRef.id,
          widget.feedType,
          hashtags,
        );
      }

      setState(() {
        _postController.clear();
        _selectedImage = null;
        _selectedImageBytes = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post created.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _postController,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: loc.t('what_is_on_your_mind'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedImageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                _selectedImageBytes!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _isPosting ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Photo'),
              ),
              const SizedBox(width: 8),
              if (_selectedImage != null)
                TextButton(
                  onPressed: _isPosting
                      ? null
                      : () => setState(() {
                          _selectedImage = null;
                          _selectedImageBytes = null;
                        }),
                  child: const Text('Remove'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _isPosting ? null : _createPost,
                child: _isPosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
