import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../Services/format_helper.dart';
import 'report.dart';

class UserDetails extends StatefulWidget {
  final String userId;     // doc id
  final String parentId;   // parent UID
  final String type;       // subcollection type

  const UserDetails({
    super.key,
    required this.userId,
    required this.parentId,
    required this.type,
  });

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  bool isWishlisted = false;
  int _userRating = 0;
  double _averageRating = 0.0;
  int _totalRatings = 0;
  late Future<DocumentSnapshot> _userDetailFuture;

  @override
  void initState() {
    super.initState();
    _userDetailFuture = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.parentId)
        .collection(widget.type)
        .doc(widget.userId)
        .get();
    _checkWishlistStatus();
    _fetchRatings();
  }

  Future<void> _fetchRatings() async {
    try {
      final ratingsSnap = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.parentId)
          .collection(widget.type)
          .doc(widget.userId)
          .collection("ratings")
          .get();

      if (ratingsSnap.docs.isNotEmpty) {
        int sum = 0;
        for (var doc in ratingsSnap.docs) {
          sum += (doc.data()['rating'] as int? ?? 0);
        }
        if (mounted) {
          setState(() {
            _totalRatings = ratingsSnap.docs.length;
            _averageRating = sum / _totalRatings;
          });
        }
      }

      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid != null) {
        final myRatingDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(widget.parentId)
            .collection(widget.type)
            .doc(widget.userId)
            .collection("ratings")
            .doc(myUid)
            .get();
        if (myRatingDoc.exists && mounted) {
          setState(() {
            _userRating = myRatingDoc.data()?['rating'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching ratings: $e");
    }
  }

  Future<void> _submitRating(int rating) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    if (myUid == widget.parentId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot rate your own ad")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.parentId)
          .collection(widget.type)
          .doc(widget.userId)
          .collection("ratings")
          .doc(myUid)
          .set({
        'rating': rating,
        'raterUid': myUid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _fetchRatings();
    } catch (e) {
      debugPrint("Error submitting rating: $e");
    }
  }

  Future<void> _checkWishlistStatus() async {
    try {
      final userAuth = FirebaseAuth.instance.currentUser;
      if (userAuth == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userAuth.uid)
          .collection("wishlist")
          .doc(widget.userId)
          .get();

      if (mounted) {
        setState(() {
          isWishlisted = doc.exists;
        });
      }
    } catch (e) {
      debugPrint("Error checking wishlist: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<DocumentSnapshot>(
      future: _userDetailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("User not found"));
        }

        final user = snapshot.data!.data() as Map<String, dynamic>;

        final phoneList = user['phones'] as List<dynamic>? ?? [];
        final teachersList = user['teachers'] as List<dynamic>? ?? [];

        final landline = user['landline']?.toString() ?? "";

        final locationMap = user['location'] as Map<String, dynamic>? ?? {};
        final locationCity = locationMap['city'] ?? '';
        final locationState = locationMap['state'] ?? '';
        final locationCountry = locationMap['country'] ?? '';
        final subLocality = locationMap['subLocality'] ?? '';
        final landmark = locationMap['landmark'] ?? user['landmark'] ?? '';
        final double? lat = locationMap['latitude'] is num ? (locationMap['latitude'] as num).toDouble() : null;
        final double? lng = locationMap['longitude'] is num ? (locationMap['longitude'] as num).toDouble() : null;

        final name = user['name'] ?? '';
        final about = user['about'] ?? '';
        final gender = user['gender'] ?? '';
        final experience = user['experience'] ?? '';
        final formType = user['formType'] ?? widget.type;
        final avatarUrl = user['avatar'] ?? user['imageUrl'] ?? user['avatarUrl'];

        final selectedPlan = user['selectedPlan']?.toString() ?? '';
        final isElite = selectedPlan.contains('Elite');
        final isPro = selectedPlan.contains('Pro');

        final specialization = user['subjects'] ?? user['subject'] ?? user['Subject'] ?? user['skills'] ?? user['skill'];

        List<String> mediaList = [];
        final rawMedia = user['media'];
        if (rawMedia is List) {
          mediaList = rawMedia.cast<String>().toList();
        } else if (rawMedia is String && rawMedia.isNotEmpty) {
          mediaList = rawMedia.split(',').map((e) => e.trim()).where((url) => url.isNotEmpty).toList();
        }

        final whatsapp = user['whatsapp']?.toString() ?? "";

        final content = SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + Wishlist + Plan Badge
              Stack(
                children: [
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (avatarUrl == null || avatarUrl.toString().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("No image found")),
                              );
                            } else {
                              _viewFullScreen(context, [avatarUrl.toString()], 0);
                            }
                          },
                          child: Hero(
                            tag: 'avatar_${widget.userId}',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isElite ? Colors.orange : (isPro ? Colors.purple : Colors.blue.withValues(alpha: 0.3)),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60.r,
                                backgroundImage: _resolveImage(avatarUrl),
                                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          name,
                          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, fontFamily: 'Mogra'),
                        ),
                        // ✅ Show Fees Range Summary
                        if (user['feesChart'] != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              FormatHelper.getFeesRange(Map<String, dynamic>.from(user['feesChart'])),
                              style: TextStyle(fontSize: 18.sp, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (_totalRatings > 0)
                          Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _averageRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                Icon(Icons.star, color: Colors.orange, size: 20.sp),
                                Text(
                                  " ($_totalRatings)",
                                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Heart Icon
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 32.sp,
                        color: isWishlisted ? Colors.red : (isDark ? Colors.white70 : Colors.grey),
                      ),
                      onPressed: () async {
                        try {
                          final adId = widget.userId;
                          if (adId.isEmpty) return;

                          setState(() => isWishlisted = !isWishlisted);

                          final userAuth = FirebaseAuth.instance.currentUser;
                          if (userAuth != null) {
                            final ref = FirebaseFirestore.instance
                                .collection("users")
                                .doc(userAuth.uid)
                                .collection("wishlist")
                                .doc(adId);

                            if (isWishlisted) {
                              await ref.set({
                                ...user,
                                "id": adId,
                                "parentId": widget.parentId,
                                "type": widget.type,
                                "wishlistedAt": DateTime.now().toIso8601String(),
                              });
                            } else {
                              await ref.delete();
                            }
                          }
                        } catch (e) {
                          debugPrint("Wishlist error: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to update wishlist")),
                          );
                        }
                      },
                    ),
                  ),
                  // Plan Badge
                  if (isElite || isPro)
                    Positioned(
                      left: 0,
                      top: 10,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isElite ? Colors.orange : Colors.purple,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isElite ? "Elite" : "Pro",
                              style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 4.w),
                            Text("👑", style: TextStyle(fontSize: 12.sp)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 30.h),
              _ratingSection(isDark),

              SizedBox(height: 30.h),
              _sectionTitle("Professional Details", isDark),
              Card(
                elevation: 0,
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      _infoRow(Icons.assignment, "Type", formType, isDark),
                      _infoRow(Icons.work, "Role", user['role'], isDark),
                      _infoRow(Icons.track_changes, "Purpose", user['purpose'], isDark),
                      _infoRow(Icons.male, "Gender", gender, isDark),
                      _infoRow(Icons.school, "Qualification", user['qualification'], isDark),
                      _infoRow(Icons.history, "Experience", experience.isNotEmpty ? "$experience Years" : null, isDark),
                      _infoRow(Icons.language, "Spoken Language", user['spoken'], isDark),
                    ],
                  ),
                ),
              ),

              if (specialization != null) ...[
                SizedBox(height: 25.h),
                _sectionTitle("Specialization / Subjects", isDark),
                _buildSpecializationChips(specialization, isDark),
              ],

              SizedBox(height: 25.h),
              _sectionTitle("Service Details", isDark),
              Card(
                elevation: 0,
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      _infoRow(Icons.school, "Preferred Board", user['board'], isDark),
                      _infoRow(Icons.class_, "Available Classes", _formatClassDisplay(user['classes'] ?? user['class']), isDark),
                      _infoRow(Icons.category, "Class Type", user['classType'], isDark),
                      _infoRow(Icons.wifi, "Online Facility", user['online'], isDark),
                      _infoRow(Icons.meeting_room, "Rooms / Capacity", user['rooms'], isDark),
                      if (user['website'] != null && user['website'].toString().isNotEmpty)
                        _websiteRow(user['website'].toString(), isDark),
                    ],
                  ),
                ),
              ),

              if (user['feesChart'] != null && (user['feesChart'] as Map).isNotEmpty) ...[
                SizedBox(height: 25.h),
                _sectionTitle("Fees Chart", isDark),
                _buildFeesChart(Map<String, dynamic>.from(user['feesChart'] ?? {}), isDark),
              ],

              SizedBox(height: 25.h),
              _sectionTitle("Full Address", isDark),
              Card(
                elevation: 0,
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _addressRow(Icons.place, "Landmark", landmark, isDark),
                      _addressRow(Icons.map, "Area / Locality", subLocality, isDark),
                      _addressRow(Icons.location_city, "City", locationCity, isDark),
                      _addressRow(Icons.flag, "State", locationState, isDark),
                      _addressRow(Icons.public, "Country", locationCountry, isDark),
                    ],
                  ),
                ),
              ),

              if (teachersList.isNotEmpty) ...[
                SizedBox(height: 25.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle("Our Faculty", isDark),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllTeachersPage(teachers: teachersList, instituteName: name),
                          ),
                        );
                      },
                      child: Text("View All", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                _teachersHorizontalSection(teachersList, isDark),
              ],

              SizedBox(height: 25.h),
              _sectionTitle("About", isDark),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: SelectableText(
                  about.isNotEmpty ? about : "No description available",
                  style: TextStyle(fontSize: 15.sp, color: isDark ? Colors.white : Colors.black87, height: 1.5),
                ),
              ),

              SizedBox(height: 25.h),
              _sectionTitle("Media Gallery", isDark),
              if (mediaList.isNotEmpty)
                SizedBox(
                  height: 250.h,
                  child: PageView.builder(
                    itemCount: mediaList.length,
                    controller: PageController(viewportFraction: 0.9),
                    itemBuilder: (context, index) {
                      final url = mediaList[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: GestureDetector(
                          onTap: () => _viewFullScreen(context, mediaList, index),
                          child: Hero(
                            tag: 'media_$url',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: url.startsWith('http')
                                  ? Image.network(url, fit: BoxFit.cover)
                                  : Image.file(File(url), fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Text("No media available",
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey)),

              SizedBox(height: 35.h),
              _contactButtons(phoneList, landline, whatsapp, name, isDark),

              if (lat != null && lng != null) ...[
                SizedBox(height: 35.h),
                _sectionTitle("Map Location", isDark),
                _mapSection(lat, lng, isDark),
              ],

              SizedBox(height: 40.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _blockButton(context),
                  _reportButton(context),
                ],
              ),
              SizedBox(height: 50.h),
            ],
          ),
        );

        return Platform.isIOS
            ? CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  middle: Text(
                    name.isNotEmpty ? name : "User Details",
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  backgroundColor: isDark ? Colors.black87 : Colors.white,
                ),
                child: SafeArea(child: content),
              )
            : Scaffold(
                appBar: AppBar(
                  title: Text(
                    name.isNotEmpty ? name : "User Details",
                    style: const TextStyle(fontFamily: 'Mogra', fontWeight: FontWeight.bold),
                  ),
                  centerTitle: true,
                  flexibleSpace: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo, Colors.deepPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  elevation: 4,
                ),
                body: content,
              );
      },
    );
  }

  Widget _ratingSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle("Ratings & Reviews", isDark),
            const Spacer(),
            if (_totalRatings > 0)
              Text(
                "${_averageRating.toStringAsFixed(1)} ★ ($_totalRatings reviews)",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              onPressed: () => _submitRating(index + 1),
              icon: Icon(
                index < _userRating ? Icons.star : Icons.star_border,
                color: Colors.orange,
                size: 32.sp,
              ),
            );
          }),
        ),
        if (_userRating > 0)
          Center(
            child: Text(
              "You rated this $_userRating stars",
              style: TextStyle(fontSize: 12.sp, color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 4.w),
      child: Text(title,
          style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.lightBlueAccent : Colors.indigo)),
    );
  }

  Widget _buildSpecializationChips(dynamic data, bool isDark) {
    List<String> items = [];
    if (data is String) {
      items = data.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else if (data is List) {
      items = data.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: items.map((item) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Text(
            item,
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? Colors.lightBlueAccent : Colors.blue.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeesChart(Map<String, dynamic> feesData, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: feesData.entries.map((entry) {
            if (entry.value.toString().isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    "₹ ${FormatHelper.formatCurrency(entry.value)}",
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _addressRow(IconData icon, String label, String value, bool isDark) {
    if (value.isEmpty || value == "null") return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sp, color: Colors.blue),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11.sp, color: isDark ? Colors.white54 : Colors.black54)),
                Text(value, style: TextStyle(fontSize: 14.sp, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value, bool isDark) {
    if (value == null || value.toString().isEmpty || value.toString() == "null") {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sp, color: Colors.blue),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11.sp, color: isDark ? Colors.white54 : Colors.black54)),
                Text(value.toString(),
                    style: TextStyle(
                        fontSize: 14.sp,
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teachersHorizontalSection(List<dynamic> teachersList, bool isDark) {
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: teachersList.length,
        itemBuilder: (context, index) {
          final teacher = teachersList[index] as Map<String, dynamic>;
          final String name = teacher['name'] ?? 'Unknown';
          final String qual = teacher['qualification'] ?? '';
          final String pos = teacher['position'] ?? '';
          final String exp = teacher['experience'] ?? '';
          final String? avatar = teacher['avatar'];

          return Container(
            width: 300.w,
            margin: EdgeInsets.only(right: 16.w),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              color: isDark ? Colors.grey[900] : Colors.white,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (avatar == null || avatar.toString().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No image found")),
                          );
                        } else {
                          _viewFullScreen(context, [avatar.toString()], 0);
                        }
                      },
                      child: Hero(
                        tag: 'teacher_avatar_h_${name}_$index',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2.w),
                          ),
                          child: CircleAvatar(
                            radius: 35.r,
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                            backgroundImage: _resolveImage(avatar),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (pos.isNotEmpty)
                            Text(
                              pos,
                              style: TextStyle(fontSize: 13.sp, color: Colors.blue, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          SizedBox(height: 4.h),
                          if (qual.isNotEmpty)
                            Text(
                              "Qual: $qual",
                              style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.white70 : Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (exp.isNotEmpty)
                            Text(
                              "Exp: $exp Years",
                              style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.white70 : Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _blockButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("blocked")
            .doc(widget.parentId)
            .set({"blockedAt": DateTime.now().toIso8601String()});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User blocked")));
        Navigator.pop(context);
      },
      icon: const Icon(Icons.block, color: Colors.white),
      label: const Text("Block", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h)),
    );
  }

  Widget _reportButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ReportPage(userId: widget.userId, parentId: widget.parentId, type: widget.type)));
      },
      icon: const Icon(Icons.report, color: Colors.white),
      label: const Text("Report", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h)),
    );
  }

  Widget _contactButtons(List<dynamic> phones, String landline, String whatsapp, String name, bool isDark) {
    List<String> allNumbers = [];
    for (var p in phones) {
      if (p.toString().isNotEmpty) allNumbers.add(p.toString());
    }
    if (landline.isNotEmpty) allNumbers.add(landline);

    if (allNumbers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Contact Now", isDark),
        SizedBox(height: 8.h),
        ElevatedButton.icon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => _contactBottomSheet(allNumbers, landline, whatsapp, name, isDark),
            );
          },
          icon: const Icon(Icons.contacts, color: Colors.white),
          label: const Text("View Contact Numbers", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            minimumSize: Size(double.infinity, 50.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
        ),
      ],
    );
  }

  Widget _singleContactRow(String number, String landline, String whatsapp, String name, bool isDark) {
    final isLandline = number == landline;
    final isWhatsApp = whatsapp.split(',').map((e) => e.trim()).contains(number.trim());
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          // Call Logo
          GestureDetector(
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: number.trim());
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Image.asset('assets/images/logocall.png', width: 24.sp, height: 24.sp),
            ),
          ),
          if (!isLandline && isWhatsApp) ...[
            SizedBox(width: 16.w),
            // WhatsApp Logo
            GestureDetector(
              onTap: () async {
                final cleanPhone = number.replaceAll(RegExp(r'[^0-9]'), '');
                final finalPhone = cleanPhone.length == 10 ? "91$cleanPhone" : cleanPhone;
                final message = "Hello $name, I saw your ad on Coze and I am interested.";
                final uri = Uri.parse("https://wa.me/$finalPhone?text=${Uri.encodeComponent(message)}");

                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Image.asset('assets/images/logowhatsapp.png', width: 24.sp, height: 24.sp),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _contactBottomSheet(List<String> numbers, String landline, String whatsapp, String name, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 30.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          Text(
            "Contact Details",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              fontFamily: 'Mogra'
            ),
          ),
          SizedBox(height: 16.h),
          ...numbers.map((number) => _singleContactRow(number, landline, whatsapp, name, isDark)),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  void _viewFullScreen(BuildContext context, List<String> urls, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenMediaViewer(urls: urls, initialIndex: index),
      ),
    );
  }

  /// ✅ Website Row with Clickable Link
  Widget _websiteRow(String url, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.language, color: isDark ? Colors.lightBlueAccent : Colors.blue, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                try {
                  String formattedUrl = url;
                  if (!url.startsWith('http://') && !url.startsWith('https://')) {
                    formattedUrl = 'https://$url';
                  }
                  final uri = Uri.parse(formattedUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Could not launch website")),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint("Error launching website: $e");
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Website",
                    style: TextStyle(fontSize: 11.sp, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDark ? Colors.lightBlueAccent : Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapSection(double lat, double lng, bool isDark) {
    final LatLng pos = LatLng(lat, lng);
    return Container(
      height: 200.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: pos,
            zoom: 16,
            tilt: 45,
          ),
          buildingsEnabled: true,
          markers: {
            Marker(
              markerId: const MarkerId("user_loc"),
              position: pos,
            ),
          },
          circles: {
            Circle(
              circleId: const CircleId("approx_area"),
              center: pos,
              radius: 300,
              fillColor: Colors.blue.withValues(alpha: 0.1),
              strokeColor: Colors.blue.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          },
          zoomControlsEnabled: true,
          mapToolbarEnabled: true,
          myLocationButtonEnabled: false,
          liteModeEnabled: false,
          onTap: (_) async {
            final url = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng";
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }

  ImageProvider _resolveImage(dynamic path) {
    if (path is String && path.isNotEmpty) {
      if (path.startsWith('http')) return NetworkImage(path);
      try {
        final file = File(path);
        if (file.existsSync()) return FileImage(file);
      } catch (_) {}
    }
    return const AssetImage('assets/images/default_avatar.png');
  }

  String _formatClassDisplay(dynamic classes) {
    if (classes == null || classes.toString().isEmpty) return "";
    
    List<String> selected = [];
    if (classes is String) {
      selected = classes.split(',').map((e) => e.trim()).toList();
    } else if (classes is List) {
      selected = classes.map((e) => e.toString().trim()).toList();
    }

    if (selected.isEmpty) return "";

    final sequence = ['Playground', 'Pre-Nur', 'Nur', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
    
    // Sort selected based on sequence
    selected.sort((a, b) {
      int idxA = sequence.indexOf(a);
      int idxB = sequence.indexOf(b);
      return idxA.compareTo(idxB);
    });

    // Check if it's a continuous range
    bool isContinuous = true;
    if (selected.length > 2) {
      int startIdx = sequence.indexOf(selected.first);
      for (int i = 0; i < selected.length; i++) {
        if (sequence.indexOf(selected[i]) != startIdx + i) {
          isContinuous = false;
          break;
        }
      }
    } else {
      isContinuous = false;
    }

    if (isContinuous && selected.length > 2) {
      return "Class ${selected.first} to ${selected.last}";
    } else {
      return "Class ${selected.join(', ')}";
    }
  }
}

class FullScreenMediaViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const FullScreenMediaViewer({super.key, required this.urls, required this.initialIndex});

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "${_currentIndex + 1} / ${widget.urls.length}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final url = widget.urls[index];
          return Center(
            child: InteractiveViewer(
              child: Hero(
                tag: 'media_$url',
                child: url.startsWith('http')
                    ? Image.network(url)
                    : Image.file(File(url)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AllTeachersPage extends StatelessWidget {
  final List<dynamic> teachers;
  final String instituteName;

  const AllTeachersPage({super.key, required this.teachers, required this.instituteName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Faculty: $instituteName", style: const TextStyle(fontFamily: 'Mogra')),
        backgroundColor: isDark ? Colors.black87 : Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: teachers.length,
        itemBuilder: (context, index) {
          final teacher = teachers[index] as Map<String, dynamic>;
          final String name = teacher['name'] ?? 'Unknown';
          final String qual = teacher['qualification'] ?? '';
          final String pos = teacher['position'] ?? '';
          final String exp = teacher['experience'] ?? '';
          final String? avatar = teacher['avatar'];

          return Card(
            elevation: 3,
            margin: EdgeInsets.only(bottom: 16.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            color: isDark ? Colors.grey[900] : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (avatar == null || avatar.toString().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No image found")),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenMediaViewer(urls: [avatar.toString()], initialIndex: 0),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 40.r,
                        backgroundImage: _resolveImage(avatar),
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                        if (pos.isNotEmpty)
                          Text(pos, style: TextStyle(fontSize: 15.sp, color: Colors.blue, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8.h),
                        if (qual.isNotEmpty)
                          _teacherDetailRow(Icons.school, "Qualification", qual, isDark),
                        if (exp.isNotEmpty)
                          _teacherDetailRow(Icons.work_history, "Experience", "$exp Years", isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _teacherDetailRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: Colors.grey),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              "$label: $value",
              style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white70 : Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _resolveImage(dynamic path) {
    if (path is String && path.isNotEmpty) {
      if (path.startsWith('http')) return NetworkImage(path);
      try {
        final file = File(path);
        if (file.existsSync()) return FileImage(file);
      } catch (_) {}
    }
    return const AssetImage('assets/images/default_avatar.png');
  }
}
