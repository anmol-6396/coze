import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:coze/home_page/user_info/user_box.dart';
import 'package:coze/home_page/user_info/user_details.dart';
import 'package:coze/Services/data_manager.dart';
import 'package:coze/advertisement/advertise.dart'; // ✅ Centralized Ads
import 'package:coze/widgets/filter_widget.dart';

class CollegeBtn extends StatefulWidget {
  const CollegeBtn({super.key});

  @override
  State<CollegeBtn> createState() => CollegeBtnState();
}

class CollegeBtnState extends State<CollegeBtn> {
  final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  late Future<List<Map<String, dynamic>>> _collegeAds;
  Position? _currentPosition;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _detectLocation();
    _collegeAds = _fetchCollegeAds();
  }

  Future<void> _detectLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        _currentPosition = await Geolocator.getCurrentPosition();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Location error in College: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCollegeAds() async {
    List<Map<String, dynamic>> docs = [];

    try {
      final subSnap = await FirebaseFirestore.instance.collectionGroup("college").get();
      for (var doc in subSnap.docs) {
        final data = doc.data();
        final parentId = doc.reference.parent.parent?.id ?? '';
        final avatarUrl = data['avatarUrl'] ?? data['imageUrl'] ?? data['avatar'];

        // ✅ Check Expiry
        final expiryStr = data['expiryDate'];
        if (expiryStr != null) {
          final expiry = DateTime.tryParse(expiryStr);
          if (expiry != null && DateTime.now().isAfter(expiry)) {
            continue; 
          }
        }

        docs.add({
          ...data,
          "id": doc.id,
          "parentId": parentId,
          "type": "college",
          "avatarUrl": avatarUrl,
        });
      }
    } catch (e) {
      debugPrint("Error fetching college ads: $e");
    }
    return docs;
  }

  bool _belongsToCategory(Map<String, dynamic> ad, String category) {
    final subjectsStr = (ad['subjects'] ?? ad['subject'] ?? "").toString().toLowerCase();
    if (subjectsStr.isEmpty) return false;

    final items = courseGroups[category];
    if (items == null) return false;

    for (var item in items) {
      if (subjectsStr.contains(item.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  final Map<String, List<String>> courseGroups = {
    'Undergraduate': ['B.A.', 'B.Sc.', 'B.Com', 'BBA', 'BCA', 'B.Tech', 'B.Arch', 'LLB', 'MBBS', 'BDS', 'B.Pharm', 'B.Ed'],
    'Postgraduate': ['M.A.', 'M.Sc.', 'M.Com', 'MBA', 'MCA', 'M.Tech', 'LLM', 'MD', 'MS', 'M.Pharm', 'M.Ed'],
    'Doctoral': ['Ph.D.', 'D.Litt', 'D.Sc'],
    'Professional': ['CA', 'CS', 'CMA', 'Pilot', 'Animation', 'Fashion', 'Data Science', 'AI', 'Digital Marketing'],
    'Diploma': ['Polytechnic', 'D.Pharm', 'D.El.Ed', 'ITI'],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Platform.isIOS
        ? CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(
                'College Ads',
                style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black),
              ),
              backgroundColor: isDark ? CupertinoColors.darkBackgroundGray : CupertinoColors.systemPurple,
            ),
            child: SafeArea(child: _buildBody(context)),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text(
                'College Ads',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.lightBlue.shade400, // Keep blue even in dark mode
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SafeArea(child: _buildBody(context)),
          );
  }

  Widget _buildBody(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        FilterWidget(
          title: "College Level Filters",
          customSections: {
            "LEVEL": courseGroups.keys.toList(),
          },
          customSelectedFilters: {
            "LEVEL": selectedCategory,
          },
          onCustomFilterChanged: (map) {
            setState(() {
              selectedCategory = map["LEVEL"];
            });
          },
        ),

        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _collegeAds,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Platform.isIOS ? const CupertinoActivityIndicator() : const CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                );
              }

              var userData = snapshot.data ?? [];

              // ✅ Apply Radius Filter
              if (_currentPosition != null) {
                userData = userData.where((u) {
                  final plan = u['selectedPlan']?.toString() ?? '';
                  double dist = _calculateDistance(u) ?? 999999;
                  int limit = 10000;
                  if (plan.contains('Elite')) {
                    limit = 50000;
                  } else if (plan.contains('Pro')) {
                    limit = 25000;
                  }
                  return dist <= limit;
                }).toList();
              }

              // ✅ Apply Category Filter
              if (selectedCategory != null) {
                userData = userData.where((u) => _belongsToCategory(u, selectedCategory!)).toList();
              }

              // ✅ Apply Sorting (Elite > Pro > Normal + Effective Time)
              userData.sort((a, b) {
                final timeA = DataManager.instance.getEffectiveTime(a);
                final timeB = DataManager.instance.getEffectiveTime(b);
                final hourA = DateTime(timeA.year, timeA.month, timeA.day, timeA.hour);
                final hourB = DateTime(timeB.year, timeB.month, timeB.day, timeB.hour);

                if (hourA != hourB) return hourB.compareTo(hourA);

                final pA = a['selectedPlan']?.toString() ?? '';
                final pB = b['selectedPlan']?.toString() ?? '';
                final rA = pA.contains('Elite') ? 0 : (pA.contains('Pro') ? 1 : 2);
                final rB = pB.contains('Elite') ? 0 : (pB.contains('Pro') ? 1 : 2);
                if (rA != rB) return rA.compareTo(rB);

                final dA = _calculateDistance(a) ?? 999999;
                final dB = _calculateDistance(b) ?? 999999;
                return dA.compareTo(dB);
              });

              if (userData.isEmpty) {
                return const Center(child: Text('No colleges found.'));
              }

              const int adFrequency = 6;
              final int totalAds = userData.length ~/ adFrequency;
              final int itemCount = userData.length + totalAds;

              return Padding(
                padding: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  top: 16.h,
                  bottom: bottomInset + 40.h,
                ),
                child: GridView.builder(
                  itemCount: itemCount,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth < 600 ? 2 : 3,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: screenWidth < 600 ? 0.85 : 1.0,
                  ),
                  itemBuilder: (context, index) {
                    if ((index + 1) % (adFrequency + 1) == 0) {
                      return Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: isDark ? Colors.amber.shade400 : Colors.amber.shade700),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.campaign, size: 32.sp, color: Colors.orange),
                            SizedBox(height: 8.h),
                            Text(
                              'Sponsored Ad',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final adCountBefore = index ~/ (adFrequency + 1);
                    final userIndex = index - adCountBefore;
                    if (userIndex >= userData.length) return const SizedBox.shrink();
                    final user = userData[userIndex];

                    return InkWell(
                      onTap: () {
                        AdvertiseManager().showInterstitialAd(() {
                          Navigator.push(
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
                        });
                      },
                      child: UserBox(
                        user: user,
                        uid: currentUserUid,
                        distance: _calculateDistance(user),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  double? _calculateDistance(Map<String, dynamic> user) {
    if (_currentPosition == null || user['location'] == null) return null;
    final loc = user['location'] as Map<String, dynamic>;
    if (loc['latitude'] == null || loc['longitude'] == null) return null;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      loc['latitude'],
      loc['longitude'],
    );
  }

  Widget _filterButton(String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedCategory == category;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? (isDark ? Colors.deepPurpleAccent : Colors.deepPurple)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          foregroundColor: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          minimumSize: const Size(0, 32),
        ),
        onPressed: () {
          setState(() {
            selectedCategory = isSelected ? null : category;
          });
        },
        child: Text(
          category,
          style: TextStyle(fontSize: 13.sp),
        ),
      ),
    );
  }
}
