import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user_activity_model.dart';

class UserActivityService {
  static final UserActivityService instance = UserActivityService._internal();

  UserActivityService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  CollectionReference get _activityRef => _firestore.collection('user_activity');

  // In-memory buffer of recent activities for rapid local scoring and guest session tracking
  final List<UserActivity> _localActivityBuffer = [];

  List<UserActivity> get localActivities => List.unmodifiable(_localActivityBuffer);

  String get _currentUserId {
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        return user?.uid ?? 'guest_session';
      }
    } catch (_) {}
    return 'guest_session';
  }

  /// Generic asynchronous activity logger
  Future<void> logActivity({
    required ActivityType activityType,
    String? userId,
    String productId = '',
    String productName = '',
    String categoryId = '',
    String categoryName = '',
  }) async {
    final uid = (userId != null && userId.isNotEmpty) ? userId : _currentUserId;

    final localItem = UserActivity(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      userId: uid,
      productId: productId,
      productName: productName,
      categoryId: categoryId,
      categoryName: categoryName,
      activityType: activityType,
      timestamp: DateTime.now(),
    );

    // Keep up to 100 recent actions in local memory
    _localActivityBuffer.insert(0, localItem);
    if (_localActivityBuffer.length > 100) {
      _localActivityBuffer.removeLast();
    }

    // Don't block UI; write to Firestore in background if Firebase is active
    if (uid.isNotEmpty && uid != 'guest_session') {
      try {
        if (Firebase.apps.isNotEmpty) {
          _activityRef.add(localItem.toMap()).catchError((e) {
            debugPrint('[UserActivityService] Firestore activity write error: $e');
            return docRefFallback();
          });
        }
      } catch (e) {
        debugPrint('[UserActivityService] Error queueing activity: $e');
      }
    }
  }

  static DocumentReference docRefFallback() {
    return FirebaseFirestore.instance.collection('user_activity').doc();
  }

  // Convenience helper methods
  void logProductView({
    required String productId,
    required String productName,
    String categoryId = '',
    String categoryName = '',
  }) {
    logActivity(
      activityType: ActivityType.productView,
      productId: productId,
      productName: productName,
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }

  void logAddToCart({
    required String productId,
    required String productName,
    String categoryId = '',
    String categoryName = '',
  }) {
    logActivity(
      activityType: ActivityType.addToCart,
      productId: productId,
      productName: productName,
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }

  void logRemoveFromCart({
    required String productId,
    required String productName,
    String categoryId = '',
    String categoryName = '',
  }) {
    logActivity(
      activityType: ActivityType.removeFromCart,
      productId: productId,
      productName: productName,
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }

  void logPurchase({
    required List<Map<String, dynamic>> items,
  }) {
    for (final item in items) {
      logActivity(
        activityType: ActivityType.purchase,
        productId: (item['productId'] ?? '').toString(),
        productName: (item['productName'] ?? item['title'] ?? '').toString(),
        categoryName: (item['category'] ?? '').toString(),
      );
    }
  }

  void logSearch(String query) {
    if (query.trim().isEmpty) return;
    logActivity(
      activityType: ActivityType.search,
      productName: query.trim(),
    );
  }

  void logCategoryView(String categoryName, {String categoryId = ''}) {
    if (categoryName.trim().isEmpty) return;
    logActivity(
      activityType: ActivityType.categoryView,
      categoryId: categoryId,
      categoryName: categoryName.trim(),
    );
  }

  /// Retrieve recent activities for the given user, combining Firestore history and local buffer
  Future<List<UserActivity>> getRecentActivities({String? userId, int limit = 50}) async {
    final uid = (userId != null && userId.isNotEmpty) ? userId : _currentUserId;
    final List<UserActivity> results = [];

    // 1. Add matching local activities
    results.addAll(_localActivityBuffer.where((a) => a.userId == uid));

    // 2. Fetch from Firestore if user is authenticated and Firebase is initialized
    if (uid.isNotEmpty && uid != 'guest_session') {
      try {
        if (Firebase.apps.isNotEmpty) {
          final snap = await _activityRef
              .where('userId', isEqualTo: uid)
              .limit(limit)
              .get()
              .timeout(const Duration(seconds: 3));

          for (final doc in snap.docs) {
            final act = UserActivity.fromFirestore(doc);
            if (!results.any((r) => r.id == act.id || (r.productId == act.productId && r.activityType == act.activityType && r.timestamp.difference(act.timestamp).abs().inSeconds < 5))) {
              results.add(act);
            }
          }
        }
      } catch (e) {
        debugPrint('[UserActivityService] getRecentActivities query error: $e');
      }
    }

    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results.take(limit).toList();
  }
}
