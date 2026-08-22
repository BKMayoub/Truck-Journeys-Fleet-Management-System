import 'package:flutter/material.dart';
import '../../services/service_provider.dart'; // ADD THIS
import '../../models/company.dart';

class GlobalCompaniesPage extends StatefulWidget {
  @override
  _GlobalCompaniesPageState createState() => _GlobalCompaniesPageState();
}

class _GlobalCompaniesPageState extends State<GlobalCompaniesPage> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _iceController = TextEditingController();
  
  bool _isEditing = false;
  bool _showForm = false;
  String _editingCompanyName = '';
  String _searchQuery = '';
  List<Company> _filteredCompanies = [];
  List<Company> _allCompanies = []; // ADD THIS
  bool _isLoading = true; // ADD THIS

  @override
  void initState() {
    super.initState();
    _loadRealCompanies(); // CHANGED THIS
    
    // ADD TIMEOUT
    Future.delayed(Duration(seconds: 30), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
        if (_allCompanies.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Still loading companies from Firebase...'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  // CHANGED THIS: Load real companies from Firebase
  void _loadRealCompanies() {
    print('🔄 Starting to load real companies from Firebase...');
    final dataService = ServiceProvider.getDataService();
    
    dataService.getGlobalCompaniesStream().listen((companies) {
      print('✅ Received ${companies.length} companies from Firebase');
      
      if (mounted) {
        setState(() {
          _allCompanies = companies;
          _filteredCompanies = companies;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print('❌ Error loading companies: $error');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading companies: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _refreshCompanies() {
    setState(() {
      _isLoading = true;
      _filteredCompanies = [];
    });
    _loadRealCompanies();
  }

  void _filterCompanies(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCompanies = _allCompanies; // CHANGED THIS
      } else {
        _filteredCompanies = _allCompanies.where((company) { // CHANGED THIS
          return company.name.toLowerCase().contains(query.toLowerCase()) ||
                 (company.address?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (company.ice?.contains(query) ?? false);
        }).toList();
      }
    });
  }

  // CHANGED THIS: Use real Firebase service
  void _addCompany() {
    final name = _companyNameController.text.trim();
    if (name.isNotEmpty) {
      final dataService = ServiceProvider.getDataService();
      
      dataService.addGlobalCompany(
        name,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        ice: _iceController.text.trim().isEmpty ? null : _iceController.text.trim(),
      ).then((_) {
        _clearForm();
        _showSuccessMessage('Company "$name" added successfully!');
      }).catchError((error) {
        _showErrorMessage('Failed to add company: $error');
      });
    }
  }

  // CHANGED THIS: Use real Firebase service
  void _updateCompany() {
    final newName = _companyNameController.text.trim();
    if (newName.isNotEmpty) {
      final dataService = ServiceProvider.getDataService();
      
      dataService.updateGlobalCompany(
        _editingCompanyName,
        newName,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        ice: _iceController.text.trim().isEmpty ? null : _iceController.text.trim(),
      ).then((_) {
        _clearForm();
        _showSuccessMessage('Company updated successfully!');
      }).catchError((error) {
        _showErrorMessage('Failed to update company: $error');
      });
    }
  }

  void _clearForm() {
    _companyNameController.clear();
    _addressController.clear();
    _iceController.clear();
    _isEditing = false;
    _editingCompanyName = '';
    _showForm = false;
    FocusScope.of(context).unfocus();
  }

  void _editCompany(Company company) {
    setState(() {
      _isEditing = true;
      _editingCompanyName = company.name;
      _companyNameController.text = company.name;
      _addressController.text = company.address ?? '';
      _iceController.text = company.ice ?? '';
      _showForm = true;
    });
  }

  // CHANGED THIS: Use real Firebase service
  void _deleteCompany(Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2d2d44),
        title: Text('Delete Company', style: TextStyle(color: Colors.red)),
        content: Text(
          'Are you sure you want to delete "${company.name}"? This company will be removed from the global list.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              final dataService = ServiceProvider.getDataService();
              
              dataService.deleteGlobalCompany(company.name).then((_) {
                Navigator.pop(context);
                _showSuccessMessage('Company "${company.name}" deleted');
              }).catchError((error) {
                Navigator.pop(context);
                _showErrorMessage('Failed to delete company: $error');
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // CHANGED THIS: Use real data for stats
  void _showCompanyStats() {
    final activeCompanies = _allCompanies.where((c) => c.isActive).length;
    final totalCompanies = _allCompanies.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2d2d44),
        title: Text('Companies Statistics', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Companies', totalCompanies.toString()),
            _buildStatRow('Active Companies', '$activeCompanies (${totalCompanies > 0 ? (activeCompanies / totalCompanies * 100).toStringAsFixed(0) : 0}%)'),
            _buildStatRow('Inactive Companies', '${totalCompanies - activeCompanies}'),
            SizedBox(height: 16),
            Text('Most Recent:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            ..._allCompanies
                .take(3)
                .map((company) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• ${company.name}', style: TextStyle(color: Colors.white70)),
                ))
                .toList(),
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
    return Scaffold(
      backgroundColor: Color(0xFF1e1e2e),
      appBar: AppBar(
        title: Text('Global Companies'),
        backgroundColor: Color(0xFF2d2d44),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: _showCompanyStats,
            tooltip: 'View Statistics',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshCompanies, // ADDED THIS
            tooltip: 'Refresh Companies',
          ),
          IconButton(
            icon: Icon(_showForm ? Icons.expand_less : Icons.expand_more),
            onPressed: () {
              setState(() {
                _showForm = !_showForm;
                if (!_showForm) _clearForm();
              });
            },
            tooltip: _showForm ? 'Hide Form' : 'Show Form',
          ),
        ],
      ),
      body: _isLoading 
          ? _buildLoadingState()
          : Column(
              children: [
                // Header with Stats
                _buildHeaderSection(),
                
                // Search Bar
                _buildSearchBar(),
                
                // Add/Edit Form (Collapsible)
                if (_showForm) _buildCompactForm(),
                
                // Companies List
                Expanded(
                  child: _filteredCompanies.isEmpty
                      ? _buildEmptyState()
                      : _buildCompaniesList(),
                ),
              ],
            ),
    );
  }

  // ADDED THIS: Loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4361ee)),
          SizedBox(height: 16),
          Text(
            'Loading companies from Firebase...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // CHANGED THIS: Use real data for header
  Widget _buildHeaderSection() {
    final activeCompanies = _allCompanies.where((c) => c.isActive).length;
    
    return Container(
      padding: EdgeInsets.all(16),
      color: Color(0xFF2d2d44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Global Companies Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Companies available to ALL drivers',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderStat('Total', _allCompanies.length.toString()),
              SizedBox(width: 12),
              _buildHeaderStat('Active', activeCompanies.toString()),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showForm = true;
                    _isEditing = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4361ee),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: Icon(Icons.add_business, size: 16),
                label: Text('Add Company'),
              ),
            ],
          ),
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
                  onChanged: _filterCompanies,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search companies by name, address, or ICE...',
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
                  '${_filteredCompanies.length}',
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

  Widget _buildCompactForm() {
    return Card(
      color: Color(0xFF2d2d44),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Header
            Row(
              children: [
                Icon(
                  _isEditing ? Icons.edit : Icons.add_business,
                  color: Color(0xFF4361ee),
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  _isEditing ? 'Editing Company' : 'Add New Company',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isEditing) ...[
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_editingCompanyName',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, size: 16),
                  onPressed: _clearForm,
                  tooltip: 'Close',
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Form Fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _companyNameController,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Company Name *',
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 10),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF4361ee)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Address',
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 10),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF4361ee)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _iceController,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'ICE',
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 10),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF4361ee)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: _isEditing ? _updateCompany : _addCompany,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEditing ? Colors.orange : Color(0xFF4361ee),
                      padding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      _isEditing ? 'Update' : 'Add',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_center, size: 64, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No companies in Firebase yet' : 'No companies found',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Add your first company to get started'
                : 'Try adjusting your search criteria',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showForm = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4361ee),
              ),
              icon: Icon(Icons.add_business),
              label: Text('Add First Company'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompaniesList() {
    return ListView.builder(
      itemCount: _filteredCompanies.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final company = _filteredCompanies[index];
        return _buildCompanyCard(company);
      },
    );
  }

  Widget _buildCompanyCard(Company company) {
    return Card(
      color: Color(0xFF2d2d44),
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: company.isActive ? Color(0xFF4361ee) : Colors.grey,
          radius: 16,
          child: Icon(Icons.business, color: Colors.white, size: 16),
        ),
        title: Text(
          company.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (company.address != null && company.address!.isNotEmpty) ...[
              SizedBox(height: 2),
              Text(
                company.address!,
                style: TextStyle(color: Colors.white70, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (company.ice != null && company.ice!.isNotEmpty) ...[
              SizedBox(height: 2),
              Text(
                'ICE: ${company.ice!}',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
            SizedBox(height: 2),
            Text(
              'Added: ${_formatDate(company.createdAt)}',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: company.isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: company.isActive ? Colors.green : Colors.red,
                ),
              ),
              child: Text(
                company.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: company.isActive ? Colors.green : Colors.red,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white70, size: 16),
              onSelected: (value) => _handleMenuAction(value, company),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: Color(0xFF4361ee)),
                      SizedBox(width: 6),
                      Text('Edit'),
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
                      Text('Delete'),
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

  void _handleMenuAction(String action, Company company) {
    switch (action) {
      case 'edit':
        _editCompany(company);
        break;
      case 'delete':
        _deleteCompany(company);
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}