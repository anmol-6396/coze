import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coze/log_in/intro_page.dart';
import 'package:coze/Profile/custom_app_bar/app_bar_widget.dart';
import 'blocked_users_page.dart';
import 'about_page.dart';
import 'delete_account_page.dart';
import 'package:coze/Services/theme_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("user_lat");
      await prefs.remove("user_lng");
      await prefs.remove("user_locality");

      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const IntroPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed: $e")),
        );
      }
    }
  }

  Future<void> _logoutAllDevices() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection("users").doc(user.uid).update({
          "lastLogoutAll": FieldValue.serverTimestamp(),
        });
      }
      await _logout();
    } catch (e) {
      debugPrint("Logout all devices failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to logout all devices: $e")),
        );
      }
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;

    return Scaffold(
      appBar: const CustomAppBar(
        title: "Settings",
        backgroundColor: Colors.blue, // Keep blue identity even in dark mode
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // ✅ About Coze Tile
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            child: ListTile(
              leading: Icon(Icons.info, size: 24.sp, color: Colors.blue),
              title: Text('About Coze', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutCozePage()),
                );
              },
            ),
          ),
          SizedBox(height: 16.h),

          // ✅ Dark Mode Toggle
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            child: SwitchListTile(
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? Colors.amber : Colors.orange, size: 24.sp),
              title: Text("Dark Mode", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
              value: isDark,
              onChanged: (val) {
                setState(() {
                  ThemeManager.instance.toggleTheme(val);
                });
              },
            ),
          ),
          SizedBox(height: 16.h),

          // ✅ Blocked Users Tile (Improved Design)
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection("users")
                .doc(_auth.currentUser!.uid)
                .collection("blocked")
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                child: ListTile(
                  leading: Icon(Icons.block, size: 24.sp, color: Colors.red),
                  title: Text("Blocked Users", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                  subtitle: Text("$count users blocked", style: TextStyle(fontSize: 12.sp)),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text("Manage",
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
                    );
                  },
                ),
              );
            },
          ),

          SizedBox(height: 40.h),

          // ✅ Logout Button
          ElevatedButton.icon(
            onPressed: _confirmLogout,
            icon: Icon(Icons.logout, size: 20.sp),
            label: Text('Logout', style: TextStyle(fontSize: 16.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 55.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
          SizedBox(height: 16.h),

          // ✅ Logout All Devices Button
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Logout from all devices"),
                  content: const Text("This will sign you out from all active sessions on other devices. Proceed?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logoutAllDevices();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                      child: const Text("Logout All"),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.phonelink_erase, size: 20.sp),
            label: Text('Logout all devices', style: TextStyle(fontSize: 16.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 55.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
          SizedBox(height: 16.h),

          // ✅ Delete Account Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeleteAccountPage()),
              );
            },
            icon: Icon(Icons.delete_forever, size: 20.sp),
            label: Text('Delete Account', style: TextStyle(fontSize: 16.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 55.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ],
      ),
    );
  }
}
