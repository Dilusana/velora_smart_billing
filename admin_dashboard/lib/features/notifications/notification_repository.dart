import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/models.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _notificationsRef => _firestore.collection('notifications');

  /// Streams real-time notifications history
  Stream<List<AdminNotificationModel>> watchNotifications() {
    return _notificationsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        return AdminNotificationModel.fromMap(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    });
  }

  /// Sends a push notification by creating a record in Firestore
  /// (which triggers the secure backend Cloud Function)
  Future<String> sendNotification({
    required String title,
    required String message,
    required String targetType,
    String targetUserId = '',
    String targetUserName = 'All Users',
  }) async {
    final docRef = _notificationsRef.doc();
    final model = AdminNotificationModel(
      id: docRef.id,
      title: title,
      message: message,
      targetType: targetType,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      status: 'Pending',
      createdAt: DateTime.now(),
    );

    await docRef.set(model.toMap());
    return docRef.id;
  }

  /// Delete a notification record from history
  Future<void> deleteNotification(String id) async {
    await _notificationsRef.doc(id).delete();
  }
}
