import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/models/delivery.dart';
import '../../data/models/courier_profile.dart';
import '../../core/services/route_service.dart';
import '../../core/services/location_service.dart';
import '../../core/config/app_config.dart';

final deliveriesProvider = FutureProvider.family<List<Delivery>, String>((
  ref,
  status,
) async {
  return ref.read(deliveryRepositoryProvider).getDeliveries(status: status);
});

final courierProfileProvider = FutureProvider<CourierProfile>((ref) async {
  return ref.read(deliveryRepositoryProvider).getProfile();
});

final routeServiceProvider = Provider<RouteService>((ref) {
  return RouteService(AppConfig.googleMapsApiKey);
});

final locationStreamProvider = StreamProvider<Position>((ref) {
  return ref.watch(locationServiceProvider).locationStream;
});
