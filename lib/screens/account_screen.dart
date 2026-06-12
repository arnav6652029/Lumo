import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'favourite_temples_screen.dart';
import 'package:lumo/services/api_services.dart';

Future<void> openWebPage() async {
  final Uri url = Uri.parse(
    "https://lumo-api-t204.onrender.com",
  );

  if (!await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  )) {
    throw Exception("Could not launch website");
  }
}

Widget religionIcon(String religion) {

  switch (religion.toLowerCase()) {

    case "hindu":
    case "hinduism":
      return const Text(
        "🕉️",
        style: TextStyle(fontSize: 28),
      );

    case "buddhist":
    case "buddhism":
      return const Text(
        "☸️",
        style: TextStyle(fontSize: 28),
      );

    case "sikh":
    case "sikhism":
      return const Text(
        "☬",
        style: TextStyle(fontSize: 28),
      );

    case "christian":
    case "christianity":
      return const Text(
        "✝️",
        style: TextStyle(fontSize: 28),
      );

    case "muslim":
    case "islam":
      return const Text(
        "☪️",
        style: TextStyle(fontSize: 28),
      );

    default:
      return const Icon(
        Icons.place,
      );
  }
}

Widget accountTile({
  required String title,
  required VoidCallback onTap,
}) {
  return ListTile(
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class AccountScreen extends StatefulWidget {

  final int userId;
  final String userName;
  final List<String> religions;

  const AccountScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.religions,
  });

  @override
  State<AccountScreen> createState() =>
      _AccountScreenState();
}

class _AccountScreenState
    extends State<AccountScreen> {

  late List<String> religions;

  @override
  void initState() {
    super.initState();

    religions = List.from(
      widget.religions,
    );
  }
  void _showReligionEditor(
    BuildContext context,
  ) {

    List<String> selected =
        List.from(religions);

    final allReligions = [
      "Hinduism",
      "Buddhism",
      "Christianity",
      "Islam",
      "Judaism",
      "Other",
    ];

    showDialog(
      context: context,
      builder: (context) {

        return StatefulBuilder(
          builder: (context, setDialogState) {

            return AlertDialog(
              title: const Text(
                "Edit Religions",
              ),

              content: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children:
                    allReligions.map(
                  (religion) {

                    return CheckboxListTile(
                      title: Text(
                        religion,
                      ),

                      value:
                          selected.contains(
                        religion,
                      ),

                      onChanged: (
                        value,
                      ) {

                        setDialogState(
                          () {

                            if (value ==
                                true) {

                            if (value == true) {

                              if (!selected.contains(religion)) {
                                selected.add(religion);
                              }

                            }

                            } else {

                              if (selected
                                      .length >
                                  1) {

                                selected.remove(
                                  religion,
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                ).toList(),
              ),

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text(
                    "Cancel",
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {

                    try {

                      await ApiService.updateReligions(
                        widget.userId,
                        selected,
                      );

                      setState(() {
                        religions = selected;
                      });

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Religions updated",
                          ),
                        ),
                      );

                    } catch (e) {

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Failed to update religions",
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Save",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Account"),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 40,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFD99200),
              ),

              child: Column(
                children: [

                  const CircleAvatar(
                    radius: 45,
                    child: Icon(
                      Icons.person,
                      size: 50,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My Religions",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          _showReligionEditor(context);
                        },
                        child: const Text("Edit"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    children: religions
                        .map(religionIcon)
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  accountTile(
                    title: "Saved Temples",
                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => 
                          FavouriteTemplesScreen(
                            userId: widget.userId,
                            userName: widget.userName,
                            religions: religions,
                          ),
                        ),
                      );

                    },
                  ),

                  accountTile(
                    title: "Payment Methods",
                    onTap: openWebPage,
                  ),

                  accountTile(
                    title: "Help & Support",
                    onTap: openWebPage,
                  ),

                  accountTile(
                    title: "About Lumo",
                    onTap: openWebPage,
                  ),

                  const SizedBox(height: 10),

                  ListTile(
                    title: const Text(
                      "Log Out",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    onTap: () {

                      Navigator.popUntil(
                        context,
                        (route) => route.isFirst,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}