import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/navigation_screen.dart';
import '../models/temple.dart';
import '../services/api_services.dart';
import '../screens/account_screen.dart';

class TempleListScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final List<String> religions;

  const TempleListScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.religions,
  });

  @override
  State<TempleListScreen> createState() =>
      _TempleListScreenState();
}

class _TempleListScreenState
    extends State<TempleListScreen> {

  List<Temple> temples = [];

  Set<int> favouriteTempleIds = {};

  bool loading = true;

  bool showFavouritesOnly = false;

  Position? currentPosition;

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    try {

      currentPosition =
          await Geolocator.getCurrentPosition();

      final List<Temple> allTemples = [];

      const allReligions = [
        "Hinduism",
        "Buddhism",
        "Christianity",
        "Islam",
        "Judaism",
        "Other",
      ];

      for (final religion in allReligions) {

        final templesForReligion =
            await ApiService.getTemples(
          religion,
        );

        allTemples.addAll(
          templesForReligion,
        );
      }

      final favourites =
          await ApiService.getFavouriteTempleIds(
        widget.userId,
      );

      setState(() {

        temples = allTemples;

        favouriteTempleIds =
            favourites.toSet();

        loading = false;

      });

    } catch (e) {

      debugPrint(e.toString());

      setState(() {
        loading = false;
      });

    }
  }

  IconData religionIcon(
    String religion,
  ) {
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
        return Icons.place;
    }
  }

  double distanceToTemple(
    Temple temple,
  ) {

    if (currentPosition == null) {
      return 999999;
    }

    return Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      temple.latitude,
      temple.longitude,
    );
  }

  List<Temple> get filteredTemples {

    List<Temple> list =
        List.from(temples);

    final query =
        searchController.text
            .trim()
            .toLowerCase();

    if (query.isNotEmpty) {

      list = list.where((temple) {

        return temple.name
                .toLowerCase()
                .contains(query) ||
            temple.religion
                .toLowerCase()
                .contains(query);

      }).toList();
    }

    if (showFavouritesOnly) {

      list = list.where((temple) {

        return favouriteTempleIds.contains(
          temple.id,
        );

      }).toList();
    }

    list.sort((a, b) {

      final distanceCompare =
          distanceToTemple(a).compareTo(
        distanceToTemple(b),
      );

      if (distanceCompare != 0) {
        return distanceCompare;
      }

      final aFav =
          favouriteTempleIds.contains(a.id);

      final bFav =
          favouriteTempleIds.contains(b.id);

      if (aFav != bFav) {
        return bFav ? 1 : -1;
      }

      return a.religion.compareTo(
        b.religion,
      );
    }
    );

    return list;
  }

  Future<void> toggleFavourite(
    Temple temple,
  ) async {

    final isFavourite =
        favouriteTempleIds.contains(
      temple.id,
    );

    setState(() {

      if (isFavourite) {

        favouriteTempleIds.remove(
          temple.id,
        );

      } else {

        favouriteTempleIds.add(
          temple.id,
        );

      }
    });

    try {

      if (isFavourite) {

        await ApiService.removeFavourite(
          widget.userId,
          temple.id,
        );

      } else {

        await ApiService.addFavourite(
          widget.userId,
          temple.id,
        );
      }

    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Temples",
        ),

        leading: PopupMenuButton(

          icon: const Icon(
            Icons.filter_list,
          ),

          onSelected: (_) {

            setState(() {

              showFavouritesOnly =
                  !showFavouritesOnly;

            });

          },

          itemBuilder: (_) => [

            CheckedPopupMenuItem(
              checked:
                  showFavouritesOnly,
              value: 1,
              child: const Text(
                "Show Favourites Only",
              ),
            ),
          ],
        ),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Column(

              children: [

                Padding(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  child: TextField(
                    controller:
                        searchController,

                    decoration:
                        const InputDecoration(
                      hintText:
                          "Search temples...",
                      prefixIcon:
                          Icon(Icons.search),
                    ),

                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                ),

                Expanded(

                  child: ListView.builder(

                    itemCount:
                        filteredTemples.length,

                    itemBuilder:
                        (context, index) {

                      final temple =
                          filteredTemples[
                              index];

                      final distance =
                          distanceToTemple(
                        temple,
                      );

                      final isFavourite =
                          favouriteTempleIds
                              .contains(
                        temple.id,
                      );

                      return ListTile(

                        onTap: () {

                          Navigator.push(

                            context,

                            MaterialPageRoute(

                              builder: (_) => 
                              NavigationScreen(

                                temple: temple,

                                userId: widget.userId,
                                userName: widget.userName,
                                religions: widget.religions,

                              ),
                            ),
                          );
                        },

                        leading: Icon(
                          religionIcon(
                            temple.religion,
                          ),
                          size: 32,
                        ),

                        title: Text(
                          temple.name,
                        ),

                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [

                            Text(
                              temple.religion,
                            ),

                            Text(
                              distance < 1000
                                  ? "${distance.toStringAsFixed(0)} m"
                                  : "${(distance / 1000).toStringAsFixed(2)} km",
                            ),
                          ],
                        ),

                        trailing:
                            IconButton(

                          icon: Icon(
                            isFavourite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                Colors.red,
                          ),

                          onPressed: () {

                            toggleFavourite(
                              temple,
                            );

                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: 1,
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

        if (index == 0) {

          Navigator.pop(context);

        }

        else if (index == 2) {

          // TODO: Itineraries Screen

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
}