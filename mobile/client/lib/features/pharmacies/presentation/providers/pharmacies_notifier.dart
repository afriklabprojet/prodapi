import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/usecases/get_featured_pharmacies_usecase.dart';
import '../../domain/usecases/get_nearby_pharmacies_usecase.dart';
import '../../domain/usecases/get_on_duty_pharmacies_usecase.dart';
import '../../domain/usecases/get_pharmacies_usecase.dart';
import '../../domain/usecases/get_pharmacy_details_usecase.dart';
import 'pharmacies_state.dart';

class PharmaciesNotifier extends StateNotifier<PharmaciesState> {
  final GetPharmaciesUseCase getPharmaciesUseCase;
  final GetNearbyPharmaciesUseCase getNearbyPharmaciesUseCase;
  final GetOnDutyPharmaciesUseCase getOnDutyPharmaciesUseCase;
  final GetPharmacyDetailsUseCase getPharmacyDetailsUseCase;
  final GetFeaturedPharmaciesUseCase getFeaturedPharmaciesUseCase;

  PharmaciesNotifier({
    required this.getPharmaciesUseCase,
    required this.getNearbyPharmaciesUseCase,
    required this.getOnDutyPharmaciesUseCase,
    required this.getPharmacyDetailsUseCase,
    required this.getFeaturedPharmaciesUseCase,
  }) : super(const PharmaciesState());

  Future<void> fetchPharmacies({bool refresh = false}) async {
    if (state.status == PharmaciesStatus.loading) return;
    if (state.hasReachedMax && !refresh) return;

    if (refresh) {
      state = const PharmaciesState(
        status: PharmaciesStatus.loading,
      );
    } else {
      state = state.copyWith(status: PharmaciesStatus.loading);
    }

    final page = refresh ? 1 : state.currentPage;

    final result = await getPharmaciesUseCase(
      page: page,
      perPage: AppConstants.defaultPageSize,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: PharmaciesStatus.error,
          errorMessage: failure.message,
        );
      },
      (pharmacies) {
        // Le backend retourne toutes les pharmacies d'un coup (pas de pagination réelle)
        // donc hasReachedMax est toujours true pour éviter les requêtes infinies
        final updatedList = refresh
            ? pharmacies
            : [...state.pharmacies, ...pharmacies];

        state = state.copyWith(
          status: PharmaciesStatus.success,
          pharmacies: updatedList,
          hasReachedMax: true,
          currentPage: page + 1,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> fetchNearbyPharmacies({
    required double latitude,
    required double longitude,
    double radius = 10.0,
  }) async {
    state = state.copyWith(status: PharmaciesStatus.loading);

    final result = await getNearbyPharmaciesUseCase(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: PharmaciesStatus.error,
          errorMessage: failure.message,
        );
      },
      (pharmacies) {
        state = state.copyWith(
          status: PharmaciesStatus.success,
          nearbyPharmacies: pharmacies,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> fetchPharmacyDetails(int id) async {
    state = state.copyWith(status: PharmaciesStatus.loading);

    final result = await getPharmacyDetailsUseCase(id);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: PharmaciesStatus.error,
          errorMessage: failure.message,
        );
      },
      (pharmacy) {
        state = state.copyWith(
          status: PharmaciesStatus.success,
          selectedPharmacy: pharmacy,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> fetchOnDutyPharmacies({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    state = state.copyWith(status: PharmaciesStatus.loading);

    final result = await getOnDutyPharmaciesUseCase(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: PharmaciesStatus.error,
          errorMessage: failure.message,
        );
      },
      (pharmacies) {
        state = state.copyWith(
          status: PharmaciesStatus.success,
          onDutyPharmacies: pharmacies,
          errorMessage: null,
        );
      },
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void clearSelectedPharmacy() {
    state = state.copyWith(clearSelectedPharmacy: true);
  }

  Future<void> fetchFeaturedPharmacies({bool isRetry = false}) async {
    // Set loading state for featured pharmacies
    state = state.copyWith(isFeaturedLoading: true);
    
    final result = await getFeaturedPharmaciesUseCase();

    result.fold(
      (failure) {
        state = state.copyWith(
          isFeaturedLoading: false,
          isFeaturedLoaded: isRetry, // only mark as loaded on retry, not first attempt
        );
        // Auto-retry once after 3 seconds on first failure
        if (!isRetry) {
          Future.delayed(const Duration(seconds: 3), () {
            fetchFeaturedPharmacies(isRetry: true);
          });
        }
      },
      (pharmacies) {
        state = state.copyWith(
          featuredPharmacies: pharmacies,
          isFeaturedLoading: false,
          isFeaturedLoaded: true,
        );
      },
    );
  }
}
