import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/bottomBar.dart';
import 'widgets/floating_profile_button.dart';

class MePage extends StatefulWidget {
  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  int _currentIndex = 1; // "Me" is at index 1

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
          // Background image
          Container(decoration: BoxDecoration()),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 14, 14, 15).withOpacity(1),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level card
                  Card(
                    color: const Color(0xFF27272A).withOpacity(0.5),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: const Color(0xFF79c339),
                        child: Icon(
                          Icons.directions_run,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        'Level 1',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: GoogleFonts.montserrat().fontFamily,
                        ),
                      ),
                      subtitle: Text(
                        '102XP to next level',
                        style: TextStyle(
                          color: const Color(0xFF79c339),
                          fontFamily: GoogleFonts.montserrat().fontFamily,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color.fromARGB(255, 254, 255, 255),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // XP Challenges
                  Card(
                    color: const Color(0xFF27272A).withOpacity(0.5),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'XP Challenges',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: GoogleFonts.montserrat().fontFamily,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _ChallengeCard(
                                icon: Icons.camera_alt,
                                label: 'Add a profile picture',
                                xp: 20,
                              ),
                              _ChallengeCard(
                                icon: Icons.privacy_tip,
                                label: 'Set preference for privacy',
                                xp: 30,
                              ),
                              _ChallengeCard(
                                icon: Icons.person_add,
                                label: 'Follow on Instagram',
                                xp: 10,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Competitions
                  Card(
                    color: const Color(0xFF27272A).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Competitions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: GoogleFonts.montserrat().fontFamily,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Terra Comp 25.7 | \$2,988 AUD in Prizes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: GoogleFonts.montserrat().fontFamily,
                              color: const Color(0xFF79c339),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: const [
                              _CompetitionCard(
                                title: "THE BREATH HAUS",
                                time: "Ends: 20h 16m",
                              ),
                              SizedBox(width: 10),
                              _CompetitionCard(
                                title: "THE BREATH HAUS",
                                time: "Ends: 20h 16m",
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF79c339),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(14),
                                ),
                              ),
                            ),
                            child: const Text(
                              'View competition',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Local Battle
                  Card(
                    color: const Color(0xFF27272A).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.sports_kabaddi,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                        title: const Text(
                          'Local Battle',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(221, 255, 255, 255),
                            // Navigator.pushNamed(context, '/localBattle'); // Uncomment to navigate on tap
                          ),
                        ),
                        subtitle: const Text(
                          'Find nearby runners to compete!',
                          style: TextStyle(color: Color(0xFF79c339)),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color.fromARGB(202, 255, 255, 255),
                        ),
                        onTap: () {
                          // Navigator.pushNamed(context, '/localBattle');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Join/Create Club
                  Card(
                    color: const Color(0xFF27272A).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              // Navigator.pushNamed(context, '/joinClub');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(14),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                            ),
                            child: Text(
                              "Join a Club",
                              style: TextStyle(
                                color: const Color.fromARGB(221, 255, 255, 255),
                                fontFamily: GoogleFonts.montserrat().fontFamily,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: null, // Disabled
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color.fromARGB(221, 255, 255, 255),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(14),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                            ),
                            child: Text(
                              "Create Your Own Club",
                              style: TextStyle(
                                color: const Color.fromARGB(221, 255, 255, 255),
                                fontFamily: GoogleFonts.montserrat().fontFamily,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Insights
                  Card(
                    color: const Color(0xFF27272A).withOpacity(0.5),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pushNamed(context, '/insights');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Insights:",
                              style: TextStyle(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                fontWeight: FontWeight.bold,
                                fontFamily: GoogleFonts.montserrat().fontFamily,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Icon(Icons.stars, color: Color(0xFF79c339)),
                            const SizedBox(width: 10),
                            Text(
                              "Achievements / Stats",
                              style: TextStyle(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                fontFamily: GoogleFonts.montserrat().fontFamily,
                              ),
                            ),
                          ],
                        ),
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

// --- helper widgets ---
class _ChallengeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int xp;

  const _ChallengeCard({
    required this.icon,
    required this.label,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Color(0xFF79c339),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '+$xp XP',
          style: TextStyle(
            fontSize: 11,
            color: Colors.green,
            fontFamily: GoogleFonts.montserrat().fontFamily,
          ),
        ),
      ],
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final String title, time;

  const _CompetitionCard({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF79c339).withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ],
      ),
    );
  }
}
