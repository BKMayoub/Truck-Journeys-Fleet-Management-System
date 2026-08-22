import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/journey.dart';
import '../models/company.dart';
import '../models/charge.dart';

class FirebaseRestService {
  static const String projectId = 'bouksim-trans-app';
  static const String baseUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  static const String apiKey = 'AIzaSyCpkRn2N6x4DUSnl7S6eOxNTv4CLlLJcP0';

  // Generic method to get documents from a collection
  static Future<List<Map<String, dynamic>>> getCollection(String collectionName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$collectionName?key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List<dynamic>? ?? [];
        
        return documents.map((doc) {
          final fields = doc['fields'] as Map<String, dynamic>? ?? {};
          final name = doc['name'] as String;
          final documentId = name.split('/').last;
          
          return {
            'id': documentId,
            ..._parseFirestoreFields(fields),
          };
        }).toList();
      } else {
        print('Firebase REST Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching $collectionName: $e');
      return [];
    }
  }

  // Parse Firestore fields to Dart types
  static Map<String, dynamic> _parseFirestoreFields(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    
    fields.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        if (value.containsKey('stringValue')) {
          result[key] = value['stringValue'].toString();
        } else if (value.containsKey('integerValue')) {
          result[key] = int.parse(value['integerValue'].toString());
        } else if (value.containsKey('doubleValue')) {
          result[key] = double.parse(value['doubleValue'].toString());
        } else if (value.containsKey('booleanValue')) {
          result[key] = value['booleanValue'];
        } else if (value.containsKey('timestampValue')) {
          result[key] = DateTime.parse(value['timestampValue'].toString());
        } else if (value.containsKey('arrayValue')) {
          final array = value['arrayValue']['values'] as List<dynamic>? ?? [];
          result[key] = array.map((item) {
            if (item is Map<String, dynamic>) {
              // For journeys array, we want to keep the raw Firebase structure
              // so our getJourneys method can handle it properly
              return item;
            } else {
              return item.toString();
            }
          }).toList();
        } else if (value.containsKey('mapValue')) {
          result[key] = _parseFirestoreFields(value['mapValue']['fields'] ?? {});
        } else if (value.containsKey('nullValue')) {
          result[key] = null;
        }
      }
    });
    
    return result;
  }

  // ========== USER MANAGEMENT ==========
  
  // IN firebase_rest_service.dart - FIX THE getUsers() METHOD
  static Future<List<AppUser>> getUsers() async {
  print('🔄 SIMPLE: Fetching users from users_data collection...');
  
  try {
    final usersData = await getCollection('users_data');
    
    List<AppUser> result = [];
    
    for (final userData in usersData) {
      final username = userData['username'] ?? userData['id'] ?? 'Unknown';
      final journeys = userData['journeys'] as List<dynamic>? ?? [];
      final journeyCount = journeys.length;
      
      result.add(AppUser(
        username: username,
        journeyCount: journeyCount, // Actual journey count from journeys array
        lastLogin: _parseTimestamp(userData['lastSync']) ?? DateTime.now(),
        isActive: true, // Default to active
      ));
      
      print('👤 $username: $journeyCount journeys');
    }
    
    print('🎯 Simple approach: ${result.length} users');
    return result;
    
  } catch (e) {
    print('❌ Error in simple getUsers: $e');
    return [];
  }
}

  // ========== JOURNEYS MANAGEMENT ==========
  
  static Future<List<Journey>> getJourneys() async {
  print('🔄 FirebaseRestService: Starting to fetch journeys...');
  
  try {
    final usersData = await getCollection('users_data');
    print('📊 Found ${usersData.length} users in users_data');
    
    List<Journey> allJourneys = [];
    
    for (final userData in usersData) {
      final username = userData['username'] ?? userData['id'] ?? 'Unknown';
      final journeys = userData['journeys'] as List<dynamic>? ?? [];
      
      print('👤 User: $username has ${journeys.length} journeys');
      
      for (final journeyData in journeys) {
        try {
          print('📍 Raw journey data: ${journeyData.runtimeType}');
          
          // Extract the actual journey fields from the nested Firebase structure
          Map<String, dynamic> journeyFields = {};
          
          if (journeyData is Map<String, dynamic>) {
            if (journeyData.containsKey('mapValue') && 
                journeyData['mapValue'] is Map<String, dynamic> &&
                journeyData['mapValue'].containsKey('fields')) {
              // This is the Firebase nested structure: {mapValue: {fields: {...}}}
              journeyFields = journeyData['mapValue']['fields'] as Map<String, dynamic>;
            } else {
              // Direct structure (shouldn't happen with your data)
              journeyFields = journeyData;
            }
          }
          
          print('📍 Journey fields: ${journeyFields.keys.toList()}');
          
          // Parse each field using direct Firebase value extraction
          final company = _extractFirebaseValue(journeyFields['company'], 'string') ?? '';
          final startCity = _extractFirebaseValue(journeyFields['startCity'], 'string') ?? '';
          final endCity = _extractFirebaseValue(journeyFields['endCity'], 'string') ?? '';
          final payment = _extractFirebaseValue(journeyFields['payment'], 'double') ?? 0.0;
          final dateMillis = _extractFirebaseValue(journeyFields['date'], 'int') ?? DateTime.now().millisecondsSinceEpoch;
          final plateNumber = _extractFirebaseValue(journeyFields['plateNumber'], 'string') ?? '';
          final cargoType = _extractFirebaseValue(journeyFields['cargoType'], 'string') ?? '';
          final cargoWeight = _extractFirebaseValue(journeyFields['cargoWeight'], 'double') ?? 0.0;
          final bonDeLivraison = _extractFirebaseValue(journeyFields['bonDeLivraison'], 'string') ?? '';
          
          // Parse charges
          List<Charge> charges = [];
          final chargesData = journeyFields['charges'];
          if (chargesData is Map<String, dynamic> && 
              chargesData.containsKey('arrayValue') &&
              chargesData['arrayValue'] is Map<String, dynamic> &&
              chargesData['arrayValue'].containsKey('values')) {
            
            final chargeItems = chargesData['arrayValue']['values'] as List<dynamic>? ?? [];
            
            for (final chargeItem in chargeItems) {
              if (chargeItem is Map<String, dynamic> && 
                  chargeItem.containsKey('mapValue') &&
                  chargeItem['mapValue'] is Map<String, dynamic> &&
                  chargeItem['mapValue'].containsKey('fields')) {
                
                final chargeFields = chargeItem['mapValue']['fields'] as Map<String, dynamic>;
                final chargeName = _extractFirebaseValue(chargeFields['name'], 'string') ?? '';
                final chargeAmount = _extractFirebaseValue(chargeFields['amount'], 'double') ?? 0.0;
                
                charges.add(Charge(name: chargeName, amount: chargeAmount));
              }
            }
          }
          
          // Create the journey
          final journey = Journey(
            company: company,
            startCity: startCity,
            endCity: endCity,
            payment: payment,
            date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
            userId: username,
            plateNumber: plateNumber,
            cargoType: cargoType,
            cargoWeight: cargoWeight,
            bonDeLivraison: bonDeLivraison,
            charges: charges,
          );
          
          allJourneys.add(journey);
          
          print('✅ Successfully parsed journey: $company');
          print('   Route: $startCity → $endCity');
          print('   Payment: $payment MAD, Date: ${DateFormat('dd/MM/yyyy').format(journey.date)}');
          print('   Charges: ${charges.length} items');
          
        } catch (e) {
          print('❌ Error parsing journey: $e');
          print('❌ Problematic journey data: $journeyData');
        }
      }
    }
    
    print('🎯 Total journeys parsed: ${allJourneys.length}');
    return allJourneys;
    
  } catch (e) {
    print('❌ Error in getJourneys: $e');
    return [];
  }
}

// ADD THIS HELPER METHOD:
static dynamic _extractFirebaseValue(dynamic field, String type) {
  if (field is! Map<String, dynamic>) return null;
  
  switch (type) {
    case 'string':
      if (field.containsKey('stringValue')) {
        return field['stringValue'].toString();
      }
      break;
    case 'int':
      if (field.containsKey('integerValue')) {
        return int.parse(field['integerValue'].toString());
      }
      break;
    case 'double':
      if (field.containsKey('doubleValue')) {
        return double.parse(field['doubleValue'].toString());
      }
      break;
    case 'bool':
      if (field.containsKey('booleanValue')) {
        return field['booleanValue'] == true;
      }
      break;
  }
  return null;
}
  // ========== COMPANIES MANAGEMENT ==========
  
  static Future<List<Company>> getGlobalCompanies() async {
    final companiesData = await getCollection('global_companies');
    
    return companiesData.map((companyData) {
      return Company(
        name: companyData['name'] ?? companyData['id'] ?? '',
        address: companyData['address'],
        ice: companyData['ice'],
        createdAt: _parseTimestamp(companyData['createdAt']) ?? DateTime.now(),
        isActive: companyData['isActive'] ?? true,
      );
    }).toList();
  }

  static Future<bool> addGlobalCompany(String name, {String? address, String? ice}) async {
    try {
      final documentPath = 'global_companies/$name';
      final documentUrl = '$baseUrl/$documentPath?key=$apiKey';
      
      final Map<String, dynamic> fields = {
        'name': {'stringValue': name},
        'isActive': {'booleanValue': true},
        'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      };
      
      if (address != null && address.isNotEmpty) {
        fields['address'] = {'stringValue': address};
      }
      
      if (ice != null && ice.isNotEmpty) {
        fields['ice'] = {'stringValue': ice};
      }
      
      final response = await http.patch(
        Uri.parse(documentUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fields': fields,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error adding company: $e');
      return false;
    }
  }

  static Future<bool> deleteGlobalCompany(String name) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/global_companies/$name?key=$apiKey'),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting company: $e');
      return false;
    }
  }

  // Helper method to parse timestamps
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp is String) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  // ========== STATISTICS ==========
  
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final users = await getUsers();
    final journeys = await getJourneys();
    
    final totalRevenue = journeys.fold(0.0, (sum, journey) => sum + journey.payment);
    
    return {
      'totalUsers': users.length,
      'totalJourneys': journeys.length,
      'totalRevenue': totalRevenue,
      'averageRevenue': journeys.isNotEmpty ? totalRevenue / journeys.length : 0,
    };
  }
}