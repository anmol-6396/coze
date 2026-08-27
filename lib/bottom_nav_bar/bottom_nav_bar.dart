import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:coze/home_page/home_page.dart';
import 'package:coze/job/job_page.dart';
import 'package:coze/Profile/profile_page.dart';
import 'package:coze/online_class/online_class_page.dart';
import 'package:coze/skill/skill_spot_btn.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => BottomNavState();
}

class BottomNavState extends State<BottomNav> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late final String currentUserUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    _updateOnlineStatus(true);
  }

  @override
  void dispose() {
    _updateOnlineStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else {
      _updateOnlineStatus(false);
    }
  }

  void _updateOnlineStatus(bool isOnline) {
    FirebaseFirestore.instance.collection("users").doc(currentUserUid).update({
      "isOnline": isOnline,
      "lastActive": FieldValue.serverTimestamp(),
    }).catchError((e) => debugPrint("Status update error: $e"));
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final List<Widget> _pages = [
      const Homepage(),
      const OnlineClassPage(),
      const SkillSpot(),
      const JobPage(),
      const ProfilePage(),
    ];

    if (Platform.isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          activeColor: isDark ? Colors.lightBlueAccent : CupertinoColors.activeBlue,
          inactiveColor: CupertinoColors.inactiveGray,
          backgroundColor: isDark ? Colors.black87 : CupertinoColors.white,
          items: const [
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.desktopcomputer), label: 'Online'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.star), label: 'Skills'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.briefcase), label: 'Job'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profile'),
          ],
        ),
        tabBuilder: (context, index) => _pages[index],
      );
    } else {
      return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          selectedItemColor: isDark ? Colors.lightBlueAccent : Colors.blue,
          unselectedItemColor: isDark ? Colors.white60 : Colors.grey,
          selectedLabelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 10.sp),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.video_camera_front_rounded), label: 'Online'),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Skills'),
            BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Job'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      );
    }
  }
}
