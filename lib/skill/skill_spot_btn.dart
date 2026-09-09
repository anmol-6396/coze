import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:coze/home_page/user_info/user_box.dart';
import 'package:coze/home_page/user_info/user_details.dart';
import 'package:coze/Services/data_manager.dart';
import 'package:coze/advertisement/advertise.dart';
import 'package:coze/app_bar/app_bar.dart';
import 'package:coze/home_page/search/search_btn.dart';
import 'package:coze/widgets/filter_widget.dart';

class SkillSpot extends StatefulWidget {
  const SkillSpot({super.key});

  @override
  State<SkillSpot> createState() => _SkillSpotState();
}

class _SkillSpotState extends State<SkillSpot> {
  final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late Future<List<Map<String, dynamic>>> _skillAds;
  Position? _currentPosition;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _detectLocation();
    _skillAds = _fetchSkillAds();
  }

  Future<void> _detectLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        _currentPosition = await Geolocator.getCurrentPosition();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Location error in SkillSpot: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSkillAds() async {
    List<Map<String, dynamic>> docs = [];
    final collections = ["homeinstructor", "skill"];

    for (var coll in collections) {
      try {
        final subSnap = await FirebaseFirestore.instance.collectionGroup(coll).get();
        for (var doc in subSnap.docs) {
          final data = doc.data();
          final parentId = doc.reference.parent.parent?.id ?? '';
          final avatarUrl = data['avatarUrl'] ?? data['imageUrl'] ?? data['avatar'];

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
            "type": coll,
            "avatarUrl": avatarUrl,
          });
        }
      } catch (e) {
        debugPrint("Error fetching $coll ads: $e");
      }
    }
    return docs;
  }

  bool _belongsToCategory(Map<String, dynamic> ad, String category) {
    if (category == "Home Service") {
      return ad['type'] == 'homeinstructor';
    }

    final skillStr = (ad['skill'] ?? ad['skills'] ?? "").toString().toLowerCase();
    if (skillStr.isEmpty) return false;

    String filterCategory = category;
    if (category == "Music") {
      filterCategory = "Instrumental Music";
    } else if (category == "Arts" || category == "Crafts") {
      filterCategory = "Arts & Crafts";
    }

    final items = subjectGroups[filterCategory];
    if (items == null) return false;

    for (var item in items) {
      if (skillStr.contains(item.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  final Map<String, List<String>> subjectGroups = {
    'Dance': ['Classical Dance','Folk Dance','Hip Hop','Contemporary','Ballet','Salsa','Zumba'],
    'Singing': ['Classical Vocal','Light Music','Western Vocal','Pop','Rock','Jazz','Choir'],
    'Instrumental Music': ['Guitar','Piano/Keyboard','Violin','Tabla','Drums','Flute','Harmonium'],
    'Sports': ['Cricket','Football','Basketball','Badminton','Tennis','Volleyball','Athletics','Swimming','Hockey'],
    'Fitness': ['Yoga','Gym Training','Aerobics','Martial Arts','Karate','Taekwondo','Boxing','Meditation'],
    'Arts & Crafts': ['Drawing','Painting','Sketching','Calligraphy','Sculpture','Photography','Handicrafts','Origami','Pottery','Embroidery','Knitting','DIY Projects','Paper Craft'],
    'Cooking': ['Indian Cuisine','Continental Cuisine','Bakery','Healthy Cooking','Street Food','Cake Decoration'],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FE),
      appBar: const MainAppBar(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SearchPage(),
                ),
                FilterWidget(
                  title: "Skill Categories",
                  customSections: const {
                    "CATEGORY": [
                      "Home Service", "Dance", "Singing", "Music", "Sports", "Fitness", "Arts", "Crafts", "Cooking"
                    ],
                  },
                  customSelectedFilters: {
                    "CATEGORY": selectedCategory,
                  },
                  onCustomFilterChanged: (map) {
                    setState(() {
                      selectedCategory = map["CATEGORY"];
                    });
                  },
                ),
                const NativeAdBanner(height: 80),
              ],
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _skillAds,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text("Error: ${snapshot.error}")));
              }

              var userData = snapshot.data ?? [];

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

              if (selectedCategory != null) {
                userData = userData.where((u) => _belongsToCategory(u, selectedCategory!)).toList();
              }

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
                return const SliverFillRemaining(child: Center(child: Text("No specialists found.")));
              }

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, bottomInset + 100.h),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth < 600 ? 2 : 3,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: screenWidth < 600 ? 0.78 : 0.95,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = userData[index];
                      return InkWell(
                        onTap: () {
                          AdvertiseManager().showInterstitialAd(() {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
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
                    childCount: userData.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    final categories = [
      "Home Service", "Dance", "Singing", "Music", "Sports", "Fitness", "Arts", "Crafts", "Cooking"
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: categories.map((cat) => _filterButton(cat)).toList(),
        ),
      ),
    );
  }

  double? _calculateDistance(Map<String, dynamic> user) {
    if (_currentPosition == null || user['location'] == null) return null;
    final loc = user['location'] as Map<String, dynamic>;
    if (loc['latitude'] == null || loc['longitude'] == null) return null;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      (loc['latitude'] as num).toDouble(),
      (loc['longitude'] as num).toDouble(),
    );
  }

  Widget _filterButton(String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedCategory == category;
    final isHome = category == "Home Service";

    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: FilterChip(
        avatar: isHome ? Icon(Icons.home_rounded, size: 16.sp, color: isSelected ? Colors.white : Colors.orangeAccent) : null,
        label: Text(category),
        selected: isSelected,
        onSelected: (val) => setState(() => selectedCategory = val ? category : null),
        selectedColor: isHome ? Colors.orangeAccent : Colors.indigo,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : (isHome ? Colors.orange.shade900 : Colors.indigo)),
        ),
        backgroundColor: isDark ? Colors.grey[900] : (isHome ? Colors.orange.shade50 : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: isSelected ? Colors.transparent : (isHome ? Colors.orangeAccent.withOpacity(0.3) : Colors.indigo.withOpacity(0.2))),
        ),
        elevation: isSelected ? 4 : 0,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
    );
  }
}
