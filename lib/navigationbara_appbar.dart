import 'package:digitalhealthcareplatform/Search/search_option.dart';
import 'package:digitalhealthcareplatform/homepage.dart';
import 'package:digitalhealthcareplatform/profilescreen.dart';
import 'package:digitalhealthcareplatform/services.dart';
import 'package:flutter/material.dart';
import 'Search/search_doctors.dart';
import 'chat/views/chat_screen.dart';

class NavigationBarAppBar extends StatefulWidget {
  const NavigationBarAppBar({super.key});

  @override
  State<NavigationBarAppBar> createState() => _NavigationBarAppBarState();
}

class _NavigationBarAppBarState extends State<NavigationBarAppBar> {
  int _currentIndex = 0;

  // Updated with explicit type safety and const where possible
  static final List<Widget> _pages = [
    Homepage(),
    OptionsScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  // Navigation items extracted to a constant for better organization
  static const List<BottomNavigationBarItem> _navBarItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Search',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat),
      label: 'Connect',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1D7A80), // Dialog background
            title: const Text(
              'Exit App',
              style: TextStyle(color: Colors.white), // Title color
            ),
            content: const Text(
              'Are you sure you want to exit the app?',
              style: TextStyle(color: Colors.black), // Content color
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white, // Text color
                ),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent, // Text color for Exit
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages, // Preserves state of all pages
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: _navBarItems,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF92C6CF),
          unselectedItemColor: Colors.black54,
          selectedItemColor: const Color(0xFF1D7A80),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          unselectedLabelStyle: const TextStyle(color: Colors.black54),
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}