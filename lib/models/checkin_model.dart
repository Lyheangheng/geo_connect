class CheckInUser {
  final int id;
  final String name;
  final String? profileImage;

  CheckInUser({
    required this.id,
    required this.name,
    this.profileImage,
  });

  factory CheckInUser.fromJson(Map<String, dynamic> json) {
    return CheckInUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Anonymous',
      profileImage: json['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImage': profileImage,
    };
  }
}

class CheckInModel {
  final int id;
  final int? userId;
  final double lat;
  final double lng;
  final String? locationName;
  final String? address;
  final double? accuracy;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;
  final CheckInUser? user;

  CheckInModel({
    required this.id,
    this.userId,
    required this.lat,
    required this.lng,
    this.locationName,
    this.address,
    this.accuracy,
    this.description,
    this.imageUrl,
    this.createdAt,
    this.user,
  });

  factory CheckInModel.fromJson(Map<String, dynamic> json) {
    return CheckInModel(
      id: json['id'] as int,
      userId: json['userId'] as int?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      locationName: json['locationName'] as String?,
      address: json['address'] as String?,
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? CheckInUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'lat': lat,
      'lng': lng,
      'locationName': locationName,
      'address': address,
      'accuracy': accuracy,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }
}
