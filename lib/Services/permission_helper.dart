import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionHelper {
  /// ✅ Request Photo Library permissions safely
  static Future<bool> requestPhotoPermission(BuildContext context) async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      PermissionStatus status;
      if (sdkInt >= 33) {
        // Request specific media permission for Android 13+
        status = await Permission.photos.request();
      } else {
        // For Android 12 and below, we still need storage permission
        status = await Permission.storage.request();
      }

      if (status.isGranted || status.isLimited) return true;
      
      if (status.isPermanentlyDenied || status.isDenied) {
        if (context.mounted) {
          _showSettingsDialog(context, "Photos");
        }
        return false;
      }
    }

    return false;
  }

  /// Request Notification Permission
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.request();
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsDialog(context, "Notifications");
      }
    }
    return false;
  }

  static void _showSettingsDialog(BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$permissionName Permission Required"),
        content: Text(
            "This app needs $permissionName permission to function correctly. Please enable it in settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }
}
