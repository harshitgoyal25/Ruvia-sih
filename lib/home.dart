// TODO Implement this library.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'widgets/floating_profile_button.dart';
import 'widgets/bottomBar.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  List<Polygon> _polygons = [];
  int _selectedBottomIndex = 0;
  LatLng? _currentLatLng;
  final LatLng _defaultLocation = LatLng(
    22.726405,
    75.871887,
  ); // Indore fallback

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

    print('Fetched ${querySnapshot.docs.length} documents from publicRuns.');

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final locationData = data['locationData'] as List<dynamic>;
      final userId = data['userId'] as String;

      print(
        'Processing run by user: $userId with ${locationData.length} points.',
      );

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
      if (_polygons.isNotEmpty && _polygons.first.points.isNotEmpty) {
        final firstPoint = _polygons.first.points.first;
        _mapController.move(firstPoint, 15); // Zoom level adjustable
      }

      print('Points for this polygon: $points');

      polygons.add(
        Polygon(
          points: points,
          color: HexColor.fromHex(
            userColor,
          ).withOpacity(0.8), // More visible fill
          borderColor: HexColor.fromHex(userColor),
          borderStrokeWidth: 2,
          isFilled: true, // Ensure fill is enabled
        ),
      );
    }

    print('Total polygons created: ${polygons.length}');

    setState(() {
      _polygons = polygons;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_mapController.center, _mapController.zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentLatLng ?? _defaultLocation;

    return Scaffold(
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
            // Handle notification tap
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: FloatingProfileButton(avatarImage: "assets/avator.png"),
          ),
        ],
      ),

      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 17.0,
          minZoom: 3,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
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