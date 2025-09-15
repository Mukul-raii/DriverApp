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
    final finalUrl = Uri.parse('$url/driver/auth');
    final response = await http.post(
      finalUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'idToken': idToken}),
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      final idToken = response.headers['authorization'];
      debugPrint("🔑 idToken: $idToken");
      final prefs = await SharedPreferences.getInstance();
      debugPrint("🔑 sving token ");

      prefs.setString('authToken', idToken ?? '');
      prefs.getString('authToken');
      debugPrint("🔑  token saved  $prefs.getString('authToken')");

      debugPrint(data);
    } else {
      debugPrint('Error: ${response.statusCode}');
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
