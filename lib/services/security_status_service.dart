import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityStatusService {
  SecurityStatusService._();

  static final SecurityStatusService instance = SecurityStatusService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveSecurityStatus({required String lockType}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No signed-in user found.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'securityConfigured': true,
      'lockType': lockType,
    }, SetOptions(merge: true));
  }

  Future<bool> hasExistingSecuritySetup() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final document = await _firestore.collection('users').doc(user.uid).get();

    final data = document.data();

    if (data == null) {
      return false;
    }

    return data['securityConfigured'] == true;
  }

  Future<String?> getLockType() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final document = await _firestore.collection('users').doc(user.uid).get();

    final data = document.data();

    if (data == null) {
      return null;
    }

    return data['lockType'] as String?;
  }
}
