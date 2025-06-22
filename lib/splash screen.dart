import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arc_text/arc_text.dart';
import 'login_page.dart';
import 'navigationbara_appbar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _opacityAnimation;
  final _supabase = Supabase.instance.client;
  final _minimumSplashDuration = const Duration(seconds: 3);
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Initialize animations
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Start the animation
    _controller.forward();

    // Start auth check after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthStatus();
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      final elapsed = DateTime.now().difference(_startTime!);
      final remaining = _minimumSplashDuration - elapsed;

      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }

      final session = _supabase.auth.currentSession;
      final isLoggedIn = session != null;

      if (isLoggedIn) {
        Get.offAll(() => const NavigationBarAppBar());
      } else {
        Get.offAll(() => const LoginPage());
      }
    } catch (e) {
      Get.offAll(() => const LoginPage());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Animated CircleAvatar
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _animation.value,
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: const CircleAvatar(
                            backgroundImage: AssetImage("assets/DHCP.png"),
                            radius: 90,
                          ),
                        ),
                      );
                    },
                  ),
                  // Positioned ArcText
                  Positioned(
                    top: 70,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _animation.value,
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: ArcText(
                              radius: 90,
                              text: 'Digital Healthcare Platform',
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 6,
                                    color: Colors.black,
                                    offset: Offset(-3, -4),
                                  ),
                                ],
                              ),
                              startAngle: 5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  color: Colors.yellow,
                  minHeight: 3,
                  backgroundColor: Colors.black,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}