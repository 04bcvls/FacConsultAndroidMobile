import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:andfacconsult/controllers/auth_controller.dart';
import 'package:andfacconsult/models/user.dart';

class EditProfileView extends StatefulWidget {
  final User user;

  const EditProfileView({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController _displayNameController;
  late GlobalKey<FormState> _formKey;
  bool _isLoading = false;
  File? _selectedPhoto;
  String? _photoUrl;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _displayNameController = TextEditingController(text: widget.user.displayName);
    _photoUrl = widget.user.photoUrl; // Store current photo URL
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  /// Pick photo from gallery or camera
  Future<void> _pickPhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                    maxWidth: 1024,
                    maxHeight: 1024,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedPhoto = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                    maxWidth: 1024,
                    maxHeight: 1024,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedPhoto = File(image.path);
                    });
                  }
                },
              ),
              if (_selectedPhoto != null || _photoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedPhoto = null;
                      _photoUrl = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Handle save profile changes
  Future<void> _saveProfile(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authController = context.read<AuthController>();
      
      // Upload photo if selected
      String? photoUrl = _photoUrl;
      if (_selectedPhoto != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading photo...'),
            duration: Duration(seconds: 30),
          ),
        );
        photoUrl = await authController.uploadProfilePhoto(_selectedPhoto!);
      }

      final updatedUser = widget.user.copyWith(
        displayName: _displayNameController.text.trim(),
        photoUrl: photoUrl,
      );

      final success = await authController.updateProfile(updatedUser);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authController.errorMessage ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        backgroundColor: const Color(0xFF1F41BB),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section header
              _buildSectionHeader('Edit Your Information'),
              const SizedBox(height: 20),

              // Profile Photo Section
              _buildProfilePhotoSection(),
              const SizedBox(height: 20),

              // Display Name Field
              _buildTextFormField(
                controller: _displayNameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name cannot be empty';
                  }
                  if (value.trim().length < 2) {
                    return 'Full name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Email Display (Read-only)
              _buildReadOnlyField(
                label: 'Email',
                value: widget.user.email,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),

              // Account Info Section
              _buildAccountInfoSection(),
              const SizedBox(height: 30),

              // Action Buttons
              _buildActionButtons(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F41BB),
      ),
    );
  }

  /// Build profile photo section
  Widget _buildProfilePhotoSection() {
    return Center(
      child: Column(
        children: [
          // Profile photo display
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              border: Border.all(
                color: const Color(0xFF1F41BB),
                width: 2,
              ),
              image: _selectedPhoto != null
                  ? DecorationImage(
                      image: FileImage(_selectedPhoto!),
                      fit: BoxFit.cover,
                    )
                  : (_photoUrl != null && _photoUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(_photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            child: _selectedPhoto == null &&
                    (_photoUrl == null || _photoUrl!.isEmpty)
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          // Photo action button
          ElevatedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Change Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F41BB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build text form field
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1F41BB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }

  /// Build read-only field
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1F41BB), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build account info section
  Widget _buildAccountInfoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Role', widget.user.role.toUpperCase()),
            const SizedBox(height: 12),
            _buildInfoRow('Login Method', _getLoginMethodLabel(widget.user.loginMethod)),
            const SizedBox(height: 12),
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
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _saveProfile(context),
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha:0.7),
                      ),
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F41BB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey[400],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Cancel Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1F41BB),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Color(0xFF1F41BB)),
            ),
          ),
        ),
      ],
    );
  }

  /// Get login method label
  String _getLoginMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'google':
        return 'Google';
      case 'email':
        return 'Email/Password';
      case 'guest':
        return 'Guest';
      default:
        return method;
    }
  }
}
