import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../views/chat_screen.dart';
import 'group_chat.dart';

class NotificationHandler {
  static void handleNotificationClick(Map<String, dynamic>? data) {
    if (data == null) {
      debugPrint('Notification data is null');
      Get.offAll(() => ChatScreen());
      return;
    }

    // Normalize the data structure
    final normalizedData = _normalizeData(data);
    debugPrint('Received notification data: $normalizedData');

    // Extract notification type
    final type = _extractType(normalizedData);
    debugPrint('Notification type: $type');

    switch (type) {
      case 'group_message':
        _handleGroupNotification(normalizedData);
        break;
      case 'chat_message':
        _handleChatNotification(normalizedData);
        break;
      default:
        debugPrint('Unknown notification type: $type');
        Get.offAll(() => ChatScreen());
    }
  }

  static Map<String, dynamic> _normalizeData(Map<String, dynamic> data) {
    // Handle nested OneSignal data structure
    if (data['a'] is Map) {
      return {...data, ...(data['a'] as Map).map((k, v) => MapEntry(k.toString(), v))};
    }

    // Convert keys to lowercase and trim strings
    return data.map((key, value) {
      final normalizedKey = key.toLowerCase();
      final normalizedValue = value is String ? value.trim() : value;
      return MapEntry(normalizedKey, normalizedValue);
    });
  }

  static String? _extractType(Map<String, dynamic> data) {
    return data['notificationtype'] ?? data['type'];
  }

  static void _handleGroupNotification(Map<String, dynamic> data) {
    try {
      final groupId = data['groupid']?.toString();
      final groupName = data['groupname']?.toString() ?? 'Group Chat';

      if (groupId == null || groupId.isEmpty) {
        throw Exception('Missing groupId in notification data');
      }
      debugPrint('Navigating to GroupChat: $groupId');
      Get.offAll(() => GroupChat(
        groupId: groupId,
        groupName: groupName,
      ));
    } catch (e) {
      debugPrint('Group notification handling failed: $e');
      Get.offAll(() => ChatScreen());
    }
  }

  static void _handleChatNotification(Map<String, dynamic> data) {
    try {
      final senderId = data['senderid']?.toString();
      final senderName = data['sendername']?.toString() ?? 'Unknown';

      if (senderId == null || senderId.isEmpty) {
        throw Exception('Missing senderId in notification data');
      }

      debugPrint('Navigating to ChatDetailScreen with sender: $senderId');
      Get.offAll(() => ChatDetailScreen(
        receiverId: senderId,
        receiverName: senderName,
      ));
    } catch (e) {
      debugPrint('Chat notification handling failed: $e');
      Get.offAll(() => ChatScreen());
    }
  }
}