import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PermissionManager {
  static final PermissionManager instance = PermissionManager._internal();
  PermissionManager._internal();

  /// Request all essential permissions for the app on startup
  Future<void> requestAllPermissions() async {
    try {
      // 1. Notification Permission (Android 13+)
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          if (await Permission.notification.status.isDenied) {
            await Permission.notification.request();
          }
        }
      } else {
        await Permission.notification.request();
      }
      
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. Location Permission
      if (await Permission.locationWhenInUse.status.isDenied) {
        await Permission.locationWhenInUse.request();
      }

      await Future.delayed(const Duration(milliseconds: 300));

      // 3. Media/Photos Permission
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          if (await Permission.photos.status.isDenied) {
            await Permission.photos.request();
          }
        } else {
          if (await Permission.storage.status.isDenied) {
            await Permission.storage.request();
          }
        }
      } else if (Platform.isIOS) {
        if (await Permission.photos.status.isDenied) {
          await Permission.photos.request();
        }
      }
      
    } catch (e) {
      debugPrint("Permission Request Error: $e");
    }
  }

  /// ✅ Check and request Location Permission Specifically
  Future<bool> handleLocationPermission(BuildContext context) async {
    PermissionStatus status = await Permission.locationWhenInUse.status;
    
    if (status.isGranted) return true;
    
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      _showSettingsDialog(context, "Location");
      return false;
    }
    
    return false;
  }

  /// ✅ Check and request Media/Gallery Permission Specifically
  Future<bool> handleMediaPermission(BuildContext context) async {
    PermissionStatus status;
    
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        status = await Permission.photos.status;
      } else {
        status = await Permission.storage.status;
      }
    } else {
      status = await Permission.photos.status;
    }

    if (status.isGranted) return true;

    if (status.isDenied) {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        status = (androidInfo.version.sdkInt >= 33) 
            ? await Permission.photos.request() 
            : await Permission.storage.request();
      } else {
        status = await Permission.photos.request();
      }
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      _showSettingsDialog(context, "Gallery/Storage");
      return false;
    }

    return false;
  }

  void _showSettingsDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$type Permission Required"),
        content: Text("You have permanently denied $type permission. Please enable it from app settings to continue."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text("OPEN SETTINGS"),
          ),
        ],
      ),
    );
  }
}
