import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:coze/advertisement/advertise.dart'; // ✅ Centralized Ads
import 'package:coze/home_page/buttons/home_btn/home_btn.dart';
import 'package:coze/home_page/buttons/nur_to_12_btn.dart';
import 'package:coze/home_page/buttons/coaching_btn.dart';
import 'package:coze/home_page/buttons/school_btn.dart';
import 'package:coze/home_page/buttons/college_btn.dart';
import 'package:coze/home_page/buttons/library_page.dart';

class MergedRows extends StatelessWidget {
  const MergedRows({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141620) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          width: 1.w,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Expanded(
                child: _CategoryItem(
                  label: "Tutor",
                  imagePath: "assets/images/homebtn.png",
                  targetPage: HomeBtn(),
                  accentColor: Colors.blueAccent,
                ),
              ),
              Expanded(
                child: _CategoryItem(
                  label: "Nur-12th",
                  imagePath: "assets/images/nur.png",
                  targetPage: Nur12Btn(),
                  accentColor: Colors.purpleAccent,
                ),
              ),
              Expanded(
                child: _CategoryItem(
                  label: "Coaching",
                  imagePath: "assets/images/coaching.png",
                  targetPage: CoachingBtn(),
                  accentColor: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Expanded(
                child: _CategoryItem(
                  label: "School",
                  imagePath: "assets/images/school.png",
                  targetPage: SchoolBtn(),
                  accentColor: Color(0xFF0D9488), // Teal
                ),
              ),
              const Expanded(
                child: _CategoryItem(
                  label: "College",
                  imagePath: "assets/images/college.png",
                  targetPage: CollegeBtn(),
                  accentColor: Colors.indigoAccent,
                ),
              ),
              Expanded(
                child: _CategoryItem(
                  label: "Library",
                  icon: Icons.local_library_rounded,
                  targetPage: const LibraryPage(),
                  accentColor: Colors.amber.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final String label;
  final String? imagePath;
  final IconData? icon;
  final Widget targetPage;
  final Color accentColor;

  const _CategoryItem({
    required this.label,
    this.imagePath,
    this.icon,
    required this.targetPage,
    required this.accentColor,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double scale = _isPressed ? 0.94 : (_isHovered ? 1.08 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          AdvertiseManager().showInterstitialAd(() {
            Navigator.push(
              context,
              Platform.isIOS
                  ? CupertinoPageRoute(builder: (context) => widget.targetPage)
                  : MaterialPageRoute(builder: (context) => widget.targetPage),
            );
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.identity()..scale(scale),
          transformAlignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: isDark
                      ? widget.accentColor.withValues(alpha: 0.15)
                      : widget.accentColor.withValues(alpha: 0.08),
                  border: Border.all(
                    color: (_isHovered || _isPressed)
                        ? widget.accentColor
                        : (isDark
                            ? widget.accentColor.withValues(alpha: 0.3)
                            : widget.accentColor.withValues(alpha: 0.18)),
                    width: 1.2,
                  ),
                  boxShadow: [
                    if (_isHovered || _isPressed)
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    else if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Center(
                  child: widget.imagePath != null
                      ? Image.asset(
                          widget.imagePath!,
                          width: 25.w,
                          height: 25.w,
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          widget.icon ?? Icons.category_rounded,
                          color: widget.accentColor,
                          size: 22.sp,
                        ),
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
