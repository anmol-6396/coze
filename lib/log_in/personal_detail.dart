import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import 'package:coze/bottom_nav_bar/bottom_nav_bar.dart';
import 'login_page.dart';
import 'package:coze/Services/permission_helper.dart'; 
import 'package:coze/Services/id_manager.dart';

class PersonalDetailsPage extends StatefulWidget {
  final bool isGuestPrompt;
  const PersonalDetailsPage({super.key, this.isGuestPrompt = false});

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  DateTime? dob;
  String? gender;
  String? imagePath;
  String? emailError;
  bool _loading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  Future<void> _prefillData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    if (doc.exists) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNav()),
      );
    } else {
      setState(() {
        nameController.text = user.displayName ?? "";
        emailController.text = user.email ?? "";
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final hasPermission = await PermissionHelper.requestPhotoPermission(context);
    if (!hasPermission) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => imagePath = pickedFile.path);
    }
  }

  void _removeImage() => setState(() => imagePath = null);

  void _validateEmail(String val) {
    if (val.isEmpty) {
      emailError = null;
      setState(() {});
      return;
    }
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(val)) {
      emailError = "Enter a valid email address";
    } else {
      emailError = null;
    }
    setState(() {});
  }

  bool get _isFormValid =>
      nameController.text.trim().isNotEmpty &&
      gender != null &&
      dob != null &&
      emailError == null;

  Future<void> _saveDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      if (imagePath != null) {
        final ref = FirebaseStorage.instance.ref().child("profile_images/${user.uid}.jpg");
        await ref.putFile(File(imagePath!));
        imageUrl = await ref.getDownloadURL();
      } else {
        imageUrl = user.photoURL;
      }

      final int userNumber = await IdManager.instance.getNextId("users");
      final String displayName = "${nameController.text.trim()} $userNumber";

      final data = {
        "uid": user.uid,
        "name": displayName,
        "email": emailController.text.trim(),
        "gender": gender,
        "dob": dob?.toIso8601String() ?? "",
        "image": imageUrl ?? "",
        "phone": user.phoneNumber ?? "",
        "user_id": userNumber,
        "createdAt": DateTime.now(),
      };

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set(data, SetOptions(merge: true));

      if (!mounted) return;
      if (widget.isGuestPrompt) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BottomNav()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black, // ✅ Premium Black BG
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Complete Profile",
          style: TextStyle(fontSize: 24.sp, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.8, -0.6),
            radius: 1.2,
            colors: [Colors.blue.withValues(alpha: 0.1), Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                
                // 📸 Modern Profile Image Picker
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.1), blurRadius: 20)
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55.r,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          backgroundImage: imagePath != null 
                              ? FileImage(File(imagePath!)) 
                              : (currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null) as ImageProvider?,
                          child: (imagePath == null && (currentUser?.photoURL == null || currentUser!.photoURL!.isEmpty))
                              ? Icon(Icons.person_rounded, size: 50.r, color: Colors.white24)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 30.h),

                // 💎 Info Card (Glassmorphism)
                Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(32.r),
                    border: Border.all(color: Colors.white10, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("FULL NAME"),
                      _buildTextField(
                        controller: nameController,
                        hint: "John Doe",
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // 📧 Enhanced Email UI
                      _buildLabel("EMAIL ADDRESS"),
                      _buildTextField(
                        controller: emailController,
                        hint: "example@gmail.com",
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        errorText: emailError,
                        onChanged: _validateEmail,
                        readOnly: (currentUser?.email != null && currentUser!.email!.isNotEmpty),
                      ),
                      
                      SizedBox(height: 20.h),

                      // 📱 Phone Section
                      if (currentUser?.phoneNumber == null || currentUser!.phoneNumber!.isEmpty)
                        _buildPhoneLinkButton()
                      else
                        _buildLabel("VERIFIED MOBILE"),
                        if (currentUser?.phoneNumber != null && currentUser!.phoneNumber!.isNotEmpty)
                        _buildTextField(
                          controller: TextEditingController(text: currentUser.phoneNumber),
                          hint: "Verified Phone",
                          icon: Icons.verified_user_rounded,
                          readOnly: true,
                          isVerified: true,
                        ),

                      SizedBox(height: 20.h),

                      Row(
                        children: [
                          Expanded(child: _buildGenderDropdown()),
                          SizedBox(width: 15.w),
                          Expanded(child: _buildDatePicker()),
                        ],
                      ),
                      
                      SizedBox(height: 32.h),

                      // 🚀 Action Button
                      Container(
                        width: double.infinity,
                        height: 60.h,
                        decoration: BoxDecoration(
                          boxShadow: [
                            if (_isFormValid && !_isSaving)
                              BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: (_isFormValid && !_isSaving) ? _saveDetails : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white10,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : Text("FINISH SETUP", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
      child: Text(text, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 1.5)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    bool isVerified = false,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    Function(String)? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: errorText != null ? Colors.redAccent : Colors.white10),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        onChanged: (value) {
          // ✅ Last 10 Digits Logic for Phone if applicable
          if (keyboardType == TextInputType.phone) {
             String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
             if (digits.length > 10) {
                String clean = digits.substring(digits.length - 10);
                controller.value = TextEditingValue(text: clean, selection: TextSelection.collapsed(offset: clean.length));
             }
          }
          onChanged?.call(value);
        },
        style: TextStyle(fontSize: 15.sp, color: Colors.white, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white10, fontSize: 14.sp),
          prefixIcon: Icon(icon, color: isVerified ? Colors.green : Colors.white54, size: 20),
          suffixIcon: isVerified ? const Icon(Icons.check_circle, color: Colors.green, size: 18) : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildPhoneLinkButton() {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage(forceLinkMode: true))).then((_) => _prefillData());
      },
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone_iphone_rounded, color: Colors.orange, size: 20),
            SizedBox(width: 12.w),
            const Text("Link Mobile Number", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.orange, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("GENDER"),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: gender,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              hint: Text("Select", style: TextStyle(color: Colors.white, fontSize: 14.sp)),
              items: ["Male", "Female", "Other"].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: (val) => setState(() => gender = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("BIRTHDAY"),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(primary: Colors.blueAccent, onPrimary: Colors.white, surface: Color(0xFF121212)),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => dob = picked);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Text(
                  dob != null ? "${dob!.day}/${dob!.month}/${dob!.year}" : "DD/MM/YYYY",
                  style: TextStyle(color: dob != null ? Colors.white : Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
