import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coze/app_bar/location_manager/location_setup.dart';
import 'package:coze/app_bar/notification/notification_btn.dart';
import 'package:coze/app_bar/notification/notification_page.dart';
import 'package:coze/advertisement/advertise.dart';

class LocationHeader extends StatefulWidget {
  final bool showNotification;
  const LocationHeader({super.key, this.showNotification = true});

  @override
  State<LocationHeader> createState() => _LocationHeaderState();
}

class _LocationHeaderState extends State<LocationHeader> {
  String? selectedLocality;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLocality();
  }

  Future<void> _loadSavedLocality() async {
    final prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString("user_locality_full");
    if (saved != null) {
      setState(() {
        selectedLocality = saved;
        isLoading = false;
      });
    } else {
      _getCurrentLocation(silent: true);
    }
  }

  Future<void> _getCurrentLocation({bool silent = false}) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (silent && (permission == LocationPermission.denied || permission == LocationPermission.deniedForever)) {
        setState(() {
          selectedLocality = "Select Location";
          isLoading = false;
        });
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { selectedLocality = "Location Disabled"; isLoading = false; });
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { selectedLocality = "Permission Denied"; isLoading = false; });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() { selectedLocality = "Permission Denied Forever"; isLoading = false; });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));

      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final String locality = place.locality ?? place.subAdministrativeArea ?? "Unknown City";
        final String area = place.subLocality ?? "";
        final String displayLocation = area.isNotEmpty ? "$area, $locality" : locality;

        setState(() {
          selectedLocality = displayLocation;
          isLoading = false;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble("user_lat", position.latitude);
        await prefs.setDouble("user_lng", position.longitude);
        await prefs.setString("user_locality", locality); 
        await prefs.setString("user_locality_full", displayLocation);
      }
    } catch (e) {
      setState(() { selectedLocality = "Error fetching location"; isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const contentColor = Colors.blue;

    final locationButton = InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          Platform.isIOS
              ? CupertinoPageRoute(builder: (_) => const LocationSetupPage())
              : MaterialPageRoute(builder: (_) => const LocationSetupPage()),
        );
        _loadSavedLocality();
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Platform.isIOS ? CupertinoIcons.location_solid : Icons.location_on_rounded,
                color: contentColor,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Current Location",
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: isDark ? Colors.white38 : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  isLoading
                      ? SizedBox(
                          height: 14.h,
                          width: 14.h,
                          child: CircularProgressIndicator(strokeWidth: 2, color: contentColor),
                        )
                      : Text(
                          selectedLocality ?? "Select Location",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.blue.shade900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blue.withOpacity(0.5), size: 18.sp),
          ],
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.only(right: 8.w),
      child: Row(
        children: [
          Expanded(child: locationButton),
          if (widget.showNotification) ...[
            SizedBox(width: 4.w),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.currentUser == null
                  ? const Stream.empty()
                  : FirebaseFirestore.instance
                      .collection("users")
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection("notifications")
                      .where("isRead", isEqualTo: false)
                      .snapshots(),
              builder: (context, snapshot) {
                int unread = (snapshot.hasData) ? snapshot.data!.docs.length : 0;
                return NotificationButton(
                  unreadCount: unread,
                  iconColor: contentColor,
                  onPressed: () {
                    AdvertiseManager().showInterstitialAd(() {
                      Navigator.push(
                        context,
                        Platform.isIOS
                            ? CupertinoPageRoute(
                                builder: (_) => const NotificationsPage())
                            : MaterialPageRoute(
                                builder: (_) => const NotificationsPage()),
                      );
                    });
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
