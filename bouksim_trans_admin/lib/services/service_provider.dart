import 'package:bouksim_trans_admin/services/mock_data_service.dart';

import 'data_service_interface.dart';
import 'firebase_rest_data_service.dart';

class ServiceProvider {
  static DataService getDataService() {
    // Try Firebase first, fallback to mock data if there are issues
    try {
      return FirebaseRestDataService();
    } catch (e) {
      print('⚠️ Firebase service failed, falling back to mock data: $e');
      return MockDataService();
    }
  }
  
  static bool get isUsingFirebase {
    return true;
  }
}