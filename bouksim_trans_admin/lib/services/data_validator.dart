class DataValidator {
  static bool validateUser(Map<String, dynamic> userData) {
    return userData.containsKey('username') &&
           userData['username'] is String &&
           userData['username'].isNotEmpty &&
           (userData['email'] == null || userData['email'] is String) &&
           (userData['isActive'] == null || userData['isActive'] is bool);
  }

  static bool validateJourney(Map<String, dynamic> journeyData) {
    return journeyData.containsKey('company') &&
           journeyData['company'] is String &&
           journeyData.containsKey('startCity') &&
           journeyData['startCity'] is String &&
           journeyData.containsKey('endCity') &&
           journeyData['endCity'] is String &&
           journeyData.containsKey('payment') &&
           journeyData['payment'] is num &&
           journeyData['payment'] >= 0;
  }

  static bool validateCompany(Map<String, dynamic> companyData) {
    return companyData.containsKey('name') &&
           companyData['name'] is String &&
           companyData['name'].length >= 2 &&
           companyData['name'].length <= 100 &&
           (companyData['isActive'] == null || companyData['isActive'] is bool);
  }
  
  // Add validation before sending data to Firebase
  static Map<String, dynamic> sanitizeJourney(Map<String, dynamic> journey) {
    return {
      'company': journey['company']?.toString() ?? '',
      'startCity': journey['startCity']?.toString() ?? '',
      'endCity': journey['endCity']?.toString() ?? '',
      'payment': (journey['payment'] ?? 0).toDouble(),
      'date': journey['date'] ?? DateTime.now().millisecondsSinceEpoch,
      'userId': journey['userId']?.toString() ?? '',
      'plateNumber': journey['plateNumber']?.toString() ?? '',
      'cargoType': journey['cargoType']?.toString() ?? '',
      'cargoWeight': (journey['cargoWeight'] ?? 0).toDouble(),
      'bonDeLivraison': journey['bonDeLivraison']?.toString() ?? '',
      'charges': journey['charges'] ?? [],
    };
  }
}