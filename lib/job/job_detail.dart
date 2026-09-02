import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class JobDetailPage extends StatelessWidget {
  final Map<String, dynamic> jobData;

  const JobDetailPage({super.key, required this.jobData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mapping fields from the Skill/Job form to the detail view
    final title = jobData['role'] ?? jobData['title'] ?? 'Job Detail';
    final company = jobData['name'] ?? jobData['company'] ?? 'Unknown Company';
    
    // Address extraction
    final locationData = jobData['location'];
    String location = 'Unknown Location';
    if (locationData is Map) {
      location = "${locationData['city'] ?? ''}, ${locationData['state'] ?? ''}";
    } else {
      location = jobData['city'] ?? jobData['location'] ?? 'Unknown Location';
    }

    final description = jobData['about'] ?? jobData['description'] ?? 'No description available.';
    final salary = jobData['salary'] ?? jobData['fees'] ?? 'Not disclosed';
    final experience = jobData['experience'] ?? jobData['since'] ?? 'Not specified';
    final qualification = jobData['qualification'] ?? 'Not specified';
    
    final landline = jobData['landline']?.toString() ?? '';
    
    final deadline = jobData['deadline'] ?? '';

    final content = SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.lightBlueAccent : Colors.indigo,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.business, size: 18.sp, color: Colors.grey),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        company,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18.sp, color: Colors.grey),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          _sectionTitle("Job Description / About", isDark),
          Text(
            description,
            style: TextStyle(fontSize: 15.sp, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
          ),

          SizedBox(height: 24.h),
          Divider(color: isDark ? Colors.white10 : Colors.grey.shade300),
          SizedBox(height: 16.h),

          _sectionTitle("Job Details", isDark),
          _infoRow(Icons.currency_rupee, "Salary/Fees", salary.toString(), isDark),
          _infoRow(Icons.work_history, "Experience", experience.toString(), isDark),
          _infoRow(Icons.school, "Qualification", qualification.toString(), isDark),
          if (jobData['spoken'] != null)
             _infoRow(Icons.language, "Languages", jobData['spoken'].toString(), isDark),
          if (deadline.isNotEmpty)
            _infoRow(Icons.calendar_today, "Deadline", deadline, isDark),

          SizedBox(height: 24.h),
          Divider(color: isDark ? Colors.white10 : Colors.grey.shade300),
          SizedBox(height: 16.h),

          _sectionTitle("Contact Information", isDark),
          _contactButtons(jobData['phones'] is List ? jobData['phones'] : (jobData['phone'] != null ? [jobData['phone']] : []), title, isDark, context),
          if (landline.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _contactRow(Icons.tty, "Landline / PNT", landline, () => _launchCaller(landline), isDark),
          ],
          if (jobData['website'] != null && jobData['website'].toString().isNotEmpty)
             _contactRow(Icons.language, "Website", jobData['website'].toString(), () => _launchEmail(jobData['website']), isDark),

          SizedBox(height: 40.h),

          // Apply Button
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Application submitted successfully!")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.indigo : Colors.indigoAccent,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text("Apply for this Job", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Details"),
        backgroundColor: isDark ? Colors.black87 : Colors.indigoAccent,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.lightBlueAccent : Colors.indigo,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) {
    if (value.isEmpty || value == "null") return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: isDark ? Colors.lightBlueAccent : Colors.blue),
          SizedBox(width: 12.w),
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15.sp, color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value, VoidCallback onTap, bool isDark) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isDark ? Colors.indigo.shade900 : Colors.indigo.shade50,
        child: Icon(icon, color: isDark ? Colors.lightBlueAccent : Colors.indigo),
      ),
      title: Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
      subtitle: Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14.sp),
      onTap: onTap,
    );
  }

  void _launchCaller(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _launchEmail(String email) async {
    if (email.startsWith("http")) {
       final uri = Uri.parse(email);
       if (await canLaunchUrl(uri)) await launchUrl(uri);
       return;
    }
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _contactButtons(List<dynamic> phones, String name, bool isDark, BuildContext context) {
    if (phones.isEmpty || phones.first == null) return const SizedBox.shrink();

    final String primaryPhone = phones.first.toString();

    return Row(
      children: [
        // Call Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri(scheme: 'tel', path: primaryPhone);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            icon: const Icon(Icons.call, color: Colors.white),
            label: const Text("Call Now", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        // WhatsApp Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              // Format phone: remove non-digits
              final cleanPhone = primaryPhone.replaceAll(RegExp(r'[^0-9]'), '');
              // Add country code if missing (assuming India +91)
              final finalPhone = cleanPhone.length == 10 ? "91$cleanPhone" : cleanPhone;
              final message = "Hello, I saw your job posting '$name' on Coze and I am interested.";
              final uri = Uri.parse("https://wa.me/$finalPhone?text=${Uri.encodeComponent(message)}");

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Could not open WhatsApp")),
                  );
                }
              }
            },
            icon: const Icon(Icons.message, color: Colors.white),
            label: const Text("WhatsApp", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366), // WhatsApp Green
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
      ],
    );
  }
}
