import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Services/format_helper.dart';

class UserBox extends StatefulWidget {
  final Map<String, dynamic> user;
  final String uid;
  final double? distance;

  const UserBox({
    super.key,
    required this.user,
    required this.uid,
    this.distance,
  });

  @override
  State<UserBox> createState() => _UserBoxState();
}

class _UserBoxState extends State<UserBox> {
  bool isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }

  @override
  void didUpdateWidget(covariant UserBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user['id'] != widget.user['id'] || oldWidget.uid != widget.uid) {
      _checkWishlistStatus();
    }
  }

  Future<void> _checkWishlistStatus() async {
    try {
      final adId = widget.user['id']?.toString() ?? '';
      if (adId.isEmpty) return;

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.uid)
          .collection("wishlist")
          .doc(adId)
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
    final name = widget.user['name'] ?? 'Unknown';
    final avatarUrl = widget.user['avatarUrl'] ??
        widget.user['imageUrl'] ??
        widget.user['avatar'];

    final rawType = widget.user['type'] ?? 'User';
    final typeLabel = _getTypeLabel(rawType);
    
    // ✅ Extract and group specializations
    final subjects = widget.user['subjects'] ?? widget.user['subject'] ?? widget.user['Subject'];
    final skills = widget.user['skills'] ?? widget.user['skill'];
    final board = widget.user['board'];
    
    final detailSummary = _getSpecializationSummary(subjects ?? skills ?? board, rawType);

    final classes = widget.user['class'];
    final location = widget.user['location'] as Map<String, dynamic>?;
    
    // ✅ Improved Location Parsing with Fallbacks
    final String city = (location?['city'] ?? widget.user['city'] ?? location?['locality'] ?? '').toString();
    final String area = (location?['subLocality'] ?? widget.user['subLocality'] ?? location?['landmark'] ?? widget.user['landmark'] ?? '').toString();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedPlan = widget.user['selectedPlan']?.toString() ?? '';
    final isElite = selectedPlan.contains('Elite');
    final isPro = selectedPlan.contains('Pro');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.white10 : Colors.black12,
                blurRadius: 8.r,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15.h), // Reduced from 15
              Center(
                child: CircleAvatar(
                  radius: 30.r, // Reduced from 32
                  backgroundImage: _resolveImage(avatarUrl),
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              SizedBox(height: 4.h), // Reduced from 6
              Row(
                children: [
                  Expanded(
                    child: Text(
                      typeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                        color: isDark ? Colors.lightBlueAccent : (Platform.isIOS ? CupertinoColors.activeBlue : Colors.deepPurple),
                      ),
                    ),
                  ),
                  _ratingSmall(),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              if (detailSummary.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Text(
                    detailSummary,
                    style: TextStyle(fontSize: 11.sp, color: Colors.indigo, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // ✅ Show Fees Range (Restricted to 1 line)
              if (widget.user['feesChart'] != null)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Text(
                    FormatHelper.getFeesRange(Map<String, dynamic>.from(widget.user['feesChart'])),
                    style: TextStyle(fontSize: 12.sp, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Spacer(),
              if (area.isNotEmpty || city.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.place, size: 12.sp, color: Colors.grey),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        "$area${area.isNotEmpty && city.isNotEmpty ? ", " : ""}$city",
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Distance Badge at Top Left Corner
        if (widget.distance != null)
          Positioned(
            top: 8.h,
            left: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.green.shade600.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                _formatDistance(widget.distance!),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mogra',
                ),
              ),
            ),
          ),

        // Plan Badge at Top Right Corner of the Card
        if (isElite || isPro)
          Positioned(
            top: 8.h,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isElite ? Colors.orange : Colors.purple,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isElite ? "Elite" : "Pro",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text("👑", style: TextStyle(fontSize: 10.sp)),
                ],
              ),
            ),
          ),

        // Heart Icon at a FIXED position in the Top Right Corner
        Positioned(
          top: 30.h, // Fixed position below the possible badge area
          right: 4.w,  // Adjusted for IconButton padding
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              isWishlisted ? Icons.favorite : Icons.favorite_border,
              size: 24.sp,
              color: isWishlisted ? Colors.red : (isDark ? Colors.white70 : Colors.grey),
            ),
            onPressed: () async {
              final adId = widget.user['id']?.toString() ?? '';
              if (adId.isEmpty) return;

              setState(() {
                isWishlisted = !isWishlisted;
              });

              final ref = FirebaseFirestore.instance
                  .collection("users")
                  .doc(widget.uid)
                  .collection("wishlist")
                  .doc(adId);

              try {
                if (isWishlisted) {
                  // Save full data for easier display in wishlist page
                  await ref.set({
                    ...widget.user,
                    "id": adId,
                    "parentId": widget.user['parentId'], // FIX: Store the seller's UID, not the current user's UID
                    "wishlistedAt": DateTime.now().toIso8601String(),
                  });
                } else {
                  await ref.delete();
                }
              } catch (e) {
                debugPrint("Error updating wishlist: $e");
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _ratingSmall() {
    final parentId = widget.user['parentId'] ?? widget.user['uid'] ?? '';
    final adId = widget.user['id'] ?? '';
    final type = widget.user['type'] ?? '';

    if (parentId.isEmpty || adId.isEmpty || type.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(parentId)
          .collection(type)
          .doc(adId)
          .collection("ratings")
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        int sum = 0;
        for (var doc in snapshot.data!.docs) {
          sum += (doc.data() as Map<String, dynamic>)['rating'] as int? ?? 0;
        }
        double avg = sum / snapshot.data!.docs.length;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              avg.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Icon(Icons.star, size: 12.sp, color: Colors.orange),
          ],
        );
      },
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'hometutor':
        return 'Private Tutor';
      case 'homeinstructor':
        return 'Private Instructor';
      case 'homecoaching':
        return 'Home Coaching';
      case 'nur-12coaching':
        return 'Nur-12 Coaching';
      case 'coaching':
        return 'Coaching';
      case 'school':
        return 'School';
      case 'college':
        return 'College';
      case 'skill':
        return 'Skill Spot';
      case 'jobs':
        return 'Job';
      default:
        if (type.isEmpty) return 'Expert';
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  String _formatClasses(dynamic classes) {
    if (classes == null || classes.toString().isEmpty) return "";

    List<String> selected = [];
    if (classes is String) {
      if (classes.toLowerCase() == "language") return "Language";
      selected = classes.split(',').map((e) => e.trim()).toList();
    } else if (classes is List) {
      selected = classes.map((e) => e.toString().trim()).toList();
    }

    if (selected.isEmpty) return "";

    final sequence = [
      'Playground', 'Pre-Nur', 'Nur', 'LKG', 'UKG',
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
    ];

    // Filter out items not in sequence if any, then sort based on sequence
    selected = selected.where((item) => sequence.contains(item)).toList();
    selected.sort((a, b) => sequence.indexOf(a).compareTo(sequence.indexOf(b)));

    if (selected.isEmpty) return "";

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

  String _formatDistance(double meters) {
    double km = meters / 1000;
    if (km < 1) {
      return "${(meters).toStringAsFixed(0)} m";
    } else {
      return "${km.toStringAsFixed(1)} km";
    }
  }


  String _getSpecializationSummary(dynamic data, String type) {
    if (data == null) return "";
    
    List<String> items = [];
    if (data is String) {
      items = data.split(',').map((e) => e.trim()).toList();
    } else if (data is List) {
      items = data.map((e) => e.toString().trim()).toList();
    }
    
    if (items.isEmpty) return "";

    // Mapping for Coaching and Skills (Aligned with Form Groups)
    final Map<String, List<String>> coachingGroups = {
      'Language': ['Assamese','Bengali','Bodo','Dogri','English','French','German','Gujarati','Japanese','Hindi','Kannada','Kashmiri','Konkani','Maithili','Malayalam','Manipuri','Marathi','Nepali','Odia','Punjabi','Sanskrit','Santhali','Sindhi','Spanish','Tamil','Telugu','Urdu'],
      'Engineering Entrance': ['IIT-JEE Mains','IIT-JEE Advanced','BITSAT','VITEEE','SRMJEEE','WBJEE','COMEDK'],
      'Medical Entrance': ['NEET UG','NEET PG','AIIMS','JIPMER','INICET'],
      'Civil Services': ['UPSC IAS','UPSC IPS','UPSC IFS','Indian Forest Service (IFoS)','Indian Economic Service (IES)','Indian Statistical Service (ISS)','Engineering Services (ESE/IES)','Combined Geo-Scientist Exam','Combined Medical Services (CMS)','CISF AC (EXE) LDCE','SO/Grade B LDCE','PCS/State Exams'],
      'Banking & Govt Jobs': ['SSC CGL','SSC CHSL','SSC MTS','SSC GD Constable','SSC JE','SSC Stenographer','SSC Translator','SSC Selection Posts','Bank PO/Clerk (IBPS, SBI)','RBI Grade B','RBI Assistant','NABARD Grade A/B','LIC AAO/ADO','NIACL AO','SEBI Grade A','Railways RRB NTPC','Railways RRB Group D','Railways RRB JE/SSE','Railways RRB ALP & Technician'],
      'Teaching Exams': ['CTET','State TET (UPTET, HTET, etc.)','UGC NET','KVS Recruitment','NVS Recruitment','DSSSB Teacher Recruitment'],
      'Judiciary': ['PCS(J)','Higher Judicial Services (HJS)','District Judge Exams'],
      'Defence': ['NDA','CDS','CAPF','AFCAT','Indian Navy SSR/AA','Territorial Army','Constable (GD) CAPFs','Sub-Inspector Delhi Police & CAPFs','SSB Interview'],
      'Management': ['CAT','MAT','XAT','GMAT','CMAT','NMAT','SNAP'],
      'Law': ['CLAT','AILET','LSAT'],
      'Computer & IT': ['Programming (Java, Python, C++)','Web Development','App Development','Data Structures & Algorithms','Database Management (SQL, NoSQL)','Cloud Computing (AWS, Azure, GCP)','Cyber Security & Ethical Hacking','Networking Fundamentals','Operating Systems (Linux, Windows)','Artificial Intelligence & Machine Learning','Data Science & Analytics','Big Data (Hadoop, Spark)','Blockchain & Cryptocurrency','UI/UX Design','Software Testing & QA','DevOps & Automation','Embedded Systems & IoT','Game Development','AR/VR Development'],
    };

    final Map<String, List<String>> skillGroups = {
      'Dance': ['Classical Dance (Bharatanatyam, Kathak)','Folk Dance','Hip Hop','Contemporary','Ballet','Salsa','Zumba'],
      'Singing': ['Classical Vocal','Light Music','Western Vocal','Pop','Rock','Jazz','Choir'],
      'Instrumental Music': ['Guitar','Piano/Keyboard','Violin','Tabla','Drums','Flute','Harmonium'],
      'Sports': ['Cricket','Football','Basketball','Badminton','Tennis','Volleyball','Athletics','Swimming','Hockey'],
      'Fitness': ['Yoga','Gym Training','Aerobics','Martial Arts','Karate','Taekwondo','Boxing','Meditation'],
      'Arts & Crafts': ['Drawing','Painting','Sketching','Calligraphy','Sculpture','Photography','Handicrafts','Origami','Pottery','Embroidery','Knitting','DIY Projects','Paper Craft'],
      'Cooking': ['Indian Cuisine','Continental Cuisine','Bakery','Healthy Cooking','Street Food','Cake Decoration'],
    };

    Set<String> matchedGroups = {};
    List<String> remainingItems = [];

    final lowType = type.toLowerCase();
    final targetGroups = (lowType.contains('skill') || lowType.contains('instructor')) ? skillGroups : coachingGroups;

    for (var item in items) {
      bool found = false;
      for (var entry in targetGroups.entries) {
        if (entry.value.contains(item)) {
          matchedGroups.add(entry.key);
          found = true;
          break;
        }
      }
      if (!found) remainingItems.add(item);
    }

    List<String> finalDisplay = matchedGroups.toList();
    if (finalDisplay.isEmpty) {
      finalDisplay.addAll(remainingItems);
    }

    return finalDisplay.join(", ");
  }
}
