import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'manual_location_set.dart'; // ✅ Added

class CityPickerPage extends StatefulWidget {
  const CityPickerPage({super.key});

  @override
  State<CityPickerPage> createState() => _CityPickerPageState();
}

class _CityPickerPageState extends State<CityPickerPage> {
  bool _loading = false;

  Future<void> _detectLocation() async {
    setState(() => _loading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
        await _updateFromCoords(position.latitude, position.longitude);
      } else {
        setState(() => _loading = false);
        _showError("Permission denied. Try manual selection.");
      }
    } catch (e) {
      setState(() => _loading = false);
      _showError("Detection failed.");
    }
  }

  Future<void> _updateFromCoords(double lat, double lng) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = place.locality ?? place.subAdministrativeArea ?? "Local Zone";
        final area = place.subLocality ?? place.thoroughfare ?? place.name ?? "";
        final full = (area.isNotEmpty && area.toLowerCase() != locality.toLowerCase())
            ? "$area, $locality"
            : locality;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble("user_lat", lat);
        await prefs.setDouble("user_lng", lng);
        await prefs.setString("user_locality", locality);
        await prefs.setString("user_locality_full", full);

        if (mounted) {
          Navigator.pop(context, full);
        }
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("Select Location", 
          style: TextStyle(fontSize: 22.sp, color: isDark ? Colors.white : Colors.indigo)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Text("Discover Experts Nearby",
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            SizedBox(height: 8.h),
            Text("Set your location to see the best services in your zone.",
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
            
            SizedBox(height: 40.h),

            // ✅ Option 1: Auto Detect (GPS) - NOW AT TOP
            _buildLocationCard(
              title: "Auto-detect Location",
              subtitle: "Use GPS for high accuracy",
              icon: Icons.my_location_rounded,
              color: Colors.indigoAccent,
              isDark: isDark,
              isLoading: _loading,
              onTap: _loading ? null : _detectLocation,
            ),

            SizedBox(height: 20.h),

            // ✅ Option 2: Manual Set (Now navigates to Manual Set Page with Map + Fields)
            _buildLocationCard(
              title: "Set Location Manually",
              subtitle: "Pick on map and fill area details",
              icon: Icons.map_rounded,
              color: Colors.blueAccent,
              isDark: isDark,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManualLocationSetPage()),
                );
                if (result != null && mounted) {
                  Navigator.pop(context, result);
                }
              },
            ),

            const Spacer(),
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    Icon(Icons.verified_user_rounded, size: 40.sp, color: Colors.grey),
                    SizedBox(height: 8.h),
                    Text("Secure Location Services", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [if(!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: isDark ? Colors.white : Colors.black87)),
                  SizedBox(height: 4.h),
                  Text(subtitle, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(width: 20.w, height: 20.h, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(color)))
            else
              Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: Colors.grey.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
