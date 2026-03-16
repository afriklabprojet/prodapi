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
    final list = data is Map && data['data'] != null ? data['data'] as List : data as List;
    return list.map((e) => DutyZone.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});
