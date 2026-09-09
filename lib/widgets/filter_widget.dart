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
    this.title = "Filter Options",
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
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h + MediaQuery.of(ctx).padding.bottom),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181A20) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Drag Handle Bar
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // 🔹 Header & Reset All Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune_rounded, color: Colors.blueAccent, size: 22.sp),
                            SizedBox(width: 8.w),
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (activeCount > 0) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  "$activeCount active",
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                        if (activeCount > 0)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                for (var key in tempSelected.keys) {
                                  tempSelected[key] = null;
                                }
                              });
                            },
                            child: Text(
                              "Reset All",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    Divider(height: 24.h, thickness: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),

                    // 🔹 Render Each Section dynamically
                    ...sections.entries.map((section) {
                      final title = section.key;
                      final options = section.value;
                      final selectedVal = tempSelected[title];
                      final isClassSection = title.toUpperCase() == "CLASS";

                      final List<LinearGradient> gradients = [
                        const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                        const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                        const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]),
                        const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)]),
                      ];
                      final sectionIndex = sections.keys.toList().indexOf(title);
                      final gradient = gradients[sectionIndex % gradients.length];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.blueAccent,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: options.map((opt) {
                              final isSelected = selectedVal == opt;
                              final displayLabel = (isClassSection && RegExp(r'^\d+$').hasMatch(opt))
                                  ? "Class $opt"
                                  : opt;

                              return _buildSheetChip(
                                label: displayLabel,
                                isSelected: isSelected,
                                activeGradient: gradient,
                                onTap: () {
                                  setModalState(() {
                                    tempSelected[title] = isSelected ? null : opt;
                                  });
                                },
                                isDark: isDark,
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      );
                    }),

                    SizedBox(height: 8.h),

                    // 🔹 Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
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
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          elevation: 0,
                        ),
                        child: Text(
                          "APPLY FILTERS",
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: isSelected ? activeGradient : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent.withValues(alpha: 0.6)
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_rounded, size: 14.sp, color: Colors.white),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
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
    final selectedMap = _getSelectedMap();
    final activeEntries = selectedMap.entries.where((e) => e.value != null && e.value!.isNotEmpty).toList();
    final activeCount = activeEntries.length;
    final hasActiveFilter = activeCount > 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // 🔹 Compact Filter Trigger Button
          InkWell(
            onTap: () => _openFilterBottomSheet(context),
            borderRadius: BorderRadius.circular(18.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: hasActiveFilter
                    ? Colors.blueAccent.withValues(alpha: 0.12)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: hasActiveFilter
                      ? Colors.blueAccent
                      : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                  width: hasActiveFilter ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16.sp,
                    color: hasActiveFilter ? Colors.blueAccent : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Filter",
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: hasActiveFilter ? Colors.blueAccent : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  if (hasActiveFilter) ...[
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.all(5.r),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "$activeCount",
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // 🔹 Quick Active Badges Scroll Row
          if (hasActiveFilter)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: activeEntries.map((entry) {
                    final key = entry.key;
                    final val = entry.value!;
                    final displayVal = (key.toUpperCase() == "CLASS" && RegExp(r'^\d+$').hasMatch(val))
                        ? "Class $val"
                        : val;

                    return Padding(
                      padding: EdgeInsets.only(right: 6.w),
                      child: _buildActiveBadge(
                        label: displayVal,
                        onRemove: () {
                          if (widget.onCustomFilterChanged != null) {
                            final newMap = Map<String, String?>.from(selectedMap);
                            newMap[key] = null;
                            widget.onCustomFilterChanged!(newMap);
                          } else if (widget.onFilterChanged != null) {
                            final b = key == "BOARD" ? null : widget.selectedBoard;
                            final c = key == "CLASS" ? null : widget.selectedClass;
                            widget.onFilterChanged!(b, c);
                          }
                        },
                        isDark: isDark,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveBadge({
    required String label,
    required VoidCallback onRemove,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.blueAccent,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.cancel_rounded,
              size: 14.sp,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
