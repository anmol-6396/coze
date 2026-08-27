import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coze/home_page/user_info/user_details.dart';
import 'package:coze/home_page/user_info/user_box.dart';
import 'package:coze/advertisement/advertise.dart';

class WishlistPage extends StatefulWidget {
  final String uid; // current logged in user UID
  const WishlistPage({super.key, required this.uid});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  Future<List<Map<String, dynamic>>> _fetchWishlist() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.uid)
        .collection("wishlist")
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  late Future<List<Map<String, dynamic>>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _wishlistFuture = _fetchWishlist();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wishlist", style: TextStyle(fontFamily: 'Mogra')),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent, // Keep pink even in dark mode
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _wishlistFuture = _fetchWishlist(); // ✅ pull‑down refresh
          });
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _wishlistFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 60.sp, color: Colors.pinkAccent),
                    SizedBox(height: 12.h),
                    Text(
                      "Your wishlist is empty",
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            final items = snapshot.data!;
            return GridView.builder(
              padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 100.h), // Added bottom padding
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.w,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final item = items[index];

                return GestureDetector(
                  onTap: () {
                    AdvertiseManager().showInterstitialAd(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserDetails(
                            userId: item['id'],
                            parentId: item['parentId'] ?? '',
                            type: item['type'] ?? 'unknown',
                          ),
                        ),
                      ).then((_) {
                        // Refresh the wishlist when returning in case it was removed from heart icon in details page
                        setState(() {
                          _wishlistFuture = _fetchWishlist();
                        });
                      });
                    });
                  },
                  child: UserBox(
                    user: item,
                    uid: widget.uid,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
