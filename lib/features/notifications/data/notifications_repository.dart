import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_runtime.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/notification_model.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) throw StateError('Firebase غير مهيأ لهذا المشروع.');
  return NotificationsRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

class NotificationsRepository {
  NotificationsRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<List<NotificationModel>> watchCurrentUserNotifications({
    int limit = 20,
  }) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const <NotificationModel>[]);
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NotificationModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<int> watchUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<void> markAsRead(NotificationModel notification) async {
    final user = _requireUser();
    if (notification.userId != user.uid) {
      throw StateError('لا تملك صلاحية تحديث هذا الإشعار.');
    }
    if (notification.isRead) return;
    await _firestore.collection('notifications').doc(notification.id).update({
      'isRead': true,
    });
  }

  /// يضيف إشعار تغير الحالة إلى Batch تحديث الطلب نفسه.
  /// هذا الربط مطلوب كي تثبت قواعد Firestore أن صاحب الشركة يحدّث طلبًا يخصه.
  NotificationModel createNotification({
    required WriteBatch batch,
    required ApplicationModel application,
    required ApplicationStatus newStatus,
  }) {
    final document = _firestore.collection('notifications').doc();
    final notification = NotificationModel(
      id: document.id,
      userId: application.seekerId,
      title: 'تحديث حالة الطلب',
      message: 'تم تحديث حالة طلبك إلى: ${newStatus.arabicLabel}.',
      isRead: false,
      createdAt: DateTime.now().toUtc(),
      applicationId: application.id,
    );
    batch.set(document, {
      ...notification.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return notification;
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null)
      throw StateError('سجل الدخول أولًا للوصول إلى الإشعارات.');
    return user;
  }
}
