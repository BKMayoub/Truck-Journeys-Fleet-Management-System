import '../models/user.dart';
import '../models/journey.dart';
import '../models/company.dart';

abstract class DataService {
  // User Management
  Stream<List<AppUser>> getUsersStream();
  Future<void> deleteUser(String username);
  Future<void> toggleUserStatus(String username, bool isActive);
  
  // Journeys Management
  Stream<List<Journey>> getJourneysStream();
  Future<void> deleteJourney(Journey journey);
  
  // Companies Management
  Stream<List<Company>> getGlobalCompaniesStream();
  Future<void> addGlobalCompany(String name, {String? address, String? ice});
  Future<void> updateGlobalCompany(String oldName, String newName, {String? address, String? ice});
  Future<void> deleteGlobalCompany(String name);
  
  // Statistics
  Future<Map<String, dynamic>> getDashboardStats();
}