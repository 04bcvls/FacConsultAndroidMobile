import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:andfacconsult/controllers/auth_controller.dart';
import 'package:andfacconsult/views/main_dashboard_view.dart';
import 'package:andfacconsult/views/my_account_view.dart';
import 'package:andfacconsult/views/my_bookings_view.dart';
import 'package:andfacconsult/views/notifications_view.dart';
import 'package:andfacconsult/services/firestore_notification_service.dart';
import 'package:andfacconsult/utils/logger.dart' as logger_util;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late FirestoreNotificationService _notificationService;
  late Timer _syncTimer;

  @override
  void initState() {
    super.initState();
    _notificationService = FirestoreNotificationService();
    // Auto-sync notifications for any booking status changes on app load
    _notificationService.syncNotificationsForBookingStatusChanges();
    
    // Auto-sync notifications every 5 seconds in the background
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (mounted) {
        try {
          await _notificationService.syncNotificationsForBookingStatusChanges();
        } catch (e) {
          logger_util.logError('Error auto-syncing notifications in dashboard: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: const Color(0xFF1F41BB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/juci_what.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Container(
          // Dark overlay for better text readability
          color: Colors.black.withValues(alpha:0.3),
          child: Consumer<AuthController>(
            builder: (context, authController, _) {
              final user = authController.currentUser;

              if (user == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "User logged out. Please login again.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pushReplacementNamed('/login'),
                        child: const Text("Go to Login"),
                      ),
                    ],
                  ),
                );
              }

              return IndexedStack(
                index: _selectedIndex,
                children: [
                  // Main Dashboard View
                  const MainDashboardView(),
                  // My Bookings View
                  const MyBookingsView(),
                  // Notifications View
                  const NotificationsView(),
                  // My Account View
                  MyAccountView(user: user),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Directory',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'My Bookings',
          ),
          // Notifications with badge
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: _notificationService.getUnreadNotificationsCountStream(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (unreadCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        backgroundColor: const Color(0xFF1F41BB),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Faculty Directory';
      case 1:
        return 'My Bookings';
      case 2:
        return 'Notifications';
      case 3:
        return 'Profile';
      default:
        return 'FacConsult';
    }
  }

  /// Handle logout
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final authController = context.read<AuthController>();
      await authController.signOut();
      authController.clearErrorMessage();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
}
