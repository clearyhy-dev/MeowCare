import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/enums.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 前台仅支持 Google 登录；邮箱密码注册/登录已移除。
  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    await _upsertUserDocument(userCred.user!);
  }

  /// Retry Firestore ops on transient unavailable (e.g. cloud_firestore/unavailable).
  static Future<T> _retryFirestore<T>(Future<T> Function() fn, {int maxAttempts = 3}) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } on FirebaseException catch (e) {
        if ((e.code == 'unavailable' || e.code == 'resource-exhausted') && attempt < maxAttempts - 1) {
          attempt++;
          await Future<void>.delayed(Duration(milliseconds: 500 * (1 << attempt)));
          continue;
        }
        rethrow;
      }
    }
  }

  Future<void> _upsertUserDocument(User firebaseUser) async {
    final uid = firebaseUser.uid;
    final ref = _firestore.collection(AppConstants.usersCollection).doc(uid);
    final existing = await _retryFirestore(() => ref.get());
    DateTime? createdAt;
    String? familyId;
    if (existing.exists && existing.data() != null) {
      final d = existing.data()!['createdAt'];
      createdAt = d is Timestamp ? d.toDate() : DateTime.now();
      familyId = existing.data()!['familyId'] as String?;
    } else {
      createdAt = DateTime.now();
    }
    final user = UserModel(
      uid: uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL ?? '',
      subscriptionStatus: SubscriptionStatus.free,
      createdAt: createdAt,
      familyId: familyId,
    );
    if (!existing.exists) {
      await _retryFirestore(() => ref.set(user.toMap()));
    } else {
      await _retryFirestore(() => ref.update({
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
      }));
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }
}
