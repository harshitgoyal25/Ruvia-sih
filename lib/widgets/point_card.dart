import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppBarPointsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('runs')
          .get(),
      builder: (context, snapshot) {
        int totalPoints = 0;

        // If data is loaded, calculate.
        if (snapshot.hasData && snapshot.data != null) {
          for (var doc in snapshot.data!.docs) {
            final pointsValue = doc['xp'];
            if (pointsValue is int) {
              totalPoints += pointsValue;
            } else if (pointsValue is double) {
              totalPoints += pointsValue.toInt();
            } else if (pointsValue is String) {
              totalPoints += int.tryParse(pointsValue) ?? 0;
            } else {
              totalPoints += 0;
            }
          }
        }

        // Show a small faded card instantly: shows "0" if loading or if no data.
        return Card(
          color: const Color.fromARGB(255, 34, 34, 38),
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, color: Colors.amber[700], size: 20),
                const SizedBox(width: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    '$totalPoints',
                    key: ValueKey(totalPoints), // smooth transition
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: snapshot.connectionState == ConnectionState.done
                          ? const Color.fromARGB(221, 240, 240, 240)
                          : Colors.grey[600], // faded if loading
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
