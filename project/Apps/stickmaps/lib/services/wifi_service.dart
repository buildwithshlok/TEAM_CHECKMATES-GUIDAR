import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

enum ButtonType { next, previous, select }

// ToF sensor data model
class ObstacleData {
  final String sensor; // "HEAD", "MID", "GROUND"
  final int distance; // in cm
  final String severity; // "none", "medium", "high", "critical"

  ObstacleData({
    required this.sensor,
    required this.distance,
    required this.severity,
  });

  factory ObstacleData.fromJson(Map<String, dynamic> json) {
    return ObstacleData(
      sensor: json['sensor'] ?? '',
      distance: json['distance'] ?? -1,
      severity: json['severity'] ?? 'none',
    );
  }

  bool get hasObstacle => distance > 0 && distance < 100;
  bool get isCritical => severity == 'critical';
  bool get isHigh => severity == 'high';
  bool get isMedium => severity == 'medium';
}

class WiFiService {
  String? _esp32IP;
  static const int ESP32_PORT = 80;
  static const String ESP32_HOSTNAME = "smartblindstick.local";

  // ============================================
  // CONFIGURATION: Set your ESP32's IP here
  // ============================================
  static const String? HARDCODED_IP = "10.225.167.76";

  // WebSocket
  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  Timer? _discoveryTimer;

  // Stream controllers
  final StreamController<ButtonType> _buttonPressController =
      StreamController<ButtonType>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<List<ObstacleData>> _obstacleController =
      StreamController<List<ObstacleData>>.broadcast();
  final StreamController<Map<String, dynamic>> _statusController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters
  Stream<ButtonType> get buttonPressStream => _buttonPressController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<List<ObstacleData>> get obstacleStream => _obstacleController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  bool get isConnected => _isConnected;
  String? get esp32IP => _esp32IP;

  WiFiService() {
    if (HARDCODED_IP != null) {
      print("WiFi Service: Using hardcoded IP: $HARDCODED_IP");
      _esp32IP = HARDCODED_IP;
      connectToESP32();
    } else {
      print("WiFi Service: Using auto-discovery mode");
      _startAutoDiscovery();
    }
  }

  void _startAutoDiscovery() {
    print("WiFi Service: Starting auto-discovery...");
    _discoverESP32();

    _discoveryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected) {
        print("Auto-discovery: Searching for ESP32...");
        _discoverESP32();
      }
    });
  }

  Future<void> _discoverESP32() async {
    if (_isConnected && _channel != null) {
      print("Already connected to ESP32");
      return;
    }

    try {
      final networkInfo = NetworkInfo();
      final wifiIP = await networkInfo.getWifiIP();

      if (wifiIP == null) {
        print("Not connected to WiFi network");
        return;
      }

      print("Phone IP: $wifiIP");
      final parts = wifiIP.split('.');
      if (parts.length != 4) return;

      final networkPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';
      print("Scanning network: $networkPrefix.x");

      // Try mDNS hostname first
      print("Trying mDNS: $ESP32_HOSTNAME");
      if (await _tryConnect(ESP32_HOSTNAME)) return;

      // Try common IPs
      final commonIPs = ['$networkPrefix.1', '$networkPrefix.254'];
      for (final ip in commonIPs) {
        print("Trying common IP: $ip");
        if (await _tryConnect(ip)) return;
      }

      // Extended scan
      print("Performing extended IP scan...");
      for (int i = 2; i <= 50; i++) {
        final ip = '$networkPrefix.$i';
        if (ip == wifiIP) continue;
        if (await _tryConnect(ip)) return;
      }

      print("ESP32 not found on network after full scan");
    } catch (e) {
      print("Discovery error: $e");
    }
  }

  Future<bool> _tryConnect(String address) async {
    try {
      final url = address.contains(':')
          ? 'http://$address/status'
          : 'http://$address:$ESP32_PORT/status';

      print("Checking: $url");

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(milliseconds: 1500));

      if (response.statusCode == 200) {
        print("Got response from $address: ${response.body}");

        try {
          final data = jsonDecode(response.body);

          final isOurDevice =
              (data['wifi_connected'] == true) ||
              (data['connected'] != null) ||
              (data['ip'] != null && data['rssi'] != null) ||
              (data['tof_sensors'] != null); // Check for ToF sensors

          if (isOurDevice) {
            final ip = address.contains(':') ? address.split(':')[0] : address;

            print("✓ Found ESP32 at: $ip");
            _esp32IP = ip;

            await connectToESP32();
            return true;
          }
        } catch (e) {
          print("JSON parse error for $address: $e");
        }
      }
    } catch (e) {
      // Silently fail during scanning
    }

    return false;
  }

  Future<bool> connectToESP32() async {
    if (_esp32IP == null) {
      print("No ESP32 IP available");
      return false;
    }

    try {
      if (_isConnected && _channel != null) {
        print("Already connected to WebSocket");
        return true;
      }

      print("Connecting to WebSocket: ws://$_esp32IP:$ESP32_PORT/ws");

      await disconnect();

      final wsUrl = Uri.parse('ws://$_esp32IP:$ESP32_PORT/ws');
      _channel = WebSocketChannel.connect(wsUrl);

      await _channel!.ready.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('WebSocket connection timeout');
        },
      );

      _isConnected = true;
      _connectionController.add(true);
      print("✓ WebSocket connected successfully!");

      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          print("WebSocket error: $error");
          _handleDisconnection();
        },
        onDone: () {
          print("WebSocket closed by server");
          _handleDisconnection();
        },
        cancelOnError: false,
      );

      _startPingTimer();
      _sendMessage({'type': 'ping'});

      return true;
    } catch (e) {
      print("Connection error: $e");
      _handleDisconnection();
      return false;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'] ?? '';

      switch (type) {
        case 'connected':
          print("ESP32 confirmed connection");
          final version = data['version'] ?? 'unknown';
          final sensors = data['sensors'] ?? 0;
          _statusController.add({
            'version': version,
            'sensors': sensors,
            'message': data['message'],
          });
          break;

        case 'button':
          _handleButtonMessage(data['button']);
          break;

        case 'obstacles':
          _handleObstacleMessage(data);
          break;

        case 'pong':
          print("Received pong from ESP32");
          final rssi = data['rssi'] ?? 0;
          _statusController.add({'rssi': rssi, 'type': 'ping'});
          break;
      }
    } catch (e) {
      print("Message parse error: $e");
    }
  }

  void _handleObstacleMessage(Map<String, dynamic> data) {
    try {
      final obstaclesData = data['data'] as List<dynamic>?;
      if (obstaclesData == null) return;

      List<ObstacleData> obstacles = obstaclesData
          .map((item) => ObstacleData.fromJson(item as Map<String, dynamic>))
          .toList();

      _obstacleController.add(obstacles);

      print("Obstacles detected:");
      for (var obs in obstacles) {
        if (obs.hasObstacle) {
          print("  ${obs.sensor}: ${obs.distance}cm (${obs.severity})");
        }
      }
    } catch (e) {
      print("Obstacle message parse error: $e");
    }
  }

  void _handleButtonMessage(String button) {
    print("Button pressed: $button");

    switch (button.toUpperCase()) {
      case 'NEXT':
        _buttonPressController.add(ButtonType.next);
        break;
      case 'PREVIOUS':
      case 'PREV':
        _buttonPressController.add(ButtonType.previous);
        break;
      case 'SELECT':
        _buttonPressController.add(ButtonType.select);
        break;
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        final jsonString = jsonEncode(message);
        _channel!.sink.add(jsonString);
        print("Sent message: $jsonString");
      } catch (e) {
        print("Send error: $e");
      }
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isConnected) {
        _sendMessage({'type': 'ping'});
      } else {
        timer.cancel();
      }
    });
  }

  void _handleDisconnection() {
    if (!_isConnected) return;

    print("Connection lost - will attempt to reconnect");

    _isConnected = false;
    _connectionController.add(false);
    _pingTimer?.cancel();

    Future.delayed(const Duration(seconds: 2), () {
      if (!_isConnected && _esp32IP != null) {
        print("Attempting to reconnect...");
        connectToESP32();
      }
    });
  }

  // Vibration commands
  Future<void> sendVibration(String pattern) async {
    _sendMessage({'type': 'vibration', 'command': pattern});
  }

  Future<void> vibrateShort() async => await sendVibration("VIBRATE_SHORT");
  Future<void> vibrateLong() async => await sendVibration("VIBRATE_LONG");
  Future<void> vibratePattern(String pattern) async =>
      await sendVibration("VIBRATE_$pattern");
  Future<void> vibrateLeftTurn() async => await sendVibration("VIBRATE_LEFT");
  Future<void> vibrateRightTurn() async => await sendVibration("VIBRATE_RIGHT");
  Future<void> vibrateDestinationReached() async =>
      await sendVibration("VIBRATE_DESTINATION");
  Future<void> vibrateDouble() async => await sendVibration("VIBRATE_DOUBLE");
  Future<void> vibrateTriple() async => await sendVibration("VIBRATE_TRIPLE");

  // Get connection info
  Future<Map<String, dynamic>> getConnectionInfo() async {
    try {
      if (!_isConnected || _esp32IP == null) {
        return {'connected': false, 'searching': true};
      }

      final response = await http
          .get(Uri.parse('http://$_esp32IP:$ESP32_PORT/status'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'connected': true,
          'ip': _esp32IP,
          'wifi_ssid': data['wifi_ssid'],
          'wifi_rssi': data['rssi'] ?? data['wifi_rssi'],
          'tof_sensors': data['tof_sensors'],
        };
      }
    } catch (e) {
      print("Get info error: $e");
    }

    return {'connected': _isConnected, 'ip': _esp32IP};
  }

  // Manual refresh
  Future<void> refresh() async {
    print("Manual refresh triggered");

    if (HARDCODED_IP != null) {
      _esp32IP = HARDCODED_IP;
      _isConnected = false;
      await connectToESP32();
    } else {
      _esp32IP = null;
      _isConnected = false;
      await _discoverESP32();
    }
  }

  // Disconnect
  Future<void> disconnect() async {
    try {
      _pingTimer?.cancel();
      if (_channel != null) {
        await _channel?.sink.close(status.goingAway);
        _channel = null;
      }
      if (_isConnected) {
        _isConnected = false;
        _connectionController.add(false);
      }
    } catch (e) {
      print("Disconnect error: $e");
    }
  }

  // Dispose
  void dispose() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _discoveryTimer?.cancel();
    disconnect();
    _buttonPressController.close();
    _connectionController.close();
    _obstacleController.close();
    _statusController.close();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
