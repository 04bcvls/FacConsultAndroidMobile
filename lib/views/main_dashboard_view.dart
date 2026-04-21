import 'package:flutter/material.dart';
import 'package:andfacconsult/models/faculty.dart';
import 'package:andfacconsult/models/department.dart';
import 'package:andfacconsult/services/firestore_faculty_service.dart';
import 'package:andfacconsult/services/firestore_department_service.dart';
import 'package:andfacconsult/utils/logger.dart' as logger_util;
import 'package:andfacconsult/utils/responsive.dart';
import 'package:andfacconsult/views/faculty_details_view.dart';

class MainDashboardView extends StatefulWidget {
  const MainDashboardView({Key? key}) : super(key: key);

  @override
  State<MainDashboardView> createState() => _MainDashboardViewState();
}

class _MainDashboardViewState extends State<MainDashboardView> {
  late FirestoreFacultyService _facultyService;
  late FirestoreDepartmentService _departmentService;
  late Stream<List<Faculty>> _facultyStream;
  late TextEditingController _searchController;
  String _searchQuery = '';
  String? _selectedDepartmentId; // null = all departments
  List<Department> _departments = [];
  bool _isLoadingDepartments = true;
  String _departmentSearchQuery = ''; // Search within filter

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _facultyService = FirestoreFacultyService();
    _departmentService = FirestoreDepartmentService();
    _facultyStream = _facultyService.getFacultyStream();
    _loadDepartments();
  }

  /// Load all departments
  Future<void> _loadDepartments() async {
    try {
      final departments = await _departmentService.getAllDepartments();
      setState(() {
        _departments = departments;
        _isLoadingDepartments = false;
      });
    } catch (e) {
      logger_util.logError('Error loading departments: $e');
      setState(() {
        _isLoadingDepartments = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    return RefreshIndicator(
      onRefresh: _refreshFaculty,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium()),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            SizedBox(height: ResponsiveSize.spacing24()),

            // Search Bar and Filter Button
            Row(
              children: [
                Expanded(
                  child: _buildSearchBar(),
                ),
                const SizedBox(width: 12),
                _buildFilterButton(),
              ],
            ),
            SizedBox(height: ResponsiveSize.spacing12()),

            // Active filter display
            if (_selectedDepartmentId != null && _selectedDepartmentId!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Department: ${_departments.firstWhere((d) => d.id == _selectedDepartmentId, orElse: () => Department(id: '', name: '')).name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SizedBox(height: ResponsiveSize.spacing16()),

            // Faculty List
            _buildFacultyList(),

            // Extra padding at bottom
            SizedBox(height: ResponsiveSize.spacing40()),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshFaculty() async {
    try {
      // Refresh the faculty stream
      _facultyStream = _facultyService.getFacultyStream();
      // Refresh departments as well
      await _loadDepartments();
      // Reset department search query
      _departmentSearchQuery = '';
      setState(() {});
    } catch (e) {
      logger_util.logError('Error refreshing faculty: $e');
    }
  }

  /// Build header
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Directory',
          style: TextStyle(
            fontSize: ResponsiveSize.fontLargeHeading(),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: ResponsiveSize.spacing8()),
        Text(
          'Browse and schedule consultations',
          style: TextStyle(
            fontSize: ResponsiveSize.fontSubtitle(),
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search faculty by name or department',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, color: Colors.grey[600]),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
        filled: true,
        fillColor: Colors.white.withValues(alpha:0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  /// Build filter button with badge
  Widget _buildFilterButton() {
    final hasActiveFilter = _selectedDepartmentId != null && _selectedDepartmentId!.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: hasActiveFilter 
            ? const Color(0xFF1F41BB)
            : Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActiveFilter
              ? const Color(0xFF1F41BB)
              : Colors.grey[300] ?? Colors.grey,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showFilterBottomSheet,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Stack(
              children: [
                Icon(
                  Icons.filter_list,
                  color: hasActiveFilter ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
                if (hasActiveFilter)
                  Positioned(
                    top: -3,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '•',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

  /// Show filter bottom sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterBottomSheetContent(),
    );
  }

  /// Build filter bottom sheet content
  Widget _buildFilterBottomSheetContent() {
    final filteredDepartments = _departmentSearchQuery.isEmpty
        ? _departments
        : _departments
            .where((dept) => dept.name
                .toLowerCase()
                .contains(_departmentSearchQuery.toLowerCase()))
            .toList();

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter by Department',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field for departments
            TextField(
              onChanged: (value) {
                setState(() {
                  _departmentSearchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search departments...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _departmentSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _departmentSearchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20),

            // Department list
            if (_isLoadingDepartments)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filteredDepartments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _departmentSearchQuery.isEmpty
                        ? 'No departments available'
                        : 'No departments match your search',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else ...[
              // All Departments option
              _buildDepartmentOption(
                name: 'All Departments',
                id: null,
                isSelected: _selectedDepartmentId == null ||
                    _selectedDepartmentId!.isEmpty,
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),

              // Department list items
              ...filteredDepartments.map((department) {
                final isSelected = _selectedDepartmentId == department.id;
                return Column(
                  children: [
                    _buildDepartmentOption(
                      name: department.name,
                      id: department.id,
                      isSelected: isSelected,
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ],

            const SizedBox(height: 16),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F41BB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Done',
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
    );
  }

  /// Build individual department option
  Widget _buildDepartmentOption({
    required String name,
    required String? id,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected ? const Color(0xFF1F41BB).withValues(alpha:0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDepartmentId = id;
          });
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? const Color(0xFF1F41BB) : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF1F41BB),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build faculty list
  Widget _buildFacultyList() {
    return StreamBuilder<List<Faculty>>(
      stream: _facultyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          logger_util.logError('Error loading faculty: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading faculty',
                style: TextStyle(color: Colors.grey[300]),
              ),
            ),
          );
        }

        final allFaculty = snapshot.data ?? [];
        
        // Filter faculty based on search query and department
        List<Faculty> filteredFaculty = allFaculty;
        
        // Apply department filter
        if (_selectedDepartmentId != null && _selectedDepartmentId!.isNotEmpty) {
          filteredFaculty = filteredFaculty
              .where((faculty) => faculty.departmentId == _selectedDepartmentId)
              .toList();
        }
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          filteredFaculty = filteredFaculty
              .where((faculty) =>
                  faculty.fullName.toLowerCase().contains(_searchQuery) ||
                  (faculty.departmentName?.toLowerCase().contains(_searchQuery) ?? false))
              .toList();
        }

        if (filteredFaculty.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _searchQuery.isEmpty && _selectedDepartmentId == null
                    ? 'No faculty members available'
                    : 'No faculty members match your filters',
                style: TextStyle(color: Colors.grey[300]),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Faculty (${filteredFaculty.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredFaculty.length,
              itemBuilder: (context, index) {
                final faculty = filteredFaculty[index];
                return _buildFacultyCard(faculty: faculty);
              },
            ),
          ],
        );
      },
    );
  }

  /// Build individual faculty card
  Widget _buildFacultyCard({required Faculty faculty}) {
    final statusColor = _getStatusColor(faculty.availabilityStatus);
    final statusIcon = _getStatusIcon(faculty.availabilityStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withValues(alpha:0.95),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image, Name and Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: faculty.profileImageUrl != null &&
                          faculty.profileImageUrl!.isNotEmpty
                      ? Image.network(
                          faculty.profileImageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderAvatar(faculty);
                          },
                        )
                      : _buildPlaceholderAvatar(faculty),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faculty.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        faculty.departmentName ?? faculty.departmentId,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        faculty.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        faculty.availabilityStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // View Details button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FacultyDetailsView(faculty: faculty),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F41BB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build placeholder avatar with initials
  Widget _buildPlaceholderAvatar(Faculty faculty) {
    final initials =
        '${faculty.firstName[0]}${faculty.lastName[0]}'.toUpperCase();
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1F41BB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  /// Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'away':
        return Colors.red;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.check_circle;
      case 'busy':
        return Icons.schedule;
      case 'away':
        return Icons.location_off;
      case 'offline':
        return Icons.circle;
      default:
        return Icons.help;
    }
  }
}
