import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../views/chat_screen.dart';
import 'notification_handler.dart';

class GroupNotificationService {
  static final GroupNotificationService _instance = GroupNotificationService._internal();
  factory GroupNotificationService() => _instance;
  GroupNotificationService._internal();

  final String oneSignalAppId = '8c2326a9-051d-4056-ad47-787c5a94ed50';
  final String oneSignalRestApiKey = 'os_v2_app_rqrsnkifdvafnlkhpb6fvfhnkan6oa375h4u6pmxx5j2rtpskw4y4nlweg2r2k4rhjctwybq3b4twdecjf27q4imxo26ntzwbb5guda';
  bool _isInitialized = false;
  final _supabase = Supabase.instance.client;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      OneSignal.Debug.setLogLevel(kDebugMode ? OSLogLevel.verbose : OSLogLevel.none);
      OneSignal.initialize(oneSignalAppId);
      await OneSignal.Notifications.requestPermission(true);
      await _savePlayerIdToDatabase();
      _setupNotificationClickHandler();
      _isInitialized = true;
      debugPrint('GroupNotificationService initialized');
    } catch (e, stack) {
      debugPrint('GroupNotificationService init failed: $e');
      rethrow;
    }
  }

  Future<void> sendGroupMessageNotification({
    required String groupId,
    required String groupName,
    required String message,
    String? imageUrl,
  }) async {
    try {
      if (!_isInitialized) await init();

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('No authenticated user');

      final senderName = (await _supabase
          .from('profiles')
          .select('username')
          .eq('id', currentUser.id)
          .maybeSingle())?['username'] ?? 'User';

      final memberIds = (await _supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId)
          .neq('user_id', currentUser.id))
          .map((m) => m['user_id'] as String)
          .toList();

      if (memberIds.isEmpty) return;

      final playerIds = await _getPlayerIdsForUsers(memberIds);
      if (playerIds.isEmpty) return;

      await _sendNotificationViaRest(
        playerIds: playerIds,
        heading: 'New message in $groupName',
        content: imageUrl != null ? '$senderName sent an image' : message,
        additionalData: {
          'notificationType': 'group_message',
          'groupId': groupId,
          'groupName': groupName,
          'senderId': currentUser.id,
          'senderName': senderName,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );
    } catch (e, stack) {
      debugPrint('Failed to send group notification: $e');
      if (kDebugMode) rethrow;
    }
  }

  Future<List<String>> _getPlayerIdsForUsers(List<String> userIds) async {
    try {
      return (await _supabase
          .from('user_devices')
          .select('player_id')
          .inFilter('user_id', userIds))
          .map((r) => r['player_id'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error getting player IDs: $e');
      return [];
    }
  }

  Future<void> _sendNotificationViaRest({
    required List<String> playerIds,
    required String heading,
    required String content,
    required Map<String, dynamic> additionalData,
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
          'data': additionalData,
        }),
      );

      if (response.statusCode >= 400) {
        throw Exception('Notification API error: ${response.body}');
      }
    } catch (e) {
      debugPrint('REST API error: $e');
      rethrow;
    }
  }

  Future<void> _savePlayerIdToDatabase() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final playerId = (await OneSignal.User.pushSubscription).id;
      if (playerId == null || playerId.isEmpty) return;

      await _supabase.from('user_devices').upsert({
        'user_id': userId,
        'player_id': playerId,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,player_id');
    } catch (e) {
      debugPrint('Failed to save player ID: $e');
    }
  }

  void _setupNotificationClickHandler() {
    OneSignal.Notifications.addClickListener((event) {
      try {
        NotificationHandler.handleNotificationClick(event.notification.additionalData);
      } catch (e) {
        debugPrint('Notification click handler failed: $e');
        Get.offAll(() => ChatScreen());
      }
    });
  }
}