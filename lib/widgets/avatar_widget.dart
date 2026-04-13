import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

class AvatarWidget extends StatefulWidget {
  const AvatarWidget({
    super.key,
    required this.name,
    this.size = 44,
    this.editable = false,
    this.imagePath,
    this.onChanged,
  });

  final String name;
  final double size;
  final bool editable;
  final String? imagePath;
  final ValueChanged<String?>? onChanged;

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  String? _path;

  String get _initials {
    final words = widget.name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      return 'GW';
    }
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _path = widget.imagePath;
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    if (widget.imagePath != null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString('profile_image_path');
    if (mounted && p != null) {
      setState(() => _path = p);
      widget.onChanged?.call(p);
    }
  }

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', picked.path);
    if (!mounted) {
      return;
    }
    setState(() => _path = picked.path);
    widget.onChanged?.call(picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.size / 2;
    final showImage = _path != null && File(_path!).existsSync();
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: const BoxDecoration(
              color: AppColors.tealMid,
              shape: BoxShape.circle,
            ),
            child: showImage
                ? CircleAvatar(radius: radius, backgroundImage: FileImage(File(_path!)))
                : Center(
                    child: Text(
                      _initials,
                      style: TextStyle(
                        fontSize: widget.size * 0.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
          if (widget.editable)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _pick,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
