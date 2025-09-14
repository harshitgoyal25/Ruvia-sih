import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static Future<String> getUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snapshot.data() as Map<String, dynamic>?;
      return data != null && data.containsKey('name') ? data['name'] : 'No Name';
    }
    return 'Guest';
  }
  static Future<String> getUserColor() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snapshot.data() as Map<String, dynamic>?;
    return data != null && data.containsKey('color') ? data['color'] : '#FF5733'; // default color
  }
  return '#FF5733'; // default color for guests or errors
}

}
