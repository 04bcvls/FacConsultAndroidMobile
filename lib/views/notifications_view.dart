import 'package:flutter/material.dart';
import 'dart:async';
import 'package:andfacconsult/models/notification.dart';
import 'package:andfacconsult/services/firestore_notification_service.dart';
import 'package:andfacconsult/services/firestore_schedule_booking_service.dart';
import 'package:andfacconsult/utils/responsive.dart';
import 'package:andfacconsult/utils/logger.dart' as logger_util;
import 'package:andfacconsult/views/booking_details_view.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late FirestoreNotificationService _notificationService;
  late FirestoreScheduleBookingService _bookingService;
  String _filterStatus = 'all'; // all, unread
  late Timer _syncTimer;

  @override
  void initState() {
    super.initState();
    _notificationService = FirestoreNotificationService();
    _bookingService = FirestoreScheduleBookingService();
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
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                SizedBox(width: ResponsiveSize.spacing12()),
                _buildFilterChip('Unread', 'unread'),
                const Spacer(),
                if (_filterStatus == 'all')
                  TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: Icon(Icons.done_all, size: ResponsiveSize.iconSmall()),
                    label: const Text('Mark all read'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1F41BB),
                    ),
                  ),
              ],
            ),
          ),
          // Clear All button (separate row for better positioning)
          if (_filterStatus == 'all')
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.paddingMedium(),
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TextButton.icon(
                  //   onPressed: () {
                  //     logger_util.logInfo('Direct brute force clear triggered');
                  //     _clearAllNotificationsDirectly();
                  //   },
                  //   icon: const Icon(Icons.delete_forever, size: 16),
                  //   label: const Text('Force Clear'),
                  //   style: TextButton.styleFrom(
                  //     foregroundColor: Colors.red[700],
                  //   ),
                  // ),
                  SizedBox(width: ResponsiveSize.spacing8()),
                  // TextButton.icon(
                  //   onPressed: _rebuildNotificationsWithCorrectTimes,
                  //   icon: const Icon(Icons.refresh, size: 16),
                  //   label: const Text('Rebuild'),
                  //   style: TextButton.styleFrom(
                  //     foregroundColor: Colors.blue[600],
                  //   ),
                  // ),
                  ElevatedButton.icon(
                    onPressed: _handleClearAllButtonTap,
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[500],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Notifications list
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _notificationService.getStudentNotificationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  logger_util.logError('Error loading notifications: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: ResponsiveSize.spacing16()),
                        const Text('Error loading notifications'),
                        SizedBox(height: ResponsiveSize.spacing16()),
                        ElevatedButton(
                          onPressed: () => _refreshNotifications(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                var notifications = snapshot.data ?? [];

                // Filter out notifications with invalid schedule datetime
                notifications = notifications.where((n) {
                  try {
                    DateTime.parse(n.scheduleDatetime);
                    return true; // Valid datetime
                  } catch (e) {
                    return false; // Invalid datetime - skip this notification
                  }
                }).toList();

                // Apply filter
                if (_filterStatus == 'unread') {
                  notifications = notifications.where((n) => !n.read).toList();
                }

                if (notifications.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshNotifications,
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
                                Icon(Icons.notifications_none,
                                    size: 64, color: Colors.grey[400]),
                                SizedBox(height: ResponsiveSize.spacing16()),
                                Text(
                                  _filterStatus == 'all'
                                      ? 'No notifications yet'
                                      : 'No unread notifications',
                                  style: TextStyle(
                                    fontSize: ResponsiveSize.fontSubtitle(),
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: ResponsiveSize.spacing8()),
                                Text(
                                  'Status updates will appear here',
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
                  onRefresh: _refreshNotifications,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.paddingMedium()),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red[400],
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) {
                          _deleteNotification(notification.id, notification.scheduleTitle);
                        },
                        child: _buildNotificationCard(context, notification),
                      );
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

  Future<void> _refreshNotifications() async {
    try {
      // Sync any missing notifications from booking status changes
      await _notificationService.syncNotificationsForBookingStatusChanges();
    } catch (e) {
      logger_util.logError('Error refreshing notifications: $e');
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      avatar: isSelected
          ? const Icon(Icons.check, size: 18, color: Colors.white)
          : null,
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

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      logger_util.logError('Error marking all as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error marking notifications as read')),
      );
    }
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification) {
    final typeColor = _getTypeColor(notification.type);
    final typeIcon = _getTypeIcon(notification.type);
    final formattedDate = _formatDateTime(notification.createdAt);
    
    // Safely parse schedule datetime
    String scheduleDateFormatted = '';
    try {
      final scheduleDateTime = DateTime.parse(notification.scheduleDatetime);
      scheduleDateFormatted = _formatDateTime(scheduleDateTime);
    } catch (e) {
      logger_util.logWarning('Invalid schedule datetime format: ${notification.scheduleDatetime}');
    }

    // Debug log to see notification data
    logger_util.logInfo('Notification: Title="${notification.scheduleTitle}" Faculty="${notification.facultyName}" Type="${notification.type}" BookingId="${notification.bookingId}"');

    return GestureDetector(
      onTap: () {
        // Mark as read when tapped on the card (but not on buttons)
        if (!notification.read) {
          _markAsRead(notification.id);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: notification.read ? Colors.white : Colors.blue[50],
        elevation: notification.read ? 0 : 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type badge and read indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            typeIcon,
                            color: typeColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Schedule Title with Faculty Name
                              Text(
                                notification.scheduleTitle.isNotEmpty ? notification.scheduleTitle : 'Consultation',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Faculty Name below title
                              Text(
                                notification.facultyName.isNotEmpty ? notification.facultyName : "Faculty Member",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Type label with status
                              Text(
                                _getTypeLabel(notification.type),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: typeColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.read)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F41BB),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Schedule Date/Time - Important Detail (hidden for pending notifications)
              if (notification.type != 'pending')
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scheduled: $scheduleDateFormatted',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Message
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer with date and action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          logger_util.logInfo('View Details tapped for booking: ${notification.bookingId}');
                          if (notification.bookingId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Booking ID not found. Please try again.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          _navigateToBookingDetails(notification.bookingId);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: typeColor.withValues(alpha:0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                size: 10,
                                color: typeColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _showDeleteConfirmationDialog(notification.id, notification.scheduleTitle);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.red[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 10,
                                color: Colors.red[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
    } catch (e) {
      logger_util.logError('Error marking notification as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error marking notification as read')),
      );
    }
  }

  Future<void> _navigateToBookingDetails(String bookingId) async {
    try {
      logger_util.logInfo('Attempting to navigate to booking details: $bookingId');
      
      // Check if bookingId is empty
      if (bookingId.isEmpty) {
        logger_util.logError('BookingId is empty!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking ID not found. Please try again.')),
          );
        }
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      
      logger_util.logInfo('Fetching booking data for ID: $bookingId');
      
      // Fetch booking data
      final booking = await _bookingService.getBookingById(bookingId);
      logger_util.logInfo('Booking fetch result: ${booking != null ? 'Found' : 'Not found'}');
      
      if (booking == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking not found')),
          );
        }
        return;
      }

      logger_util.logInfo('Fetching schedule data for schedule ID: ${booking.scheduleId}');
      
      // Fetch schedule data
      final schedule = await _bookingService.getScheduleById(booking.scheduleId);
      logger_util.logInfo('Schedule fetch result: ${schedule != null ? 'Found' : 'Not found'}');

      if (!mounted) return;

      if (schedule == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule not found')),
          );
        }
        return;
      }

      logger_util.logInfo('Navigating to booking details view');
      
      // Navigate to booking details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingDetailsView(
            booking: booking,
            schedule: schedule,
          ),
        ),
      ).then((result) {
        // Refresh if booking was cancelled or modified
        if (result == true && mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      logger_util.logError('Error navigating to booking details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      case 'pending':
        return Icons.hourglass_bottom;
      default:
        return Icons.info;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'approved':
        return 'Consultation Approved';
      case 'rejected':
        return 'Consultation Rejected';
      case 'cancelled':
        return 'Consultation Cancelled';
      case 'pending':
        return 'Awaiting Review';
      default:
        return 'Status Update';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final notificationDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (notificationDate == today) {
      dateStr = 'Today';
    } else if (notificationDate == yesterday) {
      dateStr = 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      dateStr = '${months[dateTime.month - 1]} ${dateTime.day}';
    }

    // Properly convert 24-hour to 12-hour format
    var hour = dateTime.hour;
    final meridiem = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) {
      hour = hour - 12;
    } else if (hour == 0) {
      hour = 12;
    }
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$dateStr • $hour:$minute $meridiem';
  }

  Future<void> _deleteNotification(String notificationId, String notificationTitle) async {
    try {
      logger_util.logInfo('Deleting notification: $notificationId');
      await _notificationService.deleteNotification(notificationId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$notificationTitle" deleted'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Note: Undo is not implemented as notifications are permanently deleted
                logger_util.logInfo('Undo is not available for deleted notifications');
              },
            ),
          ),
        );
      }
    } catch (e) {
      logger_util.logError('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting notification')),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(String notificationId, String notificationTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Notification?'),
          content: Text(
            'Are you sure you want to delete "$notificationTitle"?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteNotification(notificationId, notificationTitle);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[600],
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Notifications?'),
          content: const Text(
            'Are you sure you want to delete ALL notifications?\n\nThis will remove all current notifications and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllNotifications();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[600],
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllNotifications() async {
    try {
      logger_util.logInfo('Clearing all notifications');
      await _notificationService.clearAllNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared ✓'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger_util.logError('Error clearing all notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error clearing notifications')),
        );
      }
    }
  }

  void _handleClearAllButtonTap() {
    _showClearAllDialog();
  }

  Future<void> _clearAllNotificationsDirectly() async {
    try {
      logger_util.logInfo('Force clearing all notifications directly (no confirmation)');
      int count = await _notificationService.clearAllNotificationsDirectly();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count notifications cleared ✓'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } catch (e) {
      logger_util.logError('Error in force clear: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error clearing notifications')),
        );
      }
    }
  }

  Future<void> _rebuildNotificationsWithCorrectTimes() async {
    try {
      logger_util.logInfo('Rebuilding notifications with correct times');
      
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rebuilding notifications...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Step 1: Clear all notifications
      int clearedCount = await _notificationService.clearAllNotificationsDirectly();
      logger_util.logInfo('Cleared $clearedCount notifications');
      
      // Step 2: Re-sync to recreate with correct times
      await _notificationService.syncNotificationsForBookingStatusChanges();
      logger_util.logInfo('Re-synced notifications with correct times');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notifications rebuilt with correct times ✓'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      logger_util.logError('Error rebuilding notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}