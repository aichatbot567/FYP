import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fetch user/update_profile.dart';
import 'fetch user/user frofile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ImageProvider? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadImage(); // Load the image when the widget is initialized
  }

  // Function to pick image from camera or gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  await _saveImage(pickedFile.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  await _saveImage(pickedFile.path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Function to save image as base64 string in SharedPreferences and update UI
  Future<void> _saveImage(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);
    await prefs.setString('profile_image', base64Image);
    setState(() {
      _profileImage = MemoryImage(base64Decode(base64Image));
    });
  }

  // Function to load image from SharedPreferences
  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Image = prefs.getString('profile_image');
    if (base64Image != null) {
      setState(() {
        _profileImage = MemoryImage(base64Decode(base64Image));
      });
    }
  }

  // Show notification settings dialog
  Future<void> _showNotificationDialog() async {
    bool medicineReminders = true;
    bool healthTips = true;
    bool generalAlerts = true;

    final prefs = await SharedPreferences.getInstance();
    medicineReminders = prefs.getBool('medicine_reminders') ?? true;
    healthTips = prefs.getBool('health_tips') ?? true;
    generalAlerts = prefs.getBool('general_alerts') ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
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
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Notification Preferences',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text(
                      'Medicine Reminders',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: medicineReminders,
                    onChanged: (value) {
                      setDialogState(() {
                        medicineReminders = value;
                      });
                    },
                    activeColor: const Color(0xFF227683),
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Health Tips',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: healthTips,
                    onChanged: (value) {
                      setDialogState(() {
                        healthTips = value;
                      });
                    },
                    activeColor: const Color(0xFF227683),
                  ),
                  SwitchListTile(
                    title: const Text(
                      'General Alerts',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: generalAlerts,
                    onChanged: (value) {
                      setDialogState(() {
                        generalAlerts = value;
                      });
                    },
                    activeColor: const Color(0xFF227683),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          try {
                            await prefs.setBool('medicine_reminders', medicineReminders);
                            await prefs.setBool('health_tips', healthTips);
                            await prefs.setBool('general_alerts', generalAlerts);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notification settings saved'),
                                backgroundColor: Color(0xFF131F20),
                              ),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save settings: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Color(0xFF000000)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Show about dialog
  Future<void> _showAboutDialog() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
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
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About Health Companion',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Health Companion is your trusted partner in managing your well-being. Our app provides personalized health solutions, including:',
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Medicine Reminders: Never miss a dose with timely alerts.\n'
                      '• Health Tips: Daily insights to improve your lifestyle.\n'
                      '• Community Support: Connect with others through group chats.\n'
                      '• Secure Data: Your health information is protected with Supabase.',
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Our mission is to empower you to lead a healthier life with ease and confidence.',
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Color(0xFF000000)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.email,
        'title': 'Account',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UpdateProfileScreen()),
        ),
      },
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'onTap': _showNotificationDialog,
      },
      {
        'icon': Icons.info,
        'title': 'About',
        'onTap': _showAboutDialog,
      },
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4BA1AE),
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Image with + button
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4BA1AE),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImage,
                      backgroundColor: _profileImage == null ? Colors.grey[200] : null,
                      child: _profileImage == null
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4BA1AE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Profile Info
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: AuthService.getUserProfile(),
                  builder: (context, snapshot) {
                    // Loading State
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Column(
                        children: [
                          Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading profile...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      );
                    }
                    // Error State
                    if (snapshot.hasError || snapshot.data == null) {
                      return const Column(
                        children: [
                          Text(
                            'Guest User',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'guest@example.com',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      );
                    }
                    // Success State
                    final userProfile = snapshot.data!;
                    return Column(
                      children: [
                        Text(
                          userProfile['username'] ?? 'No username',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userProfile['email'] ?? 'no-email@example.com',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              // Menu Items
              ...menuItems.map(
                    (item) => Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x90FFFFFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      item['icon'] as IconData,
                      color: Colors.black54,
                    ),
                    title: Text(
                      item['title'] as String,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    onTap: item['onTap'] as void Function()?,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4BA1AE),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> signOut() async {
    try {
      final supabase = Supabase.instance.client;

      // Sign out from Supabase
      await supabase.auth.signOut();
      debugPrint('Successfully signed out from Supabase');

      // Clear SharedPreferences for profile image only
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image');

      // Navigate to login screen
      Get.offAllNamed('/login');
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }
}