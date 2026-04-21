class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? name;
  final String? avatar;
  final bool isProfileComplete;
  final String role;
  final String? phone;
  final String? address;
  final double? rating;
  final int? totalRatings;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.name,
    this.avatar,
    required this.isProfileComplete,
    required this.role,
    this.phone,
    this.address,
    this.rating,
    this.totalRatings,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        fullName: json['fullName'] ?? '',
        name: json['name'],
        avatar: json['avatar'],
        isProfileComplete: json['isProfileComplete'] ?? false,
        role: json['role'] ?? 'USER',
        phone: json['phone'],
        address: json['address'],
        rating: json['rating'] != null
            ? double.tryParse(json['rating'].toString())
            : null,
        totalRatings: json['totalRatings'],
        createdAt: json['createdAt'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'name': name,
        'avatar': avatar,
        'isProfileComplete': isProfileComplete,
        'role': role,
        'phone': phone,
        'address': address,
        'rating': rating,
        'totalRatings': totalRatings,
        'createdAt': createdAt,
      };

  String get displayName => name ?? fullName;
  bool get isAdmin => role == 'ADMIN';
  bool get isModerator => role == 'MODERATOR';
}

class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final bool requiresProfileCompletion;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.requiresProfileCompletion,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        user: UserModel.fromJson(json['user'] ?? {}),
        accessToken: json['access_token'] ?? '',
        refreshToken: json['refresh_token'] ?? '',
        requiresProfileCompletion: json['requiresProfileCompletion'] ?? false,
      );
}
