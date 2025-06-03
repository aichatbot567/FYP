import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'group notification.dart';
import 'group_model.dart';

class GroupChat extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChat({super.key, required this.groupId, required this.groupName});

  @override
  _GroupChatState createState() => _GroupChatState();
}

class _GroupChatState extends State<GroupChat> {
  final _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _notificationService = GroupNotificationService();
  Stream<List<GroupMessage>>? _messagesStream;
  final _scrollController = ScrollController();
  List<GroupMember> _members = [];
  bool _isLoadingMembers = false;
  bool _isSendingMessage = false;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _initializeMessageStream() {
    _messagesStream = _supabase
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', widget.groupId)
        .order('created_at', ascending: true)
        .map((messages) {
      final mappedMessages = messages.map((m) {
        final senderId = m['sender_id'];
        final userData = _members
            .firstWhere(
              (member) => member.userId == senderId,
          orElse: () => GroupMember(
            id: '',
            groupId: '',
            userId: '',
            joinedAt: DateTime.now(),
            user: null,
          ),
        )
            .user;

        return GroupMessage.fromJson({
          ...m,
          'sender': userData?.toJson(),
        });
      }).toList();

      if (mappedMessages.length > _previousMessageCount) {
        _previousMessageCount = mappedMessages.length;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      return mappedMessages;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadGroupMembers() async {
    if (!mounted) return;

    setState(() => _isLoadingMembers = true);
    try {
      final response = await _supabase
          .from('group_members')
          .select('''
          id,
          group_id,
          user_id,
          joined_at,
          users!user_id(id, username, email)
        ''')
          .eq('group_id', widget.groupId);

      if (mounted) {
        setState(() {
          _members = response.map((m) {
            return GroupMember(
              id: m['id'] as String,
              groupId: m['group_id'] as String,
              userId: m['user_id'] as String,
              joinedAt: DateTime.parse(m['joined_at'] as String),
              user: m['users'] != null
                  ? ChatUser.fromJson(m['users'] as Map<String, dynamic>)
                  : null,
            );
          }).toList();

          _initializeMessageStream();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading members: $e'),
            backgroundColor: const Color(0x90FFFFFF),
          ),
        );
        debugPrint('Error details: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSendingMessage) return;

    setState(() => _isSendingMessage = true);
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _supabase.from('group_messages').insert({
        'group_id': widget.groupId,
        'content': text,
        'sender_id': currentUser.id,
        'message_type': 'text',
      });

      await _notificationService.sendGroupMessageNotification(
        groupId: widget.groupId,
        groupName: widget.groupName,
        message: text,
      );

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: const Color(0x90FFFFFF),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingMessage = false);
      }
    }
  }

  Widget _buildMessageInput() {
    return Container(
      color: const Color(0x90FFFFFF),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF4BA1AE)),
            onPressed: () => _showAttachmentOptions(),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                hintStyle: const TextStyle(color: Colors.black54),
              ),
              style: const TextStyle(color: Colors.black87),
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
            ),
          ),
          _isSendingMessage
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4BA1AE),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF4BA1AE)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0x90FFFFFF),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.black87),
              title: const Text('Send Image', style: TextStyle(color: Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                _handleImageUpload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.black87),
              title: const Text('Send Video', style: TextStyle(color: Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                _handleVideoUpload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.black87),
              title: const Text('Send File', style: TextStyle(color: Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                _handleFileUpload();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageUpload() async {
    // Implement image upload logic
    // After upload, send notification:
    // await _notificationService.sendGroupMessageNotification(
    //   groupId: widget.groupId,
    //   groupName: widget.groupName,
    //   message: 'Image',
    //   imageUrl: uploadedImageUrl,
    //   senderId: _supabase.auth.currentUser!.id,
    // );
  }

  Future<void> _handleVideoUpload() async {
    // Implement video upload logic
  }

  Future<void> _handleFileUpload() async {
    // Implement file upload logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.groupName),
        backgroundColor: const Color(0xFF4BA1AE),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4BA1AE),
              Color(0xFF73B5C1),
              Color(0xFF82BDC8),
              Color(0xFF92C6CF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _messagesStream == null
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : StreamBuilder<List<GroupMessage>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  final messages = snapshot.data!;

                  if (messages.isNotEmpty && _previousMessageCount > 0) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == _supabase.auth.currentUser?.id;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              Text(
                                message.sender?.displayName ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x90FFFFFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                message.content,
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('h:mm a').format(message.createdAt),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }
}