import 'package:flutter/material.dart';
import 'package:andfacconsult/models/user.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:andfacconsult/views/edit_profile_view.dart';
import 'package:andfacconsult/utils/constants.dart';
import 'package:andfacconsult/utils/string_extensions.dart';
import 'package:andfacconsult/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class MyAccountView extends StatefulWidget {
  final User user;

  const MyAccountView({Key? key, required this.user}) : super(key: key);

  @override
  State<MyAccountView> createState() => _MyAccountViewState();
}

class _MyAccountViewState extends State<MyAccountView> {
  Future<void> _refreshProfile() async {
    try {
      final authController = context.read<AuthController>();
      await authController.initialize();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile refreshed'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshProfile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guest Access Warning
            if (widget.user.role == AppConstants.roleGuest)
              _buildGuestWarningBanner(),
            if (widget.user.role == AppConstants.roleGuest)
              const SizedBox(height: 20),

            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 32),

            // User Information Card
            _buildUserInfoCard(),
            const SizedBox(height: 24),

            // Role Information Card
            _buildRoleCard(),
            const SizedBox(height: 24),

            // Login Method Card
            _buildLoginMethodCard(),
            const SizedBox(height: 24),

            // Account Actions
            _buildAccountActions(context),

            // Extra padding at bottom
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Build guest access warning banner
  Widget _buildGuestWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest Access Limited',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can view faculty members but cannot book consultations.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build profile header with user's display name
  Widget _buildProfileHeader() {
    String greeting = "";
    switch (widget.user.loginMethod) {
      case "google":
        greeting = "Welcome back, ${widget.user.displayName}!";
        break;
      case "email":
        greeting = "Welcome, ${widget.user.displayName}!";
        break;
      case "guest":
        greeting = "Welcome, Guest User!";
        break;
      default:
        greeting = "Welcome, ${widget.user.displayName}!";
    }

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white.withValues(alpha:0.95),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1F41BB), Color(0xFF2E5BF3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Photo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.user.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey[300],
                ),
                child: widget.user.photoUrl == null || widget.user.photoUrl!.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.user.email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build user information card
  Widget _buildUserInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withValues(alpha:0.95),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Full Name', widget.user.displayName),
            const SizedBox(height: 12),
            _buildInfoRow('Email', widget.user.email),
            const SizedBox(height: 12),
            // Show Faculty ID if user is a faculty member
            if (widget.user.facultyId != null) ...[
              _buildInfoRow('Faculty ID', widget.user.facultyId!.maskId()),
              const SizedBox(height: 12),
            ],
            // Show User ID for non-faculty users
            if (widget.user.facultyId == null) ...[
              _buildInfoRow('User ID', widget.user.uid.maskId()),
              const SizedBox(height: 12),
            ],
            _buildInfoRow(
              'Member Since',
              "${widget.user.createdAt.day}/${widget.user.createdAt.month}/${widget.user.createdAt.year}",
            ),
          ],
        ),
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build role card
  Widget _buildRoleCard() {
    final roleColor = _getRoleColor(widget.user.role);
    final roleDescription = _getRoleDescription(widget.user.role);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withValues(alpha:0.95),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Role',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha:0.1),
                border: Border.all(color: roleColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    widget.user.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    roleDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
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

  /// Build login method card
  Widget _buildLoginMethodCard() {
    final methodLabel = _getLoginMethodLabel(widget.user.loginMethod);
    final methodIcon = _getLoginMethodIcon(widget.user.loginMethod);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withValues(alpha:0.95),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Login Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(methodIcon, size: 24, color: const Color(0xFF1F41BB)),
                const SizedBox(width: 12),
                Text(
                  methodLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build account actions
  Widget _buildAccountActions(BuildContext context) {
    final isFacultyMember = widget.user.facultyId != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show info banner for faculty members
        if (isFacultyMember)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Faculty details cannot be edited in the mobile app',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isFacultyMember
                ? null // Disable for faculty
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileView(user: widget.user),
                      ),
                    ).then((result) {
                      // Refresh UI if profile was updated
                      if (result == true) {
                        // The AuthController already updated the user, just rebuild
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile changes saved'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    });
                  },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFacultyMember 
                  ? Colors.grey[400] 
                  : const Color(0xFF1F41BB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _showLogoutConfirmation(context);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final authController = context.read<AuthController>();
                await authController.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Get role color
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return Colors.green;
      case 'guest':
        return Colors.grey;
      case 'admin':
        return Colors.red;
      case 'editor':
        return Colors.orange;
      case 'viewer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get role description
  String _getRoleDescription(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return 'Can view faculty members and book consultations';
      case 'guest':
        return 'View-only access - cannot book consultations';
      case 'admin':
        return 'Full access to all features and settings';
      case 'editor':
        return 'Can view and edit consultations';
      case 'viewer':
        return 'Can view faculty and schedules';
      default:
        return 'Standard user account';
    }
  }

  /// Get login method label
  String _getLoginMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'google':
        return 'Google Account';
      case 'email':
        return 'Email & Password';
      case 'guest':
        return 'Guest Account';
      default:
        return 'Unknown';
    }
  }

  /// Get login method icon
  IconData _getLoginMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'google':
        return FontAwesomeIcons.google;
      case 'email':
        return Icons.email;
      case 'guest':
        return Icons.person;
      default:
        return Icons.help;
    }
  }
}
