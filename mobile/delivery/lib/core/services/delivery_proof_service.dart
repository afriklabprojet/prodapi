import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';

/// Provider pour le service de preuve de livraison
final deliveryProofServiceProvider = Provider<DeliveryProofService>((ref) {
  return DeliveryProofService(ref.read(dioProvider));
});

/// Modèle pour une preuve de livraison
class DeliveryProof {
  final File? photo;
  final Uint8List? signatureBytes;
  final String? notes;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  DeliveryProof({
    this.photo,
    this.signatureBytes,
    this.notes,
    DateTime? timestamp,
    this.latitude,
    this.longitude,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasPhoto => photo != null;
  bool get hasSignature => signatureBytes != null && signatureBytes!.isNotEmpty;
  bool get isValid => hasPhoto || hasSignature;
}

/// Service pour capturer et envoyer les preuves de livraison
class DeliveryProofService {
  final Dio _dio;
  final ImagePicker _picker = ImagePicker();

  DeliveryProofService(this._dio);

  /// Capture une photo depuis la caméra
  Future<File?> capturePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        if (kDebugMode) debugPrint('📷 [DeliveryProof] Photo capturée: ${image.path}');
        return File(image.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [DeliveryProof] Erreur capture photo: $e');
      rethrow;
    }
  }

  /// Sélectionne une photo depuis la galerie
  Future<File?> selectFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [DeliveryProof] Erreur sélection galerie: $e');
      rethrow;
    }
  }

  /// Convertit une signature (points) en image PNG
  Future<Uint8List?> signatureToImage(List<Offset?> points, {
    double width = 400,
    double height = 200,
  }) async {
    if (points.isEmpty) return null;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Fond blanc
      final paint = Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

      // Ligne de signature
      final signaturePaint = Paint()
        ..color = const ui.Color(0xFF000000)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < points.length - 1; i++) {
        if (points[i] != null && points[i + 1] != null) {
          canvas.drawLine(points[i]!, points[i + 1]!, signaturePaint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [DeliveryProof] Erreur conversion signature: $e');
      return null;
    }
  }

  /// Sauvegarde la signature en fichier temporaire
  Future<File?> saveSignatureToFile(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [DeliveryProof] Erreur sauvegarde signature: $e');
      return null;
    }
  }

  /// Envoie la preuve de livraison au serveur
  Future<void> uploadProof({
    required int deliveryId,
    required DeliveryProof proof,
  }) async {
    try {
      final formData = FormData();

      // Photo
      if (proof.photo != null) {
        formData.files.add(MapEntry(
          'delivery_photo',
          await MultipartFile.fromFile(
            proof.photo!.path,
            filename: 'delivery_proof_${deliveryId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        ));
      }

      // Signature
      if (proof.signatureBytes != null) {
        final signatureFile = await saveSignatureToFile(proof.signatureBytes!);
        if (signatureFile != null) {
          formData.files.add(MapEntry(
            'signature',
            await MultipartFile.fromFile(
              signatureFile.path,
              filename: 'signature_${deliveryId}_${DateTime.now().millisecondsSinceEpoch}.png',
            ),
          ));
        }
      }

      // Métadonnées
      formData.fields.addAll([
        MapEntry('timestamp', proof.timestamp.toIso8601String()),
        if (proof.notes != null) MapEntry('notes', proof.notes!),
        if (proof.latitude != null) MapEntry('latitude', proof.latitude.toString()),
        if (proof.longitude != null) MapEntry('longitude', proof.longitude.toString()),
      ]);

      await _dio.post(
        '/courier/deliveries/$deliveryId/proof',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (kDebugMode) debugPrint('✅ [DeliveryProof] Preuve uploadée pour livraison #$deliveryId');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [DeliveryProof] Erreur upload preuve: $e');
      // Ne pas bloquer la livraison si l'upload échoue
      // L'API backend acceptera quand même la livraison
    }
  }

  /// Encode une image en base64 pour stockage local
  String? encodeImageToBase64(File? file) {
    if (file == null) return null;
    try {
      final bytes = file.readAsBytesSync();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  /// Décode une image base64 en fichier
  Future<File?> decodeBase64ToFile(String base64String) async {
    try {
      final bytes = base64Decode(base64String);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/decoded_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      return null;
    }
  }
}
