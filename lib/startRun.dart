import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:background_locator_2/background_locator.dart';
import 'package:background_locator_2/location_dto.dart';
import 'package:background_locator_2/settings/android_settings.dart';

import 'package:background_locator_2/settings/locator_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/floating_profile_button.dart';

// Background callback (must remain top-level)
class LocationCallbackHandler {
  static Future<void> callback(LocationDto locationDto) async {
    final prefs = await SharedPreferences.getInstance();
    final pointsJson = prefs.getStringList('run_points') ?? [];
    final point = {
      'lat': locationDto.latitude,
      'lng': locationDto.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };
    pointsJson.add(jsonEncode(point));
    await prefs.setStringList('run_points', pointsJson);
  }

  static Future<void> initCallback(Map<String, dynamic> params) async {
    // Initialize callback for Android
  }

  static Future<void> disposeCallback() async {
    // Dispose callback for Android
  }

  static Future<void> notificationCallback() async {
    // Notification tap callback for Android
  }
}

class StartRunPage extends StatefulWidget {
  const StartRunPage({super.key});
  @override
  State<StartRunPage> createState() => _StartRunPageState();
}

class _StartRunPageState extends State<StartRunPage> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  StreamSubscription<geo.Position>? _positionStream;

  bool _isRunning = false;
  bool _isPaused = false;

  String userColor = '#0000FF';
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
    _initializeBackgroundLocator();
    _determinePosition();
  }

  Future<void> _initializeBackgroundLocator() async {
    await BackgroundLocator.initialize();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) return;
    }
    if (permission == geo.LocationPermission.deniedForever) return;
    geo.Position pos = await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = LatLng(pos.latitude, pos.longitude);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentPosition != null) {
        _mapController.move(_currentPosition!, 16.0);
      }
    });
  }

  Future<void> _showPermissionDialogAndStart() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow Location Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Ruvia needs your location—even in the background—for accurate running route tracking.\n\n'
              'Please grant both location and background location permission.',
              style: TextStyle(fontSize: 15, color: Colors.grey[800]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    if (proceed == true) {
      await _requestPermissionsAndStartRun();
    }
  }

  Future<void> _requestPermissionsAndStartRun() async {
    final fg = await Permission.locationWhenInUse.request();
    final bg = await Permission.locationAlways.request();

    if (fg.isGranted && bg.isGranted) {
      await _startRun();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission required for tracking!")),
      );
    }
  }

  Future<void> _startRun() async {
    _isRunning = true;
    _isPaused = false;
    _routePoints.clear();
    _totalDistance = 0.0;
    _stopwatch.reset();
    _stopwatch.start();

    // Clear any previous run points
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('run_points');

    // Start background location
    Map<String, dynamic> data = {'countInit': 1};
    await BackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback,
      initCallback: LocationCallbackHandler.initCallback,
      initDataCallback: data,
      disposeCallback: LocationCallbackHandler.disposeCallback,
      autoStop: false,
      androidSettings: AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 5,
        distanceFilter: 10,
        client: LocationClient.google,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Location tracking',
          notificationTitle: 'Run in progress',
          notificationMsg: 'Tracking your route',
          notificationBigMsg:
              'Background location is on to keep the app up-to-date with your location.',
          notificationIconColor: Colors.grey,
          notificationTapCallback: LocationCallbackHandler.notificationCallback,
        ),
      ),
    );

    // Foreground position updates for user UI
    _positionStream =
        geo.Geolocator.getPositionStream(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((geo.Position pos) {
          final newPoint = LatLng(pos.latitude, pos.longitude);
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
            _mapController.move(newPoint, _mapController.zoom);
            setState(() {});
          }
        });

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

    setState(() {});
  }

  Future<void> _pauseRun() async {
    _isPaused = true;
    _stopwatch.stop();
    _positionStream?.pause();
    await BackgroundLocator.unRegisterLocationUpdate();
    setState(() {});
  }

  Future<void> _resumeRun() async {
    _isPaused = false;
    _stopwatch.start();
    _positionStream?.resume();
    Map<String, dynamic> data = {'countInit': 1};
    await BackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback,
      initCallback: LocationCallbackHandler.initCallback,
      initDataCallback: data,
      disposeCallback: LocationCallbackHandler.disposeCallback,
      autoStop: false,
      androidSettings: AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 5,
        distanceFilter: 10,
        client: LocationClient.google,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Location tracking',
          notificationTitle: 'Run in progress',
          notificationMsg: 'Tracking your route',
          notificationBigMsg:
              'Background location is on to keep the app up-to-date with your location.',
          notificationIconColor: Colors.grey,
          notificationTapCallback: LocationCallbackHandler.notificationCallback,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _stopRun() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("End this run?"),
        content: const Text(
          "Are you sure you want to finish and save this run?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Finish"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    _isRunning = false;
    _isPaused = false;
    _positionStream?.cancel();
    _stopwatch.stop();
    _timer?.cancel();

    // Stop background location
    await BackgroundLocator.unRegisterLocationUpdate();

    await loadAndUploadRoute();
    setState(() {});
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> loadAndUploadRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final pointsJson = prefs.getStringList('run_points') ?? [];
    List<LatLng> routePoints = pointsJson.map((p) {
      final point = jsonDecode(p);
      return LatLng(point['lat'], point['lng']);
    }).toList();

    if (_routePoints.isNotEmpty) {
      if (routePoints.isEmpty || routePoints.last != _routePoints.last) {
        routePoints.addAll(_routePoints.skip(routePoints.length));
      }
    }
    await saveRun(routePoints);
    await prefs.remove('run_points');
  }

  Future<void> saveRun(List<LatLng> finalRoutePoints) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    final runPace = _totalDistance > 0
        ? elapsedSeconds / (_totalDistance / 1000)
        : 0;

    final runData = {
      'distance': _totalDistance,
      'areaCaptured': calculateArea(finalRoutePoints),
      'timeTaken': elapsedSeconds,
      'pace': runPace,
      'timestamp': FieldValue.serverTimestamp(),
      'locationData': finalRoutePoints
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

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    _elapsedTimeNotifier.dispose();
    _paceNotifier.dispose();
    BackgroundLocator.unRegisterLocationUpdate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
                            Color.fromARGB(255, 99, 227, 82),
                            _showPermissionDialogAndStart,
                            textColor: Colors.white,
                          ),
                        if (_isRunning && !_isPaused)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _mainButton(
                                "Pause",
                                Colors.orange,
                                _pauseRun,
                                textColor: Colors.white,
                              ),
                              _mainButton(
                                "Finish",
                                Colors.red,
                                _stopRun,
                                textColor: Colors.white,
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
          fontWeight: FontWeight.w800,
          color: textColor,
          fontFamily: GoogleFonts.montserrat().fontFamily,
        ),
      ),
    );
  }

  double calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    double area = 0.0;
    final int n = points.length;
    final double latitude = points[0].latitude;
    double latToY(double lat) => lat * 111320.0;
    double lngToX(double lng) => lng * 111320.0 * cos(latitude * pi / 180);
    for (int i = 0; i < n; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % n];
      double x1 = lngToX(p1.longitude);
      double y1 = latToY(p1.latitude);
      double x2 = lngToX(p2.longitude);
      double y2 = latToY(p2.latitude);
      area += (x1 * y2) - (x2 * y1);
    }
    return area.abs() / 2.0;
  }
}

// Helper for hex color
class HexColor extends Color {
  HexColor(final int hexColor) : super(hexColor);
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
