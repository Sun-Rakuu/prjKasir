import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService._();

  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String role = 'cashier',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'createdAt': Timestamp.now(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (_auth.currentUser == null) return null;

    final doc =
        await _firestore.collection('users').doc(_auth.currentUser!.uid).get();

    return doc.data();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<AppUser?> getCurrentUser() async {
    if (_auth.currentUser == null) return null;

    final doc =
        await _firestore.collection('users').doc(_auth.currentUser!.uid).get();

    if (!doc.exists) return null;

    return AppUser.fromMap(doc.data()!);
  }
}
