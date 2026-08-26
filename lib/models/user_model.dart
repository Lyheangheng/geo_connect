class UserModel {
  final int id;
  final String name;
  final String email;
  final bool isVerified;
  final String? profileImage;
  final String? coverImage;
  final String? bio;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.isVerified,
    this.profileImage,
    this.coverImage,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      profileImage: json['profileImage'] as String?,
      coverImage: json['coverImage'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isVerified': isVerified,
      'profileImage': profileImage,
      'coverImage': coverImage,
      'bio': bio,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    bool? isVerified,
    String? profileImage,
    String? coverImage,
    String? bio,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      bio: bio ?? this.bio,
    );
  }
}
