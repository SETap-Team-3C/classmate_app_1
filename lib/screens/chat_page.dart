import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../core/utils/time_formatter.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final ChatService? chatService;
  final FirebaseAuth? auth;
  final bool showTestEmptyState;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.chatService,
    this.auth,
    this.showTestEmptyState = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  ChatService get _chatService =>
      widget.chatService ?? ChatService(auth: _auth);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploadingAttachment = false;
  double? _uploadProgress;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await _chatService.sendMessage(widget.receiverId, text);
      _messageController.clear();
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'isTyping': false});
      }
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    }
  }

  Future<void> _setTypingStatus(bool isTyping) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'isTyping': isTyping});
    } catch (_) {
      // Ignore typing state failures.
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_isUploadingAttachment) return;

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (pickedImage == null) return;

      final caption = _messageController.text.trim();

      if (mounted) {
        setState(() {
          _isUploadingAttachment = true;
          _uploadProgress = 0;
        });
      }

      await _chatService.sendImageMessage(
        widget.receiverId,
        pickedImage,
        caption: caption,
        onUploadProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      _messageController.clear();
      await _setTypingStatus(false);
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAttachment = false;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<void> _showAttachmentOptions() async {
    if (_isUploadingAttachment) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndSendImage(ImageSource.camera);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.showTestEmptyState ? null : _auth.currentUser;

    if (widget.showTestEmptyState) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.receiverName),
              const SizedBox(height: 2),
              const Text('Direct Message', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        body: const Center(
          child: Text('No messages yet. Start the conversation.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.receiverName)),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.receiverId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    bool isOnline = false;
                    if (snapshot.hasData && snapshot.data != null) {
                      try {
                        isOnline =
                            snapshot.data?.get('isOnline') as bool? ?? false;
                      } catch (e) {
                        isOnline = false;
                      }
                    }
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.receiverId)
                  .snapshots(),
              builder: (context, snapshot) {
                bool isTyping = false;
                if (snapshot.hasData && snapshot.data != null) {
                  try {
                    isTyping = snapshot.data?.get('isTyping') as bool? ?? false;
                  } catch (e) {
                    isTyping = false;
                  }
                }
                return Text(
                  isTyping ? 'typing...' : 'Direct Message',
                  style: TextStyle(
                    fontSize: 12,
                    color: isTyping ? Colors.orange : null,
                    fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isUploadingAttachment)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: LinearProgressIndicator(value: _uploadProgress),
            ),
          Expanded(
            child: currentUser == null
                ? const Center(child: Text('Please sign in to view messages.'))
                : StreamBuilder<List<Message>>(
                    stream: _chatService.getMessages(
                      currentUser.uid,
                      widget.receiverId,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        final err = snapshot.error;
                        // If Firestore permission denied, show a friendly empty state                              isCurrentUser: isCurrentUser,
                              isRead: message.read,
                              readStatusText: readStatusText,
                              isStarred: message.isStarredBy(currentUser.uid),
                              onStarToggle: () async {
                                await _chatService.toggleStar(
                                  message.id,
                                  currentUser.uid,
                                );
                              },
                              onDeleteForMe: () async {
                                await _chatService.deleteMessageForMe(
                                  message.id,
                                  currentUser.uid,
                                );
                              },
                              onDeleteForEveryone: isCurrentUser
                                  ? () async {
                                      await _chatService.deleteMessage(
                                        message.id,
                                      );
                                    }
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _isUploadingAttachment
                        ? null
                        : _showAttachmentOptions,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      onChanged: (value) async {
                        final currentUser = _auth.currentUser;
                        if (currentUser != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser.uid)
                              .update({'isTyping': value.isNotEmpty});
                          if (value.isEmpty) {
                            await Future.delayed(const Duration(seconds: 1));
                            if (_messageController.text.isEmpty && mounted) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid)
                                  .update({'isTyping': false});
                            }
                          }
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isUploadingAttachment
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isUploadingAttachment ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
