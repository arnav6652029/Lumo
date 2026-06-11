import 'dart:convert';
import 'package:http/http.dart' as http;

class NavigationService {

  static const String apiKey =
      "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImFmNDgzZjg2ZjQzMDRmN2E5ZjMzYWU0ZDlhNTMzZWIyIiwiaCI6Im11cm11cjY0In0=";

  static Future<Map<String, dynamic>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {

    final response = await http.post(
      Uri.parse(
        "https://api.openrouteservice.org/v2/directions/driving-car/geojson",
      ),
      headers: {
        "Authorization": apiKey,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "coordinates": [
          [startLng, startLat],
          [endLng, endLat]
        ]
      }),
    );

    return jsonDecode(response.body);
  }
}