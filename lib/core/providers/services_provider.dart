import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/models.dart';

// Categories provider with caching
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final response = await apiClient.getCategories();
  if (response['success'] == true) {
    final data = response['categories'] ?? response['data'] ?? [];
    return (data as List)
        .map((e) => Category.fromJson(e))
        .toList();
  }
  return [];
});

// Search results
class SearchParams {
  final String? query;
  final String? categoryId;
  final double? lat;
  final double? lng;
  final int radius;
  
  SearchParams({this.query, this.categoryId, this.lat, this.lng, this.radius = 25});
}

final searchParamsProvider = StateProvider<SearchParams>((ref) => SearchParams());

final searchResultsProvider = FutureProvider<List<ContractorService>>((ref) async {
  final params = ref.watch(searchParamsProvider);
  
  final response = await apiClient.searchServices(
    query: params.query,
    categoryId: params.categoryId,
    lat: params.lat,
    lng: params.lng,
    radius: params.radius,
  );
  
  if (response['success'] == true) {
    final data = response['services'] ?? response['data'] ?? [];
    return (data as List)
        .map((e) => ContractorService.fromJson(e))
        .toList();
  }
  return [];
});

// Nearby services
final nearbyServicesProvider = FutureProvider.family<List<ContractorService>, (double, double)>((ref, coords) async {
  final (lat, lng) = coords;
  final response = await apiClient.getNearbyServices(lat, lng);
  
  if (response['success'] == true) {
    final data = response['services'] ?? response['data'] ?? [];
    return (data as List)
        .map((e) => ContractorService.fromJson(e))
        .toList();
  }
  return [];
});

// Single service detail
final serviceDetailProvider = FutureProvider.family<ContractorService?, String>((ref, id) async {
  final response = await apiClient.getServiceDetail(id);
  if (response['success'] == true) {
    final data = response['service'] ?? response['data'];
    if (data != null) return ContractorService.fromJson(data);
  }
  return null;
});

// Contractor profile
final contractorProfileProvider = FutureProvider.family<ContractorProfile?, String>((ref, id) async {
  final response = await apiClient.getContractorProfile(id);
  if (response['success'] == true) {
    final data = response['contractor'] ?? response['data'];
    if (data != null) return ContractorProfile.fromJson(data);
  }
  return null;
});

// Contractor reviews
final contractorReviewsProvider = FutureProvider.family<List<Review>, String>((ref, contractorId) async {
  final response = await apiClient.getContractorReviews(contractorId);
  if (response['success'] == true) {
    final data = response['reviews'] ?? response['data'] ?? [];
    return (data as List)
        .map((e) => Review.fromJson(e))
        .toList();
  }
  return [];
});
