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
  final currentUserUid = FirebaseAuth.instance.currentUser!.uid;

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
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  /// ✅ Load Native Ads
  void _loadNativeAds() {
    int crossAxisCount;
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 350) {
      crossAxisCount = 1;
    } else if (screenWidth < 600) {
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
        // Just fetch data without position (or use a default)
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

      setState(() => _currentPosition = position);
      // ✅ Refresh data with new position to get correct distances
      await DataManager.instance.fetchAllData(currentPosition: position);
      if (mounted) {
        _loadNativeAds();
        setState(() {});
      }
    } catch (e) {
      debugPrint("Location error: $e");
    } finally {
      setState(() => _loading = false);
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

    setState(() {
      _loading = true;
    });

    await DataManager.instance.fetchAllData(currentPosition: _currentPosition);

    if (mounted) {
      _loadNativeAds();
      setState(() {
        _loading = false;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  /// ✅ Build Chunks of Grid with Native Ads
  List<Widget> _buildGridWithAds(int crossAxisCount, double gridSpacing, double screenWidth) {
    List<Widget> slivers = [];
    int itemsPerChunk = crossAxisCount * 5; // 5 rows

    for (int i = 0; i < _userData.length; i += itemsPerChunk) {
      int end = (i + itemsPerChunk < _userData.length) ? i + itemsPerChunk : _userData.length;
      List<Map<String, dynamic>> chunk = _userData.sublist(i, end);

      // Add Grid Chunk
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: gridSpacing,
              mainAxisSpacing: gridSpacing,
              childAspectRatio: screenWidth < 600 ? 0.78 : 0.95, // Reverted to previous balanced ratio
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final user = chunk[index];
                double? distance = user['calculatedDistance'];
                if (distance == 999999) distance = null;

                return InkWell(
                  onTap: () {
                    AdvertiseManager().showInterstitialAd(() async {
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
                      // Refresh when coming back to update wishlist hearts
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

      // Add Ad if not at the end
      if (end < _userData.length) {
        int adIndex = i ~/ itemsPerChunk;
        final isDark = ThemeManager.instance.isDarkMode;
        slivers.add(
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              height: 100.h, // Adjusted height for NativeTemplate small
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: isDark ? Colors.grey.shade900 : Colors.white,
                boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black12, blurRadius: 4.r)],
              ),
              child: _nativeAdsMap.containsKey(adIndex)
                  ? AdWidget(ad: _nativeAdsMap[adIndex]!)
                  : Center(child: Text("Ad Loading...", style: TextStyle(fontSize: 12.sp))),
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
    if (screenWidth < 350) {
      crossAxisCount = 1;
    } else if (screenWidth < 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    final gridSpacing = 12.w;

    final isDark = ThemeManager.instance.isDarkMode;

    return Scaffold(
      appBar: const MainAppBar(),
      body: (_loading || (DataManager.instance.isLoading && _userData.isEmpty))
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshData,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: SearchPage(),
                              ),
                            ),
                            const SliverToBoxAdapter(child: MergedRows()),
                            // ✅ Top Native Ad above "Near By"
                            const SliverToBoxAdapter(child: NativeAdBanner(height: 100)),
                            SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16.w, top: 8.h),
                    child: Row(
                      children: [
                        Text(
                          "Near By",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18.sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Divider(
                            thickness: 1.h,
                            color: isDark ? Colors.white30 : Colors.black,
                            endIndent: 10.w,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_userData.isEmpty)
                   SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 20.h),
                        child: Text(
                          "No Ads Found",
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                else
                    ..._buildGridWithAds(crossAxisCount, gridSpacing, screenWidth),
                            SliverToBoxAdapter(child: SizedBox(height: 80.h)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20.h,
                  right: 20.w,
                  child: SizedBox(
                    width: 45.w,
                    height: 45.h,
                    child: FloatingActionButton(
                      heroTag: "btn_up",
                      onPressed: _scrollToTop,
                      backgroundColor: isDark ? Colors.indigo.withValues(alpha: 0.9) : Colors.blue.withValues(alpha: 0.9),
                      elevation: 6,
                      shape: const CircleBorder(),
                      child: Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 28.sp),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

