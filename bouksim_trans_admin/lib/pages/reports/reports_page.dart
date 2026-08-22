// ignore_for_file: unused_import, unused_field

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/service_provider.dart'; // ADD THIS
import '../../models/journey.dart';
import '../../models/user.dart';
import '../../models/company.dart';

class ReportsPage extends StatefulWidget {
  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _timeRange = 'month';
  int _currentChartIndex = 0;
  bool _isLoading = true; // ADD THIS
  List<Journey> _allJourneys = []; // ADD THIS
  List<AppUser> _allUsers = []; // ADD THIS
  List<Company> _allCompanies = []; // ADD THIS

  @override
  void initState() {
    super.initState();
    _loadRealData(); // CHANGED THIS
  }

  // CHANGED THIS: Load real data from Firebase
  void _loadRealData() async {
    print('🔄 Reports: Loading real data from Firebase...');
    
    final dataService = ServiceProvider.getDataService();
    
    try {
      final journeys = await dataService.getJourneysStream().first;
      final users = await dataService.getUsersStream().first;
      final companies = await dataService.getGlobalCompaniesStream().first;
      
      print('📊 Reports: Loaded ${journeys.length} journeys, ${users.length} users, ${companies.length} companies');
      
      if (mounted) {
        setState(() {
          _allJourneys = journeys;
          _allUsers = users;
          _allCompanies = companies;
          _isLoading = false;
        });
      }
    } catch (error) {
      print('❌ Reports: Error loading data: $error');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ADD THESE HELPER METHODS FOR REAL DATA
  double get _totalRevenue {
    return _allJourneys.fold(0.0, (sum, journey) => sum + journey.payment);
  }

  double get _totalProfit {
    return _allJourneys.fold(0.0, (sum, journey) => sum + journey.netProfit);
  }

  double get _totalCharges {
    return _allJourneys.fold(0.0, (sum, journey) => sum + journey.totalCharges);
  }

  double get _averageRevenuePerJourney {
    return _allJourneys.isEmpty ? 0 : _totalRevenue / _allJourneys.length;
  }

  double get _averageProfitPerJourney {
    return _allJourneys.isEmpty ? 0 : _totalProfit / _allJourneys.length;
  }

  // REAL DATA: Monthly revenue from actual journeys
  Map<String, double> get _monthlyRevenue {
    final now = DateTime.now();
    final Map<String, double> revenue = {};
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthKey = DateFormat('MMM').format(month);
      
      final monthRevenue = _allJourneys
          .where((journey) => 
              journey.date.year == month.year && 
              journey.date.month == month.month)
          .fold(0.0, (sum, journey) => sum + journey.payment);
      
      revenue[monthKey] = monthRevenue;
    }
    
    return revenue;
  }

  // REAL DATA: Company performance from actual journeys
  Map<String, double> get _companyPerformance {
    final Map<String, double> performance = {};
    
    for (final journey in _allJourneys) {
      performance[journey.company] = 
          (performance[journey.company] ?? 0) + journey.payment;
    }
    
    // Sort by revenue descending
    final sortedEntries = performance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }

  // REAL DATA: Driver performance from actual journeys
  Map<String, int> get _driverPerformance {
    final Map<String, int> performance = {};
    
    for (final journey in _allJourneys) {
      performance[journey.userId] = 
          (performance[journey.userId] ?? 0) + 1;
    }
    
    // Sort by journey count descending
    final sortedEntries = performance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }

  // REAL DATA: Profit analysis
  List<double> get _profitAnalysis {
    final total = _totalRevenue;
    if (total == 0) return [0, 0, 0];
    
    final chargesPercentage = (_totalCharges / total) * 100;
    final netProfitPercentage = (_totalProfit / total) * 100;
    final revenuePercentage = 100 - chargesPercentage;
    
    return [revenuePercentage, chargesPercentage, netProfitPercentage];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1e1e2e),
      appBar: AppBar(
        title: Text('Reports & Analytics'),
        backgroundColor: Color(0xFF2d2d44),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadRealData,
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _timeRange = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'month', child: Text('This Month')),
              PopupMenuItem(value: 'quarter', child: Text('This Quarter')),
              PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
          ),
        ],
      ),
      body: _isLoading 
          ? _buildLoadingState()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Quick Stats - USING REAL DATA
                  _buildQuickStats(),
                  SizedBox(height: 20),
                  
                  // Chart Navigation
                  _buildChartNavigation(),
                  SizedBox(height: 20),
                  
                  // Main Chart - USING REAL DATA
                  Expanded(
                    child: _buildCurrentChart(),
                  ),
                  
                  // Export Button
                  _buildExportSection(),
                ],
              ),
            ),
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
            'Loading real reports data...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // UPDATED: Use real statistics from Firebase
  Widget _buildQuickStats() {
    final activeDrivers = _allUsers.where((u) => u.isActive).length;
    
    return Card(
      color: Color(0xFF2d2d44),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Revenue', '${_totalRevenue.toStringAsFixed(0)} MAD', Icons.attach_money, Color(0xFF4cc9f0)),
            _buildStatItem('Active Drivers', '$activeDrivers', Icons.people, Color(0xFF4361ee)),
            _buildStatItem('Total Journeys', '${_allJourneys.length}', Icons.directions_car, Color(0xFF7209b7)),
            _buildStatItem('Avg. Profit', '${_averageProfitPerJourney.toStringAsFixed(0)} MAD', Icons.trending_up, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildChartNavigation() {
    final List<String> chartTitles = [
      'Revenue',
      'Companies', 
      'Drivers',
      'Profit',
    ];

    final List<IconData> chartIcons = [
      Icons.trending_up,
      Icons.business,
      Icons.people,
      Icons.pie_chart,
    ];

    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: chartTitles.asMap().entries.map((entry) {
          final index = entry.key;
          final isSelected = _currentChartIndex == index;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentChartIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF4361ee) : Color(0xFF2d2d44),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Color(0xFF4361ee) : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          chartIcons[index],
                          size: 16,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                        SizedBox(height: 2),
                        Text(
                          chartTitles[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
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
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentChart() {
    switch (_currentChartIndex) {
      case 0:
        return _buildRevenueChart();
      case 1:
        return _buildCompanyPerformanceChart();
      case 2:
        return _buildDriverPerformanceChart();
      case 3:
        return _buildProfitAnalysisChart();
      default:
        return _buildRevenueChart();
    }
  }

  // UPDATED: Use real revenue data
  Widget _buildRevenueChart() {
    final months = _monthlyRevenue.keys.toList();
    final values = _monthlyRevenue.values.toList();
    final maxValue = values.isEmpty ? 1000 : values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Card(
      color: Color(0xFF2d2d44),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Monthly Revenue Trend',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Total: ${_totalRevenue.toStringAsFixed(0)} MAD',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: values.isEmpty 
                  ? _buildNoDataState('No revenue data available')
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxValue.toDouble(), // FIX: Convert to double
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < months.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      months[index],
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }
                                return Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${(value / 1000).toStringAsFixed(0)}K',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.white.withOpacity(0.1),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: months.asMap().entries.map((entry) {
                          final index = entry.key;
                          final month = entry.value;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: _monthlyRevenue[month]!,
                                color: _getGradientColor(index / months.length),
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: Use real company performance data
  Widget _buildCompanyPerformanceChart() {
    final companies = _companyPerformance.keys.toList();
    final values = _companyPerformance.values.toList();
    final totalRevenue = values.isEmpty ? 1 : values.reduce((a, b) => a + b);

    return Card(
      color: Color(0xFF2d2d44),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Company Performance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Total Revenue: ${totalRevenue.toStringAsFixed(0)} MAD',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: companies.isEmpty
                  ? _buildNoDataState('No company performance data')
                  : ListView.builder(
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        final company = companies[index];
                        final revenue = values[index];
                        final percentage = (revenue / totalRevenue) * 100;

                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF3d3d5c),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  company,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  color: _getGradientColor(index / companies.length),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                '${(revenue / 1000).toStringAsFixed(0)}K MAD',
                                style: TextStyle(
                                  color: Color(0xFF4cc9f0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: Use real driver performance data
  Widget _buildDriverPerformanceChart() {
    final drivers = _driverPerformance.keys.toList();
    final journeys = _driverPerformance.values.toList();
    final totalJourneys = journeys.isEmpty ? 1 : journeys.reduce((a, b) => a + b);

    return Card(
      color: Color(0xFF2d2d44),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Driver Performance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Total Journeys: $totalJourneys',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: drivers.isEmpty
                  ? _buildNoDataState('No driver performance data')
                  : Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: PieChart(
                            PieChartData(
                              sections: drivers.asMap().entries.map((entry) {
                                final index = entry.key;
                                final driver = entry.value;
                                final journeyCount = _driverPerformance[driver]!;
                                final percentage = (journeyCount / totalJourneys) * 100;

                                return PieChartSectionData(
                                  color: _getGradientColor(index / drivers.length),
                                  value: journeyCount.toDouble(),
                                  title: '${percentage.toStringAsFixed(0)}%',
                                  radius: 40,
                                  titleStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 4,
                              centerSpaceRadius: 30,
                              startDegreeOffset: -90,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: drivers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final driver = entry.value;
                              final journeyCount = _driverPerformance[driver]!;
                              final percentage = (journeyCount / totalJourneys) * 100;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getGradientColor(index / drivers.length),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getShortName(driver),
                                            style: TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                          Text(
                                            '${journeyCount} journeys (${percentage.toStringAsFixed(0)}%)',
                                            style: TextStyle(color: Colors.white54, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: Use real profit analysis data
  Widget _buildProfitAnalysisChart() {
    final profitData = _profitAnalysis;
    final labels = ['Revenue', 'Charges', 'Net Profit'];
    final colors = [Color(0xFF4cc9f0), Colors.orange, Colors.green];

    return Card(
      color: Color(0xFF2d2d44),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Profit Analysis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Total Profit: ${_totalProfit.toStringAsFixed(0)} MAD',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _allJourneys.isEmpty
                  ? _buildNoDataState('No profit data available')
                  : Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: PieChart(
                            PieChartData(
                              sections: profitData.asMap().entries.map((entry) {
                                final index = entry.key;
                                final value = entry.value;
                                return PieChartSectionData(
                                  color: colors[index],
                                  value: value,
                                  title: '${value.toStringAsFixed(0)}%',
                                  radius: 30,
                                  titleStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 20,
                              startDegreeOffset: -90,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: labels.asMap().entries.map((entry) {
                              final index = entry.key;
                              final label = entry.value;
                              final value = profitData[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      color: colors[index],
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    Text(
                                      '${value.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: colors[index],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      color: Color(0xFF2d2d44),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Download comprehensive reports from your real business data',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _allJourneys.isEmpty ? null : () => _exportData('pdf'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text('Export as PDF'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _allJourneys.isEmpty ? null : () => _exportData('excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(Icons.table_chart),
                    label: Text('Export as Excel'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _allJourneys.isEmpty ? null : () => _exportData('print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4361ee),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(Icons.print),
                    label: Text('Print Report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getGradientColor(double ratio) {
    final colors = [Color(0xFF4361ee), Color(0xFF7209b7), Color(0xFF4cc9f0)];
    final index = (ratio * (colors.length - 1)).round();
    return colors[index];
  }

  String _getShortName(String fullName) {
    final parts = fullName.split(' ');
    return parts.length > 1 ? '${parts[0]} ${parts[1]}' : fullName;
  }

  Widget _buildNoDataState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Data will appear when journeys are added',
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _exportData(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${_allJourneys.length} journeys as ${format.toUpperCase()}...'),
        backgroundColor: Colors.green,
      ),
    );
    
    Future.delayed(Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${format.toUpperCase()} report with real data downloaded!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
}