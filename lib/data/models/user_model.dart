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
    final roleValue = json['role'];
    final providerProfile =
        json['providerProfile'] ?? json['provider']?['providerProfile'];
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

    final latitudeValue = json['latitude'] ?? providerProfile?['latitude'];
    final longitudeValue = json['longitude'] ?? providerProfile?['longitude'];
    final ratingValue = json['rating'] ?? json['avgRating'];
    final totalReviewsValue = json['totalReviews'] ?? json['reviewsCount'];
    final completedJobsValue = json['completedJobs'] ?? json['jobsCompleted'];
    final avatarUrl = json['avatarUrl'] ?? json['profilePicture'];
    final cityValue = json['city'] ?? providerProfile?['city'];

    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      role: role,
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: json['email']?.toString(),
      profilePicture: avatarUrl?.toString(),
      city: cityValue?.toString(),
      address: json['address']?.toString(),
      bio: json['bio']?.toString(),
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
      portfolioUrls: _parseStringList(providerProfile?['portfolioUrls']),
      certificationsUrls: _parseStringList(
        providerProfile?['certificationsUrls'],
      ),
      nationalId: json['nationalId']?.toString(),
      businessLicense: json['businessLicense']?.toString(),
      educationDocument: json['educationDocument']?.toString(),
      location: json['location']?.toString(),
      latitude: latitudeValue is num ? latitudeValue.toDouble() : null,
      longitude: longitudeValue is num ? longitudeValue.toDouble() : null,
      isVerified: json['isVerified'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
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
