import 'dart:convert';
import 'package:lumo/models/temple.dart';
import 'package:http/http.dart' as http;


class ApiService {

  static const String baseUrl =
      "https://lumo-api-t204.onrender.com";
      
  static Future<List<Temple>> getTemples(
    String religion) async {

  final response = await http.get(
    Uri.parse(
      "$baseUrl/temples?religion=$religion",
    ),
  );

  final List data =
      jsonDecode(response.body);

  return data
      .map((e) => Temple.fromJson(e))
      .toList();
  }
  static Future<List<Temple>>
      getFeaturedTemples() async {

    final response = await http.get(
      Uri.parse(
        "$baseUrl/featured-temples",
      ),
    );

    if (response.statusCode == 200) {

      final List data =
          jsonDecode(response.body);

      return data
          .map(
            (e) => Temple.fromJson(e),
          )
          .toList();
    }

    throw Exception(
      "Failed to load featured temples",
    );
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password) async {

    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    return data;
  }

  static Future<Map<String, dynamic>> signup(
    Map<String, dynamic> body) async {

    final response = await http.post(
      Uri.parse("$baseUrl/signup"),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    return data;
  }
  static Future<List<int>> getFavouriteTempleIds(
    int userId,
  ) async {

    final response = await http.get(
      Uri.parse(
        "$baseUrl/favourites/$userId",
      ),
    );

    final List data =
        jsonDecode(response.body);

    return data
        .map<int>(
          (e) => e["temple_id"] as int,
        )
        .toList();
  }
  static Future<void> updateReligions(
    int userId,
    List<String> religions,
  ) async {

    await http.post(
      Uri.parse(
        "$baseUrl/update-religions",
      ),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "userId": userId,
        "religions": religions,
      }),
    );
  }
  static Future<void> addFavourite(
    int userId,
    int templeId,
  ) async {

    await http.post(
      Uri.parse(
        "$baseUrl/favourites/add",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userId": userId,
        "templeId": templeId,
      }),
    );
  }
  static Future<void> removeFavourite(
    int userId,
    int templeId,
  ) async {

    await http.post(
      Uri.parse(
        "$baseUrl/favourites/remove",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userId": userId,
        "templeId": templeId,
      }),
    );
  }
}
