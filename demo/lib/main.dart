// ignore_for_file: unnecessary_import, avoid_print, use_build_context_synchronously, deprecated_member_use, unused_local_variable, unused_import

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:animations/animations.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== SOFTER DESIGN CONSTANTS ====================
const Color primaryBlue = Color(0xFF4361ee);
const Color secondaryPurple = Color(0xFF7209b7);
const Color accentGreen = Color(0xFF4cc9f0);
const Color darkSurface = Color(0xFF1e1e2e);
const Color cardBackground = Color(0xFF2d2d44);
const Color textWhite = Color(0xFFf8f9fa);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add detailed logging
  print('🎯 ===== APP STARTING =====');
  print('📱 STEP 1: Widgets binding initialized');

  try {
    print('🔥 STEP 2: Attempting Firebase initialization...');

    // Initialize Firebase with error handling
    await Firebase.initializeApp();
    print('✅ STEP 2: Firebase.initializeApp() completed');

    // Test Firestore
    final firestore = FirebaseFirestore.instance;
    print('📡 STEP 3: Firestore instance created');

    // Try a simple operation
    try {
      print('🧪 STEP 4: Testing Firestore connection...');
      await firestore.collection('test_connection').doc('ping').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Connection test from Flutter app'
      });
      print('✅ STEP 4: Firestore write successful!');
    } catch (e) {
      print('❌ STEP 4: Firestore write failed: $e');
    }
  } catch (e) {
    print('💥 FIREBASE INITIALIZATION ERROR: $e');
    print('📋 Error type: ${e.runtimeType}');
  }

  // Continue with Hive
  print('🗃️ STEP 5: Initializing Hive...');
  await Hive.initFlutter();

  Hive.registerAdapter(ChargeAdapter());
  Hive.registerAdapter(JourneyAdapter());
  Hive.registerAdapter(CompanyAdapter());

  await Hive.openBox('usersBox');
  await Hive.openBox('journeysBox');
  await Hive.openBox('companiesBox');

  print('🎉 STEP 6: All services initialized - Starting app UI');
  print('🎯 ===== APP READY =====');

  runApp(TruckJourneysApp());
}

// ==================== MANUAL HIVE ADAPTERS ====================
class ChargeAdapter extends TypeAdapter<Charge> {
  @override
  final int typeId = 0;

  @override
  Charge read(BinaryReader reader) {
    final name = reader.readString();
    final amount = reader.readDouble();
    return Charge(name: name, amount: amount);
  }

  @override
  void write(BinaryWriter writer, Charge obj) {
    writer.writeString(obj.name);
    writer.writeDouble(obj.amount);
  }
}

class JourneyAdapter extends TypeAdapter<Journey> {
  @override
  final int typeId = 1;

  @override
  Journey read(BinaryReader reader) {
    return Journey(
      company: reader.readString(),
      startCity: reader.readString(),
      endCity: reader.readString(),
      charges: List<Charge>.from(reader.readList().map((x) => x as Charge)),
      payment: reader.readDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      userId: reader.readString(),
      plateNumber: reader.readString(),
      cargoType: reader.readString(),
      cargoWeight: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Journey obj) {
    writer.writeString(obj.company);
    writer.writeString(obj.startCity);
    writer.writeString(obj.endCity);
    writer.writeList(obj.charges);
    writer.writeDouble(obj.payment);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeString(obj.userId);
    writer.writeString(obj.plateNumber);
    writer.writeString(obj.cargoType);
    writer.writeDouble(obj.cargoWeight);
  }
}

class CompanyAdapter extends TypeAdapter<Company> {
  @override
  final int typeId = 2;

  @override
  Company read(BinaryReader reader) {
    return Company(
      name: reader.readString(),
      address: reader.readString(),
      ice: reader.readString(),
      lastUsed: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Company obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.address ?? '');
    writer.writeString(obj.ice ?? '');
    writer.writeInt(obj.lastUsed.millisecondsSinceEpoch);
  }
}

// ==================== DATA MODELS ====================
class Charge {
  final String name;
  final double amount;

  Charge({required this.name, required this.amount});
}

class Journey {
  final String company;
  final String startCity;
  final String endCity;
  final List<Charge> charges;
  final double payment;
  final DateTime date;
  final String userId;
  final String plateNumber;
  final String cargoType;
  final double cargoWeight;

  Journey({
    required this.company,
    required this.startCity,
    required this.endCity,
    required this.charges,
    required this.payment,
    required this.date,
    required this.userId,
    required this.plateNumber,
    required this.cargoType,
    required this.cargoWeight,
  });
}

class Company {
  final String name;
  final String? address;
  final String? ice;
  final DateTime lastUsed;

  Company({
    required this.name,
    this.address,
    this.ice,
    required this.lastUsed,
  });
}

// ==================== EXPORT SERVICE ====================
class ExportService {
  // Export to JSON (for PC admin app)
  static Future<String> exportToJson(
      List<Journey> journeys, String username) async {
    try {
      final exportData = {
        'user': username,
        'exportDate': DateTime.now().toIso8601String(),
        'journeys': journeys
            .map((j) => {
                  'company': j.company,
                  'startCity': j.startCity,
                  'endCity': j.endCity,
                  'payment': j.payment,
                  'date': j.date.toIso8601String(),
                  'plateNumber': j.plateNumber,
                  'cargoType': j.cargoType,
                  'cargoWeight': j.cargoWeight,
                  'charges': j.charges
                      .map((c) => {
                            'name': c.name,
                            'amount': c.amount,
                          })
                      .toList(),
                })
            .toList(),
      };

      String jsonString = jsonEncode(exportData);
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/${username}_export_${DateTime.now().millisecondsSinceEpoch}.json');

      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  // Export to CSV (for Excel)
  static Future<String> exportToCsv(List<Journey> journeys) async {
    try {
      List<List<dynamic>> csvData = [];

      // Header row
      csvData.add([
        'Company',
        'Start City',
        'End City',
        'Payment (MAD)',
        'Date',
        'Plate Number',
        'Cargo Type',
        'Cargo Weight',
        'Total Charges'
      ]);

      // Data rows
      for (var journey in journeys) {
        double totalCharges =
            journey.charges.fold(0.0, (sum, charge) => sum + charge.amount);

        csvData.add([
          journey.company,
          journey.startCity,
          journey.endCity,
          journey.payment,
          journey.date.toString().split(' ')[0],
          journey.plateNumber,
          journey.cargoType,
          journey.cargoWeight,
          totalCharges,
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/journeys_export_${DateTime.now().millisecondsSinceEpoch}.csv');

      await file.writeAsString(csv);
      return file.path;
    } catch (e) {
      throw Exception('CSV export failed: $e');
    }
  }

  // Share file
  static Future<void> shareFile(String filePath, String subject) async {
    try {
      await Share.shareXFiles([XFile(filePath)], subject: subject);
    } catch (e) {
      throw Exception('Share failed: $e');
    }
  }
}

// ==================== MAIN APP ====================
class TruckJourneysApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truck Journeys',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: primaryBlue,
          secondary: secondaryPurple,
          surface: darkSurface,
          background: darkSurface,
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: darkSurface,
        appBarTheme: AppBarTheme(
          backgroundColor: cardBackground,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textWhite,
          ),
          iconTheme: IconThemeData(color: textWhite),
        ),
        useMaterial3: true,
      ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== LOGIN PAGE ====================
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _hidePassword = true;
  String _error = '';

  final List<Map<String, String>> _users = [
    {'username': 'abderrahim bouksim', 'password': 'bouksim90@gmail.com'},
    {'username': 'abdessamad bouksim', 'password': 'abde446@bkm.com'},
    {'username': 'mohamed', 'password': '1976ma312'},
  ];

  void _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    bool valid = _users.any(
      (user) =>
          user['username']!.toLowerCase() == username.toLowerCase() &&
          user['password'] == password,
    );

    if (valid) {
      final usersBox = Hive.box('usersBox');
      await usersBox.put('currentUser', username);

      // 🔥 ADD THIS: Try to load cloud data first
      try {
        final cloudData = await FirebaseSyncService.loadFromCloud(username);
        if (cloudData != null) {
          print('📱 Loading data from cloud...');
          await _loadCloudDataToHive(username, cloudData);
        } else {
          print('📱 No cloud data found, initializing local data');
          await _initializeUserData(username);
        }
      } catch (e) {
        print('⚠️ Cloud load failed, using local data: $e');
        await _initializeUserData(username);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(currentUser: username),
        ),
      );
    } else {
      setState(() {
        _error =
            'Nom d\'utilisateur ou mot de passe incorrect / اسم المستخدم أو كلمة المرور غير صحيحة';
      });
    }
  }

// 🔥 ADD THIS METHOD: Load cloud data to Hive
  Future<void> _loadCloudDataToHive(
      String username, Map<String, dynamic> cloudData) async {
    final journeysBox = Hive.box('journeysBox');
    final companiesBox = Hive.box('companiesBox');

    try {
      // Load journeys from cloud
      if (cloudData['journeys'] != null) {
        final journeys = List<Map<String, dynamic>>.from(cloudData['journeys']);
        final journeyObjects = journeys.map((j) {
          return Journey(
            company: j['company'] ?? '',
            startCity: j['startCity'] ?? '',
            endCity: j['endCity'] ?? '',
            payment: (j['payment'] ?? 0).toDouble(),
            date: DateTime.fromMillisecondsSinceEpoch(j['date'] ?? 0),
            plateNumber: j['plateNumber'] ?? '',
            cargoType: j['cargoType'] ?? '',
            cargoWeight: (j['cargoWeight'] ?? 0).toDouble(),
            charges: List<Charge>.from((j['charges'] ?? []).map((c) => Charge(
                name: c['name'] ?? '', amount: (c['amount'] ?? 0).toDouble()))),
            userId: j['userId'] ?? username,
          );
        }).toList();

        await journeysBox.put('${username}_journeys', journeyObjects);
        print('✅ Loaded ${journeyObjects.length} journeys from cloud');
      }

      // Load companies from cloud
      if (cloudData['companies'] != null) {
        final companies = List<String>.from(cloudData['companies'] ?? []);
        await companiesBox.put('${username}_companies', companies);
        print('✅ Loaded ${companies.length} companies from cloud');
      }
    } catch (e) {
      print('❌ Error loading cloud data to Hive: $e');
      // Fallback to default initialization
      await _initializeUserData(username);
    }
  }

  Future<void> _initializeUserData(String username) async {
    final companiesBox = Hive.box('companiesBox');
    final userCompaniesKey = '${username}_companies';

    if (!companiesBox.containsKey(userCompaniesKey)) {
      final defaultCompanies = [
        'STE CAP',
        'STE JOUALI TRANS',
        'STE ATNER',
        'STE BELHASSAN',
      ];
      await companiesBox.put(userCompaniesKey, defaultCompanies);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [darkSurface, cardBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset('assets/truck.json', width: 300, height: 200),
                const SizedBox(height: 30),
                _buildSoftContainer(
                  height: 420,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Truck Journeys',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _usernameController,
                          style: TextStyle(color: textWhite),
                          decoration: InputDecoration(
                            labelText: 'Nom d\'utilisateur / اسم المستخدم',
                            labelStyle:
                                TextStyle(color: textWhite.withOpacity(0.7)),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryBlue),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryBlue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          style: TextStyle(color: textWhite),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe / كلمة المرور',
                            labelStyle:
                                TextStyle(color: textWhite.withOpacity(0.7)),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryBlue),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryBlue),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: primaryBlue,
                              ),
                              onPressed: () {
                                setState(() {
                                  _hidePassword = !_hidePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        if (_error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              _error,
                              style: TextStyle(color: Colors.orange),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryBlue, secondaryPurple],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Se connecter / تسجيل الدخول',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoftContainer({required double height, required Widget child}) {
    return Container(
      width: 350,
      height: height,
      decoration: BoxDecoration(
        color: cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ==================== FIREBASE SYNC SERVICE ====================
class FirebaseSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sync user data to Firebase
  static Future<bool> syncToCloud(
      String username, List<Journey> journeys, List<String> companies) async {
    try {
      print('☁️ Syncing data to cloud for user: $username');

      final userDocRef = _firestore.collection('users').doc(username);

      // Prepare journeys data for Firestore (FIXED: No FieldValue inside arrays)
      final journeysData = journeys.map((journey) {
        return {
          'company': journey.company,
          'startCity': journey.startCity,
          'endCity': journey.endCity,
          'payment': journey.payment,
          'date': journey.date.millisecondsSinceEpoch,
          'plateNumber': journey.plateNumber,
          'cargoType': journey.cargoType,
          'cargoWeight': journey.cargoWeight,
          'charges': journey.charges
              .map((charge) => {
                    'name': charge.name,
                    'amount': charge.amount,
                  })
              .toList(),
          'userId': journey.userId,
          // REMOVED: 'lastUpdated': FieldValue.serverTimestamp(), // This was causing the error
        };
      }).toList();

      // Prepare companies data
      final companiesData = companies.map((company) => company).toList();

      // Update user document in Firestore (FIXED: FieldValue only at document level)
      await userDocRef.set({
        'username': username,
        'journeys': journeysData,
        'companies': companiesData,
        'lastSync':
            FieldValue.serverTimestamp(), // ✅ This is OK - at document level
        'totalJourneys': journeys.length,
        'totalCompanies': companies.length,
      }, SetOptions(merge: true));

      print(
          '✅ Cloud sync successful! ${journeys.length} journeys, ${companies.length} companies');
      return true;
    } catch (e) {
      print('❌ Cloud sync failed: $e');
      return false;
    }
  }

  // Load user data from Firebase
  static Future<Map<String, dynamic>?> loadFromCloud(String username) async {
    try {
      print('📥 Loading data from cloud for user: $username');

      final userDoc = await _firestore.collection('users').doc(username).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        print('✅ Cloud data loaded successfully');
        return data;
      } else {
        print('ℹ️ No cloud data found for user: $username');
        return null;
      }
    } catch (e) {
      print('❌ Cloud load failed: $e');
      return null;
    }
  }

  // Check if user has cloud data
  static Future<bool> hasCloudData(String username) async {
    try {
      final userDoc = await _firestore.collection('users').doc(username).get();
      return userDoc.exists;
    } catch (e) {
      print('❌ Cloud check failed: $e');
      return false;
    }
  }
}

// ==================== HOME PAGE ====================
class HomePage extends StatefulWidget {
  final String currentUser;
  HomePage({required this.currentUser});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _language = 'fr';

  List<Journey> get _journeys {
    final journeysBox = Hive.box('journeysBox');
    final journeyData =
        journeysBox.get('${widget.currentUser}_journeys', defaultValue: []);

    if (journeyData is List) {
      return journeyData.whereType<Journey>().toList();
    }
    return [];
  }

  List<String> get _companies {
    final companiesBox = Hive.box('companiesBox');
    final userCompaniesKey = '${widget.currentUser}_companies';
    return List<String>.from(
        companiesBox.get(userCompaniesKey, defaultValue: []));
  }

  void _addJourney(Journey journey) async {
    final journeysBox = Hive.box('journeysBox');
    final userJourneysKey = '${widget.currentUser}_journeys';
    final currentJourneys = List<Journey>.from(_journeys);
    currentJourneys.add(journey);

    // Save to local storage (Hive)
    await journeysBox.put(userJourneysKey, currentJourneys);

    // 🔥 ADD THIS: Auto-sync to Firebase cloud
    try {
      await FirebaseSyncService.syncToCloud(
          widget.currentUser, currentJourneys, _companies);
      print('✅ Journey added and synced to cloud');
    } catch (e) {
      print('⚠️ Cloud sync failed: $e');
    }

    setState(() {});
  }

  void _updateJourney(Journey oldJourney, Journey newJourney) async {
    final journeysBox = Hive.box('journeysBox');
    final currentJourneys = List<Journey>.from(_journeys);
    final index = currentJourneys.indexWhere((j) =>
        j.company == oldJourney.company &&
        j.date == oldJourney.date &&
        j.payment == oldJourney.payment);

    if (index != -1) {
      currentJourneys[index] = newJourney;
      await journeysBox.put('${widget.currentUser}_journeys', currentJourneys);
      setState(() {});
    }
  }

  void _deleteJourney(Journey journey) async {
    final journeysBox = Hive.box('journeysBox');
    final currentJourneys = List<Journey>.from(_journeys);
    currentJourneys.removeWhere((j) =>
        j.company == journey.company &&
        j.date == journey.date &&
        j.payment == journey.payment);
    await journeysBox.put('${widget.currentUser}_journeys', currentJourneys);
    setState(() {});
  }

  void _addCompany(String name) async {
    final companiesBox = Hive.box('companiesBox');
    final userCompaniesKey = '${widget.currentUser}_companies';
    final currentCompanies =
        List<String>.from(companiesBox.get(userCompaniesKey, defaultValue: []));
    currentCompanies.add(name);

    // Save to local storage
    await companiesBox.put(userCompaniesKey, currentCompanies);

    // 🔥 ADD THIS: Auto-sync to Firebase cloud
    try {
      await FirebaseSyncService.syncToCloud(
          widget.currentUser, _journeys, currentCompanies);
      print('✅ Company added and synced to cloud');
    } catch (e) {
      print('⚠️ Cloud sync failed: $e');
    }

    setState(() {});
  }

  void _removeCompany(String name) async {
    final companiesBox = Hive.box('companiesBox');
    final journeysBox = Hive.box('journeysBox');
    final userCompaniesKey = '${widget.currentUser}_companies';
    final userJourneysKey = '${widget.currentUser}_journeys';

    // Remove from companies
    final currentCompanies =
        List<String>.from(companiesBox.get(userCompaniesKey, defaultValue: []));
    currentCompanies.remove(name);
    await companiesBox.put(userCompaniesKey, currentCompanies);

    // Remove related journeys
    final currentJourneys = List<Journey>.from(_journeys);
    currentJourneys.removeWhere((journey) => journey.company == name);
    await journeysBox.put(userJourneysKey, currentJourneys);

    // 🔥 ADD THIS: Auto-sync to Firebase cloud
    try {
      await FirebaseSyncService.syncToCloud(
          widget.currentUser, currentJourneys, currentCompanies);
      print('✅ Company removed and synced to cloud');
    } catch (e) {
      print('⚠️ Cloud sync failed: $e');
    }

    setState(() {});
  }

  String t(String fr, String ar) => _language == 'fr' ? fr : ar;

  void _signOut() async {
    final usersBox = Hive.box('usersBox');
    await usersBox.delete('currentUser');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 12),
            Text(
              t('Déconnexion', 'تسجيل الخروج'),
              style: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          t('Voulez-vous vous déconnecter de votre compte?',
              'هل تريد تسجيل الخروج من حسابك؟'),
          style: TextStyle(color: textWhite.withOpacity(0.8)),
        ),
        actions: [
          // Cancel Button
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: BorderSide(color: primaryBlue),
            ),
            child: Text(t('Annuler', 'إلغاء')),
          ),
          // Logout Button
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              t('Déconnexion', 'تسجيل الخروج'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AddJourneyPage(
        companies: _companies,
        onAdd: _addJourney,
        currentUser: widget.currentUser,
        language: _language,
      ),
      JourneysPage(
        journeys: _journeys,
        language: _language,
        onUpdate: _updateJourney,
        onDelete: _deleteJourney,
      ),
      StatsPage(
        journeys: _journeys,
        language: _language,
      ),
      CompaniesPage(
        companies: _companies,
        onAdd: _addCompany,
        onRemove: _removeCompany,
        language: _language,
        journeys: _journeys,
      ),
      // NEW EXPORT PAGE
      ExportDataPage(
        journeys: _journeys,
        currentUser: widget.currentUser,
        language: _language,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${t('Bienvenue', 'مرحبا')}, ${widget.currentUser}",
          style: TextStyle(
            color: textWhite,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: cardBackground,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.language, color: primaryBlue),
            onPressed: () {
              setState(() {
                _language = _language == 'fr' ? 'ar' : 'fr';
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: primaryBlue),
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [darkSurface, cardBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation, secondaryAnimation) =>
              FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          ),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textWhite.withOpacity(0.6),
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: t('Ajouter', 'إضافة'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: t('Historique', 'السجل'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: t('Stats', 'إحصائيات'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: t('Sociétés', 'الشركات'),
          ),
          // NEW EXPORT TAB
          BottomNavigationBarItem(
            icon: Icon(Icons.upload),
            label: t('Exporter', 'تصدير'),
          ),
        ],
      ),
    );
  }
}

// ==================== ADD/EDIT JOURNEY PAGE ====================
class AddJourneyPage extends StatefulWidget {
  final List<String> companies;
  final Function(Journey) onAdd;
  final String currentUser;
  final String language;
  final String? preFilledCompany;
  final Journey? journeyToEdit;

  AddJourneyPage({
    required this.companies,
    required this.onAdd,
    required this.currentUser,
    required this.language,
    this.preFilledCompany,
    this.journeyToEdit,
  });

  @override
  _AddJourneyPageState createState() => _AddJourneyPageState();
}

class _AddJourneyPageState extends State<AddJourneyPage> {
  final _formKey = GlobalKey<FormState>();
  String? _company;
  String _startCity = '';
  String _endCity = '';
  String _plateNumber = '';
  String _cargoType = '';
  double _cargoWeight = 0;
  double _payment = 0;
  DateTime _date = DateTime.now();
  List<Map<String, String>> _chargesInputs = [
    {"name": "", "amount": ""},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.journeyToEdit != null) {
      // Editing existing journey
      _company = widget.journeyToEdit!.company;
      _startCity = widget.journeyToEdit!.startCity;
      _endCity = widget.journeyToEdit!.endCity;
      _plateNumber = widget.journeyToEdit!.plateNumber;
      _cargoType = widget.journeyToEdit!.cargoType;
      _cargoWeight = widget.journeyToEdit!.cargoWeight;
      _payment = widget.journeyToEdit!.payment;
      _date = widget.journeyToEdit!.date;
      _chargesInputs = widget.journeyToEdit!.charges
          .map((charge) =>
              {"name": charge.name, "amount": charge.amount.toString()})
          .toList();
    } else {
      // Adding new journey
      _company = widget.preFilledCompany;
    }
  }

  String t(String fr, String ar) => widget.language == 'fr' ? fr : ar;

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryBlue,
              onPrimary: Colors.white,
              surface: cardBackground,
            ),
            dialogBackgroundColor: darkSurface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  Widget _buildSoftContainer({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSoftContainer(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.journeyToEdit != null
                            ? t('Modifier la Course', 'تعديل الرحلة')
                            : t('Nouvelle Course', 'رحلة جديدة'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Company
                      DropdownButtonFormField<String>(
                        value: _company,
                        dropdownColor: cardBackground,
                        style: TextStyle(color: textWhite),
                        decoration: InputDecoration(
                          labelText: t('Entreprise', 'الشركة'),
                          labelStyle:
                              TextStyle(color: textWhite.withOpacity(0.7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: primaryBlue),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: primaryBlue.withOpacity(0.5)),
                          ),
                        ),
                        items: widget.companies
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c,
                                      style: TextStyle(color: textWhite)),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _company = val),
                        validator: (val) => val == null
                            ? t('Choisissez une entreprise', 'اختر شركة')
                            : null,
                      ),
                      SizedBox(height: 16),

                      // Cities
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller:
                                  TextEditingController(text: _startCity),
                              style: TextStyle(color: textWhite),
                              decoration: InputDecoration(
                                labelText:
                                    t('Ville de départ', 'مدينة الانطلاق'),
                                labelStyle: TextStyle(
                                    color: textWhite.withOpacity(0.7)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: primaryBlue.withOpacity(0.5)),
                                ),
                              ),
                              onSaved: (val) => _startCity = val ?? '',
                              validator: (val) => val == null || val.isEmpty
                                  ? t('Entrez une ville', 'أدخل مدينة')
                                  : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: TextEditingController(text: _endCity),
                              style: TextStyle(color: textWhite),
                              decoration: InputDecoration(
                                labelText:
                                    t('Ville d\'arrivée', 'مدينة الوجهة'),
                                labelStyle: TextStyle(
                                    color: textWhite.withOpacity(0.7)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: primaryBlue.withOpacity(0.5)),
                                ),
                              ),
                              onSaved: (val) => _endCity = val ?? '',
                              validator: (val) => val == null || val.isEmpty
                                  ? t('Entrez une ville', 'أدخل مدينة')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Vehicle and Cargo Info
                      Text(
                        t('Informations Véhicule et Marchandise',
                            'معلومات الشحنة والمركبة'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Plate Number
                      TextFormField(
                        controller: TextEditingController(text: _plateNumber),
                        style: TextStyle(color: textWhite),
                        decoration: InputDecoration(
                          labelText:
                              t('Plaque d\'immatriculation', 'لوحة التسجيل'),
                          labelStyle:
                              TextStyle(color: textWhite.withOpacity(0.7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: primaryBlue.withOpacity(0.5)),
                          ),
                        ),
                        onSaved: (val) => _plateNumber = val ?? '',
                      ),
                      SizedBox(height: 12),

                      // Cargo Type and Weight
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller:
                                  TextEditingController(text: _cargoType),
                              style: TextStyle(color: textWhite),
                              decoration: InputDecoration(
                                labelText:
                                    t('Type de marchandise', 'نوع البضاعة'),
                                labelStyle: TextStyle(
                                    color: textWhite.withOpacity(0.7)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: primaryBlue.withOpacity(0.5)),
                                ),
                              ),
                              onSaved: (val) => _cargoType = val ?? '',
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: TextEditingController(
                                  text: _cargoWeight.toString()),
                              style: TextStyle(color: textWhite),
                              decoration: InputDecoration(
                                labelText: t('Poids (kg)', 'الوزن (كلغ)'),
                                labelStyle: TextStyle(
                                    color: textWhite.withOpacity(0.7)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: primaryBlue.withOpacity(0.5)),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (val) => _cargoWeight =
                                  double.tryParse(val ?? "0") ?? 0,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Date
                      _buildSoftContainer(
                        height: 60,
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t('Date de la course', 'تاريخ الرحلة'),
                                      style: TextStyle(
                                        color: textWhite.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(_date),
                                      style: TextStyle(
                                        color: textWhite,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: primaryBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.calendar_today,
                                    color: Colors.white, size: 20),
                                onPressed: () => _selectDate(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Charges Section
                      Text(
                        t("Charges et Dépenses", "المصاريف والنفقات"),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Make charges section scrollable
                      Container(
                        height: 200,
                        child: ListView(
                          children: _chargesInputs.asMap().entries.map((entry) {
                            int index = entry.key;
                            return _buildSoftContainer(
                              height: 80,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: TextEditingController(
                                            text: _chargesInputs[index]
                                                ["name"]),
                                        style: TextStyle(color: textWhite),
                                        decoration: InputDecoration(
                                          labelText: t(
                                              'Type de charge', 'نوع المصروف'),
                                          labelStyle: TextStyle(
                                              color:
                                                  textWhite.withOpacity(0.7)),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8),
                                        ),
                                        onSaved: (val) => _chargesInputs[index]
                                            ["name"] = val ?? "",
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        controller: TextEditingController(
                                            text: _chargesInputs[index]
                                                ["amount"]),
                                        style: TextStyle(color: textWhite),
                                        decoration: InputDecoration(
                                          labelText: t(
                                              'Montant (MAD)', 'المبلغ (درهم)'),
                                          labelStyle: TextStyle(
                                              color:
                                                  textWhite.withOpacity(0.7)),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onSaved: (val) => _chargesInputs[index]
                                            ["amount"] = val ?? "0",
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.remove_circle,
                                          color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _chargesInputs.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Add Charge Button
                      _buildSoftContainer(
                        height: 50,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _chargesInputs.add({"name": "", "amount": ""});
                            });
                          },
                          icon: Icon(Icons.add_circle, color: accentGreen),
                          label: Text(
                            t('Ajouter une charge', 'إضافة مصروف'),
                            style: TextStyle(color: accentGreen),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Payment
                      TextFormField(
                        controller:
                            TextEditingController(text: _payment.toString()),
                        style: TextStyle(color: textWhite),
                        decoration: InputDecoration(
                          labelText:
                              t('Paiement reçu (MAD)', 'المبلغ المستلم (درهم)'),
                          labelStyle:
                              TextStyle(color: textWhite.withOpacity(0.7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: primaryBlue.withOpacity(0.5)),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (val) =>
                            _payment = double.tryParse(val ?? "0") ?? 0,
                      ),
                      SizedBox(height: 24),

                      // Submit Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryBlue, secondaryPurple],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              List<Charge> charges = _chargesInputs
                                  .where((c) => c["name"]!.isNotEmpty)
                                  .map(
                                    (c) => Charge(
                                      name: c["name"]!,
                                      amount:
                                          double.tryParse(c["amount"]!) ?? 0,
                                    ),
                                  )
                                  .toList();

                              final journey = Journey(
                                company: _company!,
                                startCity: _startCity,
                                endCity: _endCity,
                                charges: charges,
                                payment: _payment,
                                date: _date,
                                userId: widget.currentUser,
                                plateNumber: _plateNumber,
                                cargoType: _cargoType,
                                cargoWeight: _cargoWeight,
                              );

                              widget.onAdd(journey);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    widget.journeyToEdit != null
                                        ? t("Course modifiée avec succès!",
                                            "تم تعديل الرحلة بنجاح!")
                                        : t("Course ajoutée avec succès!",
                                            "تم إضافة الرحلة بنجاح!"),
                                  ),
                                  backgroundColor: accentGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              if (widget.journeyToEdit == null) {
                                _formKey.currentState!.reset();
                                setState(() {
                                  _company = widget.preFilledCompany;
                                  _plateNumber = '';
                                  _cargoType = '';
                                  _cargoWeight = 0;
                                  _chargesInputs = [
                                    {"name": "", "amount": ""},
                                  ];
                                  _date = DateTime.now();
                                });
                              } else {
                                Navigator.pop(context);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            widget.journeyToEdit != null
                                ? t('Modifier la Course', 'تعديل الرحلة')
                                : t('Enregistrer la Course', 'حفظ الرحلة'),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== JOURNEYS PAGE ====================
class JourneysPage extends StatefulWidget {
  final List<Journey> journeys;
  final String language;
  final Function(Journey, Journey) onUpdate;
  final Function(Journey) onDelete;

  JourneysPage({
    required this.journeys,
    required this.language,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  _JourneysPageState createState() => _JourneysPageState();
}

class _JourneysPageState extends State<JourneysPage> {
  int expandedIndex = -1;
  String _sortBy = 'date';
  String _filterCompany = 'all';
  String _dateFilter = 'all';
  String _searchQuery = '';
  bool _showGrid = false;
  bool _showFilters = false;

  String t(String fr, String ar) => widget.language == 'fr' ? fr : ar;

  List<Journey> get _filteredJourneys {
    List<Journey> filtered = List.from(widget.journeys);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((journey) =>
              journey.startCity
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              journey.endCity
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              journey.company
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              journey.plateNumber
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              journey.cargoType
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply company filter
    if (_filterCompany != 'all') {
      filtered = filtered
          .where((journey) => journey.company == _filterCompany)
          .toList();
    }

    // Apply date filter
    final now = DateTime.now();
    if (_dateFilter == 'today') {
      filtered = filtered
          .where((journey) =>
              journey.date.year == now.year &&
              journey.date.month == now.month &&
              journey.date.day == now.day)
          .toList();
    } else if (_dateFilter == 'week') {
      final weekAgo = now.subtract(Duration(days: 7));
      filtered =
          filtered.where((journey) => journey.date.isAfter(weekAgo)).toList();
    } else if (_dateFilter == 'month') {
      final monthAgo = now.subtract(Duration(days: 30));
      filtered =
          filtered.where((journey) => journey.date.isAfter(monthAgo)).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'date':
          return b.date.compareTo(a.date);
        case 'profit':
          final profitA =
              a.payment - a.charges.fold(0.0, (sum, c) => sum + c.amount);
          final profitB =
              b.payment - b.charges.fold(0.0, (sum, c) => sum + c.amount);
          return profitB.compareTo(profitA);
        case 'payment':
          return b.payment.compareTo(a.payment);
        case 'company':
          return a.company.compareTo(b.company);
        default:
          return b.date.compareTo(a.date);
      }
    });

    return filtered;
  }

  double get _totalProfit {
    return _filteredJourneys.fold(0.0, (sum, journey) {
      final charges =
          journey.charges.fold(0.0, (cSum, charge) => cSum + charge.amount);
      return sum + (journey.payment - charges);
    });
  }

  Widget _buildProfitBadge(double profit) {
    Color color;
    String label;
    IconData icon;

    if (profit > 1000) {
      color = Color(0xFF00b894);
      label = 'Excellent';
      icon = Icons.trending_up;
    } else if (profit > 500) {
      color = Color(0xFF00cec9);
      label = 'Bon';
      icon = Icons.trending_flat;
    } else if (profit > 0) {
      color = Color(0xFFfdcb6e);
      label = 'Faible';
      icon = Icons.trending_down;
    } else if (profit == 0) {
      color = Color(0xFF74b9ff);
      label = 'Équilibré';
      icon = Icons.remove;
    } else {
      color = Color(0xFFe17055);
      label = 'Perte';
      icon = Icons.warning;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            '${profit.toStringAsFixed(0)} MAD',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final journeysCount = _filteredJourneys.length;
    final avgProfit = journeysCount > 0 ? _totalProfit / journeysCount : 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            t('Voyages', 'الرحلات'),
            journeysCount.toString(),
            Icons.directions_car,
            primaryBlue,
          ),
          _buildSummaryItem(
            t('Profit', 'الربح'),
            '${_totalProfit.toStringAsFixed(0)} MAD',
            Icons.attach_money,
            accentGreen,
          ),
          _buildSummaryItem(
            t('Moyenne', 'المعدل'),
            '${avgProfit.toStringAsFixed(0)} MAD',
            Icons.trending_up,
            secondaryPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: textWhite.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Sort Chip
          InputChip(
            label: Text(
              _getSortLabel(),
              style: TextStyle(fontSize: 12),
            ),
            selected: false,
            onPressed: () => _showSortDialog(),
            backgroundColor: cardBackground,
            labelStyle: TextStyle(color: textWhite),
          ),

          // Date Filter Chip
          if (_dateFilter != 'all')
            InputChip(
              label: Text(
                _getDateFilterLabel(),
                style: TextStyle(fontSize: 12),
              ),
              selected: false,
              onPressed: () => _showDateFilterDialog(),
              backgroundColor: primaryBlue.withOpacity(0.2),
              labelStyle: TextStyle(color: primaryBlue),
              deleteIcon: Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _dateFilter = 'all'),
            ),

          // Company Filter Chip
          if (_filterCompany != 'all')
            InputChip(
              label: Text(
                _filterCompany,
                style: TextStyle(fontSize: 12),
              ),
              selected: false,
              onPressed: () => _showCompanyFilterDialog(),
              backgroundColor: secondaryPurple.withOpacity(0.2),
              labelStyle: TextStyle(color: secondaryPurple),
              deleteIcon: Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _filterCompany = 'all'),
            ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'date':
        return t('Trier: Date', 'ترتيب: التاريخ');
      case 'profit':
        return t('Trier: Profit', 'ترتيب: الربح');
      case 'payment':
        return t('Trier: Paiement', 'ترتيب: المبلغ');
      case 'company':
        return t('Trier: Entreprise', 'ترتيب: الشركة');
      default:
        return t('Trier', 'ترتيب');
    }
  }

  String _getDateFilterLabel() {
    switch (_dateFilter) {
      case 'today':
        return t('Aujourd\'hui', 'اليوم');
      case 'week':
        return t('Cette semaine', 'هذا الأسبوع');
      case 'month':
        return t('Ce mois', 'هذا الشهر');
      default:
        return '';
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        title: Text(t('Trier par', 'ترتيب حسب'),
            style: TextStyle(color: textWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption(
                'date', t('Date', 'التاريخ'), Icons.calendar_today),
            _buildSortOption(
                'profit', t('Profit', 'الربح'), Icons.attach_money),
            _buildSortOption('payment', t('Paiement', 'المبلغ'), Icons.payment),
            _buildSortOption(
                'company', t('Entreprise', 'الشركة'), Icons.business),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: primaryBlue),
      title: Text(label, style: TextStyle(color: textWhite)),
      trailing: _sortBy == value ? Icon(Icons.check, color: accentGreen) : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }

  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        title: Text(t('Filtrer par date', 'تصفية حسب التاريخ'),
            style: TextStyle(color: textWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateFilterOption('all', t('Toutes dates', 'كل التواريخ')),
            _buildDateFilterOption('today', t('Aujourd\'hui', 'اليوم')),
            _buildDateFilterOption('week', t('Cette semaine', 'هذا الأسبوع')),
            _buildDateFilterOption('month', t('Ce mois', 'هذا الشهر')),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterOption(String value, String label) {
    return ListTile(
      title: Text(label, style: TextStyle(color: textWhite)),
      trailing:
          _dateFilter == value ? Icon(Icons.check, color: accentGreen) : null,
      onTap: () {
        setState(() => _dateFilter = value);
        Navigator.pop(context);
      },
    );
  }

  void _showCompanyFilterDialog() {
    final companies = widget.journeys.map((j) => j.company).toSet().toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        title: Text(t('Filtrer par entreprise', 'تصفية حسب الشركة'),
            style: TextStyle(color: textWhite)),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildCompanyFilterOption(
                  'all', t('Toutes les entreprises', 'كل الشركات')),
              ...companies.map(
                  (company) => _buildCompanyFilterOption(company, company)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyFilterOption(String value, String label) {
    return ListTile(
      title: Text(label, style: TextStyle(color: textWhite)),
      trailing: _filterCompany == value
          ? Icon(Icons.check, color: accentGreen)
          : null,
      onTap: () {
        setState(() => _filterCompany = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(color: textWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: t('Rechercher...', 'بحث...'),
                hintStyle: TextStyle(color: textWhite.withOpacity(0.5)),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: primaryBlue),
              ),
            ),
          ),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: primaryBlue),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: Icon(_showGrid ? Icons.list : Icons.grid_view,
                color: primaryBlue),
            onPressed: () => setState(() => _showGrid = !_showGrid),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard({required Widget child, double? height}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Icon(Icons.delete, color: Colors.red, size: 24),
        ),
      ),
    );
  }

  Widget _buildEditBackground() {
    return Container(
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Icon(Icons.edit, color: primaryBlue, size: 24),
        ),
      ),
    );
  }

  Future<bool> _showDeleteJourneyDialog(Journey journey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        title: Text(t('Supprimer la course', 'حذف الرحلة'),
            style: TextStyle(color: Colors.red)),
        content: Text(
          t('Êtes-vous sûr de vouloir supprimer cette course?',
              'هل أنت متأكد من رغبتك في حذف هذه الرحلة؟'),
          style: TextStyle(color: textWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('Annuler', 'إلغاء'),
                style: TextStyle(color: textWhite.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('Supprimer', 'حذف'),
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDelete(journey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(t('Course supprimée avec succès', 'تم حذف الرحلة بنجاح')),
          backgroundColor: accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    }
    return false;
  }

  void _editJourney(Journey journey) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AddJourneyPage(
        companies: widget.journeys.map((j) => j.company).toSet().toList(),
        onAdd: (updatedJourney) {
          widget.onUpdate(journey, updatedJourney);
        },
        currentUser: journey.userId,
        language: widget.language,
        journeyToEdit: journey,
      ),
    ));
  }

  Widget _buildJourneyListItem(Journey journey, int index) {
    double totalCharges = journey.charges.fold(0.0, (sum, c) => sum + c.amount);
    double profit = journey.payment - totalCharges;
    bool isExpanded = expandedIndex == index;

    return Dismissible(
      key: Key('${journey.company}_${journey.date}_${journey.payment}'),
      direction: DismissDirection.horizontal,
      background: _buildEditBackground(),
      secondaryBackground: _buildDeleteBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteJourneyDialog(journey);
        } else {
          _editJourney(journey);
          return false;
        }
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            expandedIndex = isExpanded ? -1 : index;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          child: _buildJourneyCard(
            height: isExpanded ? null : 120,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${journey.startCity} → ${journey.endCity}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textWhite,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              journey.company,
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildProfitBadge(profit),
                    ],
                  ),

                  // Additional info
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (journey.plateNumber.isNotEmpty)
                        Text(
                          "${t('Plaque', 'لوحة')}: ${journey.plateNumber}",
                          style: TextStyle(
                            color: textWhite.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      if (journey.cargoType.isNotEmpty)
                        Text(
                          "${t('Marchandise', 'بضاعة')}: ${journey.cargoType}",
                          style: TextStyle(
                            color: textWhite.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(journey.date),
                        style: TextStyle(
                          color: textWhite.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Expanded details
                  if (isExpanded) ...[
                    SizedBox(height: 12),
                    Divider(color: primaryBlue.withOpacity(0.3)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${t("Paiement", "المبلغ")}:",
                          style: TextStyle(
                            color: textWhite.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "${journey.payment} MAD",
                          style: TextStyle(
                            color: textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${t("Charges", "المصاريف")}:",
                          style: TextStyle(
                            color: textWhite.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "${totalCharges.toStringAsFixed(0)} MAD",
                          style: TextStyle(
                            color: textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (journey.cargoWeight > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${t("Poids", "الوزن")}:",
                            style: TextStyle(
                              color: textWhite.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "${journey.cargoWeight} kg",
                            style: TextStyle(
                              color: textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    if (journey.charges.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        "${t("Détails des charges", "تفاصيل المصاريف")}:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                          fontSize: 12,
                        ),
                      ),
                      ...journey.charges.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text(
                            "• ${c.name}: ${c.amount} MAD",
                            style: TextStyle(
                              color: textWhite.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyGridItem(Journey journey) {
    double totalCharges = journey.charges.fold(0.0, (sum, c) => sum + c.amount);
    double profit = journey.payment - totalCharges;

    return _buildJourneyCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "${journey.startCity} → ${journey.endCity}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textWhite,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildProfitBadge(profit),
              ],
            ),
            SizedBox(height: 6),
            Text(
              journey.company,
              style: TextStyle(
                color: primaryBlue,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 8),
            if (journey.plateNumber.isNotEmpty)
              Text(
                "${t('Plaque', 'لوحة')}: ${journey.plateNumber}",
                style: TextStyle(
                  color: textWhite.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            if (journey.cargoType.isNotEmpty)
              Text(
                "${t('Marchandise', 'بضاعة')}: ${journey.cargoType}",
                style: TextStyle(
                  color: textWhite.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            SizedBox(height: 8),
            Divider(color: primaryBlue.withOpacity(0.3), height: 1),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${t('Paiement', 'المبلغ')}",
                      style: TextStyle(
                        color: textWhite.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      "${journey.payment} MAD",
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${t('Date', 'التاريخ')}",
                      style: TextStyle(
                        color: textWhite.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM').format(journey.date),
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredJourneys = _filteredJourneys;

    return Column(
      children: [
        // Search Bar
        _buildSearchBar(),

        // Summary Header
        _buildSummaryHeader(),

        // Filter Chips (only when filters are active or shown)
        if (_showFilters || _dateFilter != 'all' || _filterCompany != 'all')
          _buildFilterChips(),

        // Journeys List/Grid
        if (filteredJourneys.isEmpty)
          Expanded(
            child: Center(
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off,
                        size: 48, color: textWhite.withOpacity(0.5)),
                    SizedBox(height: 16),
                    Text(
                      t("Aucun voyage trouvé", "لم يتم العثور على رحلات"),
                      style: TextStyle(
                        color: textWhite.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_showGrid)
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemCount: filteredJourneys.length,
              itemBuilder: (context, index) {
                return _buildJourneyGridItem(filteredJourneys[index]);
              },
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filteredJourneys.length,
              itemBuilder: (context, index) {
                return _buildJourneyListItem(filteredJourneys[index], index);
              },
            ),
          ),
      ],
    );
  }
}

// ==================== STATS PAGE ====================
class StatsPage extends StatefulWidget {
  final List<Journey> journeys;
  final String language;

  StatsPage({required this.journeys, required this.language});

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _timeFilter = 'all';
  int _currentChartIndex = 0;
  final PageController _chartController = PageController();

  String t(String fr, String ar) => widget.language == 'fr' ? fr : ar;

  // Time filtering
  List<Journey> get _filteredJourneys {
    final now = DateTime.now();
    switch (_timeFilter) {
      case 'month':
        final monthAgo = now.subtract(Duration(days: 30));
        return widget.journeys.where((j) => j.date.isAfter(monthAgo)).toList();
      case 'quarter':
        final quarterAgo = now.subtract(Duration(days: 90));
        return widget.journeys
            .where((j) => j.date.isAfter(quarterAgo))
            .toList();
      case 'year':
        final yearAgo = now.subtract(Duration(days: 365));
        return widget.journeys.where((j) => j.date.isAfter(yearAgo)).toList();
      default:
        return widget.journeys;
    }
  }

  // Financial calculations
  double get _totalRevenue {
    return _filteredJourneys.fold(0.0, (sum, j) => sum + j.payment);
  }

  double get _totalExpenses {
    return _filteredJourneys.fold(0.0,
        (sum, j) => sum + j.charges.fold(0.0, (cSum, c) => cSum + c.amount));
  }

  double get _totalProfit {
    return _totalRevenue - _totalExpenses;
  }

  double get _profitMargin {
    return _totalRevenue > 0 ? (_totalProfit / _totalRevenue) * 100 : 0;
  }

  // Expense analysis
  Map<String, double> get _expenseCategories {
    Map<String, double> categories = {};
    for (var journey in _filteredJourneys) {
      for (var charge in journey.charges) {
        categories.update(charge.name, (value) => value + charge.amount,
            ifAbsent: () => charge.amount);
      }
    }
    return categories;
  }

  // Advanced analytics
  Map<String, dynamic> get _topPerformers {
    Map<String, double> companyProfits = {};
    for (var journey in _filteredJourneys) {
      final profit = journey.payment -
          journey.charges.fold(0.0, (sum, c) => sum + c.amount);
      companyProfits.update(journey.company, (value) => value + profit,
          ifAbsent: () => profit);
    }

    Map<String, int> routeCounts = {};
    for (var journey in _filteredJourneys) {
      final route = "${journey.startCity} → ${journey.endCity}";
      routeCounts.update(route, (value) => value + 1, ifAbsent: () => 1);
    }

    return {
      'topCompany': companyProfits.entries.isNotEmpty
          ? companyProfits.entries.reduce((a, b) => a.value > b.value ? a : b)
          : null,
      'topRoute': routeCounts.entries.isNotEmpty
          ? routeCounts.entries.reduce((a, b) => a.value > b.value ? a : b)
          : null,
    };
  }

  // Monthly trends for line chart
  List<FlSpot> get _monthlyProfitSpots {
    Map<String, double> monthlyProfits = {};

    for (var journey in _filteredJourneys) {
      final monthKey = DateFormat('MM/yyyy').format(journey.date);
      final profit = journey.payment -
          journey.charges.fold(0.0, (sum, c) => sum + c.amount);
      monthlyProfits.update(monthKey, (value) => value + profit,
          ifAbsent: () => profit);
    }

    final sortedMonths = monthlyProfits.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedMonths.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  Widget _buildTimeFilterChips() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', t('Tout', 'الكل')),
            _buildFilterChip('month', t('Mois', 'شهر')),
            _buildFilterChip('quarter', t('Trimestre', 'ربع سنة')),
            _buildFilterChip('year', t('Année', 'سنة')),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _timeFilter == value;
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (selected) => setState(() => _timeFilter = value),
        backgroundColor: cardBackground,
        selectedColor: primaryBlue.withOpacity(0.3),
        labelStyle: TextStyle(
          color: isSelected ? primaryBlue : textWhite,
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            t('Aperçu Financier', 'نظرة عامة مالية'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFinanceCard(
                t('Revenus', 'الإيرادات'),
                '${_totalRevenue.toStringAsFixed(0)} MAD',
                Icons.attach_money,
                primaryBlue,
              ),
              _buildFinanceCard(
                t('Dépenses', 'المصاريف'),
                '${_totalExpenses.toStringAsFixed(0)} MAD',
                Icons.money_off,
                Colors.orange,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFinanceCard(
                t('Profit', 'الربح'),
                '${_totalProfit.toStringAsFixed(0)} MAD',
                Icons.trending_up,
                _totalProfit >= 0 ? accentGreen : Colors.red,
              ),
              _buildFinanceCard(
                t('Marge', 'هامش الربح'),
                '${_profitMargin.toStringAsFixed(1)}%',
                Icons.percent,
                secondaryPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: textWhite.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('Visualisations', 'الرسوم البيانية'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  _buildChartIndicator(0, Icons.pie_chart),
                  SizedBox(width: 8),
                  _buildChartIndicator(1, Icons.show_chart),
                  SizedBox(width: 8),
                  _buildChartIndicator(2, Icons.bar_chart),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 200,
            child: PageView(
              controller: _chartController,
              onPageChanged: (index) =>
                  setState(() => _currentChartIndex = index),
              children: [
                _buildPieChart(),
                _buildLineChart(),
                _buildBarChart(),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPageIndicator(0),
              SizedBox(width: 8),
              _buildPageIndicator(1),
              SizedBox(width: 8),
              _buildPageIndicator(2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartIndicator(int index, IconData icon) {
    final isActive = _currentChartIndex == index;
    return GestureDetector(
      onTap: () => _chartController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      child: Icon(
        icon,
        size: 20,
        color: isActive ? primaryBlue : textWhite.withOpacity(0.4),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentChartIndex == index
            ? primaryBlue
            : textWhite.withOpacity(0.3),
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: _totalExpenses.toDouble(),
            color: Colors.orange,
            title:
                '${_totalExpenses.toStringAsFixed(0)} MAD\n${t("Dépenses", "المصاريف")}',
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: _totalProfit.toDouble(),
            color: _totalProfit >= 0 ? accentGreen : Colors.red,
            title:
                '${_totalProfit.toStringAsFixed(0)} MAD\n${t("Profit", "الربح")}',
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final spots = _monthlyProfitSpots;

    if (spots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: textWhite.withOpacity(0.3)),
            SizedBox(height: 8),
            Text(
              t('Données insuffisantes', 'بيانات غير كافية'),
              style: TextStyle(color: textWhite.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryBlue,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(show: spots.length <= 12),
          ),
        ],
        minY: spots.isNotEmpty
            ? spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.9
            : 0,
        maxY: spots.isNotEmpty
            ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.1
            : 100,
      ),
    );
  }

  Widget _buildBarChart() {
    final categories = _expenseCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final displayCategories =
        categories.length > 5 ? categories.sublist(0, 5) : categories;

    if (displayCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: textWhite.withOpacity(0.3)),
            SizedBox(height: 8),
            Text(
              t('Aucune dépense', 'لا توجد مصاريف'),
              style: TextStyle(color: textWhite.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: displayCategories.isNotEmpty
            ? displayCategories.first.value * 1.2
            : 100,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= displayCategories.length) return Text('');
                final name = displayCategories[index].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    name.length > 8 ? '${name.substring(0, 8)}...' : name,
                    style: TextStyle(
                        fontSize: 10, color: textWhite.withOpacity(0.7)),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                      fontSize: 10, color: textWhite.withOpacity(0.7)),
                );
              },
              reservedSize: 30,
            ),
          ),
        ),
        barGroups: displayCategories.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: [
                  primaryBlue,
                  secondaryPurple,
                  accentGreen,
                  Colors.orange,
                  Colors.red,
                ][entry.key % 5],
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpenseAnalysis() {
    final categories = _expenseCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Analyse des Dépenses', 'تحليل المصاريف'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          if (categories.isEmpty)
            Text(
              t('Aucune dépense enregistrée', 'لا توجد مصاريف مسجلة'),
              style: TextStyle(color: textWhite.withOpacity(0.7)),
            )
          else
            Column(
              children: categories.take(5).map((entry) {
                final percentage = (_totalExpenses > 0)
                    ? (entry.value / _totalExpenses) * 100
                    : 0.0;
                return _buildExpenseItem(
                    entry.key, entry.value, percentage.toDouble());
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(String name, double amount, double percentage) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name.length > 20 ? '${name.substring(0, 20)}...' : name,
              style: TextStyle(color: textWhite, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${amount.toStringAsFixed(0)} MAD',
              style: TextStyle(color: textWhite.withOpacity(0.8), fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(color: primaryBlue, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedAnalytics() {
    final performers = _topPerformers;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Analyses Avancées', 'تحليلات متقدمة'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          if (performers['topCompany'] != null)
            _buildAnalyticItem(
              Icons.business,
              t('Entreprise la plus rentable', 'أكثر الشركات ربحية'),
              performers['topCompany']!.key,
              '${performers['topCompany']!.value.toStringAsFixed(0)} MAD',
            ),
          if (performers['topRoute'] != null)
            _buildAnalyticItem(
              Icons.route,
              t('Route la plus fréquente', 'أكثر الطرق تكراراً'),
              performers['topRoute']!.key,
              '${performers['topRoute']!.value} ${t("voyages", "رحلة")}',
            ),
          _buildAnalyticItem(
            Icons.analytics,
            t('Marge de profit moyenne', 'متوسط هامش الربح'),
            '${_profitMargin.toStringAsFixed(1)}%',
            _filteredJourneys.length > 0
                ? '${(_totalProfit / _filteredJourneys.length).toStringAsFixed(0)} MAD/voyage'
                : t('Aucune donnée', 'لا توجد بيانات'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticItem(
      IconData icon, String title, String value, String subtitle) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: primaryBlue),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textWhite.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textWhite.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.journeys.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics,
                  size: 48, color: textWhite.withOpacity(0.5)),
              SizedBox(height: 16),
              Text(
                t("Aucune donnée disponible", "لا توجد بيانات متاحة"),
                style: TextStyle(
                  color: textWhite.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                t("Ajoutez des voyages pour voir les statistiques",
                    "أضف رحلات لرؤية الإحصائيات"),
                style: TextStyle(
                  color: textWhite.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 8),
          _buildTimeFilterChips(),
          _buildFinancialOverview(),
          _buildChartSection(),
          _buildExpenseAnalysis(),
          _buildAdvancedAnalytics(),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ==================== ENHANCED COMPANIES PAGE ====================
class CompaniesPage extends StatefulWidget {
  final List<String> companies;
  final Function(String) onAdd;
  final Function(String) onRemove;
  final String language;
  final List<Journey> journeys;

  CompaniesPage({
    required this.companies,
    required this.onAdd,
    required this.onRemove,
    required this.language,
    required this.journeys,
  });

  @override
  _CompaniesPageState createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'recent';
  bool _showSearch = false;
  final Map<String, Company> _companyData = {};

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  void _loadCompanyData() async {
    final companiesBox = Hive.box('companiesBox');
    final userCompaniesKey = '${_getCurrentUser()}_enhanced_companies';

    final storedData = companiesBox.get(userCompaniesKey, defaultValue: {});
    if (storedData is Map) {
      setState(() {
        _companyData.addAll(Map<String, Company>.from(storedData));
      });
    }

    // Initialize missing companies
    for (var companyName in widget.companies) {
      if (!_companyData.containsKey(companyName)) {
        _companyData[companyName] = Company(
          name: companyName,
          lastUsed: _getLastUsedDate(companyName),
        );
      }
    }
    _saveCompanyData();
  }

  DateTime _getLastUsedDate(String companyName) {
    final companyJourneys =
        widget.journeys.where((j) => j.company == companyName).toList();
    if (companyJourneys.isEmpty) return DateTime(2000);
    return companyJourneys
        .map((j) => j.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  String _getCurrentUser() {
    final usersBox = Hive.box('usersBox');
    return usersBox.get('currentUser', defaultValue: 'default');
  }

  void _saveCompanyData() async {
    final companiesBox = Hive.box('companiesBox');
    final userCompaniesKey = '${_getCurrentUser()}_enhanced_companies';
    await companiesBox.put(userCompaniesKey, _companyData);
  }

  void _updateCompanyLastUsed(String companyName) {
    setState(() {
      _companyData[companyName] = Company(
        name: companyName,
        address: _companyData[companyName]?.address,
        ice: _companyData[companyName]?.ice,
        lastUsed: DateTime.now(),
      );
    });
    _saveCompanyData();
  }

  void _updateCompanyDetails(String companyName, String? address, String? ice) {
    setState(() {
      _companyData[companyName] = Company(
        name: companyName,
        address: address,
        ice: ice,
        lastUsed: _companyData[companyName]?.lastUsed ?? DateTime.now(),
      );
    });
    _saveCompanyData();
  }

  void _deleteCompany(String companyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        title: Text(t('Supprimer la société', 'حذف الشركة'),
            style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t('Êtes-vous sûr de vouloir supprimer',
                  'هل أنت متأكد من رغبتك في حذف'),
              style: TextStyle(color: textWhite),
            ),
            SizedBox(height: 8),
            Text(
              '"$companyName"?',
              style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            SizedBox(height: 12),
            if (_getCompanyJourneyCount(companyName) > 0)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t('Cette société a ${_getCompanyJourneyCount(companyName)} voyage(s) associé(s)',
                            'هذه الشركة لديها ${_getCompanyJourneyCount(companyName)} رحلة مرتبطة'),
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Annuler', 'إلغاء'),
                style: TextStyle(color: textWhite.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _companyData.remove(companyName);
              });
              _saveCompanyData();
              widget.onRemove(companyName);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t(
                      'Société supprimée avec succès', 'تم حذف الشركة بنجاح')),
                  backgroundColor: accentGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              t('Supprimer', 'حذف'),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  int _getCompanyJourneyCount(String companyName) {
    return widget.journeys
        .where((journey) => journey.company == companyName)
        .length;
  }

  List<Company> get _sortedCompanies {
    List<Company> companies = _companyData.values.toList();

    if (_searchQuery.isNotEmpty) {
      companies = companies
          .where((company) =>
              company.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (company.address
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false) ||
              (company.ice
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    switch (_sortBy) {
      case 'alphabetical':
        companies.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'recent':
      default:
        companies.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
        break;
    }

    return companies;
  }

  Map<String, List<Company>> get _groupedCompanies {
    if (_sortBy != 'alphabetical') return {'': _sortedCompanies};

    Map<String, List<Company>> groups = {};
    for (var company in _sortedCompanies) {
      final firstLetter =
          company.name.isNotEmpty ? company.name[0].toUpperCase() : '#';
      if (!groups.containsKey(firstLetter)) {
        groups[firstLetter] = [];
      }
      groups[firstLetter]!.add(company);
    }
    return groups;
  }

  String t(String fr, String ar) => widget.language == 'fr' ? fr : ar;

  Widget _buildSoftContainer({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCompanyCard(Company company) {
    return _buildSoftContainer(
      child: Dismissible(
        key: Key(company.name),
        direction: DismissDirection.horizontal,
        background: _buildSwipeBackground(
            Icons.edit, primaryBlue, Alignment.centerLeft),
        secondaryBackground: _buildSwipeBackground(
            Icons.delete, Colors.red, Alignment.centerRight),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            _showEditCompanyDialog(company);
            return false;
          } else if (direction == DismissDirection.endToStart) {
            _deleteCompany(company.name);
            return false;
          }
          return false;
        },
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, secondaryPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Text(
            company.name,
            style: TextStyle(
              color: textWhite,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (company.address != null && company.address!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 12, color: textWhite.withOpacity(0.6)),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          company.address!,
                          style: TextStyle(
                            color: textWhite.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (company.ice != null && company.ice!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(Icons.badge,
                          size: 12, color: textWhite.withOpacity(0.6)),
                      SizedBox(width: 4),
                      Text(
                        'ICE: ${company.ice!}',
                        style: TextStyle(
                          color: textWhite.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  t('Dernier voyage: ', 'آخر رحلة: ') +
                      DateFormat('dd/MM/yyyy').format(company.lastUsed),
                  style: TextStyle(
                    color: textWhite.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.directions_car, size: 18, color: accentGreen),
                onPressed: () => _navigateToAddJourney(company.name),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: textWhite.withOpacity(0.5),
              ),
            ],
          ),
          onTap: () {
            _updateCompanyLastUsed(company.name);
            _showCompanyDetails(company);
          },
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(
      IconData icon, Color color, Alignment alignment) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  void _navigateToAddJourney(String companyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        title: Text(t('Ajouter un voyage', 'إضافة رحلة'),
            style: TextStyle(color: primaryBlue)),
        content: Text(
          t('Voulez-vous ajouter un voyage pour $companyName?',
              'هل تريد إضافة رحلة لـ $companyName?'),
          style: TextStyle(color: textWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Annuler', 'إلغاء'),
                style: TextStyle(color: textWhite.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AddJourneyPage(
                  companies: widget.companies,
                  onAdd: (journey) {
                    Navigator.pop(context);
                  },
                  currentUser: _getCurrentUser(),
                  language: widget.language,
                  preFilledCompany: companyName,
                ),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: Text(
              t('Continuer', 'متابعة'),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCompanyDialog(Company company) {
    final addressController = TextEditingController(text: company.address);
    final iceController = TextEditingController(text: company.ice);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        title: Text(t('Modifier la société', 'تعديل الشركة'),
            style: TextStyle(color: textWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(company.name,
                style:
                    TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            TextField(
              controller: addressController,
              style: TextStyle(color: textWhite),
              decoration: InputDecoration(
                labelText: t('Adresse', 'العنوان'),
                labelStyle: TextStyle(color: textWhite.withOpacity(0.7)),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: iceController,
              style: TextStyle(color: textWhite),
              decoration: InputDecoration(
                labelText: 'ICE',
                labelStyle: TextStyle(color: textWhite.withOpacity(0.7)),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Annuler', 'إلغاء'),
                style: TextStyle(color: textWhite.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              _updateCompanyDetails(company.name, addressController.text.trim(),
                  iceController.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: Text(
              t('Sauvegarder', 'حفظ'),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompanyDetails(Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        title: Text(company.name, style: TextStyle(color: primaryBlue)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (company.address != null && company.address!.isNotEmpty) ...[
              Text(t('Adresse:', 'العنوان:'),
                  style: TextStyle(color: textWhite.withOpacity(0.7))),
              Text(company.address!, style: TextStyle(color: textWhite)),
              SizedBox(height: 12),
            ],
            if (company.ice != null && company.ice!.isNotEmpty) ...[
              Text('ICE:', style: TextStyle(color: textWhite.withOpacity(0.7))),
              Text(company.ice!, style: TextStyle(color: textWhite)),
              SizedBox(height: 12),
            ],
            Text(t('Dernière utilisation:', 'آخر استخدام:'),
                style: TextStyle(color: textWhite.withOpacity(0.7))),
            Text(DateFormat('dd/MM/yyyy à HH:mm').format(company.lastUsed),
                style: TextStyle(color: textWhite)),
            SizedBox(height: 12),
            Text(t('Nombre de voyages:', 'عدد الرحلات:'),
                style: TextStyle(color: textWhite.withOpacity(0.7))),
            Text('${_getCompanyJourneyCount(company.name)}',
                style: TextStyle(color: textWhite)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Fermer', 'إغلاق'),
                style: TextStyle(color: primaryBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCompanySection() {
    return _buildSoftContainer(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(color: textWhite),
                decoration: InputDecoration(
                  labelText: t('Nouvelle société', 'شركة جديدة'),
                  labelStyle: TextStyle(color: textWhite.withOpacity(0.7)),
                  border: InputBorder.none,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [primaryBlue, secondaryPurple]),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    widget.onAdd(_controller.text);
                    _updateCompanyDetails(_controller.text, null, null);
                    _controller.clear();
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndSortSection() {
    return _buildSoftContainer(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: textWhite),
                decoration: InputDecoration(
                  hintText: t('Rechercher...', 'بحث...'),
                  hintStyle: TextStyle(color: textWhite.withOpacity(0.5)),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: primaryBlue),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.sort, color: primaryBlue),
              onSelected: (value) => setState(() => _sortBy = value),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'recent',
                  child: Text(t('Récent', 'الأحدث')),
                ),
                PopupMenuItem(
                  value: 'alphabetical',
                  child: Text(t('Alphabétique', 'أبجدي')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlphabeticalIndex() {
    if (_sortBy != 'alphabetical') return SizedBox.shrink();

    final letters = _groupedCompanies.keys.toList()..sort();
    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: letters.length,
        itemBuilder: (context, index) {
          final letter = letters[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: primaryBlue.withOpacity(0.2),
              child: Text(
                letter,
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompaniesList() {
    final companies = _sortedCompanies;
    final groupedCompanies = _groupedCompanies;

    if (companies.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 64, color: textWhite.withOpacity(0.3)),
              SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? t('Aucune société ajoutée', 'لم تتم إضافة أي شركة')
                    : t('Aucun résultat trouvé', 'لم يتم العثور على نتائج'),
                style: TextStyle(color: textWhite.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      );
    }

    if (_sortBy == 'alphabetical') {
      return Expanded(
        child: ListView.builder(
          itemCount: groupedCompanies.length,
          itemBuilder: (context, index) {
            final letter = groupedCompanies.keys.elementAt(index);
            final letterCompanies = groupedCompanies[letter]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                ...letterCompanies.map((company) => _buildCompanyCard(company)),
              ],
            );
          },
        ),
      );
    } else {
      return Expanded(
        child: ListView.builder(
          itemCount: companies.length,
          itemBuilder: (context, index) {
            return _buildCompanyCard(companies[index]);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 8),
        _buildAddCompanySection(),
        _buildSearchAndSortSection(),
        _buildAlphabeticalIndex(),
        _buildCompaniesList(),
      ],
    );
  }
}

// ==================== EXPORT DATA PAGE (SIMPLIFIED) ====================
class ExportDataPage extends StatefulWidget {
  final List<Journey> journeys;
  final String currentUser;
  final String language;

  const ExportDataPage({
    Key? key,
    required this.journeys,
    required this.currentUser,
    required this.language,
  }) : super(key: key);

  @override
  _ExportDataPageState createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  bool _isExporting = false;
  String _lastExportPath = '';

  String t(String fr, String ar) => widget.language == 'fr' ? fr : ar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1e1e2e),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('Exporter les données', 'تصدير البيانات'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFf8f9fa),
              ),
            ),
            SizedBox(height: 20),

            // 🔥 ADD THIS NEW SYNC OPTION HERE
            _buildExportOption(
              t('Synchroniser avec le cloud', 'المزامنة مع السحابة'),
              t('Sauvegarder les données sur tous les appareils',
                  'احفظ البيانات على جميع الأجهزة'),
              Icons.cloud_sync,
              _manualSync,
            ),

            SizedBox(height: 12),

            // Export Options
            _buildExportOption(
              t('Exporter vers JSON', 'تصدير إلى JSON'),
              t('Format optimal pour l\'application PC',
                  'التنسيق الأمثل لتطبيق الكمبيوتر'),
              Icons.computer,
              _exportToJson,
            ),

            SizedBox(height: 12),

            _buildExportOption(
              t('Exporter vers CSV/Excel', 'تصدير إلى CSV/Excel'),
              t('Compatible avec Microsoft Excel', 'متوافق مع Microsoft Excel'),
              Icons.table_chart,
              _exportToCsv,
            ),

            SizedBox(height: 12),

            _buildExportOption(
              t('Partager par email', 'مشاركة عبر البريد الإلكتروني'),
              t('Envoyer les données par email',
                  'إرسال البيانات عبر البريد الإلكتروني'),
              Icons.email,
              _shareViaEmail,
            ),

            SizedBox(height: 20),

            // Status
            if (_isExporting)
              _buildStatusContainer(
                t('Exportation en cours...', 'جاري التصدير...'),
                Color(0xFF4361ee),
              ),

            if (_lastExportPath.isNotEmpty && !_isExporting)
              _buildStatusContainer(
                t('Exportation réussie!', 'تم التصدير بنجاح!'),
                Color(0xFF4cc9f0),
              ),

            SizedBox(height: 20),

            // Instructions
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2d2d44),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Instructions d\'exportation', 'تعليمات التصدير'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFf8f9fa),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    t('1. Exportez vos données en JSON ou CSV\n2. Partagez le fichier par email\n3. Enregistrez le fichier sur votre appareil',
                        '1. قم بتصدير بياناتك بصيغة JSON أو CSV\n2. شارك الملف عبر البريد الإلكتروني\n3. احفظ الملف على جهازك'),
                    style: TextStyle(
                      color: Color(0xFFf8f9fa).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Journey Count
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2d2d44),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t('Voyages à exporter:', 'الرحلات المراد تصديرها:'),
                    style: TextStyle(
                      color: Color(0xFFf8f9fa),
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${widget.journeys.length}',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Color(0xFF4361ee),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(
      String title, String description, IconData icon, Function() onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2d2d44),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF4cc9f0)),
        title: Text(
          title,
          style: TextStyle(
            color: Color(0xFFf8f9fa),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: Color(0xFFf8f9fa).withOpacity(0.7),
          ),
        ),
        trailing: _isExporting
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4cc9f0)),
                strokeWidth: 2,
              )
            : Icon(Icons.arrow_forward_ios,
                size: 16, color: Color(0xFFf8f9fa).withOpacity(0.5)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusContainer(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: color),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 ADD THIS NEW METHOD FOR MANUAL SYNC
  Future<void> _manualSync() async {
    setState(() => _isExporting = true);

    try {
      // Get companies data from Hive
      final companiesBox = Hive.box('companiesBox');
      final userCompaniesKey = '${widget.currentUser}_companies';
      final companies = List<String>.from(
          companiesBox.get(userCompaniesKey, defaultValue: []));

      final success = await FirebaseSyncService.syncToCloud(
        widget.currentUser,
        widget.journeys,
        companies,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(t('✅ Synchronisation réussie!', '✅ تمت المزامنة بنجاح!')),
            backgroundColor: Color(0xFF4cc9f0),
          ),
        );
      } else {
        _showError(t('Erreur de synchronisation', 'خطأ في المزامنة'),
            t('Impossible de se connecter au cloud', 'تعذر الاتصال بالسحابة'));
      }
    } catch (e) {
      _showError(
          t('Erreur de synchronisation', 'خطأ في المزامنة'), e.toString());
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToJson() async {
    setState(() {
      _isExporting = true;
      _lastExportPath = '';
    });

    try {
      final filePath =
          await ExportService.exportToJson(widget.journeys, widget.currentUser);

      setState(() {
        _lastExportPath = filePath;
      });

      // Auto-share after export
      await ExportService.shareFile(
          filePath, 'Truck Journeys Data - ${widget.currentUser}');
    } catch (e) {
      _showError(t('Erreur d\'exportation', 'خطأ في التصدير'), e.toString());
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToCsv() async {
    setState(() {
      _isExporting = true;
      _lastExportPath = '';
    });

    try {
      final filePath = await ExportService.exportToCsv(widget.journeys);

      setState(() {
        _lastExportPath = filePath;
      });

      await ExportService.shareFile(
          filePath, 'Truck Journeys CSV - ${widget.currentUser}');
    } catch (e) {
      _showError(
          t('Erreur d\'exportation CSV', 'خطأ في تصدير CSV'), e.toString());
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _shareViaEmail() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final filePath =
          await ExportService.exportToJson(widget.journeys, widget.currentUser);
      await ExportService.shareFile(
          filePath, 'Truck Journeys Data Export - ${widget.currentUser}');
    } catch (e) {
      _showError(t('Erreur de partage', 'خطأ في المشاركة'), e.toString());
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showError(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
}
