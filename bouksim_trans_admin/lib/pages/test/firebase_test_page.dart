import 'package:flutter/material.dart';
import '../../services/firebase_rest_service.dart';

class FirebaseTestPage extends StatelessWidget {
  const FirebaseTestPage({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> testFirebase() async {
    try {
      final users = await FirebaseRestService.getUsers();
      final journeys = await FirebaseRestService.getJourneys();
      final companies = await FirebaseRestService.getGlobalCompanies();
      
      return {
        'success': true,
        'users_count': users.length,
        'journeys_count': journeys.length,
        'companies_count': companies.length,
        'sample_user': users.isNotEmpty ? users.first.username : 'No users',
        'sample_journey': journeys.isNotEmpty ? '${journeys.first.startCity} → ${journeys.first.endCity}' : 'No journeys',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1e1e2e),
      appBar: AppBar(
        title: Text('Firebase Connection Test'),
        backgroundColor: Color(0xFF2d2d44),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: testFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          final data = snapshot.data!;
          
          if (!data['success']) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 20),
                  Text('Firebase Connection Failed', style: TextStyle(color: Colors.white, fontSize: 20)),
                  SizedBox(height: 10),
                  Text(data['error'], style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                ],
              ),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Firebase Connection Successful!', 
                     style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 30),
                _buildStatCard('Users in Firebase', data['users_count'].toString()),
                _buildStatCard('Journeys in Firebase', data['journeys_count'].toString()),
                _buildStatCard('Companies in Firebase', data['companies_count'].toString()),
                SizedBox(height: 20),
                Text('Sample Data:', style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(height: 10),
                Text('User: ${data['sample_user']}', style: TextStyle(color: Colors.white70)),
                Text('Journey: ${data['sample_journey']}', style: TextStyle(color: Colors.white70)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      color: Color(0xFF2d2d44),
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.white70)),
        trailing: Text(value, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}