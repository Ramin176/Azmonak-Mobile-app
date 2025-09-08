import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.name;
      if (user.profileImagePath != null) {
        _profileImage = File(user.profileImagePath!);
      }
    }
  }

   
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_path');
    if (imagePath != null) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }
Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() { _profileImage = File(pickedFile.path); });
    }
  }

  void _saveProfile() async {
    setState(() { _isLoading = true; });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // آپدیت نام
      await authProvider.updateUserName(_nameController.text.trim());
      
      // آپدیت عکس
      if (_profileImage != null) {
        await authProvider.updateProfileImage(_profileImage!.path);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پروفایل با موفقیت آپدیت شد.')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در آپدیت پروفایل: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }
   
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ویرایش پروفایل')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // بخش عکس پروفایل
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _pickImage, child: const Text('تغییر عکس پروفایل')),
            const SizedBox(height: 32),
            
            // بخش تغییر نام
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'نام کامل'),
            ),
            const SizedBox(height: 40),
            
            // دکمه ذخیره
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('ذخیره تغییرات'),
            ),
            // بخش تغییر رمز عبور را می‌توانید در یک کارت جداگانه یا در همینجا اضافه کنید
          ],
        ),
      ),
    );
  }
}