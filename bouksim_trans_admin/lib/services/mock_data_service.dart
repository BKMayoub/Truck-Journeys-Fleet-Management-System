import 'data_service_interface.dart';
import '../models/user.dart';
import '../models/journey.dart';
import '../models/company.dart';
import '../models/charge.dart';

class MockDataService implements DataService {
  // ========== MOCK DATA ==========
  
  // Mock Users
  static List<AppUser> _mockUsers = [
    AppUser(
      username: 'abderrahim bouksim',
      journeyCount: 45,
      lastLogin: DateTime.now().subtract(Duration(days: 2)),
      isActive: true,
    ),
    AppUser(
      username: 'mohamed driver',
      journeyCount: 23,
      lastLogin: DateTime.now().subtract(Duration(days: 5)),
      isActive: true,
    ),
    AppUser(
      username: 'ali trucker',
      journeyCount: 67,
      lastLogin: DateTime.now().subtract(Duration(days: 1)),
      isActive: true,
    ),
    AppUser(
      username: 'hassan transport',
      journeyCount: 12,
      lastLogin: DateTime.now().subtract(Duration(days: 10)),
      isActive: false,
    ),
  ];

  // Mock Journeys
  static List<Journey> _mockJourneys = [
    Journey(
      company: 'STE CAP',
      startCity: 'Casablanca',
      endCity: 'Marrakech',
      charges: [
        Charge(name: 'Fuel', amount: 500.0),
        Charge(name: 'Tolls', amount: 150.0),
      ],
      payment: 2500.0,
      date: DateTime.now().subtract(Duration(days: 2)),
      userId: 'abderrahim bouksim',
      plateNumber: 'A1234BC',
      cargoType: 'Electronics',
      cargoWeight: 1500.0,
      bonDeLivraison: 'BL-2024-001',
    ),
    Journey(
      company: 'STE JOUALI TRANS',
      startCity: 'Rabat',
      endCity: 'Tangier',
      charges: [
        Charge(name: 'Fuel', amount: 400.0),
        Charge(name: 'Maintenance', amount: 200.0),
      ],
      payment: 1800.0,
      date: DateTime.now().subtract(Duration(days: 5)),
      userId: 'mohamed driver',
      plateNumber: 'B5678CD',
      cargoType: 'Furniture',
      cargoWeight: 2000.0,
      bonDeLivraison: 'BL-2024-002',
    ),
    Journey(
      company: 'STE ATNER',
      startCity: 'Marrakech',
      endCity: 'Agadir',
      charges: [
        Charge(name: 'Fuel', amount: 300.0),
      ],
      payment: 1200.0,
      date: DateTime.now().subtract(Duration(days: 1)),
      userId: 'ali trucker',
      plateNumber: 'C9012DE',
      cargoType: 'Food Products',
      cargoWeight: 1800.0,
      bonDeLivraison: 'BL-2024-003',
    ),
  ];

  // Mock Companies
  static List<Company> _mockCompanies = [
    Company(
      name: 'STE CAP',
      address: 'Casablanca, Morocco',
      ice: '123456789',
      createdAt: DateTime.now().subtract(Duration(days: 100)),
      isActive: true,
    ),
    Company(
      name: 'STE JOUALI TRANS',
      address: 'Marrakech, Morocco',
      ice: '987654321',
      createdAt: DateTime.now().subtract(Duration(days: 80)),
      isActive: true,
    ),
    Company(
      name: 'STE ATNER',
      address: 'Rabat, Morocco',
      ice: '456123789',
      createdAt: DateTime.now().subtract(Duration(days: 60)),
      isActive: true,
    ),
    Company(
      name: 'STE BELHASSAN',
      address: 'Tangier, Morocco',
      ice: '789456123',
      createdAt: DateTime.now().subtract(Duration(days: 40)),
      isActive: true,
    ),
  ];

  // ========== DataService INTERFACE IMPLEMENTATION ==========

  @override
  Stream<List<AppUser>> getUsersStream() {
    return Stream.value(_mockUsers);
  }

  @override
  Future<void> deleteUser(String username) async {
    _mockUsers.removeWhere((user) => user.username == username);
  }

  @override
  Future<void> toggleUserStatus(String username, bool isActive) async {
    final userIndex = _mockUsers.indexWhere((user) => user.username == username);
    if (userIndex != -1) {
      final user = _mockUsers[userIndex];
      _mockUsers[userIndex] = AppUser(
        username: user.username,
        journeyCount: user.journeyCount,
        lastLogin: user.lastLogin,
        isActive: isActive,
      );
    }
  }

  @override
  Stream<List<Journey>> getJourneysStream() {
    return Stream.value(_mockJourneys);
  }

  @override
  Future<void> deleteJourney(Journey journey) async {
    _mockJourneys.remove(journey);
  }

  @override
  Stream<List<Company>> getGlobalCompaniesStream() {
    return Stream.value(_mockCompanies);
  }

  @override
  Future<void> addGlobalCompany(String name, {String? address, String? ice}) async {
    _mockCompanies.add(Company(
      name: name,
      address: address,
      ice: ice,
      createdAt: DateTime.now(),
      isActive: true,
    ));
  }

  @override
  Future<void> updateGlobalCompany(String oldName, String newName, {String? address, String? ice}) async {
    final companyIndex = _mockCompanies.indexWhere((company) => company.name == oldName);
    if (companyIndex != -1) {
      final company = _mockCompanies[companyIndex];
      _mockCompanies[companyIndex] = Company(
        name: newName,
        address: address ?? company.address,
        ice: ice ?? company.ice,
        createdAt: company.createdAt,
        isActive: company.isActive,
      );
    }
  }

  @override
  Future<void> deleteGlobalCompany(String name) async {
    _mockCompanies.removeWhere((company) => company.name == name);
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500));
    
    final totalRevenue = _mockJourneys.fold(0.0, (sum, journey) => sum + journey.payment);
    final totalProfit = _mockJourneys.fold(0.0, (sum, journey) => sum + journey.netProfit);
    
    return {
      'totalUsers': _mockUsers.length,
      'totalJourneys': _mockJourneys.length,
      'totalRevenue': totalRevenue,
      'totalProfit': totalProfit,
      'averageRevenue': _mockJourneys.isNotEmpty ? totalRevenue / _mockJourneys.length : 0,
    };
  }

  // ========== STATIC HELPER METHODS FOR UI UPDATES ==========
  
  // These methods are used by your existing UI code - RENAMED to avoid conflicts
  static List<AppUser> get mockUsers => _mockUsers;
  static List<Journey> get mockJourneys => _mockJourneys;
  static List<Company> get mockCompanyObjects => _mockCompanies;

  static int get totalUsers => _mockUsers.length;
  static int get totalJourneys => _mockJourneys.length;
  static int get totalCompanies => _mockCompanies.length;
  static int get totalJourneysCount => _mockJourneys.length;

  // RENAMED static methods for your existing UI code
  static void staticDeleteUser(String username) {
    _mockUsers.removeWhere((user) => user.username == username);
  }

  static void staticToggleUserStatus(String username) {
    final userIndex = _mockUsers.indexWhere((user) => user.username == username);
    if (userIndex != -1) {
      final user = _mockUsers[userIndex];
      _mockUsers[userIndex] = AppUser(
        username: user.username,
        journeyCount: user.journeyCount,
        lastLogin: user.lastLogin,
        isActive: !user.isActive,
      );
    }
  }

  static void staticDeleteJourney(Journey journey) {
    _mockJourneys.remove(journey);
  }

  static void staticAddCompany(String name, {String? address, String? ice}) {
    _mockCompanies.add(Company(
      name: name,
      address: address,
      ice: ice,
      createdAt: DateTime.now(),
      isActive: true,
    ));
  }

  static void staticDeleteCompany(String name) {
    _mockCompanies.removeWhere((company) => company.name == name);
  }

  static void staticToggleCompanyStatus(String name) {
    final companyIndex = _mockCompanies.indexWhere((company) => company.name == name);
    if (companyIndex != -1) {
      final company = _mockCompanies[companyIndex];
      _mockCompanies[companyIndex] = Company(
        name: company.name,
        address: company.address,
        ice: company.ice,
        createdAt: company.createdAt,
        isActive: !company.isActive,
      );
    }
  }

  static void staticUpdateCompany(String oldName, String newName, {String? address, String? ice}) {
    final companyIndex = _mockCompanies.indexWhere((company) => company.name == oldName);
    if (companyIndex != -1) {
      final company = _mockCompanies[companyIndex];
      _mockCompanies[companyIndex] = Company(
        name: newName,
        address: address ?? company.address,
        ice: ice ?? company.ice,
        createdAt: company.createdAt,
        isActive: company.isActive,
      );
    }
  }
}