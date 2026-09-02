import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng initialLocation;
  const MapPickerPage({super.key, required this.initialLocation});
  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng _currentPickedLocation;
  @override
  void initState() {
    super.initState();
    _currentPickedLocation = widget.initialLocation;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin Location'), 
        backgroundColor: Colors.indigo, 
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context, _currentPickedLocation), 
            icon: Icon(Icons.check, size: 28.sp)
          )
        ]
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: widget.initialLocation, zoom: 17, tilt: 45), 
            onCameraMove: (position) { _currentPickedLocation = position.target; }, 
            myLocationEnabled: true, 
            myLocationButtonEnabled: true, 
            buildingsEnabled: true
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35.h), 
              child: Icon(Icons.location_on, size: 45.sp, color: Colors.red)
            )
          ),
          Positioned(
            bottom: 20.h, 
            left: 20.w, 
            right: 20.w, 
            child: Container(
              padding: EdgeInsets.all(12.w), 
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9), 
                borderRadius: BorderRadius.circular(12.r), 
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.r)]
              ), 
              child: Text(
                'Drag the map to place the pin at your exact location', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87)
              )
            )
          ),
        ],
      ),
    );
  }
}
