import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:coze/advertisement/advertise.dart';
import 'package:coze/home_page/user_info/user_box.dart';
import 'package:coze/Services/data_manager.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  void _openSearchScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(initialQuery: _controller.text.trim()),
      ),
    ).then((value) {
      if (value != null && value is String) {
        _controller.text = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 45.h,
      child: TextField(
        controller: _controller,
        readOnly: true, // Tap to open full search
        onTap: _openSearchScreen,
        style: TextStyle(
          fontSize: 14.sp,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Search tutors, schools, locations...',
          hintStyle: TextStyle(
            fontSize: 14.sp,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
          suffixIcon: Icon(Icons.search, color: Colors.blue, size: 22.sp),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
        ),
      ),
    );
  }
}

class SearchResultsPage extends StatefulWidget {
  final String initialQuery;
  const SearchResultsPage({super.key, required this.initialQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  List<Map<String, dynamic>> _filteredResults = [];
  final String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final String _googleApiKey = "AIzaSyDL4hYN2M5E3NH9Qf2c45kuBRMBybnZBiE";

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _performSearch();
  }

  Future<List<Map<String, dynamic>>> _getPlaceSuggestions(String input) async {
    if (input.length < 3) return [];
    final url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&types=geocode&components=country:in";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['predictions']);
      }
    } catch (e) { debugPrint("Suggestions error: $e"); }
    return [];
  }

  void _performSearch() {
    final query = _searchController.text.trim().toLowerCase();
    final locationQuery = _locationController.text.trim().toLowerCase();

    final allData = DataManager.instance.userData;
    
    final results = allData.where((data) {
      // 1. Keyword Match (What)
      bool matchesKeywords = true;
      if (query.isNotEmpty) {
        final searchable = _getSearchableString(data).toLowerCase();
        final queryWords = query.split(' ').where((w) => w.isNotEmpty);
        matchesKeywords = queryWords.every((word) => searchable.contains(word));
      }

      // 2. Smart Location Match (Where)
      bool matchesLocation = true;
      if (locationQuery.isNotEmpty) {
        final storedLoc = _getLocationString(data).toLowerCase();
        // Check if any word of the query is in the stored location, OR vice versa
        final locQueryWords = locationQuery.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        matchesLocation = locQueryWords.any((word) => storedLoc.contains(word) || word.contains(storedLoc));
      }

      return matchesKeywords && matchesLocation;
    }).toList();

    setState(() {
      _filteredResults = results;
    });
  }

  String _getSearchableString(Map<String, dynamic> data) {
    final name = data['name']?.toString() ?? '';
    final role = data['role']?.toString() ?? '';
    final about = data['about']?.toString() ?? '';
    final qualification = data['qualification']?.toString() ?? '';
    final subjects = _joinList(data['subjects'] ?? data['subject'] ?? data['Subject']);
    final skills = _joinList(data['skills'] ?? data['skill']);
    final type = data['type']?.toString() ?? '';
    
    // ✅ Include location details in search string
    final location = data['location'] as Map<String, dynamic>?;
    final city = (location?['city'] ?? data['city'] ?? '').toString();
    final area = (location?['subLocality'] ?? data['subLocality'] ?? '').toString();

    return "$name $role $about $qualification $subjects $skills $type $city $area";
  }

  String _getLocationString(Map<String, dynamic> data) {
    final location = data['location'] as Map<String, dynamic>?;
    final city = (location?['city'] ?? data['city'] ?? location?['locality'] ?? '').toString();
    final area = (location?['subLocality'] ?? data['subLocality'] ?? location?['landmark'] ?? '').toString();
    final address = (location?['address'] ?? data['address'] ?? '').toString();
    
    return "$city $area $address".trim();
  }

  String _joinList(dynamic list) {
    if (list is List && list.isNotEmpty) return list.join(" ");
    if (list is String && list.isNotEmpty) return list;
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int crossAxisCount = (screenWidth < 600) ? 2 : 3;
    final gridSpacing = 12.w;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Search Experts", style: TextStyle(fontFamily: 'Mogra')),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔍 Dual Search Bars
          Container(
            padding: EdgeInsets.all(16.r),
            color: Colors.indigo,
            child: Column(
              children: [
                // Keyword Search
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _performSearch(),
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "What are you looking for? (e.g. Math, Python)",
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13.sp),
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: 12.h),
                // Location Autocomplete Search
                TypeAheadField<Map<String, dynamic>>(
                  controller: _locationController,
                  suggestionsCallback: _getPlaceSuggestions,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.black),
                      onChanged: (_) => _performSearch(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Where? Search by area/city",
                        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13.sp),
                        prefixIcon: const Icon(Icons.location_on, color: Colors.indigo),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                      ),
                    );
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      leading: const Icon(Icons.place, color: Colors.indigo),
                      title: Text(suggestion['description']),
                    );
                  },
                  onSelected: (suggestion) {
                    _locationController.text = suggestion['description'];
                    _performSearch();
                  },
                ),
              ],
            ),
          ),

          const NativeAdBanner(height: 80),

          Expanded(
            child: _filteredResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 60.sp, color: Colors.grey),
                        SizedBox(height: 16.h),
                        Text(
                          "No results found in this area",
                          style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: gridSpacing,
                      mainAxisSpacing: gridSpacing,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _filteredResults.length,
                    itemBuilder: (context, index) {
                      final user = _filteredResults[index];
                      return UserBox(
                        user: user,
                        uid: currentUserUid,
                        distance: user['calculatedDistance'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
