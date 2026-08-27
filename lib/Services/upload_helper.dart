import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UploadHelper {
  /// Uploads a single file and returns its download URL
  static Future<String?> uploadFile(String localPath, String folder) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final file = File(localPath);
      if (!file.existsSync()) return null;

      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${localPath.split(Platform.pathSeparator).last}";
      final ref = FirebaseStorage.instance.ref().child("$folder/${user.uid}/$fileName");
      
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  /// Uploads multiple files in parallel and returns a list of download URLs
  static Future<List<String>> uploadMultipleFiles(List<dynamic> localPaths, String folder) async {
    final futures = localPaths.map((path) async {
      if (path == null) return null;
      if (path.toString().startsWith('http')) return path.toString();
      return await uploadFile(path.toString(), folder);
    });

    final results = await Future.wait(futures);
    return results.whereType<String>().toList();
  }
}
