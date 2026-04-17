import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class CheckoutPrescriptionState {
  final List<XFile> images;
  final String? notes;
  final String? errorMessage;
  
  /// ID de l'ordonnance déjà uploadée (pour éviter re-upload en cas de retry)
  final int? uploadedPrescriptionId;
  
  /// URL de l'image principale de l'ordonnance uploadée
  final String? uploadedPrescriptionImage;

  const CheckoutPrescriptionState({
    this.images = const [], 
    this.notes, 
    this.errorMessage,
    this.uploadedPrescriptionId,
    this.uploadedPrescriptionImage,
  });

  CheckoutPrescriptionState copyWith({
    List<XFile>? images,
    String? notes,
    bool clearNotes = false,
    String? errorMessage,
    bool clearError = false,
    int? uploadedPrescriptionId,
    String? uploadedPrescriptionImage,
    bool clearUploaded = false,
  }) {
    return CheckoutPrescriptionState(
      images: images ?? this.images,
      notes: clearNotes ? null : (notes ?? this.notes),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      uploadedPrescriptionId: clearUploaded ? null : (uploadedPrescriptionId ?? this.uploadedPrescriptionId),
      uploadedPrescriptionImage: clearUploaded ? null : (uploadedPrescriptionImage ?? this.uploadedPrescriptionImage),
    );
  }

  bool get hasImages => images.isNotEmpty;
  bool get hasValidPrescription => images.isNotEmpty || uploadedPrescriptionId != null;
  
  /// Vérifie si l'ordonnance a déjà été uploadée (pour éviter re-upload)
  bool get isAlreadyUploaded => uploadedPrescriptionId != null;
}

class CheckoutPrescriptionNotifier
    extends StateNotifier<CheckoutPrescriptionState> {
  CheckoutPrescriptionNotifier()
      : super(const CheckoutPrescriptionState());

  void addImage(XFile image) {
    state = state.copyWith(images: [...state.images, image]);
  }

  void addImages(List<XFile> images) {
    state = state.copyWith(images: [...state.images, ...images]);
  }

  void removeImage(int index) {
    final updated = List<XFile>.from(state.images)..removeAt(index);
    state = state.copyWith(images: updated);
  }
  
  /// Marque l'ordonnance comme uploadée (appelé après upload réussi)
  void markAsUploaded(int prescriptionId, String? imageUrl) {
    state = state.copyWith(
      uploadedPrescriptionId: prescriptionId,
      uploadedPrescriptionImage: imageUrl,
    );
  }

  void reset() {
    state = const CheckoutPrescriptionState();
  }
}
