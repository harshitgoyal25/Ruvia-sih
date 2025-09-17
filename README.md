Ruvia 🏃‍♂️📍

Ruvia is a Flutter-based fitness and territory capture app that lets users track runs in real-time, visualize their routes on a map, and capture areas on a territory board game-like interface inspired by Paper.io.

The app integrates with Firebase for authentication & data storage and uses OpenStreetMap (via flutter_map) for route tracking and visualization.

🚀 Features

📍 Run Tracking – Live GPS tracking with distance, pace, and area calculation.

🗺️ Map Visualization – Real-time route display using OpenStreetMap.

🔒 Authentication – Secure login/signup with Firebase Authentication & Google Sign-In.

☁️ Cloud Storage – Save runs, stats, and captured areas in Firestore.

🎨 Custom User Colors – Each runner has a unique territory color.

🕹️ Territory Capture Mode – Capture map areas like Paper.io; overlapping areas are removed from previous owners.

🖼️ Profile Management – Update profile, run stats, and activity history.

⚡ Cross-Platform – Runs on Android, iOS, Web, Windows, macOS, Linux.

🛠️ Tech Stack

Frontend & Mobile:

Flutter
 (cross-platform framework)

flutter_map
 – Map rendering with OpenStreetMap

latlong2
 – LatLng utilities

Backend & Cloud:

Firebase Authentication
 – User login

Cloud Firestore
 – Run & territory data storage

Firebase Core

Utilities & Packages:

geolocator
 – GPS location tracking

background_locator_2
 – Background location updates

shared_preferences
 – Local caching

permission_handler
 – Permissions management

google_fonts
 – Modern typography

point_in_polygon
 – Area calculation

flutter_native_splash
 – Custom splash screen
