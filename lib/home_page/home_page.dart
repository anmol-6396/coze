import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:coze/home_page/search/search_btn.dart';
import 'package:coze/app_bar/app_bar.dart';
import 'package:coze/Services/data_manager.dart';
import 'package:coze/Services/theme_manager.dart';
import 'package:coze/advertisement/advertise.dart';
import 'package:coze/home_page/user_info/user_details.dart';
import 'package:coze/home_page/user_info/user_box.dart';
import 'package:coze/home_page/rows/merged_rows.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => HomepageState();
}

class HomepageState extends State<Homepage> with AutomaticKeepAliveClientMixin {
  Position? _currentPosition;
  bool _loading = false; // Initially false as splash handles it
  List<Map<String, dynamic>> get _userData => DataManager.instance.userData;

  final ScrollController _scrollController = ScrollController();
  final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // ✅ Native Ad Variables Managed via advertise.dart
  final Map<int, NativeAd> _nativeAdsMap = {};
  bool? _lastIsDark;

  @override
  void initState() {
    super.initState();
    _initLocationAndData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_lastIsDark != null && _lastIsDark != isDark) {
      // ✅ Theme changed, clear and reload ads with new style
      for (var ad in _nativeAdsMap.values) {
        ad.dispose();
      }
      _nativeAdsMap.clear();
      _loadNativeAds();
    }
    _lastIsDark = isDark;
  }

  Future<void> _initLocationAndData() async {
    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble("user_lat");
    double? lng = prefs.getDouble("user_lng");

    if (lat != null && lng != null) {
      // Use saved location
      _currentPosition = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      
      if (DataManager.instance.userData.isEmpty) {
        await DataManager.instance.fetchAllData(currentPosition: _currentPosition);
      }
      
      if (mounted) {
        _loadNativeAds();
        setState(() {});
      }
    } else {
      // No saved location, detect it silently (don't prompt if permission denied)
      await _detectLocation(silent: true);
    }
  }

  @override
  void dispose() {
    for (var ad in _nativeAdsMap.values) {
      ad.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  /// ✅ Load Native Ads
  void _loadNativeAds() {
    int crossAxisCount;
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      crossAxisCount = 1;
    } else if (screenWidth < 900) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }
    int itemsPerChunk = crossAxisCount * 5;

    for (int i = 0; i < _userData.length; i += itemsPerChunk) {
      int end = (i + itemsPerChunk < _userData.length) ? i + itemsPerChunk : _userData.length;
      if (end < _userData.length) {
        int adIndex = i ~/ itemsPerChunk;
        _createNativeAd(adIndex);
      }
    }
  }

  void _createNativeAd(int adIndex) {
    if (_nativeAdsMap.containsKey(adIndex)) return;

    final isDark = ThemeManager.instance.isDarkMode;

    final ad = AdvertiseManager().createNativeAd(
      isDark: isDark,
      onAdLoaded: (loadedAd) {
        debugPrint('Grid Native Ad $adIndex loaded.');
        if (mounted) setState(() {});
      },
      onAdFailed: (failedAd, error) {
        debugPrint('Grid Native Ad $adIndex failed: $error');
        _nativeAdsMap.remove(adIndex);
      },
    );

    _nativeAdsMap[adIndex] = ad;
  }

  Future<void> _detectLocation({bool silent = true}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services disabled.");

      LocationPermission permission = await Geolocator.checkPermission();
      
      // If silent (auto-detect on login/refresh) and permission not granted, don't ask
      if (silent && (permission == LocationPermission.denied || permission == LocationPermission.deniedForever)) {
        await DataManager.instance.fetchAllData(currentPosition: null);
        if (mounted) {
          _loadNativeAds();
          setState(() => _loading = false);
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions denied.");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions permanently denied.");
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // ✅ Save location to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble("user_lat", position.latitude);
      await prefs.setDouble("user_lng", position.longitude);

      if (mounted) {
        setState(() => _currentPosition = position);
      }
      
      await DataManager.instance.fetchAllData(currentPosition: position);
      if (mounted) {
        _loadNativeAds();
        setState(() {});
      }
    } catch (e) {
      debugPrint("Location error: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("cachedTutors");

    // ✅ Clear existing ads on fresh fetch
    for (var ad in _nativeAdsMap.values) {
      ad.dispose();
    }
    _nativeAdsMap.clear();

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    await DataManager.instance.fetchAllData(currentPosition: _currentPosition);

    if (mounted) {
      _loadNativeAds();
      setState(() {
        _loading = false;
      });
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// ✅ Build Chunks of List with Native Ads (1 card per line)
  List<Widget> _buildGridWithAds(int crossAxisCount, double gridSpacing, double screenWidth) {
    List<Widget> slivers = [];
    int itemsPerChunk = crossAxisCount * 5; // 5 items

    for (int i = 0; i < _userData.length; i += itemsPerChunk) {
      int end = (i + itemsPerChunk < _userData.length) ? i + itemsPerChunk : _userData.length;
      List<Map<String, dynamic>> chunk = _userData.sublist(i, end);

      // Add Grid / List Chunk
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: gridSpacing,
              mainAxisSpacing: gridSpacing,
              childAspectRatio: screenWidth < 600 ? 2.1 : 2.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = chunk[index];
                double? distance = user['calculatedDistance'];
                if (distance == 999999) distance = null;

                return InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: () {
                    AdvertiseManager().showInterstitialAd(() async {
                      if (!mounted) return;
                      await Navigator.push(
                        context,
                        Platform.isIOS
                            ? CupertinoPageRoute(
                                builder: (_) => UserDetails(
                                  userId: user['id'],
                                  parentId: user['parentId'],
                                  type: user['type'],
                                ),
                              )
                            : MaterialPageRoute(
                                builder: (_) => UserDetails(
                                  userId: user['id'],
                                  parentId: user['parentId'],
                                  type: user['type'],
                                ),
                              ),
                      );
                      if (mounted) setState(() {});
                    });
                  },
                  child: UserBox(
                    user: user,
                    uid: currentUserUid,
                    distance: distance,
                  ),
                );
              },
              childCount: chunk.length,
            ),
          ),
        ),
      );

      // Add Native Ad Banner if not at end
      if (end < _userData.length) {
        int adIndex = i ~/ itemsPerChunk;
        final isDark = ThemeManager.instance.isDarkMode;
        slivers.add(
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              height: 105.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8.r,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: _nativeAdsMap.containsKey(adIndex)
                    ? AdWidget(ad: _nativeAdsMap[adIndex]!)
                    : Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14.w,
                              height: 14.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blueAccent,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "Loading Ad...",
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        );
      }
    }
    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    int crossAxisCount;
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      crossAxisCount = 1; // 1 item per row on mobile!
    } else if (screenWidth < 900) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    final gridSpacing = 10.h;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0E12) : const Color(0xFFF8FAFC),
      appBar: const MainAppBar(),
      body: (_loading || (DataManager.instance.isLoading && _userData.isEmpty))
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16.h),
                  Text(
                    "Discovering Experts Near You...",
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                RefreshIndicator(
                  color: Colors.blueAccent,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  onRefresh: _refreshData,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      // Search Bar Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
                          child: const SearchPage(),
                        ),
                      ),

                      // Quick Category Grid
                      const SliverToBoxAdapter(child: MergedRows()),

                      // Top Native Ad Banner
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: const NativeAdBanner(height: 100),
                        ),
                      ),

                      // "Near By" Header Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.blueAccent,
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "Near By",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.sp,
                                        color: isDark ? Colors.white : Colors.black87,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              if (_userData.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Text(
                                    "${_userData.length}",
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Container(
                                  height: 1.h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        isDark ? Colors.white24 : Colors.grey.shade300,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Empty or Content Grid
                      if (_userData.isEmpty)
                        SliverToBoxAdapter(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(20.r),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blueAccent.withValues(alpha: 0.1),
                                  ),
                                  child: Icon(
                                    Icons.search_off_rounded,
                                    size: 48.sp,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  "No Experts Found Nearby",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  "Try pulling down to refresh or adjusting your search filters.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                OutlinedButton.icon(
                                  onPressed: _refreshData,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text("Refresh List"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blueAccent,
                                    side: const BorderSide(color: Colors.blueAccent),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._buildGridWithAds(crossAxisCount, gridSpacing, screenWidth),

                      SliverToBoxAdapter(child: SizedBox(height: 90.h)),
                    ],
                  ),
                ),

                // Floating Scroll to Top Action Button
                Positioned(
                  bottom: 24.h,
                  right: 20.w,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.blueAccent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _scrollToTop,
                        child: SizedBox(
                          width: 46.w,
                          height: 46.w,
                          child: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Colors.white,
                            size: 28.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
