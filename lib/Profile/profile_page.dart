import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coze/Profile/edit_profile/edit_profile_page.dart';
import 'package:coze/Profile/settings/setting_page.dart';
import 'package:coze/Profile/help_support/help_page.dart';
import 'package:coze/Profile/rate_us/rate_us_page.dart';
import 'package:coze/Profile/wishlist/wish_list.dart';

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

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        userProfile = doc.data()!;
      });
    }
  }

  Future<void> _openEditProfile() async {
    final updatedData = await Navigator.push(
      context,
      Platform.isIOS
          ? CupertinoPageRoute(builder: (_) => const EditProfilePage())
          : MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );

    if (updatedData != null && updatedData is Map<String, dynamic>) {
      setState(() {
        userProfile = updatedData;
      });
    }

    await _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      children: [
        // 👤 Profile Header
        _buildProfileHeader(isDark),
        
        SizedBox(height: 32.h),

        // 📋 Information Section
        _buildSectionTitle('Personal Information', isDark),
        SizedBox(height: 12.h),
        _buildInfoGrid(isDark),

        SizedBox(height: 32.h),

        // ⚡ Quick Actions Section
        _buildSectionTitle('Quick Actions', isDark),
        SizedBox(height: 16.h),
        _buildActionGrid(context, isDark),

        SizedBox(height: 100.h), // Increased bottom padding
      ],
    );

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: isDark ? Colors.black : Colors.grey[50],
        navigationBar: CupertinoNavigationBar(
          middle: const Text('My Profile', style: TextStyle(fontFamily: 'Mogra')),
          backgroundColor: isDark ? Colors.black87 : Colors.white,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _openEditProfile,
            child: Icon(CupertinoIcons.pencil_circle_fill, size: 28.sp),
          ),
        ),
        child: SafeArea(child: content),
      );
    } else {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.grey[50],
        appBar: AppBar(
          title: const Text('My Profile', style: TextStyle(fontFamily: 'Mogra', fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo, // Keep indigo even in dark mode
          foregroundColor: Colors.white,
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.edit_note, size: 28.sp),
              onPressed: _openEditProfile,
            ),
          ],
          elevation: 0,
        ),
        body: content,
      );
    }
  }

  Widget _buildProfileHeader(bool isDark) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.indigo.withValues(alpha: 0.2), width: 5.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20.r,
                    offset: Offset(0, 10.h),
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 60.r,
                backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                backgroundImage: (userProfile['image'] != null &&
                  userProfile['image'].toString().isNotEmpty)
                  ? NetworkImage(userProfile['image'].toString())
                  : null,
              child: (userProfile['image'] == null ||
                  userProfile['image'].toString().isEmpty)
                  ? Icon(Icons.person, size: 60.r, color: Colors.indigo.shade200)
                  : null,
              ),
            ),
            GestureDetector(
              onTap: _openEditProfile,
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 16.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          userProfile['name'] ?? 'User Name',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Mogra',
            color: isDark ? Colors.white : Colors.indigo.shade900,
          ),
        ),
        if (userProfile['user_id'] != null)
          Text(
            "User ID: #${userProfile['user_id']}",
            style: TextStyle(
              fontSize: 14.sp, 
              color: Colors.indigo.shade300, 
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2
            ),
          ),
        Text(
          userProfile['email'] ?? 'email@example.com',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.lightBlueAccent : Colors.indigo,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoGrid(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _infoRow(Icons.phone_android, 'Phone', userProfile['phone'] ?? 'Not set', isDark),
          const Divider(),
          _infoRow(Icons.wc, 'Gender', userProfile['gender'] ?? 'Not set', isDark),
          const Divider(),
          _infoRow(Icons.cake_outlined, 'Birthday', 
            userProfile['dob'] != null ? _formatDate(userProfile['dob']) : 'Not set', isDark),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: Colors.indigo.shade300),
            SizedBox(width: 12.w),
            Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.grey)),
            const Spacer(),
            Text(
              value, 
              style: TextStyle(
                fontSize: 14.sp, 
                fontWeight: FontWeight.bold, 
                color: value == 'Not Verified' ? Colors.red : (value == 'Verified' ? Colors.green : (isDark ? Colors.white : Colors.black87))
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16.w,
      crossAxisSpacing: 16.w,
      childAspectRatio: 1.4,
      children: [
        _actionCard(context, Icons.favorite, 'Wishlist', Colors.pink, WishlistPage(uid: FirebaseAuth.instance.currentUser?.uid ?? ''), isDark),
        _actionCard(context, Icons.settings_suggest, 'Settings', Colors.purple, const SettingsPage(), isDark),
        _actionCard(context, Icons.support_agent, 'Help Center', Colors.teal, const HelpPage(), isDark),
        _actionCard(context, Icons.star_rate, 'Rate Us', Colors.amber, const RateUsPage(), isDark),
        _actionCard(context, Icons.share, 'Invite Friend', Colors.green, null, isDark, 
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
      onTap: onTap ?? () {
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        }
      },
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
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
