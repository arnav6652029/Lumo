import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupScreen extends StatefulWidget {

  const StartupScreen({
    super.key,
  });

  @override
  State<StartupScreen> createState() =>
      _StartupScreenState();
}

class _StartupScreenState
    extends State<StartupScreen> {

  @override
  void initState() {

    super.initState();

    checkLogin();
  }

  Future<void> checkLogin() async {

    final prefs =
        await SharedPreferences.getInstance();

    final loggedIn =
        prefs.getBool(
          "loggedIn",
        ) ??
        false;

    if (!mounted) return;

    if (loggedIn) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MapScreen(

            userId:
                prefs.getInt(
                  "userId",
                ) ??
                0,

            userName:
                prefs.getString(
                  "name",
                ) ??
                "",

            religions:
                prefs.getStringList(
                  "religions",
                ) ??
                [],
          ),
        ),
      );

    } else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const WelcomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {

    return const Scaffold(

      body: Center(
        child:
            CircularProgressIndicator(),
      ),
    );
  }
}

void main() {
  runApp(const LumoApp());
}

class LumoApp extends StatelessWidget {
  const LumoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const StartupScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD99200),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            Image.asset(
              'assets/images/logo.png',
              width: 140,
              height: 140,
            ),
            SizedBox(height: 20),
            Text(
              "Lumo",
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Your Spiritual Journey Guide",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            )
          ],
        ),
      ),
    );
  }
}