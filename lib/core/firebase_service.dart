import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../feature/main_screen/view/ម៉ោងបិទ.dart';

class FirebaseService extends GetxService {
  static FirebaseService get to => Get.find();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  bool _isTokenBeingSaved = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      print('🔔 FCM Local: 📱 Initializing local notifications...');

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('🔔 FCM Local: ✅ Local notifications initialized successfully');
    } catch (e) {
      print(
        '🔥 FCM Local Error: ❌ Failed to initialize local notifications: $e',
      );
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('🔔 FCM Permission: ✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('🔔 FCM Permission: ⚠️ User granted provisional permission');
      } else {
        print(
          '🔔 FCM Permission: ❌ User declined or has not accepted permission',
        );
        return;
      }

      // Get FCM token but don't save to database yet (wait for user authentication)
      await _getFCMTokenWithoutSaving();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app is terminated
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      print('🔥 FCM Error: ❌ Failed to initialize Firebase Messaging: $e');
    }
  }

  Future<void> _getFCMTokenWithoutSaving() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print(
        '🎫 FCM Token Generated: 📱 $_fcmToken (not saved yet - waiting for authentication)',
      );
    } catch (e) {
      print('🔥 FCM Error: ❌ Failed to get FCM token: $e');
    }
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('🎫 FCM Token Generated: 📱 $_fcmToken');

      if (_fcmToken != null) {
        await _saveTokenToDatabase(_fcmToken!);
      }
    } catch (e) {
      print('🔥 FCM Error: ❌ Failed to get FCM token: $e');
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    print('🔄 FCM Token Refreshed: 🔄 $token');
    _fcmToken = token;

    // Only save if user is authenticated
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _saveTokenToDatabase(token);
    } else {
      print(
        '🔄 FCM Token Refresh: ⏳ User not authenticated, token will be saved on next login',
      );
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print(
          '🚫 FCM Database: ❌ No authenticated user, cannot save FCM token',
        );
        return;
      }

      print(
        '💾 FCM Database: 🔍 Checking for existing tokens for user ${user.id}',
      );

      // Check if this exact token already exists for this user
      final existingTokens = await _supabase
          .from('fcm_tokens')
          .select('id, device_token, is_active')
          .eq('user_id', user.id)
          .eq('device_token', token);

      if (existingTokens.isNotEmpty) {
        // If token exists and is active, do nothing
        if (existingTokens.first['is_active'] == true) {
          print(
            '💾 FCM Database: ℹ️ Token already exists and is active for user ${user.id} (ID: ${existingTokens.first['id']})',
          );
          return;
        } else {
          // If token exists but is inactive, reactivate it
          print(
            '💾 FCM Database: 🔄 Reactivating existing token for user ${user.id} (ID: ${existingTokens.first['id']})',
          );
          await _supabase
              .from('fcm_tokens')
              .update({'is_active': true, 'updated_at': 'NOW()'})
              .eq('id', existingTokens.first['id']);
          print('💾 FCM Database: ✅ Token reactivated for user ${user.id}');
          return;
        }
      }

      print('💾 FCM Database: 🔄 Deactivating old tokens for user ${user.id}');
      // Deactivate old tokens for this user
      await _supabase
          .from('fcm_tokens')
          .update({'is_active': false})
          .eq('user_id', user.id);

      print('💾 FCM Database: ➕ Inserting new token for user ${user.id}');
      // Insert new token
      await _supabase.from('fcm_tokens').insert({
        'user_id': user.id,
        'device_token': token,
        'device_type': defaultTargetPlatform.name,
        'is_active': true,
      });

      print('💾 FCM Database: ✅ Token saved successfully for user ${user.id}');
    } catch (e) {
      print('🔥 FCM Database Error: ❌ Failed to save token: $e');
    }
  }

  /// Force refresh and save FCM token (useful when user logs in)
  Future<void> refreshAndSaveToken() async {
    try {
      // Prevent duplicate calls
      if (_isTokenBeingSaved) {
        print('🔄 FCM Refresh: ⏳ Token save already in progress, skipping...');
        return;
      }

      _isTokenBeingSaved = true;

      // If we already have a token, just save it to database
      if (_fcmToken != null) {
        print('🔄 FCM Refresh: 💾 Saving existing token to database');
        await _saveTokenToDatabase(_fcmToken!);
      } else {
        // If no token, get a new one
        await _getFCMToken();
      }
      print(
        '🔄 FCM Refresh: ✅ Token refreshed and saved for authenticated user',
      );
    } catch (e) {
      print('🔥 FCM Refresh Error: ❌ Failed to refresh token: $e');
    } finally {
      _isTokenBeingSaved = false;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print(
      '📨 FCM Message: 📱 Received foreground message: ${message.messageId}',
    );
    print('📨 FCM Message: 📝 Title: ${message.notification?.title}');
    print('📨 FCM Message: 📄 Body: ${message.notification?.body}');
    print('📨 FCM Message: 📊 Data: ${message.data}');

    // Show popup notification in foreground
    _showForegroundNotification(message);

    // Handle specific notification types
    await _processNotificationData(message.data);
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('👆 FCM Tap: 🎯 Notification tapped: ${message.messageId}');
    print('👆 FCM Tap: 📊 Data: ${message.data}');

    // Handle specific notification types and navigation
    await _processNotificationData(message.data);
    await _handleNotificationNavigation(message.data);
  }

  /// Process notification data based on type
  Future<void> _processNotificationData(Map<String, dynamic> data) async {
    try {
      final type = data['type'] as String?;

      switch (type) {
        case 'closing_number':
          await _handleClosingNumberNotification(data);
          break;
        case 'closing_time':
          await _handleClosingTimeNotification(data);
          break;
        default:
          print('📨 FCM Process: ℹ️ Unknown notification type: $type');
      }
    } catch (e) {
      print('🔥 FCM Process Error: ❌ Failed to process notification data: $e');
    }
  }

  /// Handle closing number notifications
  Future<void> _handleClosingNumberNotification(
    Map<String, dynamic> data,
  ) async {
    try {
      final closingNumber = data['closing_number'] as String?;
      final date = data['date'] as String?;
      final time = data['time'] as String?;

      print('🔢 FCM Closing Number: 📊 New closing number received');
      print('🔢 FCM Closing Number: 🎯 Number: $closingNumber');
      print('🔢 FCM Closing Number: 📅 Date: $date');
      print('🔢 FCM Closing Number: ⏰ Time: $time');

      // Here you can update your app state, save to local storage, etc.
      // For example, you might want to update a global state or trigger a refresh
    } catch (e) {
      print(
        '🔥 FCM Closing Number Error: ❌ Failed to handle closing number: $e',
      );
    }
  }

  /// Handle closing time notifications
  Future<void> _handleClosingTimeNotification(Map<String, dynamic> data) async {
    try {
      final timeName = data['time_name'] as String?;
      final startTime = data['start_time'] as String?;
      final endTime = data['end_time'] as String?;

      print('⏰ FCM Closing Time: 📊 New closing time received');
      print('⏰ FCM Closing Time: 🏷️ Time Name: $timeName');
      print('⏰ FCM Closing Time: 🕐 Start: $startTime');
      print('⏰ FCM Closing Time: 🕐 End: $endTime');

      // Here you can update your app state, save to local storage, etc.
      // For example, you might want to update closing time schedules
    } catch (e) {
      print('🔥 FCM Closing Time Error: ❌ Failed to handle closing time: $e');
    }
  }

  /// Show popup notification when app is in foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? 'You have a new message';

      print('🔔 FCM Foreground: 📱 Showing local notification');
      print('🔔 FCM Foreground: 📝 Title: $title');
      print('🔔 FCM Foreground: 📄 Body: $body');

      // Create notification details
      const androidDetails = AndroidNotificationDetails(
        'lottery_notifications',
        'Lottery Notifications',
        channelDescription: 'Notifications for lottery app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show local notification
      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        notificationDetails,
        payload: message.data.toString(),
      );

      print('🔔 FCM Foreground: ✅ Local notification shown successfully');
    } catch (e) {
      print('🔥 FCM Foreground Error: ❌ Failed to show local notification: $e');
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('👆 FCM Local Tap: 🎯 Local notification tapped');
    print('👆 FCM Local Tap: 📊 Payload: ${response.payload}');

    if (response.payload != null) {
      try {
        // Parse the payload and handle navigation
        final payload = response.payload!;
        print('👆 FCM Local Tap: 📝 Parsing payload: $payload');

        // Navigate to closing time screen directly (no snackbar)
        Get.to(() => const ClosingTimeScreen());
      } catch (e) {
        print(
          '🔥 FCM Local Tap Error: ❌ Failed to handle local notification tap: $e',
        );
      }
    }
  }

  /// Handle notification navigation based on action
  Future<void> _handleNotificationNavigation(Map<String, dynamic> data) async {
    try {
      final action = data['action'] as String?;

      switch (action) {
        case 'open_closing_numbers':
          print('🧭 FCM Navigation: 📊 Navigating to closing numbers');
          // Navigate to closing numbers screen
          Get.toNamed('/closing-numbers');
          break;
        case 'open_closing_time':
          print('🧭 FCM Navigation: ⏰ Navigating to closing time');
          // Navigate to closing time screen
          Get.to(() => const ClosingTimeScreen());
          break;
        default:
          print(
            '🧭 FCM Navigation: ℹ️ No specific navigation for action: $action',
          );
      }
    } catch (e) {
      print('🔥 FCM Navigation Error: ❌ Failed to handle navigation: $e');
    }
  }

  Future<void> deleteFCMToken() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print(
          '🚫 FCM Delete: ❌ No authenticated user, cannot delete FCM token',
        );
        return;
      }

      print('🗑️ FCM Delete: 🔍 Deleting tokens for user ${user.id}');

      // Delete all tokens for this user (not just deactivate)
      final result = await _supabase
          .from('fcm_tokens')
          .delete()
          .eq('user_id', user.id)
          .select('id');

      print(
        '🗑️ FCM Delete: ✅ Deleted ${result.length} token(s) for user ${user.id}',
      );

      // Clear the token from memory
      _fcmToken = null;
      print('🗑️ FCM Delete: 🧹 Cleared token from memory');
    } catch (e) {
      print('🔥 FCM Delete Error: ❌ Failed to delete token: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('📢 FCM Topic: ✅ Subscribed to topic: $topic');
    } catch (e) {
      print('🔥 FCM Topic Error: ❌ Failed to subscribe to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('📢 FCM Topic: ❌ Unsubscribed from topic: $topic');
    } catch (e) {
      print('🔥 FCM Topic Error: ❌ Failed to unsubscribe from topic: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print(
    '📨 FCM Background: 🌙 Handling background message: ${message.messageId}',
  );
  print('📨 FCM Background: 📝 Title: ${message.notification?.title}');
  print('📨 FCM Background: 📄 Body: ${message.notification?.body}');
  print('📨 FCM Background: 📊 Data: ${message.data}');

  // Process notification data in background
  await _processBackgroundNotificationData(message.data);
}

/// Process notification data in background
Future<void> _processBackgroundNotificationData(
  Map<String, dynamic> data,
) async {
  try {
    final type = data['type'] as String?;

    switch (type) {
      case 'closing_number':
        print('🔢 FCM Background: 📊 Processing closing number in background');
        print('🔢 FCM Background: 🎯 Number: ${data['closing_number']}');
        print('🔢 FCM Background: 📅 Date: ${data['date']}');
        print('🔢 FCM Background: ⏰ Time: ${data['time']}');
        break;
      case 'closing_time':
        print('⏰ FCM Background: 📊 Processing closing time in background');
        print('⏰ FCM Background: 🏷️ Time Name: ${data['time_name']}');
        print('⏰ FCM Background: 🕐 Start: ${data['start_time']}');
        print('⏰ FCM Background: 🕐 End: ${data['end_time']}');

        // Handle closing time navigation in background
        final action = data['action'] as String?;
        if (action == 'open_closing_time') {
          print('⏰ FCM Background: 🧭 Navigating to closing time screen');
          // Note: Navigation in background handler should be minimal
          // The actual navigation will happen when user taps the notification
        }
        break;
      default:
        print('📨 FCM Background: ℹ️ Unknown notification type: $type');
    }
  } catch (e) {
    print(
      '🔥 FCM Background Error: ❌ Failed to process background notification: $e',
    );
  }
}
