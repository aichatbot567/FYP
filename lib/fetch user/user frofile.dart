import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Save user profile (update username) in Supabase
  static Future<void> saveUserProfile(String username, String email) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('No user is currently logged in.');
        throw Exception('No user is currently logged in.');
      }

      await Supabase.instance.client
          .from('users')
          .update({'username': username})
          .eq('id', userId);

      print('Username updated successfully in Supabase');
    } catch (e) {
      print('Error updating username: $e');
      throw Exception('Failed to update username: $e');
    }
  }

  // Retrieve user profile (username and email) from Supabase
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('No user is currently logged in.');
        return null;
      }

      final response = await Supabase.instance.client
          .from('users')
          .select('username, email')
          .eq('id', userId)
          .single();

      return {
        'username': response['username'] as String?,
        'email': response['email'] as String?,
      };
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
}