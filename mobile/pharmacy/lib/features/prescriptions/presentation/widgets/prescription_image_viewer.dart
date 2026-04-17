import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Visualiseur d'image plein écran avec zoom avancé
class FullscreenImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final String authToken;
  final bool isFullyDispensed;

  const FullscreenImageViewer({
    super.key,
    required this.urls,
    required this.initialIndex,
    required this.authToken,
    required this.isFullyDispensed,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.urls.length > 1
              ? 'Image ${_currentIndex + 1}/${widget.urls.length}'
              : 'Ordonnance',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (widget.urls.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  'Glissez ←→',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 8.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.urls[index],
                cacheKey: '${widget.urls[index]}_auth',
                fit: BoxFit.contain,
                httpHeaders: {'Authorization': 'Bearer ${widget.authToken}'},
                errorWidget: (c, u, e) => const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
                progressIndicatorBuilder: (c, u, p) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Sheet for image cropping with real ImageCropper before re-analysis
class ImageCropSheet extends StatefulWidget {
  final List<String> images;
  final String? authToken;
  final void Function(String?) onCropComplete;

  const ImageCropSheet({
    super.key,
    required this.images,
    required this.authToken,
    required this.onCropComplete,
  });

  @override
  State<ImageCropSheet> createState() => _ImageCropSheetState();
}

class _ImageCropSheetState extends State<ImageCropSheet> {
  int _selectedImageIndex = 0;
  bool _isCropping = false;
  String? _croppedImagePath;

  Future<void> _cropImage(String imageUrl) async {
    setState(() => _isCropping = true);

    try {
      // Download image to temp file
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: widget.authToken != null
            ? {'Authorization': 'Bearer ${widget.authToken}'}
            : {},
      );

      if (response.statusCode != 200) {
        throw Exception('Impossible de télécharger l\'image');
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/crop_input_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(response.bodyBytes);

      // Launch ImageCropper
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: tempFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer l\'ordonnance',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: Theme.of(context).primaryColor,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Recadrer l\'ordonnance',
            doneButtonTitle: 'Valider',
            cancelButtonTitle: AppLocalizations.of(context).cancel,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _croppedImagePath = croppedFile.path;
        });
      }

      // Clean up temp input file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du recadrage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCropping = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final documentsBaseUrl = '${AppConstants.apiBaseUrl}/documents/';

    // Build URLs
    final urls = widget.images.map((path) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }
      var cleanPath = path.startsWith('public/')
          ? path.replaceFirst('public/', '')
          : path;
      return '$documentsBaseUrl$cleanPath';
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.crop, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _croppedImagePath != null
                            ? 'Image recadrée'
                            : 'Recadrer l\'image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        _croppedImagePath != null
                            ? 'Prêt pour l\'analyse'
                            : 'Sélectionnez une image et recadrez',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  tooltip: AppLocalizations.of(context).close,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Image selector (if multiple) - only show if not cropped yet
          if (urls.length > 1 && _croppedImagePath == null)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: urls.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedImageIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedImageIndex = index),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: CachedNetworkImage(
                          imageUrl: urls[index],
                          fit: BoxFit.cover,
                          httpHeaders: widget.authToken != null
                              ? {'Authorization': 'Bearer ${widget.authToken}'}
                              : {},
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (urls.length > 1 && _croppedImagePath == null)
            const SizedBox(height: 16),

          // Preview image - show cropped or original
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.black,
                  child: _isCropping
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Préparation de l\'image...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        )
                      : _croppedImagePath != null
                      // Show cropped image
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(_croppedImagePath!),
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Recadré',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      // Show original with crop button
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: CachedNetworkImage(
                                imageUrl: urls[_selectedImageIndex],
                                fit: BoxFit.contain,
                                httpHeaders: widget.authToken != null
                                    ? {
                                        'Authorization':
                                            'Bearer ${widget.authToken}',
                                      }
                                    : {},
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                ),
                                progressIndicatorBuilder: (_, __, p) =>
                                    const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                              ),
                            ),
                            // Overlay crop button
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _cropImage(urls[_selectedImageIndex]),
                                  icon: const Icon(Icons.crop),
                                  label: const Text('Recadrer cette image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          // Info text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _croppedImagePath != null
                  ? 'L\'image est prête pour l\'analyse OCR'
                  : 'Appuyez sur "Recadrer" pour sélectionner la zone de l\'ordonnance',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                if (_croppedImagePath != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _croppedImagePath = null),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Recommencer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isCropping
                        ? null
                        : () => widget.onCropComplete(
                            _croppedImagePath ?? urls[_selectedImageIndex],
                          ),
                    icon: const Icon(Icons.document_scanner),
                    label: Text(
                      _croppedImagePath != null
                          ? 'Analyser l\'image recadrée'
                          : 'Analyser sans recadrer',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _croppedImagePath != null
                          ? Colors.green
                          : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
