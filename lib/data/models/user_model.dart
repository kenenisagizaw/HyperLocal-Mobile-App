enum UserRole { customer, provider }

class UserModel {
  final String id;
  final UserRole role;

  // Basic profile
  final String name;
  final String phone;
  final String? email;
  final String? profilePicture; // Can be URL or local path
  final String? address;
  final String? bio;

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
    this.address,
    this.bio,
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
    UserRole role = UserRole.customer;

    if (roleValue is String) {
      role = UserRole.values.firstWhere(
        (value) => value.name == roleValue,
        orElse: () => UserRole.customer,
      );
    } else if (roleValue is int &&
        roleValue >= 0 &&
        roleValue < UserRole.values.length) {
      role = UserRole.values[roleValue];
    }

    final latitudeValue = json['latitude'];
    final longitudeValue = json['longitude'];

    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      role: role,
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: json['email']?.toString(),
      profilePicture: json['profilePicture']?.toString(),
      address: json['address']?.toString(),
      bio: json['bio']?.toString(),
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
      'address': address,
      'bio': bio,
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
    String? address,
    String? bio,
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
      address: address ?? this.address,
      bio: bio ?? this.bio,
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
}
