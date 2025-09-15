import 'package:driverapp/services/rideService.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;

  void initSocket() {
    socket = IO.io(
      'http://localhost:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) => print('✅ Connected to socket server'));
    socket.emit('joinDriverRoom', 'r08gW54mzyZUf6bTa1FNJiiRj7X2');
    socket.on("newRide", (data) async {
      print("🔄 Ride update received: $data");
      await Rideservice().fetchRides();
    });

    socket.onDisconnect((_) => print('❌ Disconnected from socket server'));
  }

  void joinRiderRoom(String riderId) {
    print("🚕 Joining rider room with ID: $riderId");
    socket.emit('joinRiderRoom', riderId);
  }

  void emitRideRequest(Map<String, dynamic> ride, String riderId) {
    print("📡 Emitting ride request for $riderId: $ride");
    socket.emit('rideRequest', {"ride": ride, "riderId": riderId});
  }
}
