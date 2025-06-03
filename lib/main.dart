import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:digitalhealthcareplatform/key.dart';
import 'package:digitalhealthcareplatform/splash%20screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digitalhealthcareplatform/login_page.dart';
import 'package:digitalhealthcareplatform/signup_page.dart';
import 'package:digitalhealthcareplatform/forgot_password_page.dart';
import 'package:digitalhealthcareplatform/navigationbara_appbar.dart';
import 'chat/Group chat/group notification.dart';
import 'chat/Group chat/group_creation.dart';
import 'chat/controller/chat_controller.dart';
import 'chat/controller/user_controller.dart';
import 'chat/services/notification_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url:keys().url,
    anonKey: keys().anonKey,
  );
  await GroupNotificationService().init();

  // Initialize notifications with proper channel setup
  try {
    await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelGroupKey: 'medicine_reminder_group',
            channelKey: 'medicine_channel_id',
            channelName: 'Medicine Reminders',
            channelDescription: 'Medicine reminder notifications',
            defaultColor: Colors.blue,
            ledColor: Colors.blue,
            importance: NotificationImportance.High,
            playSound: true,
            soundSource: 'resource://raw/notification_sound', // Without .mp3 extension
            enableVibration: true,
            enableLights: true,
          )
        ],
        channelGroups: [
          NotificationChannelGroup(
              channelGroupKey: 'medicine_reminder_group',
              channelGroupName: 'Medicine Reminder Group'
          )
        ],
        debug: true
    );
    // Request notification permissions
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    print("Notifications initialized successfully");
  } catch (e) {
    print("Error initializing notifications: $e");
  }

  // Initialize controllers
  Get.put(UserController());
  Get.put(ChatController());
  Get.put(NotificationService());
  Get.put(GroupNotificationService().init());
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    // Set up notification listeners
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Health Companion App',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/splash_screen',
      getPages: [
        GetPage(name: '/splash_screen', page:()=> SplashScreen()),
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/signup', page: () => SignupPage()),
        GetPage(name: '/forgot-password', page: () => ForgotPasswordPage()),
        GetPage(name: '/home', page: () => NavigationBarAppBar()),
        GetPage(name: '/group-creation', page: () => GroupCreationScreen()),
      ],
    );
  }
}
// Add this controller class for handling notification events
class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    print('Notification created: ${receivedNotification.id}');
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    print('Notification displayed: ${receivedNotification.id}');
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    print('Notification dismissed: ${receivedAction.id}');
  }
  /// Use this method to detect when the user taps on a notification or action button
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    print('Notification action received: ${receivedAction.id}');

    // Navigate to specific page or perform actions based on the notification
    if(receivedAction.channelKey == 'medicine_channel_id') {
      // Handle medicine reminder notification taps
      // Example: Get.to(() => MedicineDetailsPage(medicineId: receivedAction.payload?['medicineId']));
    }
  }
}