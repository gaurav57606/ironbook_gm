import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    debugPrint('--- CLOUD PING STARTING ---');
  
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase Initialized.');

    final auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    
    if (user == null) {
      debugPrint('⚠️ No user logged in. Attempting Anonymous Sign-in...');
      final cred = await auth.signInAnonymously();
      user = cred.user;
      debugPrint('✅ Signed in as: ${user?.uid}');
    } else {
      debugPrint('✅ User already logged in: ${user.uid}');
    }

    debugPrint('📡 Attempting to write to Firestore...');
    final testRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cloud_verify')
        .doc('ping');

    await testRef.set({
      'status': 'success',
      'timestamp': FieldValue.serverTimestamp(),
      'message': 'Cloud Firestore is reachable from India region!',
    });
    debugPrint('✅ Write Successful.');

    debugPrint('📡 Attempting to read back from Firestore...');
    final doc = await testRef.get();
    if (doc.exists) {
      debugPrint('✅ Read Successful: ${doc.data()}');
      debugPrint('\n🎉 FIREBASE IS PROPERLY SET UP AND REACHABLE!');
    } else {
      debugPrint('❌ Read Failed: Document does not exist.');
    }

  } catch (e) {
    debugPrint('❌ ERROR: $e');
  }
}









