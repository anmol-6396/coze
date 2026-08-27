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

class SchoolBtn extends StatefulWidget {
  const SchoolBtn({super.key});

  @override
  State<SchoolBtn> createState() => SchoolBtnState();
}

class SchoolBtnState extends State<SchoolBtn> {
  final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  late Future<List<Map<String, dynamic>>> _schoolAds;
  Position? _currentPosition;
  String? selectedClass;
  String? selectedBoard;

  @override
  void initState() {
    super.initState();
    _detectLocation();
    _schoolAds = _fetchSchoolAds();
  }

  Future<void> _detectLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        _currentPosition = await Geolocator.getCurrentPosition();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Location error in School: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSchoolAds() async {
    List<Map<String, dynamic>> docs = [];

    try {
      final subSnap = await FirebaseFirestore.instance.collectionGroup("school").get();
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
          "type": "school",
          "avatarUrl": avatarUrl,
        });
      }
    } catch (e) {
      debugPrint("Error fetching school ads: $e");
    }
    return docs;
  }

  bool _belongsToClass(Map<String, dynamic> ad, String className) {
    final classStr = (ad['class'] ?? "").toString().toLowerCase();
    if (classStr.isEmpty) return false;
    final classes = classStr.split(',').map((e) => e.trim()).toList();
    return classes.contains(className.toLowerCase());
  }

  bool _belongsToBoard(Map<String, dynamic> ad, String boardName) {
    final boardStr = (ad['board'] ?? "").toString().toLowerCase();
    if (boardStr.isEmpty) return false;

    if (boardName == "State Board") {
      final nonState = ['cbse', 'icse', 'isc', 'nios', 'ib', 'cambridge'];
      bool isMainBoard = nonState.any((b) => boardStr.contains(b));
      return !isMainBoard && (boardStr.contains('board') || boardStr.isNotEmpty);
    }
    
    return boardStr.contains(boardName.toLowerCase());
  }

  final List<String> classList = [
    'Nur', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
  ];

  final List<String> boardList = [
    'State Board', 'CBSE', 'ICSE', 'ISC', 'IB', 'Cambridge', 'NIOS'
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Platform.isIOS
        ? CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(
                'School Ads',
                style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black),
              ),
              backgroundColor: isDark ? CupertinoColors.darkBackgroundGray : CupertinoColors.systemPurple,
            ),
            child: SafeArea(child: _buildBody(context)),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text(
                'School Ads',
                style: TextStyle(color: Colors.white, fontFamily: 'Mogra'),
              ),
              backgroundColor: Colors.lightBlue.shade400, // Keep blue in dark mode
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
        // ✅ Board filter buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          child: Row(
            children: boardList.map((b) => _boardFilterButton(b)).toList(),
          ),
        ),

        // ✅ Class filter buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          child: Row(
            children: classList.map((c) => _classFilterButton(c)).toList(),
          ),
        ),

        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _schoolAds,
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
              if (selectedBoard != null) {
                userData = userData.where((u) => _belongsToBoard(u, selectedBoard!)).toList();
              }
              if (selectedClass != null) {
                userData = userData.where((u) => _belongsToClass(u, selectedClass!)).toList();
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
                return const Center(child: Text('No schools found.'));
              }

              const int adFrequency = 6;
              final int totalAds = userData.length ~/ adFrequency;
              final int itemCount = userData.length + totalAds;

              return Padding(
                padding: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  top: 8.h,
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

  Widget _boardFilterButton(String board) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedBoard == board;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? (isDark ? Colors.blueAccent : Colors.blue)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          foregroundColor: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          minimumSize: const Size(0, 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        ),
        onPressed: () {
          setState(() {
            selectedBoard = isSelected ? null : board;
          });
        },
        child: Text(
          board,
          style: TextStyle(fontSize: 12.sp),
        ),
      ),
    );
  }

  Widget _classFilterButton(String className) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedClass == className;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? (isDark ? Colors.deepPurpleAccent : Colors.deepPurple)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          foregroundColor: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          minimumSize: const Size(0, 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        ),
        onPressed: () {
          setState(() {
            selectedClass = isSelected ? null : className;
          });
        },
        child: Text(
          className,
          style: TextStyle(fontSize: 12.sp),
        ),
      ),
    );
  }
}
