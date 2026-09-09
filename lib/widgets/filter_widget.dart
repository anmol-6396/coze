import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FilterWidget extends StatefulWidget {
  final String title;
  final List<String>? boardList;
  final List<String>? classList;
  final String? selectedBoard;
  final String? selectedClass;

  /// Generic sections map for Job, Skill, Coaching, Online Class, etc.
  /// Example: { "JOB TYPE": ['Full Time', 'Part Time'], "EXPERIENCE": ['Fresher', '1-2 Years'] }
  final Map<String, List<String>>? customSections;
  final Map<String, String?>? customSelectedFilters;

  final Function(String? board, String? className)? onFilterChanged;
  final Function(Map<String, String?> selectedMap)? onCustomFilterChanged;

  const FilterWidget({
    super.key,
    this.title = "Filter Results",
    this.boardList,
    this.classList,
    this.selectedBoard,
    this.selectedClass,
    this.customSections,
    this.customSelectedFilters,
    this.onFilterChanged,
    this.onCustomFilterChanged,
  });

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  Map<String, List<String>> _getSections() {
    if (widget.customSections != null) {
      return widget.customSections!;
    }
    final Map<String, List<String>> sections = {};
    if (widget.boardList != null && widget.boardList!.isNotEmpty) {
      sections["BOARD"] = widget.boardList!;
    }
    if (widget.classList != null && widget.classList!.isNotEmpty) {
      sections["CLASS"] = widget.classList!;
    }
    return sections;
  }

  Map<String, String?> _getSelectedMap() {
    if (widget.customSelectedFilters != null) {
      return Map<String, String?>.from(widget.customSelectedFilters!);
    }
    final Map<String, String?> selected = {};
    if (widget.boardList != null) {
      selected["BOARD"] = widget.selectedBoard;
    }
    if (widget.classList != null) {
      selected["CLASS"] = widget.selectedClass;
    }
    return selected;
  }

  void _openFilterBottomSheet(BuildContext context) {
    final sections = _getSections();
    final Map<String, String?> tempSelected = _getSelectedMap();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            int activeCount = tempSelected.values.where((v) => v != null && v.isNotEmpty).length;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14161F) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 12.h),

                  // 🔹 Top Drag Handle Bar
                  Center(
                    child: Container(
                      width: 42.w,
                      height: 4.5.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 🔹 Header with Title, Count Badge & Reset All Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(Icons.tune_rounded, color: Colors.blueAccent, size: 20.sp),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (activeCount > 0) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  "$activeCount Selected",
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (activeCount > 0)
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                for (var key in tempSelected.keys) {
                                  tempSelected[key] = null;
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.refresh_rounded, size: 13.sp, color: Colors.redAccent),
                                  SizedBox(width: 3.w),
                                  Text(
                                    "Reset All",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),
                  Divider(height: 1.h, thickness: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),

                  // 🔹 Scrollable Filter Sections Area
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...sections.entries.map((section) {
                            final title = section.key;
                            final options = section.value;
                            final selectedVal = tempSelected[title];
                            final isClassSection = title.toUpperCase() == "CLASS";

                            final List<LinearGradient> gradients = [
                              const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF047857)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ];
                            final sectionIndex = sections.keys.toList().indexOf(title);
                            final gradient = gradients[sectionIndex % gradients.length];
                            final accentColor = gradient.colors.first;

                            return Container(
                              margin: EdgeInsets.only(bottom: 22.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 4.w,
                                        height: 14.h,
                                        decoration: BoxDecoration(
                                          color: accentColor,
                                          borderRadius: BorderRadius.circular(4.r),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        title.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Wrap(
                                    spacing: 8.w,
                                    runSpacing: 10.h,
                                    children: options.map((opt) {
                                      final isSelected = selectedVal == opt;
                                      final displayLabel = (isClassSection && RegExp(r'^\d+$').hasMatch(opt))
                                          ? "Class $opt"
                                          : opt;

                                      return _buildSheetChip(
                                        label: displayLabel,
                                        isSelected: isSelected,
                                        activeGradient: gradient,
                                        accentColor: accentColor,
                                        onTap: () {
                                          setModalState(() {
                                            tempSelected[title] = isSelected ? null : opt;
                                          });
                                        },
                                        isDark: isDark,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // 🔹 Bottom Floating Apply Button Area
                  Container(
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h + MediaQuery.of(ctx).padding.bottom),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF181A20) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 15,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 54.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (widget.onCustomFilterChanged != null) {
                            widget.onCustomFilterChanged!(tempSelected);
                          } else if (widget.onFilterChanged != null) {
                            widget.onFilterChanged!(tempSelected["BOARD"], tempSelected["CLASS"]);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "APPLY FILTERS",
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18.sp),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetChip({
    required String label,
    required bool isSelected,
    required LinearGradient activeGradient,
    required Color accentColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
        decoration: BoxDecoration(
          gradient: isSelected ? activeGradient : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.8)
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_circle_rounded, size: 15.sp, color: Colors.white),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sections = _getSections();
    final selectedMap = _getSelectedMap();
    final activeEntries = selectedMap.entries.where((e) => e.value != null && e.value!.isNotEmpty).toList();
    final activeCount = activeEntries.length;
    final hasActiveFilter = activeCount > 0;

    // Extract quick options for horizontal scroll row (e.g. first section options)
    final quickSection = sections.entries.isNotEmpty ? sections.entries.first : null;
    final quickKey = quickSection?.key;
    final quickOptions = quickSection?.value ?? [];
    final quickSelectedVal = quickKey != null ? selectedMap[quickKey] : null;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            // 🌟 1. Compact & Ultra-Attractive Filter Button
            InkWell(
              onTap: () => _openFilterBottomSheet(context),
              borderRadius: BorderRadius.circular(20.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: hasActiveFilter
                      ? const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: hasActiveFilter
                      ? null
                      : (isDark ? const Color(0xFF161822) : Colors.white),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: hasActiveFilter
                        ? Colors.blueAccent
                        : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.blueAccent.withValues(alpha: 0.3)),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasActiveFilter
                          ? Colors.blueAccent.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: hasActiveFilter
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.blueAccent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 13.sp,
                        color: hasActiveFilter ? Colors.white : Colors.blueAccent,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "Filter",
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800,
                        color: hasActiveFilter ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (hasActiveFilter) ...[
                      SizedBox(width: 5.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          "$activeCount",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(width: 3.w),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16.sp,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 🔹 Clear All Quick Button if Filter Active
            if (hasActiveFilter) ...[
              SizedBox(width: 6.w),
              InkWell(
                onTap: () {
                  if (widget.onCustomFilterChanged != null) {
                    final newMap = <String, String?>{};
                    for (var key in selectedMap.keys) {
                      newMap[key] = null;
                    }
                    widget.onCustomFilterChanged!(newMap);
                  } else if (widget.onFilterChanged != null) {
                    widget.onFilterChanged!(null, null);
                  }
                },
                borderRadius: BorderRadius.circular(18.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.close_rounded, size: 13.sp, color: Colors.redAccent),
                      SizedBox(width: 2.w),
                      Text(
                        "Clear",
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(width: 8.w),

            // 🌟 2. Direct Quick Horizontal Filter Pills
            ...quickOptions.take(6).map((option) {
              final isSelected = quickSelectedVal == option;
              final isClass = quickKey?.toUpperCase() == "CLASS";
              final displayLabel = (isClass && RegExp(r'^\d+$').hasMatch(option))
                  ? "Class $option"
                  : option;

              return Padding(
                padding: EdgeInsets.only(right: 6.w),
                child: InkWell(
                  onTap: () {
                    final newVal = isSelected ? null : option;
                    if (widget.onCustomFilterChanged != null) {
                      final newMap = Map<String, String?>.from(selectedMap);
                      newMap[quickKey!] = newVal;
                      widget.onCustomFilterChanged!(newMap);
                    } else if (widget.onFilterChanged != null) {
                      if (quickKey == "BOARD") {
                        widget.onFilterChanged!(newVal, widget.selectedClass);
                      } else {
                        widget.onFilterChanged!(widget.selectedBoard, newVal);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(18.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blueAccent
                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                        width: isSelected ? 1.2 : 1.0,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        else if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check_rounded, size: 13.sp, color: Colors.white),
                          SizedBox(width: 3.w),
                        ],
                        Text(
                          displayLabel,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
