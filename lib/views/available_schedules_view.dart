import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:andfacconsult/models/faculty.dart';
import 'package:andfacconsult/models/schedule.dart';
import 'package:andfacconsult/models/appointment.dart';
import 'package:andfacconsult/services/firestore_schedule_booking_service.dart';
import 'package:andfacconsult/utils/responsive.dart';
import 'package:andfacconsult/views/schedule_booking_dialog.dart';
import 'package:andfacconsult/utils/logger.dart' as logger_util;
import 'package:andfacconsult/utils/string_extensions.dart';
import 'package:andfacconsult/controllers/auth_controller.dart';
import 'package:andfacconsult/utils/constants.dart';

class AvailableSchedulesView extends StatefulWidget {
  final Faculty faculty;

  const AvailableSchedulesView({Key? key, required this.faculty})
      : super(key: key);

  @override
  State<AvailableSchedulesView> createState() => _AvailableSchedulesViewState();
}

class _AvailableSchedulesViewState extends State<AvailableSchedulesView> {
  late FirestoreScheduleBookingService _scheduleService;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, available, booked
  String? _selectedDate; // yyyy-MM-dd format

  @override
  void initState() {
    super.initState();
    _scheduleService = FirestoreScheduleBookingService();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Schedules',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F41BB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by title or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          // Date picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate != null
                            ? DateTime.parse(_selectedDate!)
                            : DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate =
                              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? _formatDateForDisplay(_selectedDate!)
                                  : 'Filter by date',
                              style: TextStyle(
                                color: _selectedDate != null
                                    ? Colors.black87
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Available', 'available'),
                const SizedBox(width: 8),
                _buildFilterChip('Booked', 'booked'),
              ],
            ),
          ),
          // Schedules list
          Expanded(
            child: StreamBuilder<List<Schedule>>(
              stream: _scheduleService
                  .getSchedulesForFacultyStream(widget.faculty.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  logger_util.logError('Error loading schedules: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        SizedBox(height: ResponsiveSize.spacing16()),
                        const Text('Error loading schedules'),
                        SizedBox(height: ResponsiveSize.spacing16()),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                var schedules = snapshot.data ?? [];

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  schedules = schedules
                      .where((schedule) =>
                          schedule.title
                              .toLowerCase()
                              .contains(_searchQuery) ||
                          schedule.location
                              .toLowerCase()
                              .contains(_searchQuery))
                      .toList();
                }

                // Apply date filter
                if (_selectedDate != null) {
                  schedules = schedules
                      .where((schedule) => schedule.date == _selectedDate)
                      .toList();
                }

                if (schedules.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No schedules match your search'
                              : _selectedDate != null
                                  ? 'No schedules on ${_formatDateForDisplay(_selectedDate!)}'
                                  : 'No schedules available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group schedules by date
                final groupedSchedules = <String, List<Schedule>>{};
                for (var schedule in schedules) {
                  if (!groupedSchedules.containsKey(schedule.date)) {
                    groupedSchedules[schedule.date] = [];
                  }
                  groupedSchedules[schedule.date]!.add(schedule);
                }

                final sortedDates = groupedSchedules.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final schedulesForDate = groupedSchedules[date]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _formatDateHeader(date),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        // Schedule cards for this date
                        ...schedulesForDate
                            .map((schedule) =>
                                _buildScheduleCard(context, schedule))
                            .toList(),

                        const SizedBox(height: 24),
                      ],
                    );
                  },
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

  Widget _buildScheduleCard(BuildContext context, Schedule schedule) {
    return StreamBuilder<Appointment?>(
      stream: _scheduleService
          .getBookingsForSchedule(schedule.id)
          .asStream()
          .map((bookings) => bookings.isNotEmpty ? bookings.first : null),
      builder: (context, bookingSnapshot) {
        final isBooked =
            bookingSnapshot.data != null && bookingSnapshot.data!.status != 'cancelled';
        final booking = bookingSnapshot.data;

        // Apply status filter
        if (_filterStatus == 'available' && isBooked) {
          return const SizedBox.shrink();
        }
        if (_filterStatus == 'booked' && !isBooked) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isBooked ? Colors.grey[100] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with time and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${schedule.timeStart} - ${schedule.timeEnd}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          schedule.type.capitalize(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isBooked ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isBooked ? 'BOOKED' : 'AVAILABLE',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  schedule.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        schedule.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // If booked, show student info
                if (isBooked && booking != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booked by:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.studentName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.studentEmail,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Status: ${booking.status.capitalize()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const SizedBox(height: 12),
                ],

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: Consumer<AuthController>(
                    builder: (context, authController, _) {
                      final isGuest = authController.currentUser?.role == AppConstants.roleGuest;
                      final canBook = !isBooked && !isGuest;

                      return ElevatedButton(
                        onPressed: canBook
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      ScheduleBookingDialog(
                                    schedule: schedule,
                                    faculty: widget.faculty,
                                  ),
                                );
                              }
                            : isGuest
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Guest users cannot book consultations. Please sign in with your ADDU account.',
                                        ),
                                        backgroundColor: Colors.orange,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isGuest
                              ? Colors.grey
                              : isBooked
                                  ? Colors.grey
                                  : const Color(0xFF1F41BB),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isGuest
                              ? 'Guest - View Only'
                              : isBooked
                                  ? 'Not Available'
                                  : 'Book Schedule',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateHeader(String dateStr) {
    final parts = dateStr.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final date = DateTime(year, month, day);
    final weekday = weekdays[date.weekday - 1];

    return '$weekday, ${months[month - 1]} $day, $year';
  }

  String _formatDateForDisplay(String dateStr) {
    final parts = dateStr.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[month - 1]} $day, $year';
  }
}
