import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/bottomBar.dart';
import 'widgets/floating_profile_button.dart';

class InsightsPage extends StatefulWidget {
  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  int _currentIndex = 1;

  

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 13, 15, 12),
        elevation: 3,
        title: const Text(
          "Ruvia",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Color.fromARGB(255, 99, 227, 82),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.notifications,
            color: Color.fromARGB(255, 99, 227, 82),
          ),
          onPressed: () {
            // TODO: handle notification tap
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: FloatingProfileButton(avatarImage: "assets/avator.png"),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 14, 14, 15).withOpacity(1),
              image: DecorationImage(
                image: const AssetImage('assets/runner.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.40),
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Achievements Section
                  Card(
                    color: const Color(0xFF27272A).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Achievements',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 255, 255, 255),
                              fontFamily: GoogleFonts.montserrat().fontFamily,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _AchievementCard(
                            icon: Icons.emoji_events,
                            title: 'Marathon Finisher',
                            description:
                                'Completed a full marathon in under 4 hours.',
                            progress: 1.0,
                          ),
                          const SizedBox(height: 12),
                          _AchievementCard(
                            icon: Icons.directions_run,
                            title: '100km Running',
                            description:
                                'Accumulated 100km of running this year.',
                            progress: 0.65,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Section
                  Card(
                    color: const Color(0xFF27272A).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stats',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 255, 255, 255),
                              fontFamily: GoogleFonts.montserrat().fontFamily,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _StatTile(
                            label: 'Total Runs',
                            value: '45',
                            icon: Icons.timeline,
                          ),
                          _StatTile(
                            label: 'Total Distance',
                            value: '320 km',
                            icon: Icons.map,
                          ),
                          _StatTile(
                            label: 'Personal Best',
                            value: '5 min/km',
                            icon: Icons.speed,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double progress;

  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(200, 255, 255, 255).withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF79c339),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color.fromARGB(221, 255, 255, 255),
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Color(0xFF79c339)),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.teal.withOpacity(0.3),
                    color: Color(0xFF79c339),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(0xFF79c339).withOpacity(0.3),
        child: Icon(icon, color: Color(0xFF79c339)),
      ),
      title: Text(
        label,
        style: const TextStyle(color: Color.fromARGB(221, 255, 255, 255)),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: const Color(0xFF79c339),
          fontFamily: GoogleFonts.montserrat().fontFamily,
        ),
      ),
    );
  }
}
