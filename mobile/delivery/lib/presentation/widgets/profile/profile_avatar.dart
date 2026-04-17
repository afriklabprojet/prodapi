import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/api_constants.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 90,
    this.isOnline = false,
    this.onTap,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final bool isOnline;
  final VoidCallback? onTap;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _imageError = false;

  String get _initials {
    final parts = widget.name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';
  }

  /// Construit l'URL complète à partir d'un chemin relatif (/storage/...)
  String? get _fullImageUrl {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    // Chemin relatif — construire l'URL complète
    final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base$url';
  }

  bool get _hasValidImage => _fullImageUrl != null && !_imageError;

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: size + 8,
        height: size + 8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gradient ring
            Container(
              width: size + 8,
              height: size + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isOnline
                      ? [const Color(0xFF34D399), const Color(0xFF059669)]
                      : [const Color(0xFFD1D5DB), const Color(0xFF9CA3AF)],
                ),
              ),
            ),
            // Avatar circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: ClipOval(
                child: _hasValidImage
                    ? CachedNetworkImage(
                        imageUrl: _fullImageUrl!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: size,
                          height: size,
                          color: const Color(0xFFF0FDF4),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _imageError = true);
                          });
                          return _initialsWidget(size);
                        },
                      )
                    : _initialsWidget(size),
              ),
            ),
            // Online dot
            if (widget.isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            // Camera icon
            if (widget.onTap != null)
              Positioned(
                bottom: 0,
                right: widget.isOnline ? 24 : 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _initialsWidget(double size) {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF059669),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
