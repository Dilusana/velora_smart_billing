import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_notification_model.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'velora_notifications',
    'Velora Notifications',
    description: 'Channel for Velora Supermarket alerts and promotions.',
    importance: Importance.high,
  );

  /// Initializes FCM, permissions, listeners, and local notifications
  Future<void> init() async {
    try {
      // 1. Request notification permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User notification permission status: ${settings.authorizationStatus}');

      // 2. Setup Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Initialize local notifications for Foreground display
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Foreground notification tapped: ${response.payload}');
        },
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 4. Update Presentation Options for iOS
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Subscribe to broadcast topic
      try {
        await _fcm.subscribeToTopic('all_users');
        debugPrint('Subscribed to FCM topic: all_users');
      } catch (e) {
        debugPrint('Topic subscription error: $e');
      }

      // 6. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground FCM message: ${message.notification?.title}');
        _showForegroundNotification(message);
      });

      // 7. Register / refresh FCM Token for the current user
      await syncFcmToken();
      _fcm.onTokenRefresh.listen((token) {
        _saveTokenToFirestore(token);
      });
    } catch (e) {
      debugPrint('PushNotificationService init error: $e');
    }
  }

  /// Displays HUD / notification banner when app is in foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Saves FCM device token to the user document in Firestore
  Future<void> syncFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('customers').doc(user.uid);
        await docRef.set({
          'fcmToken': token,
          'fcmTokens': FieldValue.arrayUnion([token]),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token synced to Firestore for user: ${user.uid}');
      }
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  final Set<String> _localReadIds = {};
  final Set<String> _localDeletedIds = {};

  static final List<UserNotificationModel> defaultNotifications = [
    UserNotificationModel(
      id: 'velora_welcome',
      title: 'Welcome to Velora Supermarket! 🎉',
      message: 'Explore 100% fresh grocery, organic fruits & vegetables with quick delivery.',
      targetType: 'all',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    UserNotificationModel(
      id: 'velora_promo_1',
      title: 'Weekend Mega Savings 🥦',
      message: 'Get 10% instant discount on orders above Rs 1,000. Use coupon code VELORA10.',
      targetType: 'all',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    UserNotificationModel(
      id: 'velora_delivery_1',
      title: 'Free Express Delivery 🚚',
      message: 'Your neighborhood supermarket is now open 24/7 for fast home deliveries.',
      targetType: 'all',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  /// Streams user notifications from Firestore (supporting both 'notifications' and 'user_notifications')
  Stream<List<UserNotificationModel>> getUserNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final email = user?.email ?? '';

    return _firestore
        .collection('notifications')
        .snapshots()
        .map((snap) {
      final List<UserNotificationModel> list = [];

      DateTime parseDate(dynamic val) {
        if (val is Timestamp) return val.toDate();
        if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
        return DateTime.now();
      }

      if (snap.docs.isNotEmpty) {
        for (final doc in snap.docs) {
          if (_localDeletedIds.contains(doc.id)) continue;
          final data = doc.data();
          final t = (data['targetType'] ?? 'all').toString().toLowerCase();
          final targetUser = (data['targetUserId'] ?? '').toString();

          // Target audience filter
          if (t == 'all' || t.isEmpty || (uid.isNotEmpty && targetUser == uid) || (email.isNotEmpty && targetUser == email)) {
            final isReadDb = data['isRead'] == true;
            list.add(UserNotificationModel(
              id: doc.id,
              notificationId: doc.id,
              title: (data['title'] ?? 'Velora Notification').toString(),
              message: (data['message'] ?? data['body'] ?? '').toString(),
              targetType: t,
              targetUserId: targetUser,
              isRead: isReadDb || _localReadIds.contains(doc.id),
              createdAt: parseDate(data['createdAt']),
            ));
          }
        }
      }

      if (list.isEmpty) {
        // Return default notifications if no notifications created yet in Firestore
        return defaultNotifications.where((n) => !_localDeletedIds.contains(n.id)).map((n) {
          return n.copyWith(isRead: n.isRead || _localReadIds.contains(n.id));
        }).toList();
      }

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((_) {
      return defaultNotifications.where((n) => !_localDeletedIds.contains(n.id)).map((n) {
        return n.copyWith(isRead: n.isRead || _localReadIds.contains(n.id));
      }).toList();
    });
  }

  /// Marks a notification as read
  Future<void> markAsRead(String id) async {
    _localReadIds.add(id);
    try {
      await _firestore.collection('notifications').doc(id).update({'isRead': true});
    } catch (_) {}
    try {
      await _firestore.collection('user_notifications').doc(id).update({'isRead': true});
    } catch (_) {}
  }

  /// Marks all notifications as read
  Future<void> markAllAsRead(List<UserNotificationModel> notifications) async {
    for (final notif in notifications) {
      _localReadIds.add(notif.id);
    }
    final batch = _firestore.batch();
    for (final notif in notifications) {
      if (!notif.isRead) {
        batch.update(_firestore.collection('notifications').doc(notif.id), {'isRead': true});
      }
    }
    try {
      await batch.commit();
    } catch (_) {}
  }

  /// Delete notification from history
  Future<void> deleteNotification(String id) async {
    _localDeletedIds.add(id);
    try {
      await _firestore.collection('notifications').doc(id).delete();
    } catch (_) {}
    try {
      await _firestore.collection('user_notifications').doc(id).delete();
    } catch (_) {}
  }
}
