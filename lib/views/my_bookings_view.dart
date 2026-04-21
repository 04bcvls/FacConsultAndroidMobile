import 'package:flutter/material.dart';
import 'dart:async';
import 'package:andfacconsult/models/appointment.dart';
import 'package:andfacconsult/models/schedule.dart';
import 'package:andfacconsult/models/faculty.dart';
import 'package:andfacconsult/services/firestore_schedule_booking_service.dart';
import 'package:andfacconsult/services/firestore_faculty_service.dart';
import 'package:andfacconsult/services/firestore_notification_service.dart';
import 'package:andfacconsult/utils/responsive.dart';
import 'package:andfacconsult/views/booking_details_view.dart';
import 'package:andfacconsult/utils/logger.dart' as logger_util;
import 'package:andfacconsult/utils/string_extensions.dart';

class MyBookingsView extends StatefulWidget {
  const MyBookingsView({Key? key}) : super(key: key);

  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> {
  late FirestoreScheduleBookingService _bookingService;
  late FirestoreFacultyService _facultyService;
  late FirestoreNotificationService _notificationService;
  String _filterStatus = 'all'; // all, pending, approved, rejected, cancelled
  late Timer _syncTimer;

  @override
  void initState() {
    super.initState();
    _bookingService = FirestoreScheduleBookingService();
    _facultyService = FirestoreFacultyService();
    _notificationService = FirestoreNotificationService();
    // Auto-sync notifications for any booking status changes on load
    _notificationService.syncNotificationsForBookingStatusChanges();
    
    // Auto-sync notifications every 3 seconds for real-time updates
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (mounted) {
        try {
          await _notificationService.syncNotificationsForBookingStatusChanges();
        } catch (e) {
          logger_util.logError('Error auto-syncing notifications: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _syncTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    return Scaffold(
      body: Column(
        children: [
          // Filter buttons
          Padding(
            padding: EdgeInsets.all(ResponsiveSize.paddingMedium()),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  SizedBox(width: ResponsiveSize.spacing8()),
                  _buildFilterChip('Pending', 'pending'),
                  SizedBox(width: ResponsiveSize.spacing8()),
                  _buildFilterChip('Approved', 'approved'),
                  SizedBox(width: ResponsiveSize.spacing8()),
                  _buildFilterChip('Rejected', 'rejected'),
                  SizedBox(width: ResponsiveSize.spacing8()),
                  _buildFilterChip('Cancelled', 'cancelled'),
                ],
              ),
            ),
          ),
          // Bookings list
          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: _bookingService.getStudentBookingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  logger_util.logError('Error loading bookings: ${snapshot.error}');
                  return RefreshIndicator(
                    onRefresh: _refreshBookings,
                    child: Center(
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.3,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                SizedBox(height: ResponsiveSize.spacing16()),
                                const Text('Error loading bookings'),
                                SizedBox(height: ResponsiveSize.spacing16()),
                                ElevatedButton(
                                  onPressed: () => _refreshBookings(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var bookings = snapshot.data ?? [];

                // Apply filter
                if (_filterStatus != 'all') {
                  bookings = bookings
                      .where((b) => b.status.toLowerCase() == _filterStatus)
                      .toList();
                }

                if (bookings.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshBookings,
                    child: Center(
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.2,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 64, color: Colors.grey[400]),
                                SizedBox(height: ResponsiveSize.spacing16()),
                                Text(
                                  _filterStatus == 'all'
                                      ? 'No bookings yet'
                                      : 'No $_filterStatus bookings',
                                  style: TextStyle(
                                    fontSize: ResponsiveSize.fontSubtitle(),
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: ResponsiveSize.spacing8()),
                                Text(
                                  'Book a schedule with a faculty member',
                                  style: TextStyle(
                                    fontSize: ResponsiveSize.fontSmall(),
                                    color: Colors.grey[500],
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

                return RefreshIndicator(
                  onRefresh: _refreshBookings,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.paddingMedium()),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return _buildBookingCard(context, booking);
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF1F41BB),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Appointment booking) {
    final statusColor = _getStatusColor(booking.status);
    final statusIcon = _getStatusIcon(booking.status);

    return FutureBuilder<Schedule?>(
      future: _bookingService.getScheduleById(booking.scheduleId),
      builder: (context, scheduleSnapshot) {
        final schedule = scheduleSnapshot.data;

        return GestureDetector(
          onTap: () {
            if (schedule != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailsView(
                    booking: booking,
                    schedule: schedule,
                  ),
                ),
              ).then((result) {
                // Refresh if booking was cancelled
                if (result == true) {
                  setState(() {});
                }
              });
            }
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with status and faculty name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fetch faculty name
                            FutureBuilder<Faculty?>(
                              future: _facultyService.getFacultyById(booking.facultyId),
                              builder: (context, facultySnapshot) {
                                final faculty = facultySnapshot.data;
                                final facultyName = faculty?.fullName ?? 'Faculty ID: ${booking.facultyId}';

                                return Text(
                                  facultyName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            if (schedule != null)
                              Text(
                                schedule.type.capitalize(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                              booking.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date and time
                  if (schedule != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  schedule.formattedDate,
                                  style:
                                      TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${schedule.timeStart} - ${schedule.timeEnd}',
                                  style:
                                      TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            schedule.location,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Reason
                  if (booking.reason.isNotEmpty) ...[
                    Text(
                      'Reason: ${booking.reason}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Tap hint
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Tap for details',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF1F41BB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward,
                          size: 14, color: Color(0xFF1F41BB)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshBookings() async {
    try {
      // Sync any missing notifications from booking status changes
      await _notificationService.syncNotificationsForBookingStatusChanges();
      setState(() {});
    } catch (e) {
      logger_util.logError('Error refreshing bookings: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.close;
      default:
        return Icons.help;
    }
  }
}
