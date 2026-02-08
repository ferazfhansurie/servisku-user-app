import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/models.dart';

// Bookings list
final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final response = await apiClient.getBookings();
  if (response['success'] == true) {
    final data = response['bookings'] ?? response['data'] ?? [];
    return (data as List)
        .map((e) => Booking.fromJson(e))
        .toList();
  }
  return [];
});

// Single booking detail
final bookingDetailProvider = FutureProvider.family<Booking?, String>((ref, id) async {
  final response = await apiClient.getBookingDetail(id);
  if (response['success'] == true) {
    final data = response['booking'] ?? response['data'];
    if (data != null) return Booking.fromJson(data);
  }
  return null;
});

// Booking bids (for HELP! requests)
final bookingBidsProvider = FutureProvider.family<List<BookingBid>, String>((ref, bookingId) async {
  final response = await apiClient.getBookingBids(bookingId);
  if (response['success'] == true) {
    final data = response['bids'] ?? response['data'] ?? [];
    return (data as List)
        .map((e) => BookingBid.fromJson(e))
        .toList();
  }
  return [];
});

// Booking actions notifier
class BookingActionsNotifier extends StateNotifier<AsyncValue<void>> {
  BookingActionsNotifier(this.ref) : super(const AsyncValue.data(null));
  
  final Ref ref;
  
  Future<Booking?> createBooking({
    required String serviceId,
    required String contractorId,
    required String subcategoryId,
    String? description,
    List<String>? images,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? addressId,
    double? lat,
    double? lng,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.createBooking({
        'service_id': serviceId,
        'contractor_id': contractorId,
        'subcategory_id': subcategoryId,
        if (description != null) 'description': description,
        if (images != null) 'images': images,
        if (scheduledDate != null) 'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
        if (scheduledTime != null) 'scheduled_time': scheduledTime,
        if (addressId != null) 'address_id': addressId,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
      
      if (response['success'] == true) {
        ref.invalidate(bookingsProvider);
        state = const AsyncValue.data(null);
        final data = response['booking'] ?? response['data'];
        if (data != null) return Booking.fromJson(data);
      }
      throw Exception(response['error'] ?? 'Failed to create booking');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
  
  Future<Booking?> createHelpRequest({
    required String subcategoryId,
    required String description,
    List<String>? images,
    required double lat,
    required double lng,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.createHelpRequest({
        'subcategory_id': subcategoryId,
        'description': description,
        if (images != null) 'images': images,
        'lat': lat,
        'lng': lng,
      });
      
      if (response['success'] == true) {
        ref.invalidate(bookingsProvider);
        state = const AsyncValue.data(null);
        final data = response['booking'] ?? response['data'];
        if (data != null) return Booking.fromJson(data);
      }
      throw Exception(response['error'] ?? 'Failed to create help request');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
  
  Future<bool> acceptBid(String bookingId, String bidId) async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.acceptBid(bookingId, bidId);
      if (response['success'] == true) {
        ref.invalidate(bookingsProvider);
        ref.invalidate(bookingDetailProvider(bookingId));
        ref.invalidate(bookingBidsProvider(bookingId));
        state = const AsyncValue.data(null);
        return true;
      }
      throw Exception(response['error'] ?? 'Failed to accept bid');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
  
  Future<bool> cancelBooking(String bookingId, String reason) async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.cancelBooking(bookingId, reason);
      if (response['success'] == true) {
        ref.invalidate(bookingsProvider);
        ref.invalidate(bookingDetailProvider(bookingId));
        state = const AsyncValue.data(null);
        return true;
      }
      throw Exception(response['error'] ?? 'Failed to cancel booking');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final bookingActionsProvider = StateNotifierProvider<BookingActionsNotifier, AsyncValue<void>>((ref) {
  return BookingActionsNotifier(ref);
});
