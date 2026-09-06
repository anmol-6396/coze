import 'dart:io';
import 'package:flutter/material.dart';
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
    
    // Extract specializations
    final subjects = widget.user['subjects'] ?? widget.user['subject'] ?? widget.user['Subject'];
    final skills = widget.user['skills'] ?? widget.user['skill'];
    final board = widget.user['board'];
    
    final detailSummary = _getSpecializationSummary(subjects ?? skills ?? board, rawType);

    final rawClasses = widget.user['classes'] ?? widget.user['class'];
    final classDisplay = _formatClassDisplay(rawClasses);

    final location = widget.user['location'] as Map<String, dynamic>?;
    
    final String city = (location?['city'] ?? widget.user['city'] ?? location?['locality'] ?? '').toString();
    final String area = (location?['subLocality'] ?? widget.user['subLocality'] ?? location?['landmark'] ?? widget.user['landmark'] ?? '').toString();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedPlan = widget.user['selectedPlan']?.toString() ?? '';
    final isElite = selectedPlan.contains('Elite');
    final isPro = selectedPlan.contains('Pro');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withValues(alpha: 0.06),
            blurRadius: 8.r,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: Avatar with Plan Badge
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58.w,
                height: 58.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isElite
                        ? Colors.orange
                        : isPro
                            ? Colors.purple
                            : Colors.blueAccent.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 27.r,
                  backgroundImage: _resolveImage(avatarUrl),
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              if (isElite || isPro) ...[
                SizedBox(height: 3.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isElite ? Colors.orange : Colors.purple,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isElite ? "Elite" : "Pro",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Text("👑", style: TextStyle(fontSize: 7.sp)),
                    ],
                  ),
                ),
              ],
            ],
          ),

          SizedBox(width: 10.w),

          // Right Side: All Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row: Type Badge + Rating + Distance + Wishlist
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.blueAccent : Colors.indigo).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          typeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 9.5.sp,
                            color: isDark ? Colors.lightBlueAccent : Colors.indigo,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    _ratingSmall(),
                    if (widget.distance != null) ...[
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          _formatDistance(widget.distance!),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(width: 4.w),
                    // Heart Wishlist
                    GestureDetector(
                      onTap: () async {
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
                            await ref.set({
                              ...widget.user,
                              "id": adId,
                              "parentId": widget.user['parentId'],
                              "wishlistedAt": DateTime.now().toIso8601String(),
                            });
                          } else {
                            await ref.delete();
                          }
                        } catch (e) {
                          debugPrint("Error updating wishlist: $e");
                        }
                      },
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 18.sp,
                        color: isWishlisted ? Colors.red : (isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Name
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                // Specialization / Subjects / Skills
                if (detailSummary.isNotEmpty)
                  Text(
                    detailSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: isDark ? Colors.blue.shade300 : Colors.indigo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                // Class Info
                if (classDisplay.isNotEmpty)
                  Text(
                    classDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                // Fees Range
                if (widget.user['feesChart'] != null)
                  Text(
                    FormatHelper.getFeesRange(Map<String, dynamic>.from(widget.user['feesChart'])),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                SizedBox(height: 2.h),

                // Location
                if (area.isNotEmpty || city.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 11.sp, color: Colors.grey),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          "$area${area.isNotEmpty && city.isNotEmpty ? ", " : ""}$city",
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
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
        ],
      ),
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
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Icon(Icons.star, size: 11.sp, color: Colors.orange),
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

  String _formatDistance(double meters) {
    double km = meters / 1000;
    if (km < 1) {
      return "${(meters).toStringAsFixed(0)} m";
    } else {
      return "${km.toStringAsFixed(1)} km";
    }
  }

  String _formatClassDisplay(dynamic classes) {
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

    selected = selected.where((item) => sequence.contains(item)).toList();
    selected.sort((a, b) => sequence.indexOf(a).compareTo(sequence.indexOf(b)));

    if (selected.isEmpty) return "";

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

  String _getSpecializationSummary(dynamic data, String type) {
    if (data == null) return "";
    
    List<String> items = [];
    if (data is String) {
      items = data.split(',').map((e) => e.trim()).toList();
    } else if (data is List) {
      items = data.map((e) => e.toString().trim()).toList();
    }
    
    if (items.isEmpty) return "";

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
