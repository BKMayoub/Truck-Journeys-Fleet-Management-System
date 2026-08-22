import 'package:flutter/material.dart';
import '../../services/service_provider.dart'; // ADD THIS
import '../../models/user.dart';

class UsersListPage extends StatefulWidget {
  @override
  _UsersListPageState createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  List<AppUser> _filteredUsers = [];
  List<AppUser> _allUsers = []; // ADD THIS - stores all users from Firebase
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRealUsers(); // REPLACED: _loadUsers();

    // ======== ADD THIS TIMEOUT CODE RIGHT HERE ========
    Future.delayed(Duration(seconds: 30), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
        if (_allUsers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Still loading users from Firebase...'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
    // ======== END OF TIMEOUT CODE ========
  }

  // REPLACED: Load real users from Firebase
  void _loadRealUsers() {
    print('🔄 Starting to load real users from Firebase...');
    final dataService = ServiceProvider.getDataService();
    
    dataService.getUsersStream().listen((users) {
      print('✅ Received ${users.length} users from Firebase');
      
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print('❌ Error loading users: $error');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading users: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _refreshUsers() {
    setState(() {
      _isLoading = true;
      _filteredUsers = [];
    });
    _loadRealUsers();
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _allUsers; // REPLACED: MockDataService.mockUsers
      } else {
        _filteredUsers = _allUsers.where((user) { // REPLACED: MockDataService.mockUsers
          return user.username.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // UPDATED: Use real data for stats
  void _showUserStats() {
    final activeUsers = _allUsers.where((u) => u.isActive).length;
    final totalJourneys = _allUsers.fold(0, (sum, user) => sum + user.journeyCount);
    final avgJourneys = _allUsers.isNotEmpty ? totalJourneys / _allUsers.length : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2d2d44),
        title: Text('User Statistics', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Users', _allUsers.length.toString()),
            _buildStatRow('Active Users', '$activeUsers (${_allUsers.isNotEmpty ? (activeUsers / _allUsers.length * 100).toStringAsFixed(0) : 0}%)'),
            _buildStatRow('Total Journeys', totalJourneys.toString()),
            _buildStatRow('Avg Journeys/User', avgJourneys.toStringAsFixed(1)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70)),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1e1e2e),
      appBar: AppBar(
        title: Text('User Management'),
        backgroundColor: Color(0xFF2d2d44),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: _showUserStats,
            tooltip: 'View Statistics',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshUsers, // NOW USES REAL REFRESH
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters Bar
          _buildSearchBar(),
          
          // Stats Summary
          _buildStatsSummary(),
          
          // Users List
          Expanded(
            child: _isLoading 
                ? _buildLoadingState()
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Color(0xFF2d2d44),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: _filterUsers,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        hintStyle: TextStyle(color: Colors.white54),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF4361ee)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Color(0xFF3d3d5c),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF4361ee),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_filteredUsers.length} users',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              // Quick filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', ''),
                    SizedBox(width: 8),
                    _buildFilterChip('Active', 'active'),
                    SizedBox(width: 8),
                    _buildFilterChip('Inactive', 'inactive'),
                    SizedBox(width: 8),
                    _buildFilterChip('High Activity', 'high'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _searchQuery == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _filterUsers(filter);
        } else {
          _filterUsers('');
        }
      },
      backgroundColor: Color(0xFF3d3d5c),
      selectedColor: Color(0xFF4361ee),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontSize: 12,
      ),
    );
  }

  // UPDATED: Use real data for stats summary
  Widget _buildStatsSummary() {
    final activeUsers = _allUsers.where((u) => u.isActive).length;
    final totalJourneys = _allUsers.fold(0, (sum, user) => sum + user.journeyCount);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Color(0xFF2d2d44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', _allUsers.length.toString()),
          _buildSummaryItem('Active', '$activeUsers'),
          _buildSummaryItem('Journeys', totalJourneys.toString()),
          _buildSummaryItem('Active %', '${_allUsers.isNotEmpty ? (activeUsers / _allUsers.length * 100).toStringAsFixed(0) : 0}%'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4361ee)),
          SizedBox(height: 16),
          Text(
            'Loading users from Firebase...', // UPDATED MESSAGE
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No users found in Firebase' : 'No users match your search', // UPDATED MESSAGE
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Users will appear here when drivers register in the mobile app' // UPDATED MESSAGE
                : 'Try adjusting your search criteria',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _filterUsers(''),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4361ee),
              ),
              child: Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      itemCount: _filteredUsers.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(AppUser user) {
    return Card(
      color: Color(0xFF2d2d44),
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Color(0xFF4361ee) : Colors.grey,
          radius: 20,
          child: Text(
            user.username[0].toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.username,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.directions_car, size: 12, color: Colors.white70),
                SizedBox(width: 4),
                Text(
                  '${user.journeyCount} journeys',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 12, color: Colors.white70),
                SizedBox(width: 4),
                Text(
                  'Last: ${_formatDate(user.lastLogin)}',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: user.isActive ? Colors.green : Colors.red,
                ),
              ),
              child: Text(
                user.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: user.isActive ? Colors.green : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (value) => _handleMenuAction(value, user),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(Icons.toggle_on, size: 16, color: Colors.orange),
                      SizedBox(width: 6),
                      Text(user.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.analytics, size: 16, color: Color(0xFF4361ee)),
                      SizedBox(width: 6),
                      Text('View Stats'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 6),
                      Text('Delete User'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: Use real Firebase service for actions
  void _handleMenuAction(String action, AppUser user) {
    final dataService = ServiceProvider.getDataService();
    
    switch (action) {
      case 'toggle':
        dataService.toggleUserStatus(user.username, !user.isActive);
        setState(() {
          // Update local state to reflect the change immediately
          final userIndex = _allUsers.indexWhere((u) => u.username == user.username);
          if (userIndex != -1) {
            _allUsers[userIndex] = AppUser(
              username: user.username,
              journeyCount: user.journeyCount,
              lastLogin: user.lastLogin,
              isActive: !user.isActive,
            );
          }
        });
        break;
      case 'stats':
        _showUserDetails(user);
        break;
      case 'delete':
        _showDeleteDialog(user);
        break;
    }
  }

  void _showUserDetails(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2d2d44),
        title: Text('User Details', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Username', user.username),
            _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive',
                valueColor: user.isActive ? Colors.green : Colors.red),
            _buildDetailRow('Total Journeys', user.journeyCount.toString()),
            _buildDetailRow('Last Login', _formatDate(user.lastLogin)),
            _buildDetailRow('Account Age', 
                '${DateTime.now().difference(user.lastLogin).inDays} days'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Use real Firebase service for delete
  void _showDeleteDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2d2d44),
        title: Text('Delete User', style: TextStyle(color: Colors.red)),
        content: Text(
          'Are you sure you want to delete "${user.username}"? This will remove all their data including ${user.journeyCount} journeys.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              // Use real Firebase service
              ServiceProvider.getDataService().deleteUser(user.username);
              
              setState(() {
                _allUsers.removeWhere((u) => u.username == user.username);
                _filteredUsers.removeWhere((u) => u.username == user.username);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User "${user.username}" deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}