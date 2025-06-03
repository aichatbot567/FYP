import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuiltInGroupController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RxList<Map<String, dynamic>> groups = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxMap<String, String> _userNames = <String, String>{}.obs;
  final SupabaseClient supabase = Supabase.instance.client;
  RealtimeChannel? _messagesChannel;

  @override
  void onInit() {
    super.onInit();
    loadGroups();
  }

  Future<String> getUserName(String userId) async {
    if (_userNames.containsKey(userId)) {
      return _userNames[userId]!;
    }

    try {
      // Fetch from public.users table instead of auth.users
      final response = await _supabase
          .from('users')
          .select('username, email')
          .eq('id', userId)
          .single();

      // Use name if available, otherwise use email prefix
      final name = response['name'] ??
          response['email']?.split('@').first ??
          'User ${userId.substring(0, 6)}';

      _userNames[userId] = name;
      return name;
    } catch (e) {
      // Fallback to user ID if any error occurs
      return 'User ${userId.substring(0, 6)}';
    }
  }

  Future<void> loadGroups() async {
    final response = await _supabase.from('builtin_groups').select();
    groups.value = response ?? [];
  }

  Future<bool> isMember(String groupId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('builtin_group_members')
        .select()
        .eq('user_id', userId)
        .eq('group_id', groupId)
        .maybeSingle();

    return response != null;
  }

  Future<void> joinGroup(String groupId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('builtin_group_members').insert({
      'user_id': userId,
      'group_id': groupId,
    });
    await loadGroups();
  }

  void initializeChat(String groupId) {
    // Unsubscribe from previous channel if exists
    _messagesChannel?.unsubscribe();

    _messagesChannel = _supabase.channel('group_$groupId');

    // Subscribe to new messages
    _messagesChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'builtin_group_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'group_id',
        value: groupId,
      ),
      callback: (payload) {
        messages.add(payload.newRecord);
      },
    ).subscribe();

    _loadInitialMessages(groupId);
  }
  // Add this method to BuiltInGroupController class
  Future<void> leaveGroup(String groupId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('builtin_group_members')
        .delete()
        .eq('user_id', userId)
        .eq('group_id', groupId);
    await loadGroups();
  }

  Future<void> _loadInitialMessages(String groupId) async {
    final response = await _supabase
        .from('builtin_group_messages')
        .select()
        .eq('group_id', groupId)
        .order('created_at');
    messages.value = response ?? [];
  }

  Future<void> sendMessage({
    required String groupId,
    required String content,
    bool anonymous = false,
  }) async {
    await _supabase.from('builtin_group_messages').insert({
      'group_id': groupId,
      'content': content,
      'user_id': anonymous ? null : _supabase.auth.currentUser!.id,
      'is_anonymous': anonymous,
    });
  }

  @override
  void onClose() {
    _messagesChannel?.unsubscribe();
    super.onClose();
  }
}