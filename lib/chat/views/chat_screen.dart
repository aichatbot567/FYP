import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../Group chat/group_list.dart';
import '../built in groups/builtin_groups_screen.dart';
import '../controller/chat_controller.dart';
import '../controller/user_controller.dart';
import '../models/message.dart';
import '../models/user_model.dart';
import 'full_screen_image.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatController chatController = Get.put(ChatController());
  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    await userController.fetchUserData();
    await chatController.fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Chats"),
        backgroundColor: const Color(0xFF4BA1AE),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Groups'),
            Tab(text: 'Built-In-Groups'),
          ],
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildUserList(),
            GroupListScreen(),
            BuiltInGroupsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return Obx(() {
      if (chatController.users.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                "Loading users...",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        itemCount: chatController.users.length + 1, // Add 1 for "ALL USERS"
        separatorBuilder: (context, index) => const Divider(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
           return Container(
              color: const Color(0xFF4BA1AE),
              child: const ListTile(
                title: Center(
                  child: Text(
                    'ALL USERS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }
          final user = chatController.users[index - 1]; // Adjust index for users
          return UserListItem(user: user);
        },
      );
    });
  }}

class UserListItem extends StatelessWidget {
  final UserModel user;

  const UserListItem({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x90FFFFFF),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF73B5C1),
          child: Text(
            user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.username,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          user.email,
          style: const TextStyle(color: Colors.black),
        ),
        trailing: const Icon(Icons.chat_bubble_outline, color: Color(0xFF094655)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              receiverId: user.id,
              receiverName: user.username,
            ),
          ),
        ),
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatController chatController = Get.find<ChatController>();
  final UserController userController = Get.find<UserController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    chatController.receiverId.value = widget.receiverId;
    chatController.receiverName.value = widget.receiverName;
    chatController.senderId.value = userController.getUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1B656E),
              radius: 16,
              child: Text(
                widget.receiverName.isNotEmpty
                    ? widget.receiverName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.receiverName),
          ],
        ),
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
              child: _MessageList(scrollController: _scrollController),
            ),
            _ChatInput(),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatefulWidget {
  final ScrollController scrollController;

  const _MessageList({required this.scrollController});

  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final ChatController chatController = Get.find<ChatController>();
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _setupMessageListener() {
    _messageSubscription = chatController.getMessages().listen((messages) {
      if (!mounted) return;

      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _scrollToBottom();
      });
    }, onError: (error) {
      debugPrint('Error in message stream: $error');
    });
  }

  void _scrollToBottom() {
    try {
      if (widget.scrollController.hasClients && mounted) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Error scrolling to bottom: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Message>>(
      stream: chatController.getMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (snapshot.hasError) {
          debugPrint('Stream error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading messages',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'Start a conversation!',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToBottom();
        });

        return ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(8),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return MessageWidget(message: snapshot.data![index]);
          },
        );
      },
    );
  }
}

class MessageWidget extends StatelessWidget {
  final Message message;

  const MessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final isSender = message.senderId == chatController.senderId.value;
    final formattedTime = DateFormat('h:mm a').format(message.createdAt);

    final String firstLetter = chatController.receiverName.value.isNotEmpty
        ? chatController.receiverName.value[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFF73B5C1),
              radius: 16,
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x90FFFFFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(context),
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (message.type == 'image' && message.photoUrl != null) {
      return InkWell(
        onTap: () {
          if (message.photoUrl != null && message.photoUrl!.startsWith('http')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenChatImage(photoUrl: message.photoUrl!),
              ),
            );
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.photoUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey.shade300,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFF4BA1AE),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Image error: $error');
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                ),
              );
            },
          ),
        ),
      );
    }
    return Text(
      message.content ?? '[No content]',
      style: const TextStyle(color: Colors.black87),
    );
  }
}

class _ChatInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0x90FFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF4BA1AE)),
            onPressed: () => chatController.showImageSourceDialog(context),
          ),
          Expanded(
            child: TextField(
              controller: chatController.messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                hintStyle: const TextStyle(color: Colors.black54),
              ),
              style: const TextStyle(color: Colors.black87),
              onSubmitted: (_) => chatController.onMessageSend(),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => chatController.isSending.value
              ? Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            child: const CircularProgressIndicator(color: Color(0xFF4BA1AE)),
          )
              : Material(
            color: const Color(0xFF4BA1AE),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: chatController.onMessageSend,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}