class UserProfileSummary {
  final String id;
  final String name;
  final String email;

  const UserProfileSummary({
    required this.id,
    required this.name,
    required this.email,
  });

  UserProfileSummary copyWith({String? name, String? email}) {
    return UserProfileSummary(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  factory UserProfileSummary.fromJson(Map<String, dynamic> json) {
    return UserProfileSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}
