// Helper function to safely parse doubles from various types
double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double _parseDoubleRequired(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class User {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final String preferredLanguage;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    this.preferredLanguage = 'en',
    this.isActive = true,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        email: json['email'],
        phone: json['phone'],
        fullName: json['full_name'],
        avatarUrl: json['avatar_url'],
        role: json['role'],
        preferredLanguage: json['preferred_language'] ?? 'en',
        isActive: json['is_active'] ?? true,
        createdAt: DateTime.parse(json['created_at']),
      );
}

class Address {
  final String id;
  final String userId;
  final String? label;
  final String addressLine;
  final String? city;
  final String? state;
  final String? postcode;
  final double? lat;
  final double? lng;
  final bool isDefault;

  Address({
    required this.id,
    required this.userId,
    this.label,
    required this.addressLine,
    this.city,
    this.state,
    this.postcode,
    this.lat,
    this.lng,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'],
        userId: json['user_id'],
        label: json['label'],
        addressLine: json['address_line'],
        city: json['city'],
        state: json['state'],
        postcode: json['postcode'],
        lat: _parseDoubleNullable(json['lat']),
        lng: _parseDoubleNullable(json['lng']),
        isDefault: json['is_default'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'address_line': addressLine,
        'city': city,
        'state': state,
        'postcode': postcode,
        'lat': lat,
        'lng': lng,
        'is_default': isDefault,
      };
}

class Category {
  final String id;
  final String nameEn;
  final String nameMs;
  final String slug;
  final String? icon;
  final String? color;
  final List<Subcategory> subcategories;

  Category({
    required this.id,
    required this.nameEn,
    required this.nameMs,
    required this.slug,
    this.icon,
    this.color,
    this.subcategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        nameEn: json['name_en'],
        nameMs: json['name_ms'],
        slug: json['slug'],
        icon: json['icon'],
        color: json['color'],
        subcategories: (json['subcategories'] as List<dynamic>?)
                ?.map((e) => Subcategory.fromJson(e))
                .toList() ??
            [],
      );

  String getName(String locale) => locale == 'ms' ? nameMs : nameEn;
}

class Subcategory {
  final String id;
  final String categoryId;
  final String nameEn;
  final String nameMs;
  final String slug;
  final String? icon;

  Subcategory({
    required this.id,
    required this.categoryId,
    required this.nameEn,
    required this.nameMs,
    required this.slug,
    this.icon,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) => Subcategory(
        id: json['id'],
        categoryId: json['category_id'],
        nameEn: json['name_en'],
        nameMs: json['name_ms'],
        slug: json['slug'],
        icon: json['icon'],
      );

  String getName(String locale) => locale == 'ms' ? nameMs : nameEn;
}

class ContractorProfile {
  final String id;
  final String userId;
  final String? businessName;
  final String? description;
  final String verificationStatus;
  final double avgRating;
  final int totalReviews;
  final int totalJobsCompleted;
  final bool isOnline;
  final int serviceRadiusKm;
  final double? lat;
  final double? lng;
  final User? user;
  final List<ContractorService> services;

  ContractorProfile({
    required this.id,
    required this.userId,
    this.businessName,
    this.description,
    required this.verificationStatus,
    this.avgRating = 0,
    this.totalReviews = 0,
    this.totalJobsCompleted = 0,
    this.isOnline = false,
    this.serviceRadiusKm = 25,
    this.lat,
    this.lng,
    this.user,
    this.services = const [],
  });

  factory ContractorProfile.fromJson(Map<String, dynamic> json) =>
      ContractorProfile(
        id: json['id'],
        userId: json['user_id'],
        businessName: json['business_name'],
        description: json['description'],
        verificationStatus: json['verification_status'],
        avgRating: _parseDoubleRequired(json['avg_rating']),
        totalReviews: json['total_reviews'] ?? 0,
        totalJobsCompleted: json['total_jobs_completed'] ?? 0,
        isOnline: json['is_online'] ?? false,
        serviceRadiusKm: json['service_radius_km'] ?? 25,
        lat: _parseDoubleNullable(json['lat']),
        lng: _parseDoubleNullable(json['lng']),
        user: json['user'] != null ? User.fromJson(json['user']) : null,
        services: (json['services'] as List<dynamic>?)
                ?.map((e) => ContractorService.fromJson(e))
                .toList() ??
            [],
      );
}

class ContractorService {
  final String id;
  final String contractorId;
  final String? subcategoryId;
  final String title;
  final String? description;
  final double basePrice;
  final String priceType;
  final List<String> images;
  final bool isActive;
  final ContractorProfile? contractor;
  final Subcategory? subcategory;
  // Additional fields from search API
  final String? businessName;
  final double? avgRating;
  final int? totalReviews;
  final bool? isOnline;
  final String? contractorName;
  final String? contractorAvatar;
  final String? subcategoryName;
  final String? categoryName;
  final String? categorySlug;
  final double? distance;
  final double? contractorLat;
  final double? contractorLng;

  ContractorService({
    required this.id,
    required this.contractorId,
    this.subcategoryId,
    required this.title,
    this.description,
    required this.basePrice,
    this.priceType = 'fixed',
    this.images = const [],
    this.isActive = true,
    this.contractor,
    this.subcategory,
    this.businessName,
    this.avgRating,
    this.totalReviews,
    this.isOnline,
    this.contractorName,
    this.contractorAvatar,
    this.subcategoryName,
    this.categoryName,
    this.categorySlug,
    this.distance,
    this.contractorLat,
    this.contractorLng,
  });

  factory ContractorService.fromJson(Map<String, dynamic> json) =>
      ContractorService(
        id: json['id'],
        contractorId:
            json['contractor_id'] ?? json['contractor_profile_id'] ?? '',
        subcategoryId: json['subcategory_id'],
        title: json['title'] ?? '',
        description: json['description'],
        basePrice: _parseDoubleRequired(json['base_price']),
        priceType: json['price_type'] ?? 'fixed',
        images: _parseImages(json['images']),
        isActive: json['is_active'] ?? true,
        contractor: json['contractor'] != null
            ? ContractorProfile.fromJson(json['contractor'])
            : null,
        subcategory: json['subcategory'] != null
            ? Subcategory.fromJson(json['subcategory'])
            : null,
        businessName: json['business_name'],
        avgRating: _parseDoubleRequired(json['avg_rating']),
        totalReviews: json['total_reviews'],
        isOnline: json['is_online'],
        contractorName: json['contractor_name'],
        contractorAvatar: json['contractor_avatar'],
        subcategoryName: json['subcategory_name'],
        categoryName: json['category_name'],
        categorySlug: json['category_slug'],
        distance: _parseDoubleNullable(json['distance']),
        contractorLat: _parseDoubleNullable(json['contractor_lat']),
        contractorLng: _parseDoubleNullable(json['contractor_lng']),
      );

  static List<String> _parseImages(dynamic images) {
    if (images == null) return [];
    if (images is List) return images.cast<String>();
    if (images is String) {
      try {
        final parsed = images;
        if (parsed.startsWith('[')) {
          // It's a JSON array string
          return [];
        }
      } catch (_) {}
    }
    return [];
  }
}

class Booking {
  final String id;
  final String bookingNumber;
  final String userId;
  final String? contractorId;
  final String? serviceId;
  final String? subcategoryId;
  final String status;
  final bool isHelpRequest;
  final String? description;
  final List<String> images;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final Map<String, dynamic>? addressSnapshot;
  final double? lat;
  final double? lng;
  final double? quotedPrice;
  final double? finalPrice;
  final DateTime createdAt;
  final ContractorProfile? contractor;
  final ContractorService? service;

  Booking({
    required this.id,
    required this.bookingNumber,
    required this.userId,
    this.contractorId,
    this.serviceId,
    this.subcategoryId,
    required this.status,
    this.isHelpRequest = false,
    this.description,
    this.images = const [],
    this.scheduledDate,
    this.scheduledTime,
    this.addressSnapshot,
    this.lat,
    this.lng,
    this.quotedPrice,
    this.finalPrice,
    required this.createdAt,
    this.contractor,
    this.service,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'],
        bookingNumber: json['booking_number'],
        userId: json['user_id'],
        contractorId: json['contractor_id'],
        serviceId: json['service_id'],
        subcategoryId: json['subcategory_id'],
        status: json['status'],
        isHelpRequest: json['is_help_request'] ?? false,
        description: json['description'],
        images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
        scheduledDate: json['scheduled_date'] != null
            ? DateTime.parse(json['scheduled_date'])
            : null,
        scheduledTime: json['scheduled_time'],
        addressSnapshot: json['address_snapshot'],
        lat: _parseDoubleNullable(json['lat']),
        lng: _parseDoubleNullable(json['lng']),
        quotedPrice: _parseDoubleNullable(json['quoted_price']),
        finalPrice: _parseDoubleNullable(json['final_price']),
        createdAt: DateTime.parse(json['created_at']),
        contractor: json['contractor'] != null
            ? ContractorProfile.fromJson(json['contractor'])
            : null,
        service: json['service'] != null
            ? ContractorService.fromJson(json['service'])
            : null,
      );
}

class BookingBid {
  final String id;
  final String bookingId;
  final String contractorId;
  final double price;
  final String? message;
  final int? etaMinutes;
  final String status;
  final DateTime createdAt;
  final ContractorProfile? contractor;

  BookingBid({
    required this.id,
    required this.bookingId,
    required this.contractorId,
    required this.price,
    this.message,
    this.etaMinutes,
    required this.status,
    required this.createdAt,
    this.contractor,
  });

  factory BookingBid.fromJson(Map<String, dynamic> json) => BookingBid(
        id: json['id'],
        bookingId: json['booking_id'],
        contractorId: json['contractor_id'],
        price: _parseDoubleRequired(json['price']),
        message: json['message'],
        etaMinutes: json['eta_minutes'],
        status: json['status'],
        createdAt: DateTime.parse(json['created_at']),
        contractor: json['contractor'] != null
            ? ContractorProfile.fromJson(json['contractor'])
            : null,
      );
}

class ChatRoom {
  final String id;
  final String? bookingId;
  final String userId;
  final String contractorId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final ContractorProfile? contractor;
  final int unreadCount;

  ChatRoom({
    required this.id,
    this.bookingId,
    required this.userId,
    required this.contractorId,
    this.lastMessage,
    this.lastMessageAt,
    this.contractor,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    // Build contractor from flat fields if 'contractor' object not present
    ContractorProfile? contractor;
    if (json['contractor'] != null) {
      contractor = ContractorProfile.fromJson(json['contractor']);
    } else if (json['business_name'] != null ||
        json['contractor_name'] != null) {
      // Build from flat fields returned by backend
      contractor = ContractorProfile(
        id: json['contractor_id'] ?? '',
        userId: '',
        businessName: json['business_name'] ?? json['contractor_name'],
        description: null,
        verificationStatus: 'verified',
        avgRating: 0.0,
        totalReviews: 0,
      );
    }

    return ChatRoom(
      id: json['id'],
      bookingId: json['booking_id'],
      userId: json['user_id'],
      contractorId: json['contractor_id'],
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      contractor: contractor,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String? message;
  final String messageType;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.message,
    this.messageType = 'text',
    this.metadata = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        roomId: json['room_id'],
        senderId: json['sender_id'],
        message: json['message'],
        messageType: json['message_type'] ?? 'text',
        metadata: json['metadata'] ?? {},
        isRead: json['is_read'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
      );
}

class Review {
  final String id;
  final String bookingId;
  final String userId;
  final String contractorId;
  final int rating;
  final String? comment;
  final String? contractorReply;
  final List<String> images;
  final DateTime createdAt;
  final User? user;

  Review({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.contractorId,
    required this.rating,
    this.comment,
    this.contractorReply,
    this.images = const [],
    required this.createdAt,
    this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'],
        bookingId: json['booking_id'],
        userId: json['user_id'],
        contractorId: json['contractor_id'],
        rating: json['rating'],
        comment: json['comment'],
        contractorReply: json['contractor_reply'],
        images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.parse(json['created_at']),
        user: json['user'] != null ? User.fromJson(json['user']) : null,
      );
}
