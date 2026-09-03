class Customer {
  final String id;
  final String? customerCode;
  final String fullName;
  final String? email;
  final String? phone;
  final String? riskProfile;
  final String currency;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    this.customerCode,
    required this.fullName,
    this.email,
    this.phone,
    this.riskProfile,
    this.currency = 'USD',
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String? ?? '',
      customerCode: json['customer_code'] as String?,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      riskProfile: json['risk_profile'] as String?,
      currency: json['currency'] as String? ?? 'USD',
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        if (customerCode != null) 'customer_code': customerCode,
        'full_name': fullName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (riskProfile != null) 'risk_profile': riskProfile,
        'currency': currency,
        if (notes != null) 'notes': notes,
      };
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}
