import 'package:flutter/material.dart';
import '../models/temple.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/temple_list_screen.dart';
import '../services/navigation_service.dart';
import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import '../screens/account_screen.dart';

class NavigationScreen extends StatefulWidget {

  final Temple temple;
  final int userId;
  final String userName;
  final List<String> religions;

  const NavigationScreen({
    super.key,
    required this.temple,
    required this.userId,
    required this.userName,
    required this.religions,
  });

  @override
  State<NavigationScreen> createState() =>
      _NavigationScreenState();
  }

  class _NavigationScreenState
      extends State<NavigationScreen> {

    @override
    void initState() {
      super.initState();

      loadLocation();
    }

    LatLng? currentLocation;

    double currentHeading = 0;

    double mapRotation = 0;

    double currentSpeed = 0;

    bool isRecalculating = false;

    bool isMoving = false;

    bool isOffRoute() {

      if (routePoints.isEmpty ||
          currentLocation == null) {
        return false;
      }

      final distance = Distance();

      double nearest = double.infinity;

      for (final point in routePoints) {

        final d = distance(
          currentLocation!,
          point,
        );

        if (d < nearest) {
          nearest = d;
        }
      }

      return nearest > rerouteDistanceMeters;
    }

    double rerouteDistanceMeters = 30;

    StreamSubscription<Position>? positionStream;

    StreamSubscription<CompassEvent>? compassStream;

    final MapController mapController =
        MapController();

    bool loading = true;
    
    List<LatLng> routePoints = [];

    List<LatLng> travelledPoints = [];

    List<LatLng> remainingPoints = [];

    double routeDistanceKm = 0;

    double routeDurationMin = 0;

    Future<void> loadLocation() async {

      final position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );

      setState(() {

        currentLocation = LatLng(
          position.latitude,
          position.longitude,
        );

        loading = false;

      });

      await loadRoute();
      startLiveTracking();
      startCompassTracking();

      setState(() {});
    }
  void updateRemainingDistance() {

    if (currentLocation == null ||
        routePoints.isEmpty) {
      return;
    }

    final distance = Distance();

    double remainingMeters = 0;

    int nearestIndex = 0;
    double nearestDistance = double.infinity;

    for (int i = 0; i < routePoints.length; i++) {

      final d = distance(
        currentLocation!,
        routePoints[i],
      );

      if (d < nearestDistance) {
        nearestDistance = d;
        nearestIndex = i;
      }
    }

    for (int i = nearestIndex;
        i < routePoints.length - 1;
        i++) {

      remainingMeters += distance(
        routePoints[i],
        routePoints[i + 1],
      );
    }

    setState(() {

      routeDistanceKm =
          remainingMeters / 1000;

      double speedKmh = 5;

        if (isMoving) {
          speedKmh = currentSpeed * 3.6;
        }

        routeDurationMin =
            (remainingMeters / 1000) /
            speedKmh *
            60;
    });
  }
  void updateRouteProgress() {

    if (currentLocation == null ||
        routePoints.isEmpty) {
      return;
    }

    double nearestDistance =
        double.infinity;

    int nearestIndex = 0;

    for (int i = 0;
        i < routePoints.length;
        i++) {

      final distance =
          Geolocator.distanceBetween(

        currentLocation!.latitude,
        currentLocation!.longitude,

        routePoints[i].latitude,
        routePoints[i].longitude,
      );

      if (distance <
          nearestDistance) {

        nearestDistance =
            distance;

        nearestIndex = i;
      }
    }

    setState(() {

      travelledPoints =
          routePoints
              .sublist(
                0,
                nearestIndex + 1,
              );

      remainingPoints =
          routePoints
              .sublist(
                nearestIndex,
              );

    });
  }  
  void startLiveTracking() {

    positionStream =
        Geolocator.getPositionStream(

      locationSettings:
          const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),

    ).listen((Position position) {
      
      if (!mounted) return;

      setState(() {

        currentLocation = LatLng(
          position.latitude,
          position.longitude,
        );

        currentSpeed = position.speed;

        if (isOffRoute() && !isRecalculating) {
          isRecalculating = true;

          loadRoute().then((_) {
            isRecalculating = false;
          });
        }

        if (position.speed > 1.0) {
          isMoving = true;
          currentHeading = position.heading;
          mapRotation = -position.heading;

          mapController.rotate(
            -position.heading,
          );
        } else {
          isMoving = false;
        }
      });

      updateRemainingDistance();
      updateRouteProgress();
      mapController.move(
        currentLocation!,
        mapController.camera.zoom,
      );
    });
  }
  void startCompassTracking() {

    compassStream =
        FlutterCompass.events?.listen(

      (CompassEvent event) {

        if (!mounted) return;

        if (!isMoving) {

          setState(() {

            currentHeading =
                event.heading ?? 0;

            mapRotation =
                -(event.heading ?? 0);

          });

          mapController.rotate(
            -(event.heading ?? 0),
          );
        }
      },
    );
  }
  Future<void> loadRoute() async {

    final data =
        await NavigationService.getRoute(

      startLat: currentLocation!.latitude,
      startLng: currentLocation!.longitude,

      endLat: widget.temple.latitude,
      endLng: widget.temple.longitude,
    );

    final coordinates =
        data["features"][0]["geometry"]["coordinates"];

    final summary =
        data["features"][0]["properties"]["summary"];

    setState(() {

      routePoints =
          coordinates.map<LatLng>((c) {

        return LatLng(
          c[1].toDouble(),
          c[0].toDouble(),
        );

      }).toList();

      remainingPoints =
          List.from(routePoints);

      travelledPoints = [];      

      routeDistanceKm =
          summary["distance"] / 1000;

      routeDurationMin =
          summary["duration"] / 60;

    }
    );
    updateRouteProgress();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Navigation"),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Stack(

              children: [

                FlutterMap(

                  mapController:
                      mapController,

                  options: MapOptions(
                    initialCenter:
                        currentLocation!,
                    initialZoom: 15,
                    initialRotation: mapRotation,
                  ),

                  children: [

                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.lumo.app',
                    ),

                    PolylineLayer(

                    polylines: [

                      Polyline(

                        points: travelledPoints,

                        strokeWidth: 5,

                        color: Colors.grey,
                      ),

                      Polyline(

                        points: remainingPoints,

                        strokeWidth: 5,

                        color: Colors.blue,
                      ),
                    ],
                    ),

                    MarkerLayer(
                      markers: [

                        Marker(
                          point: currentLocation!,
                          width: 60,
                          height: 60,
                          child: Transform.rotate(
                                  angle:
                                      (currentHeading * 3.1415926535 / 180),

                            child: 
                            const Icon(
                              Icons.navigation,
                              color: Colors.blue,
                              size: 45,
                            ),
                          ),
                        ),
                        Marker(
                          point: LatLng(
                            widget.temple.latitude,
                            widget.temple.longitude,
                          ),
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            color:
                                Colors.red,
                            size: 45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Positioned(

                  top: 20,
                  left: 20,
                  right: 20,

                  child: Card(

                    child: Padding(

                      padding:
                          const EdgeInsets.all(12),

                      child: Column(

                        children: [

                          Text(
                            widget.temple.name,
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          Text(
                            widget.temple.religion,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Distance: ${routeDistanceKm.toStringAsFixed(1)} km",
                          ),

                            Text(
                              "ETA: ${routeDurationMin.toStringAsFixed(0)} min",
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 20,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFFD99200),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                    ),
                    onPressed: () {

                      if (currentLocation != null) {

                        mapController.move(
                          currentLocation!,
                          17,
                        );

                      }
                    },
                  ),
                ),
              ],
            ),

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: 2,

        selectedItemColor:
            const Color(0xFFD99200),

        type:
            BottomNavigationBarType.fixed,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Map",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "List",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: "Navigation",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Account",
          ),
        ],

        onTap: (index) {

          if (index == 0) {

            Navigator.popUntil(
              context,
              (route) => route.isFirst,
            );

          }

          else if (index == 1) {

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => 
                TempleListScreen(
                  userId: widget.userId,
                  userName: widget.userName,
                  religions: widget.religions,
                ),
              ),
            );

          }

          else if (index == 2) {

            // Already on Navigation screen

          }

          else if (index == 3) {

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => 
                AccountScreen(
                  userId: widget.userId,
                  userName: widget.userName,
                  religions: widget.religions,
                ),
              ),
            );

          }
        },
      ),
    );
  }
  @override
  void dispose() {

    positionStream?.cancel();

    compassStream?.cancel();

    super.dispose();
  }
}