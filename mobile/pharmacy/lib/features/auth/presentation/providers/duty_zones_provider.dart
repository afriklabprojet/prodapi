import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';

/// Modèle simplifié de zone de garde
class DutyZone {
  final int id;
  final String name;
  final String? description;

  const DutyZone({required this.id, required this.name, this.description});

  factory DutyZone.fromJson(Map<String, dynamic> json) {
    return DutyZone(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

/// Provider qui récupère les zones de garde depuis l'API
final dutyZonesProvider = FutureProvider<List<DutyZone>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.get('/duty-zones');
    final data = response.data;
    // Handle direct list, {data: [...]}, or {data: {data: [...]}}
    List rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      final inner = data['data'];
      if (inner is List) {
        rawList = inner;
      } else if (inner is Map && inner['data'] is List) {
        rawList = inner['data'] as List;
      } else {
        rawList = [];
      }
    } else {
      rawList = [];
    }
    return rawList.map((e) => DutyZone.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});
