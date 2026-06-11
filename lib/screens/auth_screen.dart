import 'package:flutter/material.dart';
import 'package:lumo/services/api_services.dart';
import 'map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {

  final bool startInLoginMode;

  const AuthScreen({
    super.key,
    this.startInLoginMode = false,
  });
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  late bool isLogin;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();

  final List<String> religions = [
    "Hinduism",
    "Buddhism",
    "Christianity",
    "Islam",
    "Judaism",
    "Other"
  ];

  final Set<String> selectedReligions = {"Hinduism"};

  @override
  void initState() {
    super.initState();

    isLogin = widget.startInLoginMode;
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey.shade100,

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(24),

          child: Column(

            children: [

              const SizedBox(height: 30),

              Image.asset(
                'assets/images/logo.png',
                width: 120,
              ),

              const SizedBox(height: 20),

              Text(
                isLogin
                    ? "Welcome Back"
                    : "Create Your Account",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLogin = false;
                        });
                      },
                      child: const Text("Sign Up"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLogin = true;
                        });
                      },
                      child: const Text("Login"),
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 20),

              if (!isLogin)
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                  ),
                ),

              if (!isLogin)
                const SizedBox(height: 15),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                ),
              ),

              const SizedBox(height: 15),

              if (!isLogin)
                TextField(
                  controller: mobileController,
                  decoration: const InputDecoration(
                    labelText: "Mobile Number",
                  ),
                ),

              if (!isLogin)
                const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                ),
              ),

              const SizedBox(height: 25),

              if (!isLogin) ...[

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select Religion(s)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: religions.map((religion) {

                    final selected =
                        selectedReligions.contains(religion);

                    return FilterChip(
                      label: Text(religion),
                      selected: selected,
                      onSelected: (_) {

                        setState(() {

                          if (selected) {
                            selectedReligions.remove(religion);
                          } else {
                            selectedReligions.add(religion);
                          }

                        });

                      },
                    );

                  }).toList(),
                ),

                const SizedBox(height: 25),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (isLogin) {

                      final result = await ApiService.login(
                        emailController.text.trim(),
                        passwordController.text,
                      );

                      if (!mounted) return;

                      if (result["success"] == true) {

                        final int userId =
                            result["userId"];

                        final String name =
                            result["name"] ?? "";

                        final List<String> religions =
                            List<String>.from(
                              result["religions"],
                            );

                        final prefs =
                            await SharedPreferences.getInstance();

                        await prefs.setBool(
                          "loggedIn",
                          true,
                        );

                        await prefs.setInt(
                          "userId",
                          userId,
                        );

                        await prefs.setString(
                          "name",
                          name,
                        );

                        await prefs.setStringList(
                          "religions",
                          religions,
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapScreen(
                              userId: userId,
                              userName: name,
                              religions: religions,
                            ),
                          ),
                        );
                      }
                      else {

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result["message"] ?? "Login Failed",
                            ),
                          ),
                        );

                      }
                      
                    } 
                    else {

                      final result = await ApiService.signup({

                        "name": nameController.text.trim(),

                        "email": emailController.text.trim(),

                        "password": passwordController.text,

                        "mobile": mobileController.text.trim(),

                        "religions": selectedReligions.toList(),

                      });

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result["success"] == true
                              ? "Signup Successful"
                              : "Signup Failed"
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    isLogin
                        ? "Login"
                        : "Create Account",
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}