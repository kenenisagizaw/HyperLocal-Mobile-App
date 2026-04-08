enum UserRole { customer, provider }

class UserModel {
  final String id;
  final UserRole role;

  // Basic profile
  final String name;
  final String phone;
  final String? email;
  final String? profilePicture; // Can be URL or local path
  final String? city;
  final String? address;
  final String? bio;
  final double? rating;
  final int? totalReviews;
  final int? completedJobs;

  // Provider profile fields
  final String? businessName;
  final double? hourlyRate;
  final String? serviceCategory;
  final double? serviceRadius;
  final String? availabilityStatus;
  final List<String> portfolioUrls;
  final List<String> certificationsUrls;

  // Provider verification fields
  final String? nationalId;
  final String? businessLicense;
  final String? educationDocument;
  final String? location;
  final double? latitude; // <-- new field
  final double? longitude; // <-- new field
  final bool isVerified;

  // Meta
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.role,
    required this.name,
    required this.phone,
    this.email,
    this.profilePicture,
    this.city,
    this.address,
    this.bio,
    this.rating,
    this.totalReviews,
    this.completedJobs,
    this.businessName,
    this.hourlyRate,
    this.serviceCategory,
    this.serviceRadius,
    this.availabilityStatus,
    this.portfolioUrls = const [],
    this.certificationsUrls = const [],
    this.nationalId,
    this.businessLicense,
    this.educationDocument,
    this.location,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final base = _extractBase(json);
    final roleValue = base['role'] ?? json['role'];
    final providerProfile = base['providerProfile'] ??
      base['provider']?['providerProfile'] ??
      json['providerProfile'] ??
      json['provider']?['providerProfile'];
    UserRole role = UserRole.customer;

    if (roleValue is String) {
      final normalized = roleValue.toLowerCase();
      if (normalized == 'provider' || normalized == 'work') {
        role = UserRole.provider;
      } else if (normalized == 'customer' || normalized == 'hire') {
        role = UserRole.customer;
      } else {
        role = UserRole.values.firstWhere(
          (value) => value.name == normalized,
          orElse: () => UserRole.customer,
        );
      }
    } else if (roleValue is int &&
        roleValue >= 0 &&
        roleValue < UserRole.values.length) {
      role = UserRole.values[roleValue];
    }

    if (roleValue == null && providerProfile is Map) {
      role = UserRole.provider;
    }

    final latitudeValue =
      base['latitude'] ?? providerProfile?['latitude'] ?? json['latitude'];
    final longitudeValue =
      base['longitude'] ?? providerProfile?['longitude'] ?? json['longitude'];
    final ratingValue =
      base['rating'] ?? base['avgRating'] ?? json['rating'] ?? json['avgRating'];
    final totalReviewsValue = base['totalReviews'] ??
      base['reviewsCount'] ??
      json['totalReviews'] ??
      json['reviewsCount'];
    final completedJobsValue = base['completedJobs'] ??
      base['jobsCompleted'] ??
      json['completedJobs'] ??
      json['jobsCompleted'];
    final avatarUrl = base['avatarUrl'] ?? base['profilePicture'];
    final cityValue = base['city'] ?? providerProfile?['city'];
    final phoneValue = base['phone'] ??
      base['phoneNumber'] ??
      json['phone'] ??
      json['phoneNumber'] ??
      json['provider']?['phone'] ??
      json['provider']?['phoneNumber'] ??
      json['user']?['phone'] ??
      json['user']?['phoneNumber'];
    final emailValue = base['email'] ?? json['email'];

    return UserModel(
      id: (base['id'] ?? base['_id'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      role: role,
      name: (base['name'] ?? json['name'] ?? '').toString(),
      phone: (phoneValue ?? '').toString(),
      email: emailValue?.toString(),
      profilePicture: avatarUrl?.toString(),
      city: cityValue?.toString(),
      address: base['address']?.toString(),
      bio: base['bio']?.toString(),
      rating: ratingValue is num ? ratingValue.toDouble() : null,
      totalReviews: totalReviewsValue is num ? totalReviewsValue.toInt() : null,
      completedJobs: completedJobsValue is num
          ? completedJobsValue.toInt()
          : null,
      businessName: providerProfile?['businessName']?.toString(),
      hourlyRate: providerProfile?['hourlyRate'] is num
          ? (providerProfile?['hourlyRate'] as num).toDouble()
          : null,
      serviceCategory: providerProfile?['serviceCategory']?.toString(),
      serviceRadius: providerProfile?['serviceRadius'] is num
          ? (providerProfile?['serviceRadius'] as num).toDouble()
          : null,
      availabilityStatus: providerProfile?['availabilityStatus']?.toString(),
      portfolioUrls: _parseStringList(providerProfile?['portfolioUrls']),
      certificationsUrls: _parseStringList(
        providerProfile?['certificationsUrls'],
      ),
      nationalId: base['nationalId']?.toString(),
      businessLicense: base['businessLicense']?.toString(),
      educationDocument: base['educationDocument']?.toString(),
      location: base['location']?.toString(),
      latitude: latitudeValue is num ? latitudeValue.toDouble() : null,
      longitude: longitudeValue is num ? longitudeValue.toDouble() : null,
      isVerified: base['isVerified'] == true,
      createdAt: base['createdAt'] != null
          ? DateTime.tryParse(base['createdAt'].toString())
          : null,
    );
  }

  static Map<String, dynamic> _extractBase(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is Map) {
      return user.cast<String, dynamic>();
    }
    final provider = json['provider'];
    if (provider is Map) {
      return provider.cast<String, dynamic>();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'name': name,
      'phone': phone,
      'email': email,
      'profilePicture': profilePicture,
      'city': city,
      'address': address,
      'bio': bio,
      'rating': rating,
      'totalReviews': totalReviews,
      'completedJobs': completedJobs,
      'businessName': businessName,
      'hourlyRate': hourlyRate,
      'serviceCategory': serviceCategory,
      'serviceRadius': serviceRadius,
      'availabilityStatus': availabilityStatus,
      'portfolioUrls': portfolioUrls,
      'certificationsUrls': certificationsUrls,
      'nationalId': nationalId,
      'businessLicense': businessLicense,
      'educationDocument': educationDocument,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Creates a copy of the user with updated fields
  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? profilePicture,
    String? city,
    String? address,
    String? bio,
    double? rating,
    int? totalReviews,
    int? completedJobs,
    String? businessName,
    double? hourlyRate,
    String? serviceCategory,
    double? serviceRadius,
    String? availabilityStatus,
    List<String>? portfolioUrls,
    List<String>? certificationsUrls,
    String? nationalId,
    String? businessLicense,
    String? educationDocument,
    String? location,
    double? latitude,
    double? longitude,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id,
      role: role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      city: city ?? this.city,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      completedJobs: completedJobs ?? this.completedJobs,
      businessName: businessName ?? this.businessName,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      serviceRadius: serviceRadius ?? this.serviceRadius,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      portfolioUrls: portfolioUrls ?? this.portfolioUrls,
      certificationsUrls: certificationsUrls ?? this.certificationsUrls,
      nationalId: nationalId ?? this.nationalId,
      businessLicense: businessLicense ?? this.businessLicense,
      educationDocument: educationDocument ?? this.educationDocument,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
