import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notification")),
        body: const Center(child: Text("No Notification")),
      );
    }

    final content = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("notifications")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off,
                    size: 60.sp, color: isDark ? Colors.white30 : Colors.grey),
                SizedBox(height: 12.h),
                Text(
                  'No notifications yet.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: isDark ? Colors.white60 : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data!.docs;

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: notifications.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? Colors.white10 : null),
          itemBuilder: (context, index) {
            final data = notifications[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? 'No Title';
            final body = data['body'] ?? 'No Message';
            final timestamp = data['timestamp'] as Timestamp?;
            final timeStr = timestamp != null
                ? _formatTimestamp(timestamp)
                : 'Recently';

            return Platform.isIOS
                ? CupertinoListTile(
                    leading: Icon(Icons.notifications,
                        color: isDark ? Colors.lightBlueAccent : CupertinoColors.activeBlue, size: 24.sp),
                    title: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: isDark ? Colors.white : Colors.black)),
                    subtitle: Text(body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.sp, color: isDark ? Colors.white70 : Colors.black87)),
                    trailing: Text(timeStr,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: CupertinoColors.systemGrey)),
                    onTap: () {
                      _markAsRead(notifications[index].id);
                      _showNotificationDetails(context, title, body, timeStr);
                    },
                  )
                : ListTile(
                    leading: Icon(Icons.notifications,
                        color: isDark ? Colors.lightBlueAccent : Colors.deepPurple, size: 24.sp),
                    title: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: isDark ? Colors.white : Colors.black)),
                    subtitle: Text(body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.sp, color: isDark ? Colors.white70 : Colors.black87)),
                    trailing: Text(timeStr,
                        style: TextStyle(
                            fontSize: 12.sp, color: isDark ? Colors.white60 : Colors.grey)),
                    onTap: () {
                      _markAsRead(notifications[index].id);
                      _showNotificationDetails(context, title, body, timeStr);
                    },
                  );
          },
        );
      },
    );

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Notifications', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          backgroundColor: isDark ? Colors.black87 : CupertinoColors.systemPurple,
        ),
        child: SafeArea(child: content),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.deepPurple, // Keep deepPurple even in dark mode
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _markAsRead(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("notifications")
        .doc(docId)
        .update({"isRead": true});
  }

  void _showNotificationDetails(BuildContext context, String title, String body, String time) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            Text(body),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CupertinoListTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    final trail = trailing;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Row(
        children: [
          leading,
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                if (sub != null) sub,
              ],
            ),
          ),
          if (trail != null) trail,
        ],
      ),
    );
  }
}
