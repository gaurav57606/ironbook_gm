import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';

// ignore: subtype_of_sealed_class
class MockFirebaseFirestore extends Fake implements FirebaseFirestore {}
// ignore: subtype_of_sealed_class
class MockCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {}

// DocumentReference and Query are sealed, use Fake with Mock naming for compatibility
// ignore: subtype_of_sealed_class
class MockDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {}
// ignore: subtype_of_sealed_class
class MockQuery extends Fake implements Query<Map<String, dynamic>> {}
// ignore: subtype_of_sealed_class
class MockQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {}
// ignore: subtype_of_sealed_class
class MockQueryDocumentSnapshot extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {}
