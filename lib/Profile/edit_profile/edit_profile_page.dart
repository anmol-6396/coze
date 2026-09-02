import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coze/Services/permission_helper.dart'; // ✅ Added
import 'package:coze/log_in/login_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  String? _phone;
  String? _gender;
  String? _imageUrl; // ✅ Firebase Storage URL
  String? _localImagePath; // ✅ Local path before upload
  bool _isUploading = false; // ✅ Loading state for image upload

  int? _userId;
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ✅ Load data from Firestore
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        nameController.text = data["name"] ?? "";
        emailController.text = data["email"] ?? "";
        _gender = data["gender"];
        _phone = data["phone"] ?? user.phoneNumber ?? "Not Provided";
        _imageUrl = data["image"];
        _userId = data["user_id"]; // ✅ Load numeric ID
      });
    }
  }

  // ✅ Pick image and upload to Firebase Storage
  Future<void> _pickImage() async {
    final hasPermission = await PermissionHelper.requestPhotoPermission(context);
    if (!hasPermission) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _localImagePath = pickedFile.path;
        _isUploading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final ref = FirebaseStorage.instance.ref().child("profile_images/${user.uid}.jpg");
        await ref.putFile(File(pickedFile.path));
        final url = await ref.getDownloadURL();

        // ✅ Save to Firestore immediately
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "image": url,
        }, SetOptions(merge: true));

        setState(() {
          _imageUrl = url;
          _localImagePath = null;
          _isUploading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile image updated!")),
          );
        }
      } catch (e) {
        debugPrint("Upload failed: $e");
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: $e")),
          );
        }
      }
    }
  }

  // ✅ Remove image from Firestore + Storage
  Future<void> _removeImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final ref = FirebaseStorage.instance.ref().child("profile_images/${user.uid}.jpg");
      await ref.delete(); // delete from storage
    } catch (e) {
      debugPrint("No image in storage: $e");
    }

    await FirebaseFirestore.instance.collection("users").doc(user.uid).update({"image": ""});

    setState(() {
      _imageUrl = null;
      _localImagePath = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile image removed")),
    );
  }

  // ✅ Save updated data
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final updatedData = {
        "uid": user.uid,
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": _phone,
        "gender": _gender,
        "image": _imageUrl ?? "",
      };

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set(updatedData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, updatedData);
      }
    }
  }

  Widget _buildAvatar() {
    ImageProvider? image;
    if (_localImagePath != null) {
      image = FileImage(File(_localImagePath!));
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      image = NetworkImage(_imageUrl!);
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.indigo.shade100, width: 4.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10.r,
                spreadRadius: 2.r,
              )
            ],
          ),
          child: CircleAvatar(
            radius: 60.r,
            backgroundColor: Colors.indigo.shade50,
            backgroundImage: image,
            child: _isUploading 
                ? const CircularProgressIndicator(color: Colors.indigo)
                : (image == null
                    ? Icon(Icons.person, size: 60.r, color: Colors.indigo.shade200)
                    : null),
          ),
        ),
        if (!_isUploading)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: const BoxDecoration(
                color: Colors.indigo,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 20.sp),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18.sp)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header section
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(bottom: 30.h),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.r),
                  bottomRight: Radius.circular(30.r),
                ),
              ),
              child: Column(
                children: [
                  _buildAvatar(),
                  if (_imageUrl != null && _imageUrl!.isNotEmpty)
                    TextButton.icon(
                      onPressed: _removeImage,
                      icon: Icon(Icons.delete, color: Colors.white70, size: 16.sp),
                      label: Text("Remove Photo", style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PERSONAL INFORMATION", 
                      style: TextStyle(
                        fontSize: 12.sp, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.indigo,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 15.h),

                    // Full Name
                    _buildTextField(
                      controller: nameController,
                      label: "Full Name",
                      icon: Icons.person_outline,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          final capitalized = val[0].toUpperCase() + val.substring(1);
                          if (capitalized != val) {
                            nameController.value = TextEditingValue(
                              text: capitalized,
                              selection: TextSelection.collapsed(offset: capitalized.length),
                            );
                          }
                        }
                      },
                    ),
                    SizedBox(height: 15.h),

                    // Email Section
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.email_outlined, color: Colors.indigo, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text("Email Address", style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.indigo)),
                              const Spacer(),
                              if (FirebaseAuth.instance.currentUser?.emailVerified ?? false)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20.r)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.verified, color: Colors.green, size: 12.sp),
                                      SizedBox(width: 4.w),
                                      Text("Verified", style: TextStyle(color: Colors.green, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )
                              else
                                Text("Not Verified", style: TextStyle(color: Colors.redAccent, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(fontSize: 16.sp, color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              hintText: "Enter your email",
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            validator: (v) => (v == null || !v.contains('@')) ? "Invalid email" : null,
                          ),
                          if (!(FirebaseAuth.instance.currentUser?.emailVerified ?? false))
                            Padding(
                              padding: EdgeInsets.only(top: 12.h),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Verification link sent to your email!")),
                                          );
                                        }
                                      },
                                      icon: Icon(Icons.send_rounded, size: 14.sp),
                                      label: Text("VERIFY EMAIL", style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade800,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  TextButton(
                                    onPressed: () async {
                                      await FirebaseAuth.instance.currentUser?.reload();
                                      setState(() {});
                                    },
                                    child: Text("Check Status", style: TextStyle(fontSize: 12.sp, decoration: TextDecoration.underline)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Phone Number Card
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.indigo.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone_iphone_rounded, color: Colors.indigo, size: 24.sp),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Login Number", style: TextStyle(fontSize: 11.sp, color: Colors.indigo.shade300, fontWeight: FontWeight.bold)),
                                Text((_phone != null && _phone!.isNotEmpty && _phone != "Not Provided") ? _phone! : "Not Verified", 
                                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.indigo.shade900)),
                              ],
                            ),
                          ),
                          if (_phone == null || _phone!.isEmpty || _phone == "Not Provided")
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => LoginPage(forceLinkMode: true)),
                                ).then((_) => _loadProfile());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                minimumSize: const Size(0, 35),
                              ),
                              child: const Text("VERIFY"),
                            )
                          else
                            Icon(Icons.lock_outline_rounded, color: Colors.indigo.withValues(alpha: 0.3), size: 18.sp),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Gender
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        items: const [
                          DropdownMenuItem(value: "Male", child: Text("Male")),
                          DropdownMenuItem(value: "Female", child: Text("Female")),
                          DropdownMenuItem(value: "Other", child: Text("Other")),
                        ],
                        onChanged: (val) => setState(() => _gender = val),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16.sp),
                        decoration: InputDecoration(
                          labelText: "Gender",
                          labelStyle: const TextStyle(color: Colors.indigo),
                          prefixIcon: const Icon(Icons.wc_outlined, color: Colors.indigo),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 40.h),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 55.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                        elevation: 4,
                        shadowColor: Colors.indigo.withValues(alpha: 0.4),
                      ),
                      child: Text('SAVE CHANGES', 
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),

                    SizedBox(height: 10.h),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', 
                          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? helperText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: (val) {
          if (val.isNotEmpty) {
            final words = val.split(' ');
            final capitalizedWords = words.map((word) {
              if (word.isEmpty) return word;
              return word[0].toUpperCase() + word.substring(1);
            }).join(' ');
            
            if (capitalizedWords != val) {
              if (controller != null) {
                controller.value = TextEditingValue(
                  text: capitalizedWords,
                  selection: TextSelection.collapsed(offset: capitalizedWords.length),
                );
              }
            }
          }
          onChanged?.call(val);
        },
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.indigo),
          helperText: helperText,
          helperStyle: TextStyle(color: Colors.indigo.shade300, fontSize: 10.sp),
          prefixIcon: Icon(icon, color: Colors.indigo),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      ),
    );
  }
}
