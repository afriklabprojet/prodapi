import 'package:equatable/equatable.dart';
import '../../domain/entities/pharmacy_entity.dart';

enum PharmaciesStatus { initial, loading, success, error }

class PharmaciesState extends Equatable {
  final PharmaciesStatus status;
  final List<PharmacyEntity> pharmacies;
  final List<PharmacyEntity> nearbyPharmacies;
  final List<PharmacyEntity> onDutyPharmacies;
  final List<PharmacyEntity> featuredPharmacies;
  final PharmacyEntity? selectedPharmacy;
  final String? errorMessage;
  final bool hasReachedMax;
  final int currentPage;
  final bool isFeaturedLoading;
  final bool isFeaturedLoaded;

  const PharmaciesState({
    this.status = PharmaciesStatus.initial,
    this.pharmacies = const [],
    this.nearbyPharmacies = const [],
    this.onDutyPharmacies = const [],
    this.featuredPharmacies = const [],
    this.selectedPharmacy,
    this.errorMessage,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.isFeaturedLoading = false,
    this.isFeaturedLoaded = false,
  });

  PharmaciesState copyWith({
    PharmaciesStatus? status,
    List<PharmacyEntity>? pharmacies,
    List<PharmacyEntity>? nearbyPharmacies,
    List<PharmacyEntity>? onDutyPharmacies,
    List<PharmacyEntity>? featuredPharmacies,
    PharmacyEntity? selectedPharmacy,
    bool clearSelectedPharmacy = false,
    String? errorMessage,
    bool clearError = false,
    bool? hasReachedMax,
    int? currentPage,
    bool? isFeaturedLoading,
    bool? isFeaturedLoaded,
  }) {
    return PharmaciesState(
      status: status ?? this.status,
      pharmacies: pharmacies ?? this.pharmacies,
      nearbyPharmacies: nearbyPharmacies ?? this.nearbyPharmacies,
      onDutyPharmacies: onDutyPharmacies ?? this.onDutyPharmacies,
      featuredPharmacies: featuredPharmacies ?? this.featuredPharmacies,
      selectedPharmacy: clearSelectedPharmacy ? null : (selectedPharmacy ?? this.selectedPharmacy),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      isFeaturedLoading: isFeaturedLoading ?? this.isFeaturedLoading,
      isFeaturedLoaded: isFeaturedLoaded ?? this.isFeaturedLoaded,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pharmacies,
        nearbyPharmacies,
        onDutyPharmacies,
        featuredPharmacies,
        selectedPharmacy,
        errorMessage,
        hasReachedMax,
        currentPage,
        isFeaturedLoading,
        isFeaturedLoaded,
      ];
}
