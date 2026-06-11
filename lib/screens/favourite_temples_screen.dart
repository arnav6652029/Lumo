import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/temple.dart';
import '../services/api_services.dart';
import 'navigation_screen.dart';

class FavouriteTemplesScreen extends StatefulWidget {

  final int userId;
  final String userName;
  final List<String> religions;

  const FavouriteTemplesScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.religions,
  });

  @override
  State<FavouriteTemplesScreen> createState() =>
      _FavouriteTemplesScreenState();
}

class _FavouriteTemplesScreenState
    extends State<FavouriteTemplesScreen> {

  List<Temple> favouriteTemples = [];

  bool loading = true;

  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    currentPosition =
        await Geolocator.getCurrentPosition();

    final List<Temple> allTemples = [];

    const religions = [
      "Hinduism",
      "Buddhism",
      "Christianity",
      "Islam",
      "Judaism",
      "Other",
    ];

    for (final religion in religions) {

      final temples =
          await ApiService.getTemples(
        religion,
      );

      allTemples.addAll(temples);
    }

    final favourites =
        await ApiService.getFavouriteTempleIds(
      widget.userId,
    );

    favouriteTemples = allTemples.where((t) {
      return favourites.contains(t.id);
    }).toList();

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  double distanceToTemple(
    Temple temple,
  ) {

    if (currentPosition == null) {
      return 0;
    }

    return Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      temple.latitude,
      temple.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Saved Temples",
        ),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : favouriteTemples.isEmpty
              ? const Center(
                  child: Text(
                    "No saved temples yet",
                  ),
                )
              : ListView.builder(

                  itemCount:
                      favouriteTemples.length,

                  itemBuilder:
                      (context, index) {

                    final temple =
                        favouriteTemples[index];

                    final distance =
                        distanceToTemple(
                      temple,
                    );

                    return ListTile(

                      leading: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                      ),

                      title:
                          Text(temple.name),

                      subtitle: Text(
                        distance < 1000
                            ? "${distance.toStringAsFixed(0)} m"
                            : "${(distance / 1000).toStringAsFixed(2)} km",
                      ),

                      onTap: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NavigationScreen(
                              temple: temple,
                              userId:
                                  widget.userId,
                              userName:
                                  widget.userName,
                              religions:
                                  widget.religions,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}