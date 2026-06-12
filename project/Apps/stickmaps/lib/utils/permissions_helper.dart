import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionsHelper {
  // Request all necessary permissions
  static Future<Map<String, bool>> requestAllPermissions() async {
    Map<String, bool> permissionStatus = {};

    // Request location permissions
    PermissionStatus locationStatus = await Permission.location.request();
    permissionStatus['location'] = locationStatus.isGranted;

    PermissionStatus locationWhenInUse = await Permission.locationWhenInUse
        .request();
    permissionStatus['locationWhenInUse'] = locationWhenInUse.isGranted;

    // Request Bluetooth permissions (Android 12+)
    PermissionStatus bluetoothScan = await Permission.bluetoothScan.request();
    permissionStatus['bluetoothScan'] = bluetoothScan.isGranted;

    PermissionStatus bluetoothConnect = await Permission.bluetoothConnect
        .request();
    permissionStatus['bluetoothConnect'] = bluetoothConnect.isGranted;

    PermissionStatus bluetooth = await Permission.bluetooth.request();
    permissionStatus['bluetooth'] = bluetooth.isGranted;

    // Request microphone for speech recognition
    PermissionStatus microphone = await Permission.microphone.request();
    permissionStatus['microphone'] = microphone.isGranted;

    // Request speech recognition
    PermissionStatus speech = await Permission.speech.request();
    permissionStatus['speech'] = speech.isGranted;

    return permissionStatus;
  }

  // Request location permission
  static Future<bool> requestLocation() async {
    PermissionStatus status = await Permission.location.request();
    return status.isGranted;
  }

  // Request Bluetooth permissions
  static Future<bool> requestBluetooth() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  // Request microphone permission
  static Future<bool> requestMicrophone() async {
    PermissionStatus status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Request speech recognition permission
  static Future<bool> requestSpeech() async {
    PermissionStatus status = await Permission.speech.request();
    return status.isGranted;
  }

  // Check if location permission is granted
  static Future<bool> isLocationGranted() async {
    PermissionStatus status = await Permission.location.status;
    return status.isGranted;
  }

  // Check if Bluetooth permissions are granted
  static Future<bool> isBluetoothGranted() async {
    PermissionStatus bluetooth = await Permission.bluetooth.status;
    PermissionStatus bluetoothScan = await Permission.bluetoothScan.status;
    PermissionStatus bluetoothConnect =
        await Permission.bluetoothConnect.status;

    return bluetooth.isGranted &&
        bluetoothScan.isGranted &&
        bluetoothConnect.isGranted;
  }

  // Check if microphone permission is granted
  static Future<bool> isMicrophoneGranted() async {
    PermissionStatus status = await Permission.microphone.status;
    return status.isGranted;
  }

  // Check if speech permission is granted
  static Future<bool> isSpeechGranted() async {
    PermissionStatus status = await Permission.speech.status;
    return status.isGranted;
  }

  // Show permission explanation dialog
  static Future<void> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onAccept,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(message)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Grant Permission'),
              onPressed: () {
                Navigator.of(context).pop();
                if (onAccept != null) {
                  onAccept();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Open app settings
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  // Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(
    Permission permission,
  ) async {
    PermissionStatus status = await permission.status;
    return status.isPermanentlyDenied;
  }

  // Request permission with explanation
  static Future<bool> requestPermissionWithExplanation(
    BuildContext context,
    Permission permission,
    String title,
    String message,
  ) async {
    // Check if permission is already granted
    if (await permission.isGranted) {
      return true;
    }

    // Check if we should show rationale
    if (await permission.shouldShowRequestRationale) {
      // Show explanation dialog
      bool shouldRequest = false;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  shouldRequest = false;
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  shouldRequest = true;
                  Navigator.of(context).pop();
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );

      if (!shouldRequest) {
        return false;
      }
    }

    // Request the permission
    PermissionStatus status = await permission.request();

    // If permanently denied, show settings dialog
    if (status.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permission Required'),
            content: Text(
              'This permission is required for the app to function properly. '
              'Please grant it in the app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
      return false;
    }

    return status.isGranted;
  }

  // Get permission status summary
  static Future<Map<String, String>> getPermissionStatusSummary() async {
    Map<String, String> summary = {};

    summary['Location'] = (await Permission.location.status).toString();
    summary['Bluetooth'] = (await Permission.bluetooth.status).toString();
    summary['Bluetooth Scan'] = (await Permission.bluetoothScan.status)
        .toString();
    summary['Bluetooth Connect'] = (await Permission.bluetoothConnect.status)
        .toString();
    summary['Microphone'] = (await Permission.microphone.status).toString();
    summary['Speech'] = (await Permission.speech.status).toString();

    return summary;
  }
}
