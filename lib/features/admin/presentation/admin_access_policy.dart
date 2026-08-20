import '../../../shared/models/user_model.dart';

/// يحدد ما إذا كان ملف Firestore يمنح المستخدم صلاحية الإدارة حاليًا.
///
/// لا تكفي جلسة Firebase وحدها للوصول؛ يجب أن يكون الدور إداريًا والحساب نشطًا.
bool hasAdminAccess(UserModel? profile) =>
    profile != null && profile.role == UserRole.admin && profile.isActive;
