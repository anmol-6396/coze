import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationSetupPage extends StatefulWidget {
  const LocationSetupPage({super.key});

  @override
  State<LocationSetupPage> createState() => _LocationSetupPageState();
}

class _LocationSetupPageState extends State<LocationSetupPage> {
  String? _status;
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  
  // 🔑 Replace with your actual Google API Key
  final String _googleApiKey = "AIzaSyDL4hYN2M5E3NH9Qf2c45kuBRMBybnZBiE";

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    setState(() => _loading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _status = " Location services are disabled.";
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _status = "️ Permission denied by user.";
            _loading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _status = " Permission permanently denied.\nEnable from settings.";
          _loading = false;
        });
        return;
      }

      // ✅ If permission granted
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      
      setState(() {
        _status = "Access granted. Searching details...";
      });

      // Automatically try to get address for current location
      try {
        final List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
           final p = placemarks.first;
           final locality = p.locality ?? p.subAdministrativeArea ?? "Unknown City";
           final area = p.subLocality ?? "";
           final full = area.isNotEmpty ? "$area, $locality" : locality;
           
           final prefs = await SharedPreferences.getInstance();
           await prefs.setDouble("user_lat", position.latitude);
           await prefs.setDouble("user_lng", position.longitude);
           await prefs.setString("user_locality", locality);
           await prefs.setString("user_locality_full", full);
           
           setState(() {
             _status = "Current Location: $full\n\nSearch another area or city below if you wish to change.";
             _loading = false;
           });
           return;
        }
      } catch (_) {}

      setState(() {
        _status = "Location Access granted. Please search manually below.";
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _status = "Error: $e";
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getPlaceSuggestions(String input) async {
    if (input.isEmpty || _googleApiKey == "YOUR_GOOGLE_API_KEY") return [];
    
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&types=geocode&components=country:in";
        
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = data['predictions'] as List;
        
        return predictions.map((item) {
          final mainText = item['structured_formatting']['main_text'] ?? "";
          final secondaryText = item['structured_formatting']['secondary_text'] ?? "";
          
          final city = secondaryText.split(',').first.trim();
          
          return {
            'display': mainText.isNotEmpty && city.isNotEmpty ? "$mainText, $city" : item['description'],
            'placeId': item['place_id'],
            'main': mainText,
            'city': city,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Google Suggestions error: $e");
    }
    return [];
  }

  Future<void> _onSuggestionSelected(Map<String, dynamic> suggestion) async {
    setState(() {
      _searchController.text = suggestion['display'];
      _loading = true;
    });

    final placeId = suggestion['placeId'];
    final detailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey&fields=geometry";

    try {
      final response = await http.get(Uri.parse(detailsUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final location = data['result']['geometry']['location'];
        final lat = location['lat'];
        final lon = location['lng'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble("user_lat", lat);
        await prefs.setDouble("user_lng", lon);
        await prefs.setString("user_locality", suggestion['city']);
        await prefs.setString("user_locality_full", suggestion['display']);

        if (mounted) Navigator.pop(context, suggestion['display']);
      }
    } catch (e) {
      debugPrint("Details error: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.black, Colors.indigo.shade900]
                : [Colors.deepPurple, Colors.indigoAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: TypeAheadField<Map<String, dynamic>>(
                    controller: _searchController,
                    suggestionsCallback: (pattern) async {
                      return await _getPlaceSuggestions(pattern);
                    },
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: "Search Area, City...",
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.9),
                          prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      );
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        tileColor: isDark ? Colors.grey.shade900 : Colors.white,
                        leading: const Icon(Icons.location_on, color: Colors.indigo),
                        title: Text(suggestion['display'], 
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            )),
                      );
                    },
                    onSelected: (suggestion) async {
                      await _onSuggestionSelected(suggestion);
                    },
                  ),
                ),
                SizedBox(height: 24.h),
                Icon(Icons.location_on, size: 80.r, color: Colors.white),
                SizedBox(height: 16.h),
                Text(
                  "Location Setup",
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 40.h),
                SizedBox(
                  height: 250.h,
                  child: Center(
                    child: _loading
                        ? const CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : Card(
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      margin: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 8.h),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r)),
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Text(
                          _status ?? "Requesting location permission...",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                ElevatedButton.icon(
                  onPressed: _checkPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.indigo : Colors.white,
                    foregroundColor: isDark ? Colors.white : Colors.deepPurple,
                    padding:
                    EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    elevation: 6,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    "Retry",
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
