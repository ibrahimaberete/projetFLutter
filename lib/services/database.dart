import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';

class DatabaseService {
  final String uid;

  DatabaseService(this.uid);

  final CollectionReference<Map<String, dynamic>> userCollection =
      FirebaseFirestore.instance.collection("users");

  Future<void> saveUser(String name, String email) async {
    return await userCollection.doc(uid).set({'name': name, 'email': email});
  }

  Future<void> saveToken(String? token) async {
    return await userCollection.doc(uid).update({'token': token});
  }

  AppUserData _userFromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    var data = snapshot.data();
    if (data == null) throw Exception("user not found");
    return AppUserData(
        uid: snapshot.id,
        name: data['name'],
        email: data['email'],
        favorites: []);
  }

  Future<void> updateUserFavorites(String uid, List<String> favorites) async {
    {
      return await userCollection.doc(uid).update({'favorites': favorites});
    }
  }

  Future<List<String>> getUserFavorites(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await userCollection.doc(uid).get();
      print('data $snapshot');
      if (snapshot.exists) {
        print('data $snapshot');
        Map<String, dynamic> userData = snapshot.data()!;
        List<String> favorites = List<String>.from(userData['favorites'] ?? []);
        return favorites;
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching favorites: $e");
      return [];
    }
  }

  Stream<AppUserData> get user {
    return userCollection.doc(uid).snapshots().map(_userFromSnapshot);
  }

  List<AppUserData> _userListFromSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map((doc) {
      return _userFromSnapshot(doc);
    }).toList();
  }

  Stream<List<AppUserData>> get users {
    return userCollection.snapshots().map(_userListFromSnapshot);
  }
}
