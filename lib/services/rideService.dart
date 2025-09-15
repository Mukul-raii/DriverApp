import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final url = dotenv.env['API_URL'];

class Rideservice {
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) {
      throw Exception("No auth token found");
    }
    return token;
  }

  // Example method to fetch rides
  Future<List<Map<String, dynamic>>> fetchRides() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final res = await http.get(
      Uri.parse('$url/driver/rides'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      debugPrint('Response: ${res.body}');

      // If API returns { result: [...] } - YOUR CURRENT API STRUCTURE
      if (body is Map && body['result'] is List) {
        return List<Map<String, dynamic>>.from(body['result']);
      }
      // If API returns { rides: [...] }
      else if (body is Map && body['rides'] is List) {
        return List<Map<String, dynamic>>.from(body['rides']);
      }
      // If API directly returns [...]
      else if (body is List) {
        return List<Map<String, dynamic>>.from(body);
      }
    }

    return []; // fallback empty
  }

  // Example method to fetch rides
  Future<void> getProfile() async {
    // Use the url variable here for API calls
    final res = await http.get(
      uriParse('driver/profile'),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": await getToken(),
      },
    );
    print('Fetching rides from $url');
    print(' Response: ${res.body}');
    // Add your API call logic here
  }
}

Uri uriParse(String path) {
  final parsedUrl = Uri.parse('$url/$path');
  return parsedUrl;
}
