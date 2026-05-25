import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import '../env_config.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handling
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Scopes required for FCM HTTP v1 API
  final _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  Future<void> init() async {
    try {
      // 1. Setup Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Request Permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Explicitly request Android 13+ permissions via local notifications plugin
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // 3. Initialize Local Notifications for Foreground display
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);
      await _localNotificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {},
      );

      // Explicitly create notification channel so Android immediately adds app to the Settings list
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        EnvConfig.notificationChannelId,
        EnvConfig.notificationChannelName,
        description: 'AgriDirect Live System Notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 4. Retrieve and sync FCM Token on startup if user is already logged in
      try {
        final token = await _fcm.getToken();
        if (token != null) {
          await _syncTokenToSupabase(token);
        }
      } catch (e) {
        debugPrint("FCM GetToken error: $e");
      }

      // 5. Dynamic Sync: Listen to Auth State changes to register token the moment a user logs in!
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null && session.user.id.isNotEmpty) {
          try {
            final token = await _fcm.getToken();
            if (token != null) {
              await _syncTokenToSupabase(token);
            }
          } catch (e) {
            debugPrint("FCM GetToken onAuth error: $e");
          }
        }
      });

      // 6. Listen to token refreshes
      _fcm.onTokenRefresh.listen(_syncTokenToSupabase);

      // 7. Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });
    } catch (e) {
      debugPrint("Firebase Messaging initialization failed (likely unsupported platform or missing play services): $e");
    }
  }

  Future<void> _syncTokenToSupabase(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Use secure SECURITY DEFINER RPC to bypass RLS conflicts on same-device switches
      await Supabase.instance.client.rpc(
        'register_device_token',
        params: {
          'fcm_token': token,
          'client_platform': Platform.operatingSystem,
        },
      );
      debugPrint('FCM Token synced successfully via RPC');
    } catch (e) {
      debugPrint('FCM Token Sync Error (RPC): $e');
      // Fallback to standard upsert if RPC is not yet loaded in database
      try {
        await Supabase.instance.client.from('device_tokens').upsert(
          {
            'user_id': userId,
            'token': token,
            'platform': Platform.operatingSystem,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'token',
        );
      } catch (err) {
        debugPrint('FCM Token Sync Fallback Error: $err');
      }
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    if (message.notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      EnvConfig.notificationChannelId,
      EnvConfig.notificationChannelName,
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF1B6B3A),
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    _localNotificationsPlugin.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  /// Send an FCM Push Notification to another user securely via FCM HTTP v1 API
  Future<void> sendPushNotification({
    required String receiverId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // 1. Fetch receiver's FCM tokens
      final response = await Supabase.instance.client
          .from('device_tokens')
          .select('token')
          .eq('user_id', receiverId);
          
      if (response.isEmpty) {
        debugPrint("No device token found for user $receiverId");
        return; // User has no registered devices
      }

      // 2. Load Service Account JSON
      final jsonString = await rootBundle.loadString('assets/firebase_service_account.json');
      final serviceAccount = auth.ServiceAccountCredentials.fromJson(jsonString);

      // 3. Get OAuth2 Token
      final client = await auth.clientViaServiceAccount(serviceAccount, _scopes);
      final accessToken = client.credentials.accessToken.data;
      final projectId = serviceAccount.projectId;

      // 4. Send to all registered devices of the user
      for (var row in response) {
        final fcmToken = row['token'] as String;
        
        final payload = {
          "message": {
            "token": fcmToken,
            "notification": {
              "title": title,
              "body": body,
            },
            "data": data ?? {},
          }
        };

        final result = await http.post(
          Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(payload),
        );

        if (result.statusCode != 200) {
          debugPrint("Failed to send FCM: ${result.body}");
        } else {
          debugPrint("FCM Push sent successfully to $fcmToken");
        }
      }
      
      client.close();
      
    } catch (e) {
      debugPrint("Error sending push notification: $e");
    }
  }
}
