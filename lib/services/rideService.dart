import 'dart:convert';

import 'package:driverapp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final url = dotenv.env['API_URL'];
final rideUrl = 'http://localhost:8002/api/v1/rider';

class Rideservice {
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) {
      throw Exception("No auth token found");
    }
    return token;
  }

  Future<List<Map<String, dynamic>>> fetchRides() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final res = await http.get(
      Uri.parse('$url/driver/ride/rides'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      debugPrint('Response: ${res.body}');

      // API returns { data: [...] }
      if (body is Map && body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
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

  //Accept or reject ride

  // Example method to fetch rides
  Future<void> updateRideStatus(Map<String, dynamic> rideData) async {
    // Use the url variable here for API calls
    final res = await http.patch(
      uriParse('driver/ride/update-status/${rideData['id']}'),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": await getToken(),
      },
      body: jsonEncode(rideData),
    );
    if (res.statusCode == 200) {
      await Rideservice().fetchRides();
      rideData['status'] = jsonDecode(res.body)['data']['status'];
      print(rideData['status']);
      if (rideData['status'] == 'ACCEPTED') {
        await acceptRide(rideData);
      }
      if (rideData['status'] == 'REJECTED') {
        await rejectRide(rideData);
      }
      socketService.updateRideStatus(jsonDecode(res.body)['data']);
      print('✅ Ride status updated: ${res.body}');
    } else {
      print('❌ Failed to update ride status: ${res.statusCode} - ${res.body}');
    }
    // Add your API call logic here
  }

  acceptRide(Map<String, dynamic> rideData) async {
    final res = await http.patch(
      rideUrlParse('ride/accept-ride'),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": await getToken(),
      },
      body: jsonEncode(rideData),
    );
    if (res.statusCode == 200) {
    } else {
      print('❌ Failed to accept ride: ${res.statusCode} - ${res.body}');
    }
  }

  rejectRide(Map<String, dynamic> rideData) async {
    final res = await http.patch(
      rideUrlParse('ride/reject-ride'),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": await getToken(),
      },
      body: jsonEncode(rideData),
    );
    if (res.statusCode == 200) {
    } else {
      print('❌ Failed to reject ride: ${res.statusCode} - ${res.body}');
    }
  }
}

Uri uriParse(String path) {
  final parsedUrl = Uri.parse('$url/$path');
  return parsedUrl;
}

Uri rideUrlParse(String path) {
  final parsedUrl = Uri.parse('$rideUrl/$path');
  return parsedUrl;
}
