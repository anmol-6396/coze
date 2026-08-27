import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Blocked Users", style: TextStyle(fontSize: 18.sp))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .collection("blocked")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No blocked users", style: TextStyle(fontSize: 16.sp)));
          }

          final blockedUsers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: blockedUsers.length,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            itemBuilder: (context, index) {
              final blockedId = blockedUsers[index].id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(blockedId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  final userData = userSnap.data!.data() as Map<String, dynamic>;
                  final name = userData['name'] ?? 'Unknown';
                  final avatarUrl = userData['image'] ?? userData['avatar'] ?? userData['imageUrl'];

                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    leading: CircleAvatar(
                      radius: 24.r,
                      backgroundImage: (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : const AssetImage('assets/images/default_avatar.png')
                      as ImageProvider,
                    ),
                    title: Text(name, style: TextStyle(fontSize: 16.sp)),
                    trailing: IconButton(
                      icon: Icon(Icons.undo, color: Colors.blue, size: 24.sp),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(user.uid)
                            .collection("blocked")
                            .doc(blockedId)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("$name unblocked")),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
