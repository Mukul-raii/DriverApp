import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("🔑 signIn userCredential: $userCredential");
      return userCredential.user;
    } catch (e) {
      print("Error in signIn: $e");
      return null;
    }
  }

  // Register with email and password
  Future<User?> register({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      debugPrint("🔑 signIn userCredential: $userCredential");
      return userCredential.user;
    } catch (e) {
      print("Error in register: $e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error in signOut: $e");
    }
  }

  Future<void> authenticateUser(res) async {
    final url = dotenv.env['API_URL'];
    final idToken = await _auth.currentUser?.getIdToken();
    final finalUrl = Uri.parse('$url/driver/auth/verify');
    final response = await http.post(
      finalUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'idToken': idToken}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Get the authorization token from response headers
      final authToken = response.headers['authorization'];

      debugPrint("🔑 Auth token from headers: $authToken");
      debugPrint("🔑 Response data: $data");

      // Save the token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      debugPrint("🔑 Saving token to SharedPreferences");

      await prefs.setString('authToken', authToken ?? '');

      // Verify the token was saved
      final savedToken = prefs.getString('authToken');
      debugPrint("🔑 Saved token verification: $savedToken");

      print('✅ Authentication successful: ${response.statusCode}');
    } else {
      print(
        '❌ Authentication failed: ${response.statusCode} - ${response.body}',
      );
      print('URL: $finalUrl');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Auth state changes (useful for routing)
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}

class Authorization extends FirebaseAuthService {
  /// Function that handles both sign-in and registration
  Future<User?> authenticate({
    required String email,
    required String password,
    required String authType, // "login" or "register"
  }) async {
    try {
      User? res;
      if (authType == "login") {
        res = await signIn(email: email, password: password);
      } else if (authType == "register") {
        res = await register(email: email, password: password);
      } else {
        throw Exception("Invalid auth type: $authType");
      }
      debugPrint("🔑 Authentication result: $res");
      if (res != null) {
        await authenticateUser(res);
        debugPrint("User authenticated: ${res.email}");
      }
      return res;
    } catch (e) {
      print("Error in authenticate: $e");
      return null;
    }
  }
}
