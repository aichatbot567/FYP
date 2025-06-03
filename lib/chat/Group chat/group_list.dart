import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'group_chat.dart';
import 'group_creation.dart';
import 'group_model.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final _supabase = Supabase.instance.client;
  List<Group> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('group_members')
          .select('group_id, groups(*)')
          .eq('user_id', userId);

      if (mounted) {
        setState(() {
          _groups = response.map<Group>((g) => Group.fromJson(g['groups'])).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load groups: ${e.toString()}',
          backgroundColor: const Color(0x90FFFFFF),
          colorText: Colors.black87,
        );
        setState(() => _isLoading = false);
      }
      print("Error fetching groups: $e");
    }
  }

  Future<void> _deleteGroup(String groupId) async {
    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: const Color(0x90FFFFFF),
          title: const Text('Delete Group', style: TextStyle(color: Colors.black87)),
          content: const Text('Are you sure you want to delete this group?', style: TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      if (mounted) setState(() => _isLoading = true);

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _supabase.rpc('delete_group_with_dependencies', params: {
        'p_group_id': groupId,
        'p_user_id': currentUserId,
      });

      if (mounted) {
        Get.snackbar(
          'Success',
          'Group deleted successfully',
          backgroundColor: const Color(0x90FFFFFF),
          colorText: Colors.black87,
        );
        _fetchGroups();
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to delete group: ${e.toString()}',
          backgroundColor: const Color(0x90FFFFFF),
          colorText: Colors.black87,
        );
        setState(() => _isLoading = false);
      }
      print("Error deleting group: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Create A New Group"),
        backgroundColor: const Color(0xFF4BA1AE),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: () => Get.to(() => const GroupCreationScreen())
                ?.then((_) => _fetchGroups()),
          ),
        ],
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
        child: RefreshIndicator(
          onRefresh: _fetchGroups,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _groups.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No groups found',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.to(() => const GroupCreationScreen())
                      ?.then((_) => _fetchGroups()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4BA1AE),
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Create a Group'),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              final group = _groups[index];
              return Dismissible(
                key: Key(group.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  final currentUserId = _supabase.auth.currentUser?.id;

                  final groupResponse = await _supabase
                      .from('groups')
                      .select('created_by')
                      .eq('id', group.id)
                      .single();

                  if (groupResponse['created_by'] != currentUserId) {
                    Get.snackbar(
                      '',
                      'Only group creator can delete the group',
                      backgroundColor: const Color(0x90FFFFFF),
                      colorText: Colors.black87,
                    );
                    return false;
                  }

                  return await Get.dialog<bool>(
                    AlertDialog(
                      backgroundColor: const Color(0x90FFFFFF),
                      title: const Text('Delete Group', style: TextStyle(color: Colors.black87)),
                      content: const Text('Are you sure you want to delete this group?', style: TextStyle(color: Colors.black87)),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  _deleteGroup(group.id);
                },
                background: Container(
                  color: const Color(0xFF4BA1AE),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Container(
                  color: const Color(0x90FFFFFF),
                  child: ListTile(
                    title: Text(
                      group.name,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    onTap: () {
                      Get.to(
                            () => GroupChat(
                          groupId: group.id,
                          groupName: group.name,
                        ),
                      )?.then((_) => _fetchGroups());
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.black87),
                      onPressed: () => _showGroupOptions(group),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showGroupOptions(Group group) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    final groupResponse = await _supabase
        .from('groups')
        .select('created_by')
        .eq('id', group.id)
        .single();

    final isCreator = groupResponse['created_by'] == currentUserId;

    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Color(0x90FFFFFF),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message, color: Colors.black87),
              title: const Text('Open Chat', style: TextStyle(color: Colors.black87)),
              onTap: () {
                Get.back();
                Get.to(
                      () => GroupChat(
                    groupId: group.id,
                    groupName: group.name,
                  ),
                )?.then((_) => _fetchGroups());
              },
            ),
            if (isCreator) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.black87),
                title: const Text('Edit Group', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  Get.back();
                  // Navigate to edit group screen
                  // Get.to(() => EditGroupScreen(group: group))?.then((_) => _fetchGroups());
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Group', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Get.back();
                  _deleteGroup(group.id);
                },
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.black87),
                title: const Text('Leave Group', style: TextStyle(color: Colors.black87)),
                onTap: () async {
                  Get.back();
                  try {
                    await _supabase
                        .from('group_members')
                        .delete()
                        .eq('group_id', group.id)
                        .eq('user_id', currentUserId as Object);

                    _fetchGroups();
                    Get.snackbar(
                      'Success',
                      'You left the group',
                      backgroundColor: const Color(0x90FFFFFF),
                      colorText: Colors.black87,
                    );
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      'Failed to leave group: ${e.toString()}',
                      backgroundColor: const Color(0x90FFFFFF),
                      colorText: Colors.black87,
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}