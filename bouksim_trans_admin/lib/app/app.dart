import 'package:bouksim_trans_admin/pages/reports/reports_page.dart';
import 'package:bouksim_trans_admin/pages/test/firebase_test_page.dart';
import 'package:flutter/material.dart';
import '../pages/login/admin_login_page.dart';
import '../pages/dashboard/admin_dashboard.dart';
import '../pages/users/users_list_page.dart';
import '../pages/companies/global_companies_page.dart';
import '../pages/journeys/all_journeys_page.dart';

class AdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bouksim Trans Admin',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF1e1e2e),
        cardColor: Color(0xFF2d2d44),
        primaryColor: Color(0xFF4361ee),
      ),
      home: AdminLoginPage(),
      routes: {
        '/dashboard': (context) => AdminDashboard(),
        '/users': (context) => UsersListPage(),
        '/companies': (context) => GlobalCompaniesPage(),
        '/journeys': (context) => AllJourneysPage(),
        '/reports': (context) => ReportsPage(),
        '/firebase-test': (context) => FirebaseTestPage(), // Add this
      },
      debugShowCheckedModeBanner: false,
    );
  }
}