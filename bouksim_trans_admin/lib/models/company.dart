class Company {
  final String name;
  final String? address;
  final String? ice;
  final DateTime createdAt;
  final bool isActive;

  Company({
    required this.name,
    this.address,
    this.ice,
    required this.createdAt,
    required this.isActive,
  });
}