import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'map_picker.dart';

class ManualLocationSetPage extends StatefulWidget {
  const ManualLocationSetPage({super.key});

  @override
  State<ManualLocationSetPage> createState() => _ManualLocationSetPageState();
}

class _ManualLocationSetPageState extends State<ManualLocationSetPage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? locationData;
  GoogleMapController? _mapController;
  Timer? _debounce;

  final landmarkController = TextEditingController();
  final areaController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();

  @override
  void dispose() {
    landmarkController.dispose();
    areaController.dispose();
    cityController.dispose();
    stateController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _updateAddressFromCoords(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          locationData = {
            'latitude': lat,
            'longitude': lng,
            'city': place.locality ?? place.subAdministrativeArea ?? '',
            'subLocality': place.subLocality ?? '',
          };
          landmarkController.text = place.name ?? '';
          areaController.text = place.subLocality ?? '';
          cityController.text = place.locality ?? place.subAdministrativeArea ?? '';
          stateController.text = place.administrativeArea ?? '';
        });
        _moveCamera(lat, lng);
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
  }

  void _onAddressFieldChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () async {
      final address = "${areaController.text}, ${cityController.text}, ${stateController.text}";
      if (cityController.text.isEmpty) return;

      try {
        List<Location> locations = await Geocoding().locationFromAddress(address);
        if (locations.isNotEmpty) {
          final lat = locations.first.latitude;
          final lng = locations.first.longitude;
          setState(() {
            locationData = {'latitude': lat, 'longitude': lng};
          });
          _moveCamera(lat, lng);
        }
      } catch (_) {}
    });
  }

  void _moveCamera(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 16, tilt: 45),
      ),
    );
  }

  void _confirmLocation() async {
    if (!_formKey.currentState!.validate()) return;
    
    final String area = areaController.text.trim();
    final String finalCity = cityController.text.trim();
    final double lat = locationData?['latitude'] ?? 28.6139;
    final double lng = locationData?['longitude'] ?? 77.2090;

    final String fullDisplay = (area.isNotEmpty && area.toLowerCase() != finalCity.toLowerCase())
        ? "$area, $finalCity"
        : finalCity;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("user_lat", lat);
    await prefs.setDouble("user_lng", lng);
    await prefs.setString("user_locality", finalCity);
    await prefs.setString("user_locality_full", fullDisplay);

    if (mounted) {
      Navigator.pop(context, fullDisplay); // Return "Area, City" to Homepage
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Set Area Details"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🗺 Half Screen Map
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(target: LatLng(28.6139, 77.2090), zoom: 14),
                      onMapCreated: (c) => _mapController = c,
                      markers: locationData != null ? {
                        Marker(markerId: const MarkerId("selected"), position: LatLng(locationData!['latitude'], locationData!['longitude']))
                      } : {},
                      onTap: (_) async {
                        final LatLng? picked = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MapPickerPage(
                            initialLocation: locationData != null 
                                ? LatLng(locationData!['latitude'], locationData!['longitude'])
                                : const LatLng(28.6139, 77.2090),
                          )),
                        );
                        if (picked != null) {
                          await _updateAddressFromCoords(picked.latitude, picked.longitude);
                        }
                      },
                    ),
                    Positioned(
                      bottom: 16.h,
                      right: 16.w,
                      child: FloatingActionButton.small(
                        onPressed: () async {
                          final LatLng? picked = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MapPickerPage(initialLocation: LatLng(28.6139, 77.2090))),
                          );
                          if (picked != null) await _updateAddressFromCoords(picked.latitude, picked.longitude);
                        },
                        backgroundColor: Colors.indigo,
                        child: const Icon(Icons.fullscreen, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // 📝 Address Fields
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("MANUAL ADDRESS", style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, color: Colors.indigo, letterSpacing: 1.2)),
                    SizedBox(height: 16.h),
                    _buildField(landmarkController, "Building / Landmark", Icons.business_rounded, isDark),
                    SizedBox(height: 16.h),
                    _buildField(areaController, "Area / Locality", Icons.map_rounded, isDark),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(child: _buildField(cityController, "City", Icons.location_city_rounded, isDark)),
                        SizedBox(width: 12.w),
                        Expanded(child: _buildField(stateController, "State", Icons.flag_rounded, isDark)),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    ElevatedButton(
                      onPressed: _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 60.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                        elevation: 4,
                      ),
                      child: Text("SET THIS LOCATION", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, bool isDark) {
    return TextFormField(
      controller: controller,
      onChanged: (_) => _onAddressFieldChanged(),
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo.withOpacity(0.5), size: 20.sp),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.indigo.withOpacity(0.1))),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }
}
