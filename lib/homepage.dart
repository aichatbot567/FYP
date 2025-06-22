import 'dart:convert';
import 'dart:ui';
import 'package:digitalhealthcareplatform/Bmi_calculator.dart';
import 'package:digitalhealthcareplatform/chatbot/chat%20bot.dart';
import 'package:digitalhealthcareplatform/profilescreen.dart';
import 'package:digitalhealthcareplatform/tip%20of%20the%20day.dart';
import 'package:flutter/material.dart';
import 'package:digitalhealthcareplatform/reminders/medican%20reminder.dart';
import 'package:digitalhealthcareplatform/scaner/scan_code.dart';
import 'package:digitalhealthcareplatform/call%20embulance/call_embulance.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AI_model/disease_predictor.dart';
import 'E-Aid/e-aid.dart';
import 'fetch user/user frofile.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController searchController = TextEditingController();
  ImageProvider? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadImage(); // Load the image when the widget is initialized
  }
  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Image = prefs.getString('profile_image');
    if (base64Image != null) {
      setState(() {
        _profileImage = MemoryImage(base64Decode(base64Image));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'title': 'Medicine Reminder',
        'icon': Icons.alarm,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MedicineReminderScreen(),
          ),
        ),
      },
      {
        'title': 'Scan Medicine',
        'icon': Icons.qr_code_scanner,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StaticBarcodeScan(),
          ),
        ),
      },
      {
        'title': 'Disease Prediction',
        'icon': Icons.analytics,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DiseasePredictorScreen()),
        ),
      },
      {
        'title': 'Call an Ambulance',
        'icon': Icons.local_hospital,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Near_hosiptal()),
        ),
      },
      {
        'title': 'E-Aid',
        'icon': Icons.medical_services,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FirstAidHome()),
        ),
      },
      {
        'title': 'BMI Calculator',
        'icon': Icons.monitor_weight,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BMICalculatorScreen()),
        ),
      },
    ];
    return Scaffold(
      backgroundColor: const Color(0xff4ca1af),
      body: SafeArea(
        child: Container(
          height: MediaQuery.sizeOf(context).height,
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
              // User Greeting Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: AuthService.getUserProfile(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Your personal health companion',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    // Handle error or null data
                    if (snapshot.hasError || snapshot.data == null) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Hello, Guest!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Your personal health companion',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    // Success case
                    final userProfile = snapshot.data!;
                    final userName = userProfile['username'] ?? 'Guest';

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $userName!',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Your personal health companion',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                        InkWell(
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: _profileImage,
                            backgroundColor: _profileImage == null ? Colors.grey[200] : null,
                            child: _profileImage == null
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProfileScreen()),
                              );
                            }

                        ),
                      ],
                    );
                  },
                ),
              ),
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar with Glass Effect
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0x54104950),
                                  Color(0x572d6977),
                                ],
                                stops: [0, 1],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.black,
                                ),
                                hintText: 'Quick Help',
                                hintStyle: const TextStyle(color: Colors.black),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                              style: const TextStyle(color: Colors.black),
                              onSubmitted: (query) {
                                if (query.trim().isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Chatbot(initialQuery: query),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        HealthTipWidget(),
                        // Categories Section
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categories.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return GestureDetector(
                              onTap: category['onTap'] as void Function()?,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                  child: Card(
                                    color: Color(0x90FFFFFF),
                                    elevation: 9,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            category['icon'] as IconData,
                                            size: 50,
                                            color: const Color(0xFF032F60),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            category['title'] as String,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}