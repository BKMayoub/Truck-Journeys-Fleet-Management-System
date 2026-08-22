// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import '../../services/service_provider.dart'; // ADD THIS
import '../../models/user.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  List<AppUser> _recentUsers = [];
  Map<String, dynamic> _stats = {}; // ADD THIS - stores real statistics

  @override
  void initState() {
    super.initState();
    _loadRealDashboardData(); // CHANGED THIS
  }

  // CHANGED THIS: Load real data from Firebase
  void _loadRealDashboardData() async {
    print('🔄 Dashboard: Loading real data from Firebase...');
    
    final dataService = ServiceProvider.getDataService();
    
    try {
      // Load real statistics
      final stats = await dataService.getDashboardStats();
      print('📊 Dashboard: Received stats: $stats');
      
      // Load recent users
      final users = await dataService.getUsersStream().first;
      final recentUsers = users.take(5).toList(); // Get first 5 users
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentUsers = recentUsers;
          _isLoading = false;
        });
      }
    } catch (error) {
      print('❌ Dashboard: Error loading data: $error');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _refreshData() {
    setState(() {
      _isLoading = true;
    });
    _loadRealDashboardData();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2d2d44),
        title: Text('Logout', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to logout?', 
                     style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1e1e2e),
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Color(0xFF2d2d44),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading 
          ? _buildLoadingState()
          : _buildDashboardContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF4361ee),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading Dashboard...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bouksim Trans Admin',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage your trucking business',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Spacer(),
              // Quick stats in header - USING REAL DATA
              Row(
                children: [
                  _buildHeaderStat('Users', _stats['totalUsers']?.toString() ?? '0'),
                  SizedBox(width: 12),
                  _buildHeaderStat('Journeys', _stats['totalJourneys']?.toString() ?? '0'),
                  SizedBox(width: 12),
                  _buildHeaderStat('Active', '${_recentUsers.where((u) => u.isActive).length}'),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Compact Stats Cards - USING REAL DATA
          _buildCompactStatsSection(),
          SizedBox(height: 16),

          // Navigation Cards - REMOVED FIREBASE TEST
          _buildCompactNavigationSection(),
          SizedBox(height: 16),
          
          // Recent Users Section - USING REAL DATA
          _buildRecentUsersSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // UPDATED: Use real statistics from Firebase
  Widget _buildCompactStatsSection() {
    final totalRevenue = _stats['totalRevenue'] ?? 0;
    final averageRevenue = _stats['averageRevenue'] ?? 0;
    
    return Card(
      color: Color(0xFF2d2d44),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCompactStatItem('Total Users', _stats['totalUsers']?.toString() ?? '0', Icons.people),
            _buildCompactStatItem('Total Journeys', _stats['totalJourneys']?.toString() ?? '0', Icons.directions_car),
            _buildCompactStatItem('Total Revenue', '${totalRevenue.toStringAsFixed(0)} MAD', Icons.attach_money),
            _buildCompactStatItem('Avg Revenue', '${averageRevenue.toStringAsFixed(0)} MAD', Icons.trending_up),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(String title, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xFF4361ee).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Color(0xFF4361ee), size: 16),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // UPDATED: Removed Firebase Test card
  Widget _buildCompactNavigationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 80,
          child: Row(
            children: [
              _buildCompactNavCard('Users', Icons.people, '/users', context),
              SizedBox(width: 8),
              _buildCompactNavCard('Companies', Icons.business, '/companies', context),
              SizedBox(width: 8),
              _buildCompactNavCard('Journeys', Icons.explore, '/journeys', context),
              SizedBox(width: 8),
              _buildCompactNavCard('Reports', Icons.analytics, '/reports', context),
              // REMOVED: Firebase Test card
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactNavCard(String title, IconData icon, String route, BuildContext context) {
    return Expanded(
      child: Card(
        color: Color(0xFF2d2d44),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Color(0xFF4361ee), size: 20),
                SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // UPDATED: Use real users from Firebase
  Widget _buildRecentUsersSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Drivers',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                '${_recentUsers.length} total', // USING REAL COUNT
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: _recentUsers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _recentUsers.length,
                    itemBuilder: (context, index) {
                      final user = _recentUsers[index];
                      return _buildCompactUserCard(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactUserCard(AppUser user) {
    return Card(
      color: Color(0xFF2d2d44),
      margin: EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: user.isActive ? Color(0xFF4361ee) : Colors.grey,
          child: Text(
            user.username[0].toUpperCase(),
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(
          user.username,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        subtitle: Text(
          '${user.journeyCount} journeys', // REAL JOURNEY COUNT
          style: TextStyle(color: Colors.white70, fontSize: 10),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: user.isActive 
                ? Colors.green.withOpacity(0.2) 
                : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: user.isActive ? Colors.green : Colors.red,
            ),
          ),
          child: Text(
            user.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: user.isActive ? Colors.green : Colors.red,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            'No Users Found',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Users will appear here when drivers register',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}