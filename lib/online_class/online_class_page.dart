import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coze/home_page/user_info/user_details.dart';
import 'package:coze/home_page/user_info/user_box.dart';
import 'package:coze/advertisement/advertise.dart';

class OnlineClassPage extends StatefulWidget {
  const OnlineClassPage({super.key});

  @override
  State<OnlineClassPage> createState() => _OnlineClassPageState();
}

class _OnlineClassPageState extends State<OnlineClassPage> {
  final TextEditingController _searchController = TextEditingController();
  final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  List<Map<String, dynamic>> _allOnlineClasses = [];
  List<Map<String, dynamic>> _filteredClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOnlineClasses();
  }

  Future<void> _fetchOnlineClasses() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collectionGroup("onlineclass").get();
      final List<Map<String, dynamic>> docs = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final parentId = doc.reference.parent.parent?.id ?? '';
        
        // Check Expiry
        final expiryStr = data['expiryDate'];
        if (expiryStr != null) {
          final expiry = DateTime.tryParse(expiryStr);
          if (expiry != null && DateTime.now().isAfter(expiry)) {
            continue; 
          }
        }

        docs.add({
          ...data,
          "id": doc.id,
          "parentId": parentId,
          "type": "onlineclass",
        });
      }

      if (mounted) {
        setState(() {
          _allOnlineClasses = docs;
          _filteredClasses = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching online classes: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredClasses = _allOnlineClasses
          .where((item) => 
            (item['name'] ?? '').toString().toLowerCase().contains(query.toLowerCase()) || 
            (item['subjects'] ?? '').toString().toLowerCase().contains(query.toLowerCase()) ||
            (item['about'] ?? '').toString().toLowerCase().contains(query.toLowerCase())
          )
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Online Classes",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 🔍 Specific Search Bar for this page
          Container(
            padding: EdgeInsets.all(16.r),
            color: Colors.indigo,
            child: TextField(
              controller: _searchController,
              onChanged: _filterSearch,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Search online courses (e.g. Python, Math)",
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _filterSearch('');
                      },
                    )
                  : null,
                contentPadding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 16.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredClasses.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 60.sp, color: Colors.grey),
                        SizedBox(height: 12.h),
                        Text("No courses found match your search.", style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                    itemCount: _filteredClasses.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.8, // Adjusted for UserBox style
                    ),
                    itemBuilder: (context, index) {
                      final data = _filteredClasses[index];
                      return InkWell(
                        onTap: () {
                          AdvertiseManager().showInterstitialAd(() {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserDetails(
                                  userId: data['id'],
                                  parentId: data['parentId'],
                                  type: data['type'],
                                ),
                              ),
                            );
                          });
                        },
                        child: UserBox(
                          user: data,
                          uid: currentUserUid,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
