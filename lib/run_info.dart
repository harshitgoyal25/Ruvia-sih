import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class RunInfoPage extends StatelessWidget {
  final String userId;
  final String runDocId;
  const RunInfoPage({required this.userId, required this.runDocId, Key? key})
    : super(key: key);

  Future<Map<String, dynamic>?> fetchRunInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('runs')
        .doc(runDocId)
        .get();
    return doc.data();
  }

  Future<void> deleteRun(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      // Delete from user's runs
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('runs')
          .doc(runDocId)
          .delete();
      // Delete from publicRuns
      await FirebaseFirestore.instance
          .collection('publicRuns')
          .doc(runDocId)
          .delete();
      if (context.mounted) {
        Navigator.of(context).pop(); // Close the RunInfoPage
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Run deleted successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting run: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF79c339);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 13, 15, 12),
        elevation: 3,
        title: Text(
          "Run Stats",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.2,
            color: accent,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFF111112),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchRunInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text(
                "Run not found.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final distance = ((data['distance'] ?? 0));
          final area = (data['areaCaptured'] ?? 0).toStringAsFixed(2);
          final timeTaken = data['timeTaken'] ?? 0;
          final xp = data['xp'] ?? 0;
          final pace = (data['pace'] != null && data['pace'] > 0)
              ? "${(data['pace'] / 60).floor()}:${(data['pace'] % 60).toStringAsFixed(0).padLeft(2, '0')}"
              : "--";
          final userName = data['userName'] ?? "Unknown";
          final timestamp =
              data['timestamp'] != null && data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).toDate().toString()
              : "--";
          final points =
              (data['locationData'] as List<dynamic>?)
                  ?.map((e) => LatLng(e['lat'], e['lng']))
                  .toList() ??
              [];

          final isMine = myUid == userId;

          return LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      userName,
                                      style: GoogleFonts.montserrat(
                                        color: accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        letterSpacing: 0.6,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.event,
                                    color: Colors.white70,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      timestamp,
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white70,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _statCard(
                                      icon: Icons.timeline,
                                      label: "Distance",
                                      value: "$distance m",
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: _statCard(
                                      icon: Icons.public,
                                      label: "Area",
                                      value: "$area m²",
                                      color: const Color(0xFF38cd94),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: _statCard(
                                      icon: Icons.star_rounded,
                                      label: "XP",
                                      value: xp.toString(),
                                      color: const Color(0xffe3d902),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _statCard(
                                      icon: Icons.timer,
                                      label: "Time",
                                      value: "$timeTaken s",
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: _statCard(
                                      icon: Icons.speed,
                                      label: "Pace",
                                      value: "$pace min/km",
                                      color: Colors.deepOrangeAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Route Points",
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(
                                  maxHeight: 130,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 14,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text(
                                    points
                                        .map(
                                          (e) =>
                                              "(${e.latitude.toStringAsFixed(5)}, ${e.longitude.toStringAsFixed(5)})",
                                        )
                                        .join("\n"),
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white70,
                                      fontSize: 13.5,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (isMine)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ElevatedButton(
                      onPressed: () async {
                        bool? confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF232323),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            title: Text(
                              "Delete Run?",
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent,
                              ),
                            ),
                            content: Text(
                              "Are you sure you want to delete this run?\nThis cannot be undone.",
                              style: GoogleFonts.montserrat(
                                color: Colors.white70,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.montserrat(),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text(
                                  "Delete",
                                  style: GoogleFonts.montserrat(),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await deleteRun(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        "Delete This Run",
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 0.07,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
