import 'package:flutter/material.dart';
import 'package:andfacconsult/models/appointment.dart';
import 'package:andfacconsult/models/faculty.dart';
import 'package:andfacconsult/services/firestore_schedule_booking_service.dart';
import 'package:andfacconsult/services/firestore_faculty_service.dart';
import 'package:andfacconsult/utils/logger.dart' as logger_util;
import 'package:andfacconsult/utils/responsive.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FacultyConsultationsView extends StatefulWidget {
  const FacultyConsultationsView({Key? key}) : super(key: key);

  @override
  State<FacultyConsultationsView> createState() =>
      _FacultyConsultationsViewState();
}

class _FacultyConsultationsViewState extends State<FacultyConsultationsView> {
  late FirestoreScheduleBookingService _bookingService;
  late FirestoreFacultyService _facultyService;
  late String _facultyId;
  String _filterStatus = 'pending'; // pending, approved, rejected, cancelled, all

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Faculty? _currentFaculty;

  @override
  void initState() {
    super.initState();
    _bookingService = FirestoreScheduleBookingService();
    _facultyService = FirestoreFacultyService();
    _facultyId = _auth.currentUser?.uid ?? '';
    _loadFacultyInfo();
  }

  Future<void> _loadFacultyInfo() async {
    try {
      final faculty = await _facultyService.getFacultyById(_facultyId);
      setState(() {
        _currentFaculty = faculty;
      });
    } catch (e) {
      logger_util.logError('Error loading faculty info: $e');
    }
  }

  Future<void> _approvBooking(Appointment booking) async {
    try {
      await _bookingService.approveBooking(
        bookingId: booking.id,
        studentId: booking.studentId,
        facultyId: _facultyId,
        facultyName: _currentFaculty?.firstName ?? 'Faculty',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation approved! Notification sent to student.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger_util.logError('Error approving booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBooking(Appointment booking) async {
    final reasonController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Consultation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }

              try {
                await _bookingService.rejectBooking(
                  bookingId: booking.id,
                  studentId: booking.studentId,
                  facultyId: _facultyId,
                  facultyName: _currentFaculty?.firstName ?? 'Faculty',
                  reason: reasonController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Consultation rejected! Notification sent to student.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                logger_util.logError('Error rejecting booking: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error rejecting: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(Appointment booking) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Consultation'),
        content: const Text('Are you sure you want to cancel this consultation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _bookingService.cancelBookingWithNotification(
                  bookingId: booking.id,
                  studentId: booking.studentId,
                  facultyId: _facultyId,
                  facultyName: _currentFaculty?.firstName ?? 'Faculty',
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Consultation cancelled! Notification sent to student.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                logger_util.logError('Error cancelling booking: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error cancelling: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Consultations'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F41BB),
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium()),
              child: Row(
                children: [
                  _buildFilterChip('Pending', 'pending'),
                  SizedBox(width: ResponsiveSize.spacing12()),
                  _buildFilterChip('Approved', 'approved'),
                  SizedBox(width: ResponsiveSize.spacing12()),
                  _buildFilterChip('Rejected', 'rejected'),
                  SizedBox(width: ResponsiveSize.spacing12()),
                  _buildFilterChip('Cancelled', 'cancelled'),
                  SizedBox(width: ResponsiveSize.spacing12()),
                  _buildFilterChip('All', 'all'),
                ],
              ),
            ),
            // Bookings list
            Expanded(
              child: StreamBuilder<List<Appointment>>(
                stream: _bookingService.getFacultyBookingsStream(_facultyId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    logger_util.logError('Error loading bookings: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: ResponsiveSize.spacing16()),
                          const Text('Error loading consultations'),
                          SizedBox(height: ResponsiveSize.spacing16()),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final allBookings = snapshot.data ?? [];
                  final filteredBookings = _filterStatus == 'all'
                      ? allBookings
                      : allBookings.where((b) => b.status == _filterStatus).toList();

                  if (filteredBookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: ResponsiveSize.spacing16()),
                          Text(
                            'No $_filterStatus consultations yet',
                            style: TextStyle(
                              fontSize: ResponsiveSize.fontBody(),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(ResponsiveSize.paddingMedium()),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      return _buildBookingCard(booking);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      selectedColor: const Color(0xFF1F41BB),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBookingCard(Appointment booking) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacing12()),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.studentName,
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontSubtitle(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: ResponsiveSize.spacing4()),
                      Text(
                        booking.studentEmail,
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontSmall(),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.paddingSmall(),
                    vertical: ResponsiveSize.spacing4(),
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(ResponsiveSize.spacing8()),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontXSmall(),
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(booking.status),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.spacing12()),
            // Booking details
            Divider(height: ResponsiveSize.spacing16()),
            Row(
              children: [
                Icon(Icons.person, size: ResponsiveSize.iconSmall(), color: Colors.grey[600]),
                SizedBox(width: ResponsiveSize.spacing8()),
                Expanded(
                  child: Text(
                    'Department: ${booking.studentDepartment}',
                    style: TextStyle(fontSize: ResponsiveSize.fontSmall()),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.spacing8()),
            Row(
              children: [
                Icon(Icons.description, size: ResponsiveSize.iconSmall(), color: Colors.grey[600]),
                SizedBox(width: ResponsiveSize.spacing8()),
                Expanded(
                  child: Text(
                    'Reason: ${booking.reason}',
                    style: TextStyle(fontSize: ResponsiveSize.fontSmall()),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.spacing8()),
            Row(
              children: [
                Icon(Icons.access_time, size: ResponsiveSize.iconSmall(), color: Colors.grey[600]),
                SizedBox(width: ResponsiveSize.spacing8()),
                Expanded(
                  child: Text(
                    'Booked: ${booking.createdAt.toString().split('.')[0]}',
                    style: TextStyle(fontSize: ResponsiveSize.fontSmall()),
                  ),
                ),
              ],
            ),
            // Action buttons
            if (booking.status == 'pending') ...[
              SizedBox(height: ResponsiveSize.spacing16()),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectBooking(booking),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                      ),
                      child: Text(
                        'Reject',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: ResponsiveSize.fontSmall(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.spacing8()),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approvBooking(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        'Approve',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontSmall(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (booking.status == 'approved') ...[
              SizedBox(height: ResponsiveSize.spacing16()),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelBooking(booking),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: Text(
                    'Cancel Consultation',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: ResponsiveSize.fontSmall(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
