// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/service_provider.dart'; // ADD THIS
import '../../models/journey.dart';

class AllJourneysPage extends StatefulWidget {
  @override
  _AllJourneysPageState createState() => _AllJourneysPageState();
}

class _AllJourneysPageState extends State<AllJourneysPage> {
  String _filterDriver = 'all';
  String _filterCompany = 'all';
  String _filterDate = 'all';
  String _sortBy = 'date';
  String _searchQuery = '';
  bool _sortAscending = false;
  List<Journey> _filteredJourneys = [];
  List<Journey> _allJourneys = []; // ADD THIS - stores all journeys from Firebase
  bool _isLoading = true; // ADD THIS - loading state

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection(); // Add this temporary test
    _loadRealData(); // REPLACED: _filteredJourneys = MockDataService.mockJourneys;
    // Add timeout to prevent infinite loading
  Future.delayed(Duration(seconds: 5), () {
    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Timeout: Could not load journeys from Firebase'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  });
  }

// TEMPORARY: Test Firebase connection directly
void _testFirebaseConnection() async {
  try {
    print('🧪 Testing Firebase connection...');
    
    // Test if we can reach Firebase
    final response = await http.get(
      Uri.parse('https://firestore.googleapis.com/v1/projects/bouksim-trans-app/databases/(default)/documents/users_data?key=AIzaSyCpkRn2N6x4DUSnl7S6eOxNTv4CLlLJcP0'),
    );
    
    print('📡 Firebase HTTP Status: ${response.statusCode}');
    print('📦 Firebase Response: ${response.body}');
    
    if (response.statusCode == 200) {
      print('✅ Firebase connection successful!');
    } else {
      print('❌ Firebase connection failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Firebase connection error: $e');
  }
}

  // UPDATED: Load real data from Firebase with better error handling
void _loadRealData() {
  final dataService = ServiceProvider.getDataService();
  
  print('🔄 Starting to load journeys from Firebase...');
  
  dataService.getJourneysStream().listen((journeys) {
    print('✅ Successfully loaded ${journeys.length} journeys from Firebase');
    
    if (mounted) {
      setState(() {
        _allJourneys = journeys;
        _filteredJourneys = journeys;
        _isLoading = false;
      });
    }
  }, onError: (error) {
    print('❌ Error loading journeys: $error');
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    // Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to load journeys: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }, onDone: () {
    print('🎯 Journey stream completed');
  });
}

  List<Journey> get _currentJourneys {
    List<Journey> journeys = List.from(_filteredJourneys);

    // Apply filters
    if (_filterDriver != 'all') {
      journeys = journeys.where((j) => j.userId == _filterDriver).toList();
    }
    if (_filterCompany != 'all') {
      journeys = journeys.where((j) => j.company == _filterCompany).toList();
    }
    if (_filterDate != 'all') {
      final now = DateTime.now();
      switch (_filterDate) {
        case 'today':
          journeys = journeys.where((j) => 
            j.date.year == now.year && 
            j.date.month == now.month && 
            j.date.day == now.day).toList();
          break;
        case 'week':
          final weekAgo = now.subtract(Duration(days: 7));
          journeys = journeys.where((j) => j.date.isAfter(weekAgo)).toList();
          break;
        case 'month':
          final monthAgo = now.subtract(Duration(days: 30));
          journeys = journeys.where((j) => j.date.isAfter(monthAgo)).toList();
          break;
      }
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      journeys = journeys.where((j) {
        return j.startCity.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               j.endCity.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               j.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               j.plateNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               j.cargoType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               j.bonDeLivraison.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply sorting
    journeys.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'payment':
          comparison = a.payment.compareTo(b.payment);
          break;
        case 'profit':
          comparison = a.netProfit.compareTo(b.netProfit);
          break;
        case 'driver':
          comparison = a.userId.compareTo(b.userId);
          break;
        case 'company':
          comparison = a.company.compareTo(b.company);
          break;
        case 'route':
          comparison = '${a.startCity}${a.endCity}'.compareTo('${b.startCity}${b.endCity}');
          break;
        default:
          comparison = a.date.compareTo(b.date);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return journeys;
  }

  // UPDATED: Get drivers from real data
  List<String> get _availableDrivers {
    return _allJourneys.map((j) => j.userId).toSet().toList();
  }

  // UPDATED: Get companies from real data
  List<String> get _availableCompanies {
    return _allJourneys.map((j) => j.company).toSet().toList();
  }

  // UPDATED: Refresh method for real data
  void _forceRefresh() {
    setState(() {
      _isLoading = true;
      _filteredJourneys = [];
    });
    
    _loadRealData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Refreshing data from Firebase...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showJourneyStats() {
  final journeys = _currentJourneys;
  final totalRevenue = journeys.fold(0.0, (sum, j) => sum + j.payment);
  final totalProfit = journeys.fold(0.0, (sum, j) => sum + j.netProfit);
  final profitableJourneys = journeys.where((j) => j.netProfit > 0).length;
  final avgRevenue = journeys.isNotEmpty ? totalRevenue / journeys.length : 0;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Color(0xFF2d2d44),
      title: Text('Journey Statistics', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow('Total Journeys', journeys.length.toString()),
          _buildStatRow('Total Revenue', '${totalRevenue.toStringAsFixed(0)} MAD'),
          _buildStatRow('Total Profit', '${totalProfit.toStringAsFixed(0)} MAD'),
          _buildStatRow('Avg Revenue/Journey', '${avgRevenue.toStringAsFixed(0)} MAD'),
          _buildStatRow('Profitable Journeys', '$profitableJourneys (${journeys.isNotEmpty ? (profitableJourneys / journeys.length * 100).toStringAsFixed(0) : 0}%)'),
          SizedBox(height: 16),
          Text('Top Drivers:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ..._getTopDrivers().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('• ${entry.key}: ${entry.value} journeys', style: TextStyle(color: Colors.white70)),
          )),
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

  Map<String, int> _getTopDrivers() {
  final driverCounts = <String, int>{};
  for (final journey in _currentJourneys) {
    driverCounts[journey.userId] = (driverCounts[journey.userId] ?? 0) + 1;
  }
  
  // Sort by journey count descending and take top 3
  final sortedDrivers = driverCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  return Map.fromEntries(sortedDrivers.take(3));
}

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

    // ADD LOADING STATE
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF1e1e2e),
        appBar: AppBar(
          title: Text('All Journeys Explorer'),
          backgroundColor: Color(0xFF2d2d44),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading journeys from Firebase...', 
                   style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    final journeys = _currentJourneys;
    final totalRevenue = journeys.fold(0.0, (sum, j) => sum + j.payment);
    final totalProfit = journeys.fold(0.0, (sum, j) => sum + j.netProfit);

    return Scaffold(
      backgroundColor: Color(0xFF1e1e2e),
      appBar: AppBar(
  title: Text('All Journeys Explorer'),
  backgroundColor: Color(0xFF2d2d44),
  elevation: 0,
  actions: [
    IconButton(
      icon: Icon(Icons.bar_chart),
      onPressed: _showJourneyStats,
      tooltip: 'View Statistics',
    ),
    // UPDATED: Use real refresh method
    IconButton(
      icon: Icon(Icons.refresh),
            onPressed: _forceRefresh,
            tooltip: 'Refresh Data',
    ),
  ],
),
      


      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Filters Bar
          _buildFiltersBar(),
          
          // Quick Stats
          _buildQuickStats(journeys, totalRevenue, totalProfit),
          
          // Journeys List
          Expanded(
            child: journeys.isEmpty
                ? _buildEmptyState()
                : _buildJourneysList(journeys),
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by route, company, plate, cargo...',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF4361ee)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color(0xFF3d3d5c),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF4361ee),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_currentJourneys.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Card(
      color: Color(0xFF2d2d44),
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // First row of filters
            Row(
              children: [
                _buildFilterDropdown('Driver', _filterDriver, _availableDrivers, (value) {
                  setState(() => _filterDriver = value!);
                }),
                SizedBox(width: 12),
                _buildFilterDropdown('Company', _filterCompany, _availableCompanies, (value) {
                  setState(() => _filterCompany = value!);
                }),
                SizedBox(width: 12),
                _buildFilterDropdown('Date', _filterDate, ['all', 'today', 'week', 'month'], (value) {
                  setState(() => _filterDate = value!);
                }),
              ],
            ),
            SizedBox(height: 12),
            // Second row - sort options
            Row(
              children: [
                _buildFilterDropdown('Sort By', _sortBy, 
                  ['date', 'payment', 'profit', 'driver', 'company', 'route'], (value) {
                  setState(() => _sortBy = value!);
                }),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _sortAscending = !_sortAscending);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Color(0xFF4361ee)),
                    ),
                    icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                    label: Text(_sortAscending ? 'Ascending' : 'Descending'),
                  ),
                ),
                SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.red),
                  ),
                  icon: Icon(Icons.clear, size: 16),
                  label: Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
          SizedBox(height: 4),
          Container(
            height: 36,
            child: DropdownButtonFormField<String>(
              value: value,
              dropdownColor: Color(0xFF2d2d44),
              style: TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Color(0xFF4361ee)),
                ),
                filled: true,
                fillColor: Color(0xFF3d3d5c),
              ),
              items: [
                DropdownMenuItem(value: 'all', child: Text('All ${label.toLowerCase()}s')),
                ...options.where((opt) => opt != 'all').map((option) => 
                  DropdownMenuItem(value: option, child: Text(option))
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filterDriver = 'all';
      _filterCompany = 'all';
      _filterDate = 'all';
      _searchQuery = '';
      _sortBy = 'date';
      _sortAscending = false;
    });
  }

  Widget _buildQuickStats(List<Journey> journeys, double totalRevenue, double totalProfit) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Color(0xFF2d2d44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStatItem('Journeys', journeys.length.toString()),
          _buildQuickStatItem('Revenue', '${totalRevenue.toStringAsFixed(0)} MAD'),
          _buildQuickStatItem('Profit', '${totalProfit.toStringAsFixed(0)} MAD'),
          _buildQuickStatItem('Avg', '${journeys.isNotEmpty ? (totalRevenue / journeys.length).toStringAsFixed(0) : 0} MAD'),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty && _filterDriver == 'all' && _filterCompany == 'all'
                ? 'No journeys recorded yet'
                : 'No journeys match your criteria',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty && _filterDriver == 'all' && _filterCompany == 'all'
                ? 'Journeys will appear here when drivers add them'
                : 'Try adjusting your filters or search',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty || _filterDriver != 'all' || _filterCompany != 'all') ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4361ee),
              ),
              child: Text('Clear All Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJourneysList(List<Journey> journeys) {
    return ListView.builder(
      itemCount: journeys.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final journey = journeys[index];
        return _buildJourneyCard(journey);
      },
    );
  }

  Widget _buildJourneyCard(Journey journey) {
    return Card(
      color: Color(0xFF2d2d44),
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: Color(0xFF4361ee),
          radius: 16,
          child: Icon(Icons.directions_car, color: Colors.white, size: 16),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${journey.startCity} → ${journey.endCity}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: journey.netProfit >= 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: journey.netProfit >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    '${journey.netProfit.toStringAsFixed(0)} MAD',
                    style: TextStyle(
                      color: journey.netProfit >= 0 ? Colors.green : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              '${journey.company} • ${journey.plateNumber}',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 10, color: Colors.white54),
                SizedBox(width: 2),
                Expanded(
                  child: Text(
                    journey.userId,
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 10, color: Colors.white54),
                SizedBox(width: 2),
                Text(
                  DateFormat('dd/MM/yy').format(journey.date),
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.attach_money, size: 10, color: Colors.white54),
                SizedBox(width: 2),
                Text(
                  '${journey.payment} MAD',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
                SizedBox(width: 8),
                Icon(Icons.local_shipping, size: 10, color: Colors.white54),
                SizedBox(width: 2),
                Text(
                  '${journey.cargoWeight} kg • ${journey.cargoType}',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            if (journey.bonDeLivraison.isNotEmpty) ...[
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.description, size: 10, color: Color(0xFF4cc9f0)),
                  SizedBox(width: 2),
                  Text(
                    'BL: ${journey.bonDeLivraison}',
                    style: TextStyle(color: Color(0xFF4cc9f0), fontSize: 10),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white70, size: 16),
          onSelected: (value) => _handleMenuAction(value, journey),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 14, color: Color(0xFF4361ee)),
                  SizedBox(width: 6),
                  Text('View Details'),
                ],
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 14, color: Colors.red),
                  SizedBox(width: 6),
                  Text('Delete Journey'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Journey journey) {
    switch (action) {
      case 'view':
        _showJourneyDetails(journey);
        break;
      case 'delete':
        _deleteJourney(journey);
        break;
    }
  }

  void _showJourneyDetails(Journey journey) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Color(0xFF2d2d44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF4361ee).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.directions_car, color: Color(0xFF4361ee), size: 28),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Journey Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${journey.startCity} → ${journey.endCity}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Main Information Cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - Journey Info
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Route Card
                        _buildInfoCard(
                          icon: Icons.route,
                          title: 'Route Information',
                          children: [
                            _buildInfoItem('Start City', journey.startCity),
                            _buildInfoItem('End City', journey.endCity),
                            _buildInfoItem('Distance', 'Approx. 300 km'),
                            _buildInfoItem('Travel Date', DateFormat('dd MMM yyyy').format(journey.date)),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Vehicle & Cargo Card
                        _buildInfoCard(
                          icon: Icons.local_shipping,
                          title: 'Vehicle & Cargo',
                          children: [
                            _buildInfoItem('Plate Number', journey.plateNumber),
                            _buildInfoItem('Cargo Type', journey.cargoType),
                            _buildInfoItem('Cargo Weight', '${journey.cargoWeight} kg'),
                            if (journey.bonDeLivraison.isNotEmpty)
                              _buildInfoItem('Delivery Note', journey.bonDeLivraison,
                                valueColor: Color(0xFF4cc9f0)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Right Column - Financial & Company
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Financial Card
                        _buildInfoCard(
                          icon: Icons.attach_money,
                          title: 'Financial Summary',
                          children: [
                            _buildInfoItem('Total Payment', '${journey.payment} MAD',
                              valueStyle: TextStyle(
                                color: Color(0xFF4cc9f0),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                            _buildInfoItem('Total Charges', '${journey.totalCharges} MAD',
                              valueStyle: TextStyle(color: Colors.orange)),
                            Divider(color: Colors.white24, height: 20),
                            _buildInfoItem('Net Profit', '${journey.netProfit} MAD',
                              valueStyle: TextStyle(
                                color: journey.netProfit >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              )),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: journey.netProfit >= 0 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: journey.netProfit >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    journey.netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                                    color: journey.netProfit >= 0 ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    journey.netProfit >= 0 ? 'Profitable Journey' : 'Loss Journey',
                                    style: TextStyle(
                                      color: journey.netProfit >= 0 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Company & Driver Card
                        _buildInfoCard(
                          icon: Icons.business,
                          title: 'Company & Driver',
                          children: [
                            _buildInfoItem('Transport Company', journey.company),
                            _buildInfoItem('Driver', journey.userId,
                              valueStyle: TextStyle(
                                color: Color(0xFF4361ee),
                                fontWeight: FontWeight.w600,
                              )),
                            _buildInfoItem('Journey ID', 'J${journey.date.millisecondsSinceEpoch}',
                              valueStyle: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Charges Breakdown (if any)
              if (journey.charges.isNotEmpty) 
                _buildInfoCard(
                  icon: Icons.receipt,
                  title: 'Charges Breakdown',
                  children: [
                    Column(
                      children: journey.charges.map((charge) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(Icons.arrow_forward, size: 12, color: Colors.orange),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    charge.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${charge.amount} MAD',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    Divider(color: Colors.white24, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Charges',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${journey.totalCharges} MAD',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              
              SizedBox(height: 24),
              
              // Action Buttons
              Container(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white24),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: Icon(Icons.close, size: 18),
                        label: Text('Close Details'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close details first
                          _deleteJourney(journey); // Show delete confirmation
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.9),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: Icon(Icons.delete, size: 18),
                        label: Text('Delete Journey'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildInfoCard({
  required IconData icon,
  required String title,
  required List<Widget> children,
}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Color(0xFF3d3d5c),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(0xFF4361ee).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Color(0xFF4361ee), size: 18),
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        // Card Content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ],
    ),
  );
}

Widget _buildInfoItem(String label, String value, {
  TextStyle? valueStyle,
  Color? valueColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: valueStyle ?? TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(child: Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 12))),
        ],
      ),
    );
  }

  void _deleteJourney(Journey journey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2d2d44),
        title: Text('Delete Journey', style: TextStyle(color: Colors.red)),
        content: Text(
          'Are you sure you want to delete this journey from ${journey.startCity} to ${journey.endCity}?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              // UPDATED: Use service provider instead of mock data
              ServiceProvider.getDataService().deleteJourney(journey);
              
              setState(() {
                _filteredJourneys.remove(journey);
                _allJourneys.remove(journey);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Journey deleted successfully'),
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
}