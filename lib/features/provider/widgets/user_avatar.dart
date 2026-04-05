import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imagePath,
    this.radius = 20,
  });

  final String name;
  final String? imagePath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    final initials = _getInitials(name);
    final imageProvider = hasImage ? _resolveImage(imagePath!) : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
      backgroundImage: imageProvider,
      child: hasImage
          ? null
          : Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2563EB),
                fontSize: radius * 0.5,
              ),
            ),
    );
  }

  ImageProvider? _resolveImage(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return NetworkImage(trimmed);
    }
    if (trimmed.startsWith('/')) {
      return NetworkImage('${ApiConstants.baseUrl}$trimmed');
    }
    return FileImage(File(trimmed));
  }
}

String _getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return 'P';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}
