import 'package:driverapp/services/rideService.dart';
import 'package:driverapp/utils/socket.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> rideData = [];

  @override
  void initState() {
    super.initState();
    _loadRides();

    // Listen for socket updates
    SocketService().initSocket();
    SocketService().socket.on("rideRequested", (_) {
      _loadRides();
    });
    SocketService().socket.on("newRide", (_) {
      _loadRides();
    });
  }

  Future<void> _loadRides() async {
    debugPrint("🔄 Fetching latest rides...");

    try {
      final response = await Rideservice().fetchRides();

      if (mounted) {
        setState(() {
          // Since fetchRides() returns List<Map<String, dynamic>>,
          // we can directly assign it
          rideData = response;
        });
      }
    } catch (e) {
      debugPrint("Error loading rides: $e");
      if (mounted) {
        setState(() {
          rideData = []; // Set empty list on error
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomeScreen(rideData: rideData),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Driver App'), // You can set a title here if needed
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> rideData;
  const HomeScreen({super.key, required this.rideData});

  @override
  Widget build(BuildContext context) {
    if (rideData.isEmpty) {
      return const Center(
        child: Text("No rides available", style: TextStyle(fontSize: 18)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rideData.length,
      itemBuilder: (context, index) {
        final ride = rideData[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🚖 Ride ID: ${ride['id'] ?? ''}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text("📍 From: ${ride['fromLocation'] ?? ''}"),
                Text("🏁 To: ${ride['toLocation'] ?? ''}"),
                const SizedBox(height: 10),
                if (ride['status'] == "REQUESTED")
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await Rideservice().updateRideStatus({
                            "id": ride['id'],
                            "status": "ACCEPTED",
                          });
                          await Rideservice().fetchRides();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text("Accept"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          await Rideservice().updateRideStatus({
                            "id": ride['id'],
                            "status": "REJECTED",
                          });
                          await Rideservice().fetchRides();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text("Reject"),
                      ),
                    ],
                  ),
                Text(
                  "📌 Status: ${ride['status'] ?? ''}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (ride['createdAt'] != null)
                  Text("🕒 Created: ${ride['createdAt']}"),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// PROFILE SCREEN
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person, size: 80, color: Colors.blue),
          SizedBox(height: 20),
          Text(
            'This is your Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
