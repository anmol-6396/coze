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
      final nonState = ['cbse', 'cisce', 'icse', 'isc', 'nios', 'ib', 'cambridge'];
      bool isMainBoard = nonState.any((b) => boardStr.contains(b));
      return !isMainBoard && (boardStr.contains('board') || boardStr.isNotEmpty);
    }

    if (boardName == "CISCE") {
      return boardStr.contains('cisce') || boardStr.contains('icse') || boardStr.contains('isc');
    }
    
    return boardStr.contains(boardName.toLowerCase());
  }

  final List<String> classList = [
    'Nur', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
  ];

  final List<String> boardList = [
    'State Board', 'CBSE', 'CISCE', 'IB', 'Cambridge', 'NIOS'
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
                style: TextStyle(color: Colors.white),
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
        _buildFilterHeader(context),

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

  Widget _buildFilterHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveFilter = selectedBoard != null || selectedClass != null;

    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasActiveFilter)
            Padding(
              padding: EdgeInsets.only(left: 6.w, right: 6.w, bottom: 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 14.sp, color: Colors.blueAccent),
                      SizedBox(width: 4.w),
                      Text(
                        "FILTERED BY",
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBoard = null;
                        selectedClass = null;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.close_rounded, size: 12.sp, color: Colors.redAccent),
                          SizedBox(width: 2.w),
                          Text(
                            "Clear Filters",
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Board Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: boardList.map((b) => _buildFilterChip(
                label: b,
                isSelected: selectedBoard == b,
                activeGradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                activeColor: Colors.blueAccent,
                onTap: () {
                  setState(() {
                    selectedBoard = selectedBoard == b ? null : b;
                  });
                },
              )).toList(),
            ),
          ),

          SizedBox(height: 6.h),

          // Class Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: classList.map((c) {
                final displayLabel = RegExp(r'^\d+$').hasMatch(c) ? "Class $c" : c;
                return _buildFilterChip(
                  label: displayLabel,
                  isSelected: selectedClass == c,
                  activeGradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                  activeColor: Colors.purpleAccent,
                  onTap: () {
                    setState(() {
                      selectedClass = selectedClass == c ? null : c;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required LinearGradient activeGradient,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 7.h),
          decoration: BoxDecoration(
            gradient: isSelected ? activeGradient : null,
            color: isSelected
                ? null
                : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.5)
                  : (isDark ? Colors.white12 : Colors.grey.shade300),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_circle_rounded, size: 12.sp, color: Colors.white),
                SizedBox(width: 4.w),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
      ),
    );
  }
}
