import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class DataManager {
  static final DataManager instance = DataManager._internal();
  DataManager._internal();

  List<Map<String, dynamic>> userData = [];
  bool isLoading = false;

  Future<void> fetchAllData({Position? currentPosition}) async {
    if (isLoading) return; // Prevent multiple simultaneous fetches

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    isLoading = true;
    try {
      final List<Map<String, dynamic>> docs = [];

      // 🔥 Get blocked user IDs for current user
      final blockedSnap = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("blocked")
          .get();
      final blockedIds = blockedSnap.docs.map((d) => d.id).toSet();

      // ✅ 1. Fetch from global 'ads' collection (Primary Teacher App collection)
      try {
        final adsSnap = await FirebaseFirestore.instance.collection("ads").get();
        for (var doc in adsSnap.docs) {
          final data = doc.data();
          final parentId = data['teacherId']?.toString() ?? data['uid']?.toString() ?? '';

          if (blockedIds.contains(parentId)) continue;
          if (blockedIds.contains(doc.id)) continue;

          final expiryStr = data['expiryDate'];
          if (expiryStr != null) {
            final expiry = expiryStr is Timestamp
                ? expiryStr.toDate()
                : DateTime.tryParse(expiryStr.toString());
            if (expiry != null && DateTime.now().isAfter(expiry)) {
              continue;
            }
          }

          final avatarUrl = data['avatar'] ?? data['avatarUrl'] ?? data['imageUrl'] ?? data['profilePic'];
          final plan = data['selectedPlan']?.toString() ?? '';

          double distance = 999999;
          if (currentPosition != null && data['location'] != null) {
            if (data['location'] is Map) {
              final uLoc = data['location'] as Map;
              final lat = uLoc['lat'] ?? uLoc['latitude'];
              final lng = uLoc['lng'] ?? uLoc['longitude'];
              if (lat != null && lng != null) {
                distance = Geolocator.distanceBetween(
                  currentPosition.latitude,
                  currentPosition.longitude,
                  (lat as num).toDouble(),
                  (lng as num).toDouble(),
                );
              }
            }
          }

          int radiusLimit = 10000;
          if (plan.contains('Elite')) {
            radiusLimit = 50000;
          } else if (plan.contains('Pro')) {
            radiusLimit = 25000;
          }

          if (distance > radiusLimit) continue;

          docs.add({
            ...data,
            "id": doc.id,
            "parentId": parentId,
            "type": data['formType'] ?? data['type'] ?? 'hometutor',
            "avatarUrl": avatarUrl,
            "calculatedDistance": distance,
          });
        }
      } catch (e) {
        debugPrint("Error fetching global ads: $e");
      }

      // ✅ 2. Fetch from legacy subcollections
      final subCollections = [
        "hometutor",
        "homecoaching",
        "homeinstructor",
        "nur-12coaching",
        "coaching",
        "school",
        "college",
        "skill",
        "jobs",
        "onlineclass"
      ];

      // ✅ Use collectionGroup to fetch all ads of a type across all users in one go.
      // This is much faster than looping through every user.
      final allSubCollectionsFetches = subCollections.map((sub) => 
        FirebaseFirestore.instance.collectionGroup(sub).get()
      );

      final querySnapshots = await Future.wait(allSubCollectionsFetches);

      for (int i = 0; i < subCollections.length; i++) {
        final sub = subCollections[i];
        final subSnap = querySnapshots[i];

        for (var doc in subSnap.docs) {
          final data = doc.data();
          final parentId = doc.reference.parent.parent?.id ?? '';

          // ✅ Skip if Parent is blocked
          if (blockedIds.contains(parentId)) continue;
          // ✅ Skip if Ad itself is blocked
          if (blockedIds.contains(doc.id)) continue;
          
          // ✅ Check Expiry
          final expiryStr = data['expiryDate'];
          if (expiryStr != null) {
            final expiry = DateTime.tryParse(expiryStr);
            if (expiry != null && DateTime.now().isAfter(expiry)) {
              continue; 
            }
          }

          final avatarUrl = data['avatarUrl'] ?? data['imageUrl'] ?? data['avatar'];
          final plan = data['selectedPlan']?.toString() ?? '';

          double distance = 999999; 
          if (currentPosition != null && data['location'] != null) {
            final uLoc = data['location'] as Map<String, dynamic>;
            if (uLoc['latitude'] != null && uLoc['longitude'] != null) {
              distance = Geolocator.distanceBetween(
                currentPosition.latitude,
                currentPosition.longitude,
                (uLoc['latitude'] as num).toDouble(),
                (uLoc['longitude'] as num).toDouble(),
              );
            }
          }

          int radiusLimit = 10000;
          if (plan.contains('Elite')) {
            radiusLimit = 50000;
          } else if (plan.contains('Pro')) {
            radiusLimit = 25000;
          }

          if (distance > radiusLimit) continue;

          docs.add({
            ...data,
            "id": doc.id,
            "parentId": parentId,
            "type": sub,
            "avatarUrl": avatarUrl,
            "calculatedDistance": distance,
          });
        }
      }

      // 🔥 Sorting Logic
      // 1. Primary: Effective Time (Descending) - This handles "Freshness" and "Boosting"
      // 2. Secondary: Priority Rank (Elite > Pro > Normal) for similar times
      // 3. Tertiary: Distance Ascending (Near to Far)
      docs.sort((a, b) {
        final timeA = getEffectiveTime(a);
        final timeB = getEffectiveTime(b);

        // Compare effective times (rounded to the nearest hour to allow rank tie-breaking)
        final hourA = DateTime(timeA.year, timeA.month, timeA.day, timeA.hour);
        final hourB = DateTime(timeB.year, timeB.month, timeB.day, timeB.hour);

        if (hourA != hourB) {
          return hourB.compareTo(hourA); // Newest/Boosted first
        }

        // Tie-break with Rank
        final planA = a['selectedPlan']?.toString() ?? '';
        final planB = b['selectedPlan']?.toString() ?? '';

        // ✅ NEW: 24-Hour "New Ad" Rank Bonus
        // Logic: For the first 24 hours, a Basic ad gets the same rank as a 'Pro' ad.
        // After 24 hours, it drops to the lowest rank (Basic).
        int getRank(Map<String, dynamic> ad, String plan) {
          if (plan.contains('Elite')) return 0;
          if (plan.contains('Pro')) return 1;
          
          final uploadStr = ad['uploadedAt'];
          if (uploadStr != null) {
            final uploadedAt = DateTime.tryParse(uploadStr) ?? DateTime(2000);
            if (DateTime.now().difference(uploadedAt).inHours < 24) {
              return 1; // Treated as Pro for the first 1 day
            }
          }
          return 2; // Drops below Elite/Pro after 24 hours
        }

        final rankA = getRank(a, planA);
        final rankB = getRank(b, planB);

        if (rankA != rankB) {
          return rankA.compareTo(rankB);
        }

        // 🌟 NEW: Dynamic Rank-Specific Rotation
        // Calculates how often to shuffle based on the number of users in THAT specific tier (Elite or Pro).
        final planType = planA.contains('Elite') ? 'Elite' : (planA.contains('Pro') ? 'Pro' : 'Basic');
        final tierCount = docs.where((d) => (d['selectedPlan'] ?? '').toString().contains(planType)).length;
        
        int rotationInterval = 1; 
        if (tierCount <= 5) {
          rotationInterval = 12; 
        } else if (tierCount <= 15) {
          rotationInterval = 4;
        } else if (tierCount <= 30) {
          rotationInterval = 2;
        }
        
        final now = DateTime.now();
        final rotationSeed = "${planType}_${now.day}_${(now.hour / rotationInterval).floor()}";
        
        final sortKeyA = (a['id'].toString() + rotationSeed).hashCode;
        final sortKeyB = (b['id'].toString() + rotationSeed).hashCode;

        if (sortKeyA != sortKeyB) {
          return sortKeyA.compareTo(sortKeyB);
        }

        // Final tie-break with Distance
        final distA = a['calculatedDistance'] as double;
        final distB = b['calculatedDistance'] as double;
        return distA.compareTo(distB);
      });

      userData = docs;
    } catch (e) {
      debugPrint("Fetch data error: $e");
    } finally {
      isLoading = false;
    }
  }

  /// ✅ Logic to calculate "Effective Time" for boosting
  DateTime getEffectiveTime(Map<String, dynamic> ad) {
    final uploadStr = ad['uploadedAt'];
    if (uploadStr == null) return DateTime(2000);

    final uploadedAt = DateTime.tryParse(uploadStr) ?? DateTime(2000);
    final plan = ad['selectedPlan']?.toString() ?? '';
    
    int intervalDays = 0;
    if (plan.contains('Elite')) {
      intervalDays = 5;
    } else if (plan.contains('Pro')) {
      intervalDays = 10;
    }

    if (intervalDays == 0) return uploadedAt;

    final daysSinceUpload = DateTime.now().difference(uploadedAt).inDays;
    final boostCount = (daysSinceUpload / intervalDays).floor();
    
    return uploadedAt.add(Duration(days: boostCount * intervalDays));
  }
}
