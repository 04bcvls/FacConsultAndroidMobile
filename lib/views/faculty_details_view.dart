import 'package:flutter/material.dart';
import 'package:andfacconsult/models/faculty.dart';
import 'package:andfacconsult/utils/responsive.dart';
import 'package:andfacconsult/views/available_schedules_view.dart';
import 'package:andfacconsult/utils/string_extensions.dart';

class FacultyDetailsView extends StatelessWidget {
  final Faculty faculty;

  const FacultyDetailsView({Key? key, required this.faculty}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F41BB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Faculty Details',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Scrollable Content Area
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Profile Image Section - Full Blue Background
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1F41BB),
                          Color(0xFF2E5090),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: ResponsiveSize.spacing24()),
                        // Compact Profile Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(ResponsiveSize.spacing16()),
                          child: faculty.profileImageUrl != null &&
                                  faculty.profileImageUrl!.isNotEmpty
                              ? Image.network(
                                  faculty.profileImageUrl!,
                                  width: ResponsiveSize.profileImageHeight() * 0.75,
                                  height: ResponsiveSize.profileImageHeight() * 0.75,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildCompactAvatarPlaceholder(faculty);
                                  },
                                )
                              : _buildCompactAvatarPlaceholder(faculty),
                        ),
                        SizedBox(height: ResponsiveSize.spacing16()),
                        // Name & Email (compact vertical stack)
                        Column(
                          children: [
                            Text(
                              faculty.fullName,
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontSubtitle(),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: ResponsiveSize.spacing4()),
                            Text(
                              faculty.email,
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontSmall(),
                                color: Colors.grey[200],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveSize.spacing24()),
                      ],
                    ),
                  ),
                  // Details Section - All in One Card
                  Padding(
                    padding: EdgeInsets.all(ResponsiveSize.paddingLarge()),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveSize.spacing16()),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(ResponsiveSize.paddingMedium()),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Details Title
                            Text(
                              'Details',
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontBody(),
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: ResponsiveSize.spacing12()),
                            // Faculty ID
                            _buildDetailRow(
                              icon: Icons.badge_outlined,
                              label: 'Faculty ID',
                              value: faculty.id.maskId(),
                            ),
                            Divider(height: ResponsiveSize.spacing16()),
                            // Availability Status
                            _buildDetailRow(
                              icon: Icons.circle,
                              label: 'Availability Status',
                              value: faculty.availabilityStatus,
                              valueColor: _getStatusColor(faculty.availabilityStatus),
                            ),
                            Divider(height: ResponsiveSize.spacing16()),
                            // Department
                            _buildDetailRow(
                              icon: Icons.business,
                              label: 'Department',
                              value: faculty.departmentName ?? faculty.departmentId,
                            ),
                            Divider(height: ResponsiveSize.spacing16()),
                            // First Name
                            _buildDetailRow(
                              icon: Icons.person_outline,
                              label: 'First Name',
                              value: faculty.firstName,
                            ),
                            Divider(height: ResponsiveSize.spacing16()),
                            // Last Name
                            _buildDetailRow(
                              icon: Icons.person_outline,
                              label: 'Last Name',
                              value: faculty.lastName,
                            ),
                            Divider(height: ResponsiveSize.spacing16()),
                            // Email
                            _buildDetailRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: faculty.email,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacing32()),
                ],
              ),
            ),
          ),
          // Fixed Bottom Button Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ResponsiveSize.paddingLarge()),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.15),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View Schedules Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              AvailableSchedulesView(faculty: faculty),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F41BB),
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveSize.spacing16(),
                        horizontal: ResponsiveSize.paddingMedium(),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveSize.spacing12()),
                      ),
                    ),
                    label: Text(
                      'View Available Schedules',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveSize.fontSubtitle(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveSize.spacing12()),
                // Send Email Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Send email to faculty
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveSize.spacing16(),
                        horizontal: ResponsiveSize.paddingMedium(),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveSize.spacing12()),
                      ),
                      side: const BorderSide(
                        color: Color(0xFF1F41BB),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'Send Email',
                      style: TextStyle(
                        color: const Color(0xFF1F41BB),
                        fontSize: ResponsiveSize.fontSubtitle(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build detail row with icon, label and value (for card layout) - Compact
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF1F41BB),
          size: ResponsiveSize.iconSmall(),
        ),
        SizedBox(width: ResponsiveSize.spacing8()),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveSize.fontSmall(),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveSize.spacing2()),
              Text(
                value,
                style: TextStyle(
                  fontSize: ResponsiveSize.fontSmall(),
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build compact placeholder avatar with initials
  Widget _buildCompactAvatarPlaceholder(Faculty faculty) {
    final initials =
        '${faculty.firstName[0]}${faculty.lastName[0]}'.toUpperCase();
    return Container(
      width: ResponsiveSize.profileImageHeight() * 0.75,
      height: ResponsiveSize.profileImageHeight() * 0.75,
      decoration: BoxDecoration(
        color: const Color(0xFF1F41BB).withValues(alpha:0.3),
        borderRadius: BorderRadius.circular(ResponsiveSize.spacing16()),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveSize.fontLargeHeading(),
          ),
        ),
      ),
    );
  }

  /// Build large placeholder avatar with initials
  Widget _buildLargeAvatarPlaceholder(Faculty faculty) {
    final initials =
        '${faculty.firstName[0]}${faculty.lastName[0]}'.toUpperCase();
    return Container(
      width: ResponsiveSize.profileImageHeight(),
      height: ResponsiveSize.profileImageHeight(),
      decoration: BoxDecoration(
        color: const Color(0xFF1F41BB).withValues(alpha:0.3),
        borderRadius: BorderRadius.circular(ResponsiveSize.spacing16()),
        border: Border.all(
          color: Colors.white.withValues(alpha:0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveSize.fontXLargeHeading(),
          ),
        ),
      ),
    );
  }

  /// Get status color based on availability
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
}
