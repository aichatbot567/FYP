import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({super.key});

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final List<String> _selectedUsers = [];
  bool _isCreating = false;
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoadingUsers = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoadingUsers = false;
        });
        return;
      }
      final response = await _supabase
          .from('users')
          .select('id, email')
          .neq('id', currentUserId);
      if (response.isEmpty) {
        setState(() {
          _errorMessage = 'No users found';
          _isLoadingUsers = false;
        });
        return;
      }

      setState(() {
        _allUsers = response;
        _isLoadingUsers = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: ${e.toString()}';
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate() || _isCreating) return;

    setState(() => _isCreating = true);
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Call the PostgreSQL function
      final response = await _supabase.rpc('create_group_with_members', params: {
        'group_name': _nameController.text.trim(),
        'creator_id': currentUserId,
        'member_ids': _selectedUsers.isNotEmpty ? _selectedUsers : null,
      }).select();

      if (response.isEmpty) throw Exception('No group created');

      Get.back(result: true);
      Get.snackbar('Success', 'Group created successfully');
    } on PostgrestException catch (e) {
      Get.snackbar('Error', 'Database error: ${e.message}');
      print("'Error', 'Database error: ${e.message}'");
    } catch (e) {
      Get.snackbar('Error', 'Failed to create group: ${e.toString()}');
    } finally {
      setState(() => _isCreating = false);
    }
  }  Widget _buildUserList() {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_allUsers.isEmpty) {
      return const Center(child: Text('No users available'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allUsers.length,
      itemBuilder: (context, index) {
        final user = _allUsers[index];
        final username = user['username'] ?? user['email'] ?? 'Unknown';
        return CheckboxListTile(
          title: Text(username),
          value: _selectedUsers.contains(user['id']),
          onChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedUsers.add(user['id']);
              } else {
                _selectedUsers.remove(user['id']);
              }
            });
          },
          secondary: CircleAvatar(
            child: Text(username[0].toUpperCase()),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Group')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Members:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _buildUserList(),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _selectedUsers.map((userId) {
                  final user = _allUsers.firstWhere(
                        (u) => u['id'] == userId,
                    orElse: () => {},
                  );
                  final username = user['username'] ?? user['email'] ?? 'Unknown';
                  return Chip(
                    label: Text(username),
                    onDeleted: () => setState(() => _selectedUsers.remove(userId)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createGroup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCreating
                    ? const CircularProgressIndicator()
                    : const Text('Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}