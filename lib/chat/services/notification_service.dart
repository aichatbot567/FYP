import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Group chat/notification_handler.dart';
import '../controller/chat_controller.dart';
import '../views/chat_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final String oneSignalAppId = '8c2326a9-051d-4056-ad47-787c5a94ed50';
  final String oneSignalRestApiKey = 'os_v2_app_rqrsnkifdvafnlkhpb6fvfhnkan6oa375h4u6pmxx5j2rtpskw4y4nlweg2r2k4rhjctwybq3b4twdecjf27q4imxo26ntzwbb5guda';
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      OneSignal.Debug.setLogLevel(kDebugMode ? OSLogLevel.verbose : OSLogLevel.none);
      OneSignal.initialize(oneSignalAppId);
      await OneSignal.Notifications.requestPermission(true);
      _setupNotificationClickHandler();
      _isInitialized = true;
      debugPrint('Chat Notification service initialized');
    } catch (e, stack) {
      debugPrint('Error initializing Chat Notification: $e');
      rethrow;
    }
  }

  void _setupNotificationClickHandler() {
    OneSignal.Notifications.addClickListener((event) {
      try {
        NotificationHandler.handleNotificationClick(event.notification.additionalData);
      } catch (e, stack) {
        debugPrint('Chat Notification click error: $e');
        Get.offAll(() => ChatScreen());
      }
    });
  }

  Future<void> verifyNotificationSetup(String userId) async {
    debugPrint('Starting notification setup verification for user: $userId');

    final localPlayerId = OneSignal.User.pushSubscription.id;
    debugPrint('Local player ID: $localPlayerId');

    final storedPlayerId = await _getPlayerIdForUser(userId);

    if (storedPlayerId == null) {
      debugPrint('No player ID stored - attempting to store current ID');
      await storePlayerId(userId);
    } else if (localPlayerId != storedPlayerId) {
      debugPrint('Player ID mismatch - updating stored ID');
      await storePlayerId(userId);
    } else {
      debugPrint('Player IDs match - setup is correct');
    }
  }

  Future<void> storePlayerId(String userId) async {
    try {
      if (!_isInitialized) await init();

      String? playerId;
      int maxRetries = 5;

      for (int i = 0; i < maxRetries; i++) {
        playerId = OneSignal.User.pushSubscription.id;
        if (playerId != null && playerId.isNotEmpty) break;
        await Future.delayed(const Duration(seconds: 2));
        debugPrint('Retrying player ID fetch (attempt ${i + 1}/$maxRetries)');
      }

      if (playerId == null || playerId.isEmpty) {
        debugPrint('Failed to get player ID after $maxRetries attempts');
        return;
      }

      debugPrint('Storing player ID: $playerId for user: $userId');

      final supabase = Supabase.instance.client;
      await supabase.from('user_devices').upsert({
        'user_id': userId,
        'player_id': playerId,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      debugPrint('Player ID stored successfully');

    } catch (e) {
      debugPrint('Error in storePlayerId: $e');
    }
  }

  Future<String?> _getPlayerIdForUser(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('user_devices')
          .select('player_id, updated_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('No device record found for user $userId');
        return null;
      }

      return response['player_id'] as String?;
    } catch (e) {
      debugPrint('Error fetching player ID: $e');
      return null;
    }
  }

  Future<void> sendChatNotification({
    required String receiverId,
    required String receiverName,
    required String senderName,
    required String message,
    String? imageUrl,
  }) async {
    debugPrint('Attempting to send chat notification to: $receiverId');

    try {
      if (!_isInitialized) await init();

      await verifyNotificationSetup(Get.find<ChatController>().senderId.value);

      final receiverPlayerId = await _getPlayerIdForUser(receiverId);

      if (receiverPlayerId == null || receiverPlayerId.isEmpty) {
        debugPrint('No player ID found for user $receiverId');
        Get.snackbar(
          'Notice',
          'Recipient may not receive push notifications',
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final content = imageUrl != null ? '$senderName sent an image' : message;
      final heading = 'New message from $senderName';

      await _sendNotificationViaRest(
        playerIds: [receiverPlayerId],
        heading: heading,
        content: content,
        additionalData: {
          'notificationType': 'chat_message',
          'receiverId': receiverId,
          'receiverName': receiverName,
          'senderId': Get.find<ChatController>().senderId.value,
          'senderName': senderName,
          'imageUrl': imageUrl,
        },
      );

    } catch (e) {
      debugPrint('Error sending chat notification: $e');
      if (kDebugMode) rethrow;
    }
  }

  Future<void> _sendNotificationViaRest({
    required List<String> playerIds,
    required String heading,
    required String content,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $oneSignalRestApiKey',
        },
        body: jsonEncode({
          'app_id': oneSignalAppId,
          'include_player_ids': playerIds,
          'headings': {'en': heading},
          'contents': {'en': content},
          'data': additionalData ?? {},
        }),
      );
      if (response.statusCode >= 400) {
        throw Exception('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      debugPrint('REST API error: $e');
      rethrow;
    }
  }
}