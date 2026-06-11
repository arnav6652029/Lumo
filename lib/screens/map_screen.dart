import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/temple_list_screen.dart';
import '../screens/navigation_screen.dart';
import '../models/temple.dart';
import '../services/api_services.dart';
import '../screens/account_screen.dart';

class MapScreen extends StatefulWidget {

  final int userId;
  final String userName;
  final List<String> religions;

  const MapScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.religions,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  Temple? selectedTemple;

  List<Temple> featuredTemples = [];
  List<Temple> allReligionTemples = [];
  List<Temple> myReligionTemples = [];
  final TextEditingController searchController =
    TextEditingController();

  IconData getReligionIcon(String religion) {
    switch (religion) {
      case "Hinduism":
        return Icons.temple_hindu;

      case "Christianity":
        return Icons.church;

      case "Islam":
        return Icons.mosque;

      case "Judaism":
        return Icons.synagogue;

      case "Buddhism":
        return Icons.temple_buddhist;

      default:
        return Icons.location_on;
    }
  }

  List<Temple> get nearestTemples {

    final sorted =
        List<Temple>.from(
      visibleTemples,
    );

    if (currentLocation == null) {
      return sorted;
    }

    sorted.sort((a, b) {

      final da = Geolocator.distanceBetween(
        currentLocation!.latitude,
        currentLocation!.longitude,
        a.latitude,
        a.longitude,
      );

      final db = Geolocator.distanceBetween(
        currentLocation!.latitude,
        currentLocation!.longitude,
        b.latitude,
        b.longitude,
      );

      return da.compareTo(db);

    });

    return sorted;
  }

  List<Temple> get visibleTemples {

    final Map<int, Temple> result = {};

    for (final temple in featuredTemples) {
      result[temple.id] = temple;
    }

    if (showAllReligionsFeatured) {
      for (final temple in allReligionTemples) {
        result[temple.id] = temple;
      }
    }

    if (showMyReligionAll) {
      for (final temple in myReligionTemples) {
        result[temple.id] = temple;
      }
    }

    return result.values.toList();
  }

  List<Temple> get searchResults {

    if (searchController.text.trim().isEmpty) {
      return [];
    }

    final query =
        searchController.text
            .toLowerCase()
            .trim();

    final results = visibleTemples.where((temple) {

      return temple.name
              .toLowerCase()
              .contains(query) ||
          temple.address
              .toLowerCase()
              .contains(query);

    }).toList();

    if (currentLocation != null) {

      results.sort((a, b) {

        final da = Geolocator.distanceBetween(
          currentLocation!.latitude,
          currentLocation!.longitude,
          a.latitude,
          a.longitude,
        );

        final db = Geolocator.distanceBetween(
          currentLocation!.latitude,
          currentLocation!.longitude,
          b.latitude,
          b.longitude,
        );

        return da.compareTo(db);

      });

    }

    return results;
  }

  bool showAllReligionsFeatured = false;
  bool showMyReligionAll = false;
  bool showFilters = false;

  LatLng? currentLocation;

  final MapController mapController =
      MapController();

  @override
  void initState() {
    super.initState();

    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {

    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) return;

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {

      permission =
          await Geolocator.requestPermission();

      if (permission ==
          LocationPermission.denied) {
        return;
      }
    }

    if (permission ==
        LocationPermission.deniedForever) {
      return;
    }

    Position position =
        await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {

      currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

    });

    mapController.move(
      currentLocation!,
      15,
    );
    await loadTemples();
  }

  Future<void> loadTemples() async {

    try {

      final allFeatured =
          await ApiService.getFeaturedTemples();

      featuredTemples.clear();
      myReligionTemples.clear();

      for (final religion in widget.religions) {

        featuredTemples.addAll(
          allFeatured.where(
            (t) => t.religion == religion,
          ),
        );

        final temples =
            await ApiService.getTemples(
              religion,
            );

        myReligionTemples.addAll(
          temples,
        );
      }

      allReligionTemples = allFeatured;

      setState(() {});

    } catch (e) {

      debugPrint(e.toString());

    }
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Lumo"),
        backgroundColor: const Color(0xFFD99200),
        actions: [

          IconButton(
            icon: Icon(
              showFilters
                  ? Icons.close
                  : Icons.filter_list,
            ),
            onPressed: () {

              setState(() {

                showFilters = !showFilters;

              });

            },
          ),

        ],
      ),

      body: Stack(

        children: [

          FlutterMap(

            mapController: mapController,

            options: MapOptions(
              initialCenter:
                  currentLocation ??
                  const LatLng(
                    22.5726,
                    88.3639,
                  ),
              initialZoom: 15,
            ),

            children: [

              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.lumo.app',
              ),

              MarkerLayer(

                markers: [

                  if (currentLocation != null)

                    Marker(
                      point: currentLocation!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),

                  ...visibleTemples.map((temple) {

                      return Marker(

                      point: LatLng(
                        temple.latitude,
                        temple.longitude,
                      ),

                      width: 180,
                      height: 80,

                      child: GestureDetector(

                        onTap: () {

                          setState(() {
                            selectedTemple = temple;
                          });

                          mapController.move(
                            LatLng(
                              temple.latitude,
                              temple.longitude,
                            ),
                            17,
                          );

                          final meters = Geolocator.distanceBetween(
                            currentLocation!.latitude,
                            currentLocation!.longitude,
                            temple.latitude,
                            temple.longitude,
                          );

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    temple.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Text(temple.address),

                                  const SizedBox(height: 10),

                                  Text(temple.description),

                                  const SizedBox(height: 10),

                                  Text(
                                    meters < 1000
                                        ? "${meters.toStringAsFixed(0)} m away"
                                        : "${(meters / 1000).toStringAsFixed(2)} km away",
                                  ),
                                  ElevatedButton.icon(

                                    icon: const Icon(Icons.route),

                                    label: const Text(
                                      "Navigate",
                                    ),

                                    onPressed: () {

                                      Navigator.pop(context);

                                      Navigator.push(

                                        context,

                                        MaterialPageRoute(

                                          builder: (_) =>
                                              NavigationScreen(
                                                temple: temple,
                                                userId: widget.userId,
                                                userName: widget.userName,
                                                religions: widget.religions,
                                              )
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },

                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            Icon(
                              getReligionIcon(temple.religion),
                              color: selectedTemple?.id == temple.id
                                  ? Colors.red
                                  : getMarkerColor(temple),
                              size: 40,
                            ),

                            Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 4,
                                    color: Colors.black26,
                                  )
                                ],
                              ),

                              child: Text(
                                temple.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 70,
            child: Card(
              elevation: 4,
              child: 
              TextField(
                controller: searchController,

                decoration: InputDecoration(
                  hintText: "Search temples...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),

                onChanged: (_) {
                  setState(() {});
                },
              ),
            ),
          ),
          if (searchController.text.isNotEmpty)
            Positioned(
              top: 70,
              left: 10,
              right: 10,
              child: Card(
                elevation: 5,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 250,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {

                      final temple =
                          searchResults[index];

                      final meters =
                          currentLocation == null
                              ? 0
                              : Geolocator.distanceBetween(
                                  currentLocation!.latitude,
                                  currentLocation!.longitude,
                                  temple.latitude,
                                  temple.longitude,
                                );

                      return ListTile(

                        leading: Icon(
                          getReligionIcon(
                            temple.religion,
                          ),
                        ),

                        title: Text(
                          temple.name,
                        ),

                        subtitle: Text(
                          meters < 1000
                              ? "${meters.toStringAsFixed(0)} m away"
                              : "${(meters / 1000).toStringAsFixed(2)} km away",
                        ),

                        onTap: () {
                          searchController.clear();
                          setState(() {});
                          Navigator.push(

                            context,

                            MaterialPageRoute(

                              builder: (_) =>
                                  NavigationScreen(
                                    temple: temple,
                                    userId: widget.userId,
                                    userName: widget.userName,
                                    religions: widget.religions,
                                  )
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          if (showFilters)
            Positioned(
              top: 70,
              right: 10,
              child: Card(
                elevation: 5,
                child: SizedBox(
                  width: 280,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      CheckboxListTile(
                        title: const Text(
                          "Show Featured Temples of All Religions",
                        ),
                        value: showAllReligionsFeatured,
                        onChanged: (value) {
                          setState(() {
                            showAllReligionsFeatured =
                                value ?? false;
                          });
                        },
                      ),

                      CheckboxListTile(
                        title: Text(
                          "Show All My Temples",
                        ),
                        value: showMyReligionAll,
                        onChanged: (value) {
                          setState(() {
                            showMyReligionAll =
                                value ?? false;
                          });
                        },
                      ),

                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFD99200),
              onPressed: () {
                if (currentLocation != null) {
                  setState(() {
                    selectedTemple = null;
                  });

                  mapController.move(
                    currentLocation!,
                    15,
                  );
                }
              },
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFFD99200),
        type: BottomNavigationBarType.fixed,
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
          if (index == 1) {
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
  Color getMarkerColor(
    Temple temple,
  ) {

    if (
        widget.religions.contains(
          temple.religion,
        )
    ) {

      final isFeatured =
          featuredTemples.any(
        (t) => t.id == temple.id,
      );

      if (isFeatured) {
        return Colors.green;
      }

      return Colors.blue;
    }

    return Colors.grey;
  }
}