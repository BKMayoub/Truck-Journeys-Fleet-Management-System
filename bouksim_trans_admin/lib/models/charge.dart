class Charge {
  final String name;
  final double amount;
  
  Charge({required this.name, required this.amount});

  // Optional: Add fromJson for consistency
  factory Charge.fromJson(Map<String, dynamic> json) {
    return Charge(
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  // Optional: Add toJson for future use
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
    };
  }
}