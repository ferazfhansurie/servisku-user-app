import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Riverpod provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Handle token expiry - redirect to login
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Auth
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await _dio.post('/auth/send-otp', data: {'phone': phone});
    return response.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await _dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/register', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/auth/me', data: data);
    return response.data;
  }

  // Categories
  Future<Map<String, dynamic>> getCategories() async {
    final response = await _dio.get('/categories');
    return response.data;
  }

  // Services & Search
  Future<Map<String, dynamic>> searchServices({
    String? query,
    String? categoryId,
    double? lat,
    double? lng,
    int? radius,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get('/services/search', queryParameters: {
      if (query != null) 'q': query,
      if (categoryId != null) 'category_id': categoryId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radius != null) 'radius': radius,
      'page': page,
      'limit': limit,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getNearbyServices(double lat, double lng,
      {int radius = 25}) async {
    final response = await _dio.get('/services/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getServiceDetail(String id) async {
    final response = await _dio.get('/services/$id');
    return response.data;
  }

  // Contractors
  Future<Map<String, dynamic>> getContractorProfile(String id) async {
    final response = await _dio.get('/contractors/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> getContractorReviews(String id,
      {int page = 1}) async {
    final response = await _dio
        .get('/contractors/$id/reviews', queryParameters: {'page': page});
    return response.data;
  }

  // Bookings
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    final response = await _dio.post('/bookings', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> createHelpRequest(
      Map<String, dynamic> data) async {
    final response = await _dio.post('/bookings/help', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getBookings(
      {String? status, int page = 1}) async {
    final response = await _dio.get('/bookings', queryParameters: {
      if (status != null) 'status': status,
      'page': page,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getBookingDetail(String id) async {
    final response = await _dio.get('/bookings/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> getBookingBids(String id) async {
    final response = await _dio.get('/bookings/$id/bids');
    return response.data;
  }

  Future<Map<String, dynamic>> acceptBid(String bookingId, String bidId) async {
    final response = await _dio.put('/bookings/$bookingId/bids/$bidId/accept');
    return response.data;
  }

  Future<Map<String, dynamic>> cancelBooking(String id, String reason) async {
    final response =
        await _dio.put('/bookings/$id/cancel', data: {'reason': reason});
    return response.data;
  }

  // Payments
  Future<Map<String, dynamic>> createPaymentIntent(String bookingId) async {
    final response = await _dio
        .post('/payments/create-intent', data: {'booking_id': bookingId});
    return response.data;
  }

  // Chat
  Future<Map<String, dynamic>> getChatRooms() async {
    final response = await _dio.get('/chat/rooms');
    return response.data;
  }

  Future<Map<String, dynamic>> startChat(String contractorId,
      {String? serviceId}) async {
    final response = await _dio.post('/chat/start', data: {
      'contractor_id': contractorId,
      if (serviceId != null) 'service_id': serviceId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getChatRoom(String roomId) async {
    final response = await _dio.get('/chat/rooms/$roomId');
    return response.data;
  }

  Future<Map<String, dynamic>> getChatMessages(String roomId,
      {int page = 1}) async {
    final response = await _dio
        .get('/chat/rooms/$roomId/messages', queryParameters: {'page': page});
    return response.data;
  }

  Future<Map<String, dynamic>> sendMessage(String roomId, String message,
      {String type = 'text'}) async {
    final response = await _dio.post('/chat/rooms/$roomId/messages', data: {
      'message': message,
      'message_type': type,
    });
    return response.data;
  }

  // Reviews
  Future<Map<String, dynamic>> submitReview(Map<String, dynamic> data) async {
    final response = await _dio.post('/reviews', data: data);
    return response.data;
  }

  // Addresses
  Future<Map<String, dynamic>> getAddresses() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  Future<Map<String, dynamic>> addAddress(Map<String, dynamic> data) async {
    final response = await _dio.post('/addresses', data: data);
    return response.data;
  }

  // Notifications
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final response =
        await _dio.get('/notifications', queryParameters: {'page': page});
    return response.data;
  }

  Future<void> markNotificationsRead() async {
    await _dio.put('/notifications/read-all');
  }

  // Generic methods for flexibility
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}

final apiClient = ApiClient();
