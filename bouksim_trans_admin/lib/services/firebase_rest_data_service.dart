import 'data_service_interface.dart';
import '../models/user.dart';
import '../models/journey.dart';
import '../models/company.dart';
import 'firebase_rest_service.dart';

class FirebaseRestDataService implements DataService {
  @override
  Stream<List<AppUser>> getUsersStream() {
    // For REST API, we use periodic updates instead of real-time streams
    return Stream.periodic(Duration(seconds: 30), (_) async {
      return await FirebaseRestService.getUsers();
    }).asyncMap((event) => event);
  }

  @override
  Future<void> deleteUser(String username) async {
    // Implement later - for now use mock data
    print('Delete user: $username - REST API not implemented yet');
  }

  @override
  Future<void> toggleUserStatus(String username, bool isActive) async {
    // Implement later
    print('Toggle user status: $username - REST API not implemented yet');
  }

  @override
  Stream<List<Journey>> getJourneysStream() {
    return Stream.periodic(Duration(seconds: 30), (_) async {
      return await FirebaseRestService.getJourneys();
    }).asyncMap((event) => event);
  }

  @override
  Future<void> deleteJourney(Journey journey) async {
    // Implement later
    print('Delete journey - REST API not implemented yet');
  }

  @override
  Stream<List<Company>> getGlobalCompaniesStream() {
    return Stream.periodic(Duration(seconds: 30), (_) async {
      return await FirebaseRestService.getGlobalCompanies();
    }).asyncMap((event) => event);
  }

  @override
  Future<void> addGlobalCompany(String name, {String? address, String? ice}) async {
    await FirebaseRestService.addGlobalCompany(name, address: address, ice: ice);
  }

  @override
  Future<void> updateGlobalCompany(String oldName, String newName, {String? address, String? ice}) async {
    if (oldName != newName) {
      await FirebaseRestService.deleteGlobalCompany(oldName);
    }
    await FirebaseRestService.addGlobalCompany(newName, address: address, ice: ice);
  }

  @override
  Future<void> deleteGlobalCompany(String name) async {
    await FirebaseRestService.deleteGlobalCompany(name);
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    return await FirebaseRestService.getDashboardStats();
  }
}