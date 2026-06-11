import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'favourite_temples_screen.dart';

Future<void> openWebPage() async {
  final Uri url = Uri.parse(
    "https://undamageable-histogenetically-bowen.ngrok-free.dev/",
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

class AccountScreen extends StatelessWidget {

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
                    userName,
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
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,

                    children: const [
                      Text(
                        "My Religions",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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
                            userId: userId,
                            userName: userName,
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