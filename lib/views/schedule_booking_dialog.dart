import 'package:flutter/material.dart';
import 'package:andfacconsult/models/schedule.dart';
import 'package:andfacconsult/models/faculty.dart';
import 'package:andfacconsult/models/department.dart';
import 'package:andfacconsult/services/firestore_schedule_booking_service.dart';
import 'package:andfacconsult/services/firestore_department_service.dart';
import 'package:andfacconsult/utils/responsive.dart';
import 'package:andfacconsult/utils/logger.dart' as logger_util;

class ScheduleBookingDialog extends StatefulWidget {
  final Schedule schedule;
  final Faculty faculty;

  const ScheduleBookingDialog({
    Key? key,
    required this.schedule,
    required this.faculty,
  }) : super(key: key);

  @override
  State<ScheduleBookingDialog> createState() => _ScheduleBookingDialogState();
}

class _ScheduleBookingDialogState extends State<ScheduleBookingDialog> {
  late FirestoreScheduleBookingService _scheduleService;
  late FirestoreDepartmentService _departmentService;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _reasonController;
  
  List<Department> _departments = [];
  String? _selectedDepartmentId;
  bool _isLoading = false;
  bool _isLoadingDepartments = true;

  @override
  void initState() {
    super.initState();
    _scheduleService = FirestoreScheduleBookingService();
    _departmentService = FirestoreDepartmentService();
    _nameController = TextEditingController();
    _reasonController = TextEditingController();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _departmentService.getAllDepartments();
      setState(() {
        _departments = departments;
        _isLoadingDepartments = false;
        // Auto-select first department if available
        if (_departments.isNotEmpty) {
          _selectedDepartmentId = _departments.first.id;
        }
      });
    } catch (e) {
      logger_util.logError('Error loading departments: $e');
      setState(() {
        _isLoadingDepartments = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading departments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _bookSchedule() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get the selected department name
      final selectedDept = _departments.firstWhere(
        (dept) => dept.id == _selectedDepartmentId,
        orElse: () => Department(id: '', name: 'Unknown'),
      );

      await _scheduleService.bookSchedule(
        scheduleId: widget.schedule.id,
        facultyId: widget.faculty.id,
        reason: _reasonController.text,
        studentName: _nameController.text,
        studentDepartment: selectedDept.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      logger_util.logError('Error booking schedule: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    return Dialog(
      insetPadding: EdgeInsets.all(ResponsiveSize.paddingMedium()),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.paddingLarge()),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Book Schedule',
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontTitle(),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'With ${widget.faculty.fullName}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Schedule details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1F41BB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.schedule.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          '${widget.schedule.timeStart} - ${widget.schedule.timeEnd}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.schedule.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 12, color: Colors.blue[800]),
                        const SizedBox(width: 4),
                        Text(
                          widget.schedule.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Your Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildSectionLabel('Your Department'),
                    const SizedBox(height: 8),
                    _isLoadingDepartments
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          )
                        : _departments.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'No departments available',
                                  style: TextStyle(color: Colors.red),
                                ),
                              )
                            : DropdownButtonFormField<String>(
                                value: _selectedDepartmentId,
                                decoration: InputDecoration(
                                  hintText: 'Select your department',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _departments.map((dept) {
                                  return DropdownMenuItem<String>(
                                    value: dept.id,
                                    child: Text(dept.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDepartmentId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Department is required';
                                  }
                                  return null;
                                },
                              ),
                    const SizedBox(height: 16),

                    _buildSectionLabel('Reason for Booking'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Why are you booking this schedule?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Reason is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _bookSchedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F41BB),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Confirm Booking',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}
