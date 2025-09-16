import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ruvia/widgets/floating_profile_button.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final String uid;

  @override
  void initState() {
    super.initState();
    // Safe fallback to current user if userId isn't provided
    uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF63E352);
    final bgColor = const Color(0xFF0E0E0F);
    final cardColor = const Color(0xFF27272A).withOpacity(0.55);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 2,
        title: Text(
          'RUVIA',
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.montserrat().fontFamily,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accentColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: FloatingProfileButton(avatarImage: "assets/avator.png"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? {};
                final username = data['name'] ?? 'Username';
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: accentColor,
                      child: Icon(Icons.person, size: 56, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      username,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: GoogleFonts.montserrat().fontFamily,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('runs')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final runs = snapshot.data?.docs ?? [];
                    int totalRuns = runs.length;
                    double totalDistance = 0;
                    double totalArea = 0;

                    for (var run in runs) {
                      final data = run.data();
                      final distance = data['distance'] ?? 0;
                      final area = data['areaCaptured'] ?? 0;
                      totalDistance += distance is num
                          ? distance.toDouble()
                          : 0;
                      totalArea += area is num ? area.toDouble() : 0;
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('Total Runs', '$totalRuns'),
                        _statItem(
                          'Distance (Km)',
                          (totalDistance / 1000).toStringAsFixed(2),
                        ),
                        _statItem(
                          'Area (Km²)',
                          (totalArea / 1000000).toStringAsFixed(3),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Run Logs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('runs')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final runs = snapshot.data!.docs;
                    if (runs.isEmpty) {
                      return Center(
                        child: Text(
                          'No runs recorded yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    return Column(
                      children: runs.map((run) {
                        final data = run.data();
                        final timestamp = data['timestamp'];
                        DateTime date = timestamp is Timestamp
                            ? timestamp.toDate()
                            : DateTime.now();
                        final formattedDate = DateFormat(
                          'EEE\ndd MMM',
                        ).format(date);
                        final distance = (data['distance'] ?? 0).toDouble();
                        final duration = (data['timeTaken'] ?? 0).toDouble();
                        final pace = (data['pace'] ?? 0).toDouble();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: _runLogItem(
                            formattedDate,
                            _formatDuration(duration),
                            (distance / 1000).toStringAsFixed(2),
                            _formatPace(pace),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.montserrat().fontFamily,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontFamily: GoogleFonts.montserrat().fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _runLogItem(
    String date,
    String duration,
    String distance,
    String avgPace,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3C).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 70,
            child: Text(
              date,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: GoogleFonts.montserrat().fontFamily,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  duration,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$distance Km',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Distance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  avgPace,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Avg Pace',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(double durationInSeconds) {
    int totalSeconds = durationInSeconds.toInt();
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatPace(double paceInSeconds) {
    if (paceInSeconds <= 0) {
      return '0:00';
    }
    int totalSeconds = paceInSeconds.toInt();
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
