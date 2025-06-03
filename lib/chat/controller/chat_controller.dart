import 'dart:io';
import 'package:digitalhealthcareplatform/chat/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/user_model.dart';
import 'package:path/path.dart' as path_lib;
import '../services/notification_service.dart';

class ChatController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RxList<UserModel> users = <UserModel>[].obs;
  final TextEditingController messageController = TextEditingController();
  final RxBool isSending = false.obs;
  final RxString receiverName = 'Loading...'.obs;
  final RxString senderId = ''.obs;
  final RxString receiverId = ''.obs;
  final ImagePicker _imagePicker = ImagePicker();
  late final NotificationService _notificationService;

  @override
  void onInit() {
    super.onInit();
    _notificationService = Get.put(NotificationService());
    _initialize();
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }

  Future<void> _initialize() async {
    try {
      // First verify that auth is working
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        senderId.value = currentUser.id;
      } else {
        debugPrint('No authenticated user found');
        return;
      }

      // Initialize notification service
      await _notificationService.init();

      // Then verify storage
      await _verifyStorageBucket();

      // Finally fetch users
      await fetchUsers();

      // Store player ID for notifications with delay to ensure OneSignal is ready
      await Future.delayed(const Duration(seconds: 2));
      await _notificationService.storePlayerId(currentUser.id);
    } catch (e) {
      debugPrint('ChatController initialization error: $e');
    }
  }

  Future<void> _verifyStorageBucket() async {
    try {
      // Use consistent bucket name
      const String bucketName = 'chat_images';
      await _supabase.storage.from(bucketName).list();
      debugPrint('Storage bucket verified');
    } catch (e) {
      debugPrint('Storage bucket error: $e');
      _showSafeSnackbar('Chat storage not ready. Please try again later.');
    }
  }

  Future<void> fetchUsers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null || currentUserId.isEmpty) {
        debugPrint('Cannot fetch users: No current user ID');
        return;
      }

      final response = await _supabase
          .from('users')
          .select()
          .neq('id', currentUserId);

      if (response is List) {
        users.value = response
            .map((user) => UserModel.fromJson(user))
            .toList();
        debugPrint('Fetched ${users.length} users');
      } else {
        debugPrint('Unexpected response format from users query');
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      _showSafeSnackbar('Failed to load users');
    }
  }

  Future<void> sendMessage(String content, String type, {String? imageUrl}) async {
    try {
      if ((content.isEmpty && type == 'text') || senderId.value.isEmpty || receiverId.value.isEmpty) {
        if (senderId.value.isEmpty || receiverId.value.isEmpty) {
          _showSafeSnackbar('Please select a recipient first');
        }
        return;
      }

      isSending.value = true;

      // Insert the message
      await _supabase.from('messages').insert({
        'sender_id': senderId.value,
        'receiver_id': receiverId.value,
        'type': type,
        'content': content,
        'photo_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Get user controller instance safely
      UserController? userController;
      try {
        userController = Get.find<UserController>();
      } catch (e) {
        debugPrint('UserController not found: $e');
      }

      // Send notification
      await _notificationService.sendChatNotification(
        receiverId: receiverId.value,
        receiverName: receiverName.value,
        senderName: userController?.currentUser.value.username ?? 'User',
        message: content,
        imageUrl: imageUrl,
      );

      messageController.clear();
    } catch (e) {
      debugPrint('Error sending message: $e');
      _showSafeSnackbar('Failed to send message');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> onMessageSend() async {
    final text = messageController.text.trim();
    if (text.isNotEmpty) {
      await sendMessage(text, 'text');
    }
  }

  Future<void> onPickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image == null) return;

      isSending.value = true;

      final fileExtension = path_lib.extension(image.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final file = File(image.path);

      debugPrint('Uploading image: $fileName');

      // Use consistent bucket name
      const String bucketName = 'chat_images';

      // Check file size
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) { // 5MB limit
        _showSafeSnackbar('Image too large (max 5MB). Please choose a smaller image.');
        isSending.value = false;
        return;
      }

      await _supabase.storage
          .from(bucketName)
          .upload(fileName, file);

      final imageUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);

      debugPrint('Image uploaded successfully. URL: $imageUrl');

      await sendMessage('Image', 'image', imageUrl: imageUrl);
    } catch (e) {
      debugPrint('Image upload error: $e');
      _showSafeSnackbar('Failed to upload image. Please try again.');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> showImageSourceDialog(BuildContext context) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                onPickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                onPickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<Message>> getMessages() {
    if (senderId.value.isEmpty || receiverId.value.isEmpty) {
      return Stream.value([]);
    }

    try {
      return _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: true)
          .map((events) {
        try {
          final messages = events
              .map((e) => Message.fromJson(e))
              .where((m) =>
          (m.senderId == senderId.value && m.receiverId == receiverId.value) ||
              (m.senderId == receiverId.value && m.receiverId == senderId.value))
              .toList();
          return messages;
        } catch (e) {
          debugPrint('Error processing messages: $e');
          return <Message>[];
        }
      });
    } catch (e) {
      debugPrint('Error getting messages stream: $e');
      return Stream.value([]);
    }
  }

  Future<void> fetchReceiverName() async {
    try {
      if (receiverId.value.isEmpty) {
        receiverName.value = 'Unknown';
        return;
      }

      final response = await _supabase
          .from('users')
          .select('username')
          .eq('id', receiverId.value)
          .maybeSingle();

      receiverName.value = response?['username'] ?? 'Unknown';
    } catch (e) {
      debugPrint('Error fetching receiver name: $e');
      receiverName.value = 'Unknown';
    }
  }

  void _showSafeSnackbar(String message) {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isSnackbarOpen) return;

        Get.showSnackbar(
          GetSnackBar(
            message: message,
            duration: const Duration(seconds: 3),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            margin: const EdgeInsets.all(10),
            borderRadius: 8,
          ),
        );
      });
    } catch (e) {
      debugPrint('Error showing snackbar: $e');
    }
  }
}