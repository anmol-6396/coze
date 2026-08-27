
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'job_detail.dart';
import 'package:coze/Services/data_manager.dart';
import 'package:coze/advertisement/advertise.dart';
import 'package:coze/app_bar/app_bar.dart';

class JobPage extends StatefulWidget {
  const JobPage({super.key});

  @override
  State<JobPage> createState() => _JobPageState();
}

class _JobPageState extends State<JobPage> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  Position? _currentPosition;

  // ✅ Native Ad Tracking
  final Map<int, NativeAd> _nativeAdsMap = {};
  bool? _lastIsDark;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_lastIsDark != null && _lastIsDark != isDark) {
      // ✅ Theme changed, clear ads to force reload with new background
      for (var ad in _nativeAdsMap.values) {
        ad.dispose();
      }
      _nativeAdsMap.clear();
    }
    _lastIsDark = isDark;
  }

  Future<void> _detectLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        _currentPosition = await Geolocator.getCurrentPosition();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Location error in JobPage: $e");
    }
  }

  double? _calculateDistance(Map<String, dynamic> job) {
    if (_currentPosition == null || job['location'] == null) return null;
    final loc = job['location'] as Map<String, dynamic>;
    if (loc['latitude'] == null || loc['longitude'] == null) return null;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      (loc['latitude'] as num).toDouble(),
      (loc['longitude'] as num).toDouble(),
    );
  }

  @override
  void dispose() {
    for (var ad in _nativeAdsMap.values) {
      ad.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const MainAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Top Native Ad in Job Page
            const NativeAdBanner(height: 100),
            // 🔍 Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by job role...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => searchQuery = "");
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.r),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => searchQuery = val.trim().toLowerCase()),
              ),
            ),

            // 📚 Results
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collectionGroup("jobs").snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  var docs = snapshot.data?.docs ?? [];
                  List<Map<String, dynamic>> jobList = [];

                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final role = (data['role'] ?? '').toString().toLowerCase();
                    final company = (data['name'] ?? '').toString().toLowerCase();
                    final jobType = (data['jobType'] ?? '').toString().toLowerCase();
                    final expLevel = (data['experienceLevel'] ?? '').toString().toLowerCase();
                    
                    // Filter by search query
                    if (searchQuery.isNotEmpty) {
                      if (!role.contains(searchQuery) && 
                          !company.contains(searchQuery) &&
                          !jobType.contains(searchQuery) &&
                          !expLevel.contains(searchQuery)) {
                        continue;
                      }
                    }

                    jobList.add({
                      ...data,
                      'id': doc.id,
                      'parentId': doc.reference.parent.parent?.id ?? '',
                      'type': 'jobs',
                    });
                  }

                  // 🔥 Sorting Logic (Elite > Pro > Normal + Effective Time)
                  jobList.sort((a, b) {
                    final timeA = DataManager.instance.getEffectiveTime(a);
                    final timeB = DataManager.instance.getEffectiveTime(b);
                    final hourA = DateTime(timeA.year, timeA.month, timeA.day, timeA.hour);
                    final hourB = DateTime(timeB.year, timeB.month, timeB.day, timeB.hour);

                    if (hourA != hourB) return hourB.compareTo(hourA);

                    final pA = a['selectedPlan']?.toString() ?? '';
                    final pB = b['selectedPlan']?.toString() ?? '';
                    final rA = pA.contains('Elite') ? 0 : (pA.contains('Pro') ? 1 : 2);
                    final rB = pB.contains('Elite') ? 0 : (pB.contains('Pro') ? 1 : 2);
                    return rA.compareTo(rB);
                  });

                  if (jobList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_off, size: 60.sp, color: Colors.grey),
                          SizedBox(height: 10.h),
                          const Text("No jobs found matching your search."),
                        ],
                      ),
                    );
                  }

                  // ✅ Calculate item count including Ads (1 ad every 6 items)
                  const int adFrequency = 6;
                  final int totalItems = jobList.length + (jobList.length ~/ adFrequency);

                  return ListView.builder(
                    padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 12.h, bottom: 100.h), // Added bottom padding
                    itemCount: totalItems,
                    itemBuilder: (context, index) {
                      if ((index + 1) % (adFrequency + 1) == 0) {
                        // Insert Native Ad
                        int adIndex = index ~/ (adFrequency + 1);
                        if (!_nativeAdsMap.containsKey(adIndex)) {
                          _nativeAdsMap[adIndex] = AdvertiseManager().createNativeAd(
                            isDark: isDark,
                            onAdLoaded: (ad) => setState(() {}),
                            onAdFailed: (ad, error) => _nativeAdsMap.remove(adIndex),
                          );
                        }

                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          height: 100.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4.r)],
                          ),
                          child: _nativeAdsMap.containsKey(adIndex)
                              ? AdWidget(ad: _nativeAdsMap[adIndex]!)
                              : Center(child: Text("Ad Loading...", style: TextStyle(fontSize: 12.sp))),
                        );
                      }

                      final actualIndex = index - (index ~/ (adFrequency + 1));
                      if (actualIndex >= jobList.length) return const SizedBox.shrink();

                      final job = jobList[actualIndex];
                      final role = job['role'] ?? 'Job Opening';
                      final company = job['name'] ?? 'Confidential';
                      final salary = job['salary'] ?? 'Negotiable';
                      final jobType = job['jobType'] ?? '';
                      final expLevel = job['experienceLevel'] ?? '';
                      final plan = job['selectedPlan']?.toString() ?? '';
                      final isPremium = plan.contains('Pro') || plan.contains('Elite');

                      return Card(
                        elevation: isPremium ? 4 : 1,
                        margin: EdgeInsets.only(bottom: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: isPremium 
                            ? BorderSide(color: plan.contains('Elite') ? Colors.orange : Colors.purple, width: 1)
                            : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                          leading: CircleAvatar(
                            radius: 25.r,
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                            backgroundImage: (job['avatar'] != null && job['avatar'].toString().isNotEmpty)
                                ? NetworkImage(job['avatar'])
                                : null,
                            child: (job['avatar'] == null || job['avatar'].toString().isEmpty)
                                ? Icon(Icons.business, color: Colors.indigoAccent)
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  role, 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPremium)
                                Icon(Icons.verified, size: 18.sp, color: plan.contains('Elite') ? Colors.orange : Colors.purple),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      company, 
                                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (expLevel.isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Text(
                                        expLevel,
                                        style: TextStyle(fontSize: 10.sp, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              if (jobType.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 6.h),
                                  child: Text(
                                    jobType,
                                    style: TextStyle(fontSize: 12.sp, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "₹ $salary", 
                                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 14.sp),
                                  ),
                                  if (_calculateDistance(job) != null)
                                    Text(
                                      "${(_calculateDistance(job)! / 1000).toStringAsFixed(1)} km",
                                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            AdvertiseManager().showInterstitialAd(() {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => JobDetailPage(jobData: job)),
                              );
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
