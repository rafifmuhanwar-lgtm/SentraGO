import 'package:flutter/material.dart';

/// Generates a consistent initial avatar from a name.
class AvatarWidget extends StatelessWidget {
  final String name;
  final double size;
  final String? photoUrl;

  const AvatarWidget({
    super.key,
    required this.name,
    this.size = 48,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoUrl!),
        onBackgroundImageError: (_, __) => _buildInitialsAvatar(),
      );
    }
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    final initials = _getInitials(name);
    final color = _getColor(name);

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getColor(String name) {
    final colors = [
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    final index = name.hashCode % colors.length;
    return colors[index];
  }
}
