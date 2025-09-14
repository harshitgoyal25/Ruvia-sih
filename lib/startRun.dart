// TODO Implement this library.
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:ruvia/home.dart';


import 'widgets/floating_profile_button.dart';

class StartRunPage extends StatefulWidget {
  const StartRunPage({super.key});

  @override
  State<StartRunPage> createState() => _StartRunPageState();
}

class _StartRunPageState extends State<StartRunPage> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  bool _isRunning = false;
  bool _isPaused = false;

  String userColor = '#0000FF'; // Default red if not fetched
  final List<LatLng> _routePoints = [];
  double _totalDistance = 0.0;
  final Distance _distance = const Distance();
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  final ValueNotifier<String> _elapsedTimeNotifier = ValueNotifier("00:00");
  final ValueNotifier<String> _paceNotifier = ValueNotifier("0:00");

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(pos.latitude, pos.longitude);
    });

    // Delay map move until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentPosition != null) {
        _mapController.move(_currentPosition!, 16.0);
      }
    });
  }

  void _startRun() {
    _isRunning = true;
    _isPaused = false;
    _routePoints.clear();
    _totalDistance = 0.0;

    _stopwatch.reset();
    _stopwatch.start();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = _stopwatch.elapsed;
      _elapsedTimeNotifier.value =
          "${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}";

      if (_totalDistance > 0) {
        final paceSeconds = elapsed.inSeconds ~/ (_totalDistance / 1000);
        final paceMinutes = paceSeconds ~/ 60;
        final paceRemainder = paceSeconds % 60;
        _paceNotifier.value =
            "$paceMinutes:${paceRemainder.toString().padLeft(2, '0')}";
      }
    });

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Increase filter to reduce updates
          ),
        ).listen((Position pos) {
          final newPoint = LatLng(pos.latitude, pos.longitude);

          // Only update if moved significantly
          if (_routePoints.isEmpty ||
              _distance.as(LengthUnit.Meter, _routePoints.last, newPoint) > 5) {
            if (_routePoints.isNotEmpty) {
              _totalDistance += _distance.as(
                LengthUnit.Meter,
                _routePoints.last,
                newPoint,
              );
            }
            _routePoints.add(newPoint);
            _currentPosition = newPoint;

            // Only move map if user moved significantly
            _mapController.move(newPoint, _mapController.zoom);

            // Only call setState when needed
            setState(() {});
          }
        });

    setState(() {});
  }

  void _pauseRun() {
    _isPaused = true;
    _stopwatch.stop();
    _positionStream?.pause();
    setState(() {});
  }

  void _resumeRun() {
    _isPaused = false;
    _stopwatch.start();
    _positionStream?.resume();
    setState(() {});
  }

  void _stopRun() {
    _isRunning = false;
    _isPaused = false;
    _positionStream?.cancel();
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {});
    saveRun();
    // Redirect to /home after finishing
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> saveRun() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    final runPace = _totalDistance > 0
        ? elapsedSeconds / (_totalDistance / 1000)
        : 0;

    final runData = {
      'distance': _totalDistance,
      'areaCaptured': calculateArea(),
      'timeTaken': elapsedSeconds,
      'pace': runPace,
      'timestamp': FieldValue.serverTimestamp(),
      'locationData': _routePoints
          .map((e) => {'lat': e.latitude, 'lng': e.longitude})
          .toList(),
      'userId': user.uid,
      'userName': user.displayName ?? 'Unknown',
    };

    final runRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('runs')
        .doc();

    await runRef.set(runData);

    final publicRef = FirebaseFirestore.instance
        .collection('publicRuns')
        .doc(runRef.id);

    await publicRef.set(runData);
  }

  Future<void> fetchUserColor() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          userColor = data?['color'] ?? '#FF0000';
        });
      }
    } catch (e) {
      print('Error fetching user color: $e');
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    _elapsedTimeNotifier.dispose();
    _paceNotifier.dispose();
    super.dispose();
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
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition!,
                    initialZoom: 16.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          color: HexColor.fromHex(userColor).withOpacity(0.7),
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition!,
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
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Bottom panel with stats and buttons
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: const Color.fromARGB(255, 13, 15, 12),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ValueListenableBuilder<String>(
                              valueListenable: _elapsedTimeNotifier,
                              builder: (_, elapsed, __) =>
                                  _statColumn("Duration", elapsed),
                            ),
                            _statColumn(
                              "Distance",
                              "${(_totalDistance / 1000).toStringAsFixed(2)} km",
                            ),
                            ValueListenableBuilder<String>(
                              valueListenable: _paceNotifier,
                              builder: (_, pace, __) =>
                                  _statColumn("Avg Pace", pace),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!_isRunning)
                          _mainButton(
                            "Start Run",
                            Colors.green,
                            _startRun,
                            textColor: const Color.fromARGB(255, 255, 253, 253),
                          ),
                        if (_isRunning && !_isPaused)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _mainButton(
                                "Pause",
                                Colors.orange,
                                _pauseRun,
                                textColor: const Color.fromARGB(
                                  255,
                                  255,
                                  253,
                                  253,
                                ),
                              ),
                              _mainButton(
                                "Finish",
                                Colors.red,
                                _stopRun,
                                textColor: const Color.fromARGB(
                                  255,
                                  255,
                                  253,
                                  253,
                                ),
                              ),
                            ],
                          ),
                        if (_isRunning && _isPaused)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _mainButton("Resume", Colors.green, _resumeRun),
                              _mainButton("Finish", Colors.red, _stopRun),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statColumn(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _mainButton(
    String text,
    Color color,
    VoidCallback onPressed, {
    Color textColor = Colors.white,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
        backgroundColor: color,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: GoogleFonts.montserrat().fontFamily,
        ),
      ),
    );
  }

  double calculateArea() {
    if (_routePoints.length < 3) return 0.0; // Need at least 3 points

    double area = 0.0;
    final int n = _routePoints.length;
    final double latitude =
        _routePoints[0].latitude; // Use first point for approximation

    // Helper to convert lat/lng to Cartesian meters
    double latToY(double lat) => lat * 111320.0;
    double lngToX(double lng) => lng * 111320.0 * cos(latitude * pi / 180);

    for (int i = 0; i < n; i++) {
      final p1 = _routePoints[i];
      final p2 = _routePoints[(i + 1) % n]; // wrap around to first point

      double x1 = lngToX(p1.longitude);
      double y1 = latToY(p1.latitude);
      double x2 = lngToX(p2.longitude);
      double y2 = latToY(p2.latitude);

      area += (x1 * y2) - (x2 * y1);
    }

    return area.abs() / 2.0; // area in square meters
  }
}