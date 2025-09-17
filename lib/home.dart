import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'widgets/point_card.dart';
import 'widgets/floating_profile_button.dart';
import 'widgets/bottomBar.dart';

import 'widgets/chatbot_fab.dart';
import 'widgets/chatbot_panel.dart';
import 'package:point_in_polygon/point_in_polygon.dart';

import 'run_info.dart';
import 'edit.dart'; // <-- Import your EditProfilePage

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  List<Polygon> _polygons = [];
  List<Map<String, dynamic>> _polygonOwners = [];
  int _selectedBottomIndex = 0;
  LatLng? _currentLatLng;
  final LatLng _defaultLocation = LatLng(22.726405, 75.871887);

  @override
  void initState() {
    super.initState();
    _determinePosition();
    fetchTerritories();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      if (!mounted) return;
      setState(() {
        _currentLatLng = LatLng(pos.latitude, pos.longitude);
      });
    } catch (_) {
      // fallback silently
    }
  }

  void _onBottomNavSelect(int index) {
    setState(() {
      _selectedBottomIndex = index;
    });
  }

  Future<void> fetchTerritories() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('publicRuns')
        .get();

    List<Polygon> polygons = [];
    List<Map<String, dynamic>> polygonOwners = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final locationData = data['locationData'] as List<dynamic>;
      final userId = data['userId'] as String;
      final runDocId = doc.id;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data();
      final userColor = userData != null && userData.containsKey('color')
          ? userData['color'] as String
          : '#FF0000';

      List<LatLng> points = locationData.map((point) {
        final lat = point['lat'] as double;
        final lng = point['lng'] as double;
        return LatLng(lat, lng);
      }).toList();
      if (points.isNotEmpty && points.first != points.last) {
        points.add(points.first);
      }

      Polygon polygon = Polygon(
        points: points,
        color: HexColor.fromHex(userColor).withOpacity(0.4),
        borderColor: HexColor.fromHex(userColor),
        borderStrokeWidth: 2,
        isFilled: true,
      );
      polygons.add(polygon);
      polygonOwners.add({
        'polygon': polygon,
        'userId': userId,
        'runDocId': runDocId,
        'points': points,
      });
    }

    if (!mounted) return;
    setState(() {
      _polygons = polygons;
      _polygonOwners = polygonOwners;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && polygons.isNotEmpty && polygons.first.points.isNotEmpty) {
        final firstPoint = polygons.first.points.first;
        _mapController.move(firstPoint, 17); // Zoom level adjustable
      }
    });
  }

  bool _containsLatLng(List<LatLng> polygon, LatLng point) {
    final poly = polygon
        .map((latLng) => Point(x: latLng.latitude, y: latLng.longitude))
        .toList();
    return Poly.isPointInPolygon(
      Point(x: point.latitude, y: point.longitude),
      poly,
    );
  }

  void _navigateToRunInfo(String userId, String runDocId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunInfoPage(userId: userId, runDocId: runDocId),
      ),
    );
  }

  // <-- Profile editing function with refresh logic
  void _goToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    ).then((_) => fetchTerritories());
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentLatLng ?? _defaultLocation;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 13, 15, 12),
        elevation: 3,
        title: Text(
          "Ruvia",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.2,
            color: const Color.fromARGB(255, 99, 227, 82),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.notifications,
            color: Color.fromARGB(255, 99, 227, 82),
          ),
          onPressed: () {},
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: AppBarPointsCard(),
          ),
          // ADD THIS BUTTON for EDIT PROFILE and refresh logic!
          // IconButton(
          //   icon: const Icon(Icons.edit, color: Color(0xFF79c339), size: 22),
          //   onPressed: () => _goToEditProfile(context),
          //   tooltip: 'Edit Profile',
          // ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: FloatingProfileButton(avatarImage: "assets/avator.png"),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 17.0,
              minZoom: 3,
              onTap: (tapPosition, tappedLatLng) {
                for (var entry in _polygonOwners) {
                  Polygon polygon = entry['polygon'];
                  String userId = entry['userId'];
                  String runDocId = entry['runDocId'];
                  List<LatLng> points = entry['points'];
                  if (_containsLatLng(points, tappedLatLng)) {
                    _navigateToRunInfo(userId, runDocId);
                    break;
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'your.app.package',
              ),
              PolygonLayer(polygons: _polygons),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 120,
                    height: 80,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Chatbot FAB
          Positioned(
            bottom: 88,
            right: 20,
            child: ChatBotFAB(
              onPressed: () {
                showChatBotPanel(context);
              },
            ),
          ),
          // Refresh FAB
          Positioned(
            bottom: 16,
            right: 20,
            child: Material(
              color: Colors.black,
              elevation: 5,
              shape: const CircleBorder(),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF79c339),
                child: const Icon(Icons.refresh_rounded, color: Colors.black),
                tooltip: 'Refresh Map',
                onPressed: fetchTerritories,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onTap: _onBottomNavSelect,
      ),
    );
  }
}

class HexColor extends Color {
  HexColor(final int hexColor) : super(hexColor);
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
