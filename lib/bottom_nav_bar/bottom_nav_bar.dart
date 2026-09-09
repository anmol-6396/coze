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

  final List<_NavItemData> _navItems = const [
    _NavItemData(
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      iosActiveIcon: CupertinoIcons.house_fill,
      iosInactiveIcon: CupertinoIcons.house,
      label: 'Home',
    ),
    _NavItemData(
      activeIcon: Icons.video_camera_front_rounded,
      inactiveIcon: Icons.video_camera_front_outlined,
      iosActiveIcon: CupertinoIcons.desktopcomputer,
      iosInactiveIcon: CupertinoIcons.desktopcomputer,
      label: 'Online',
    ),
    _NavItemData(
      activeIcon: Icons.stars_rounded,
      inactiveIcon: Icons.stars_outlined,
      iosActiveIcon: CupertinoIcons.star_fill,
      iosInactiveIcon: CupertinoIcons.star,
      label: 'Skills',
    ),
    _NavItemData(
      activeIcon: Icons.work_rounded,
      inactiveIcon: Icons.work_outline_rounded,
      iosActiveIcon: CupertinoIcons.briefcase_fill,
      iosInactiveIcon: CupertinoIcons.briefcase,
      label: 'Job',
    ),
    _NavItemData(
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
      iosActiveIcon: CupertinoIcons.person_fill,
      iosInactiveIcon: CupertinoIcons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      const Homepage(),
      const OnlineClassPage(),
      const SkillSpot(),
      const JobPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14161F) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 64.h,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                return Expanded(
                  child: _AnimatedNavItem(
                    data: _navItems[index],
                    isSelected: _selectedIndex == index,
                    isDark: isDark,
                    onTap: () => _onItemTapped(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final IconData iosActiveIcon;
  final IconData iosInactiveIcon;
  final String label;

  const _NavItemData({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.iosActiveIcon,
    required this.iosInactiveIcon,
    required this.label,
  });
}

class _AnimatedNavItem extends StatefulWidget {
  final _NavItemData data;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.data,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isDark ? Colors.blueAccent : Colors.blue.shade700;
    final inactiveColor = widget.isDark ? Colors.white54 : Colors.grey.shade600;

    final double targetScale = widget.isSelected
        ? 1.25
        : (_isHovered ? 1.15 : 1.0);

    final iconData = Platform.isIOS
        ? (widget.isSelected ? widget.data.iosActiveIcon : widget.data.iosInactiveIcon)
        : (widget.isSelected ? widget.data.activeIcon : widget.data.inactiveIcon);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 Glowing Capsule Indicator & Bouncing Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? activeColor.withValues(alpha: 0.15)
                      : (_isHovered ? activeColor.withValues(alpha: 0.08) : Colors.transparent),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1.0, end: targetScale),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Icon(
                        iconData,
                        color: widget.isSelected ? activeColor : inactiveColor,
                        size: 22.sp,
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 2.h),

              // 🔹 Animated Bold Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: widget.isSelected ? FontWeight.extrabold : FontWeight.w500,
                  color: widget.isSelected ? activeColor : inactiveColor,
                  letterSpacing: 0.2,
                ),
                child: Text(widget.data.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
