import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'builtin_group_controller.dart';
import 'group_chat_screen.dart';

class BuiltInGroupsScreen extends StatelessWidget {
  final BuiltInGroupController _controller = Get.put(BuiltInGroupController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Health Communities'),
        backgroundColor: const Color(0xFF4BA1AE),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4BA1AE),
              Color(0xFF73B5C1),
              Color(0xFF82BDC8),
              Color(0xFF92C6CF),
            ],
          ),
        ),
        child: Obx(() {
          if (_controller.groups.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _controller.groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildGroupCard(index),
          );
        }),
      ),
    );
  }

  Widget _buildGroupCard(int index) {
    final group = _controller.groups[index];
    return Card(
      color: const Color(0x90FFFFFF),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleGroupTap(group['id'], group['name']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4BA1AE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      group['name'] ?? 'Unnamed Group',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildJoinButton(group['id']),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                group['description'] ?? 'No description available',
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinButton(String groupId) {
    return FutureBuilder<bool>(
      future: _controller.isMember(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          );
        }
        return snapshot.data == true
            ? Row(
          children: [
            OutlinedButton(
              onPressed: () => _controller.leaveGroup(groupId),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text(
                'Leave',
                style: TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(width: 8),
            const Chip(
              label: Text(
                'Joined',
                style: TextStyle(color: Colors.black),
              ),
              backgroundColor: Color(0xFF52C11F),
            ),
          ],
        )
            : OutlinedButton(
          onPressed: () => _controller.joinGroup(groupId),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: const BorderSide(color: Color(0xFF4BA1AE)),
          ),
          child: const Text(
            'Join',
            style: TextStyle(color: Color(0xFF000000)),
          ),
        );
      },
    );
  }

  Future<void> _handleGroupTap(String groupId, String groupName) async {
    final isMember = await _controller.isMember(groupId);
    if (isMember) {
      Get.to(() => GroupChatScreen(
        groupId: groupId,
        groupName: groupName,
      ));
    } else {
      Get.snackbar(
        'Join Required',
        'Please join the group first to participate in discussions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0x90FFFFFF),
        colorText: Colors.black87,
      );
    }
  }
}