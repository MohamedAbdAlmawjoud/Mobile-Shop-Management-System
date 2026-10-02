class SupplierModel {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime? createdAt;

  const SupplierModel({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.createdAt,
  });

  factory SupplierModel.fromMap(Map<String, Object?> map) {
    return SupplierModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  SupplierModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt,
    );
  }
}
