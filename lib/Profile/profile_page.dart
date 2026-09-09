import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coze/Profile/edit_profile/edit_profile_page.dart';
import 'package:coze/Profile/settings/setting_page.dart';
import 'package:coze/Profile/help_support/help_page.dart';
import 'package:coze/Profile/rate_us/rate_us_page.dart';
import 'package:coze/Profile/wishlist/wish_list.dart';
import 'package:coze/Services/app_action_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> userProfile = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        setState(() {
          userProfile = doc.data()!;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _openEditProfile() async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );

    if (!mounted) return;

    if (updatedData != null && updatedData is Map<String, dynamic>) {
      setState(() {
        userProfile = updatedData;
      });
    }

    await _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D0E12) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                  ),
                  child: Icon(Icons.person_rounded, size: 70.sp, color: Colors.blueAccent),
                ),
                SizedBox(height: 20.h),
                Text(
                  "Guest User",
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Please log in to manage your profile, view wishlist, and edit account settings.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: isDark ? Colors.white60 : Colors.grey.shade600),
                ),
                SizedBox(height: 28.h),
                ElevatedButton(
                  onPressed: () async {
                    final authed = await AppActionHelper.requireAuth(context);
                    if (authed && mounted) {
                      _loadUserProfile();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: Size(220.w, 52.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 4,
                  ),
                  child: Text("LOGIN / SIGN UP", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0E12) : const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_rounded, size: 28.sp),
            onPressed: _openEditProfile,
          ),
        ],
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        children: [
          // 👤 Profile Header
          _buildProfileHeader(isDark, user),
          
          SizedBox(height: 28.h),

          // 📋 Personal Information Section
          _buildSectionTitle('Personal Information', isDark),
          SizedBox(height: 12.h),
          _buildInfoGrid(isDark, user),

          SizedBox(height: 28.h),

          // ⚡ Quick Actions Section
          _buildSectionTitle('Quick Actions', isDark),
          SizedBox(height: 14.h),
          _buildActionGrid(context, isDark),

          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, User user) {
    final name = userProfile['name'] ?? user.displayName ?? 'User Name';

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 4.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    blurRadius: 25.r,
                    offset: Offset(0, 8.h),
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 56.r,
                backgroundColor: isDark ? const Color(0xFF1E222D) : Colors.white,
                backgroundImage: (userProfile['image'] != null &&
                        userProfile['image'].toString().isNotEmpty)
                    ? NetworkImage(userProfile['image'].toString())
                    : null,
                child: (userProfile['image'] == null ||
                        userProfile['image'].toString().isEmpty)
                    ? Icon(Icons.person_rounded, size: 55.r, color: Colors.blueAccent.shade100)
                    : null,
              ),
            ),
            GestureDetector(
              onTap: _openEditProfile,
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Text(
          name,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 14.h,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(bool isDark, User user) {
    final email = userProfile['email'] ?? user.email ?? 'Not set';
    final phone = userProfile['phone'] ?? user.phoneNumber ?? 'Not set';
    final gender = userProfile['gender'] ?? 'Not set';
    final dob = userProfile['dob'] != null ? _formatDate(userProfile['dob']) : 'Not set';

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161822) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _infoRow(Icons.alternate_email_rounded, 'Email', email, isDark),
          Divider(height: 20.h, color: isDark ? Colors.white10 : Colors.grey.shade200),
          _infoRow(Icons.phone_android_rounded, 'Phone', phone, isDark),
          Divider(height: 20.h, color: isDark ? Colors.white10 : Colors.grey.shade200),
          _infoRow(Icons.wc_rounded, 'Gender', gender, isDark),
          Divider(height: 20.h, color: isDark ? Colors.white10 : Colors.grey.shade200),
          _infoRow(Icons.cake_outlined, 'Birthday', dob, isDark),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.sp, color: Colors.blueAccent),
          ),
          SizedBox(width: 12.w),
          Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : Colors.grey.shade600)),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14.w,
      crossAxisSpacing: 14.w,
      childAspectRatio: 1.4,
      children: [
        _actionCard(
          context,
          Icons.favorite_rounded,
          'Wishlist',
          Colors.pinkAccent,
          WishlistPage(uid: FirebaseAuth.instance.currentUser?.uid ?? ''),
          isDark,
        ),
        _actionCard(context, Icons.settings_suggest_rounded, 'Settings', Colors.purpleAccent, const SettingsPage(), isDark),
        _actionCard(context, Icons.support_agent_rounded, 'Help Center', Colors.tealAccent.shade700, const HelpPage(), isDark),
        _actionCard(context, Icons.star_rate_rounded, 'Rate Us', Colors.amber.shade700, const RateUsPage(), isDark),
        _actionCard(
          context,
          Icons.share_rounded,
          'Invite Friend',
          Colors.greenAccent.shade700,
          null,
          isDark,
          onTap: () {
            Share.share(
              "Hey! Check out Coze - Connect Our Zone of Experts. Find jobs, tutors, and services easily! Download now from Play Store: https://play.google.com/store/apps/details?id=com.anmol.coze&pcampaignid=web_share",
              subject: "Download Coze App",
            );
          },
        ),
      ],
    );
  }

  Widget _actionCard(BuildContext context, IconData icon, String label, Color color, Widget? destination, bool isDark, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ??
          () {
            if (destination != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
            }
          },
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 22.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return dateStr;
    }
  }
}
