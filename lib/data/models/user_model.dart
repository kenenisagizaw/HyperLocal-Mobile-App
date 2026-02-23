enum UserRole { customer, provider }

class UserModel {
  final String id;
  final UserRole role;

  // Basic profile
  final String name;
  final String phone;
  final String? email;
  final String? profilePicture; // Can be URL or local path

  // Provider verification fields
  final String? nationalId;
  final String? businessLicense;
  final String? educationDocument;
  final String? location;
  final double? latitude;  // <-- new field
  final double? longitude; // <-- new field
  final bool isVerified;

  UserModel({
    required this.id,
    required this.role,
    required this.name,
    required this.phone,
    this.email,
    this.profilePicture,
    this.nationalId,
    this.businessLicense,
    this.educationDocument,
    this.location,
    this.latitude,
    this.longitude,
    this.isVerified = false,
  });

  /// Creates a copy of the user with updated fields
  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? profilePicture,
    String? nationalId,
    String? businessLicense,
    String? educationDocument,
    String? location,
    double? latitude,
    double? longitude,
    bool? isVerified,
  }) {
    return UserModel(
      id: id,
      role: role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      nationalId: nationalId ?? this.nationalId,
      businessLicense: businessLicense ?? this.businessLicense,
      educationDocument: educationDocument ?? this.educationDocument,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}