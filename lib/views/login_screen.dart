import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:andfacconsult/controllers/auth_controller.dart';
import 'package:andfacconsult/widgets/custom_button.dart';
import 'package:andfacconsult/utils/constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late GlobalKey<FormState> _formKey;
  bool _isPasswordVisible = false;
  bool _isLoadingSignIn = false;
  bool _isLoadingGoogle = false;
  bool _isLoadingGuest = false;
  bool _isSignUpMode = false; // Toggle between Sign In and Sign Up
  late TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _displayNameController = TextEditingController();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          color: const Color.fromARGB(255, 223, 223, 223).withValues(alpha:0.9),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Consumer<AuthController>(
                builder: (context, authController, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Logo/Title
                      _buildHeader(),
                      const SizedBox(height: 32),

                      // Form
                      _buildForm(authController),
                      const SizedBox(height: 24),

                      // Error Message
                      if (authController.errorMessage != null)
                        _buildErrorWidget(authController),
                      const SizedBox(height: 16),

                      // Sign In/Up Button
                      _buildSignInButton(authController),
                      const SizedBox(height: 20),

                      // Divider
                      _buildDivider(),
                      const SizedBox(height: 20),

                      // Google Sign In Button
                      _buildGoogleSignInButton(authController),
                      const SizedBox(height: 12),

                      // Guest Button
                      _buildGuestButton(authController),
                      const SizedBox(height: 24),

                      // Toggle Sign In/Sign Up
                      _buildToggleSignUpButton(),

                      // Extra padding at bottom for full scrollability
                      const SizedBox(height: 30),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build app header
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppConstants.loginWelcome,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUpMode ? "Create your account" : AppConstants.loginSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color.fromARGB(255, 100, 100, 100),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Build email and password form
  Widget _buildForm(AuthController authController) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Display Name Field (Sign Up mode only)
          if (_isSignUpMode)
            Column(
              children: [
                _buildTextFormField(
                  controller: _displayNameController,
                  label: "Full Name",
                  hint: "Enter your full name",
                  icon: Icons.person,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return "Full name is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Email Field
          _buildTextFormField(
            controller: _emailController,
            label: AppConstants.loginEmail,
            hint: "Enter your email",
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return AppConstants.errorEmptyEmail;
              }
              if (!RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              ).hasMatch(value!)) {
                return AppConstants.errorInvalidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          _buildPasswordFormField(
            controller: _passwordController,
            label: AppConstants.loginPassword,
            hint: "Enter your password",
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return AppConstants.errorEmptyPassword;
              }
              if (_isSignUpMode && (value?.length ?? 0) < 6) {
                return AppConstants.errorPasswordTooShort;
              }
              return null;
            },
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
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F41BB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
    );
  }

  /// Build password field with visibility toggle
  Widget _buildPasswordFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !_isPasswordVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F41BB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
    );
  }

  /// Build error message widget
  Widget _buildErrorWidget(AuthController authController) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              authController.errorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: () => authController.clearErrorMessage(),
            child: Icon(Icons.close, color: Colors.red[700]),
          ),
        ],
      ),
    );
  }

  /// Build main sign in/sign up button
  Widget _buildSignInButton(AuthController authController) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        label: _isSignUpMode ? "Sign Up" : AppConstants.loginButton,
        onPressed: () => _handleSignIn(authController),
        isLoading: _isLoadingSignIn,
        backgroundColor: const Color(0xFF1F41BB),
        textColor: Colors.white,
        height: 52,
      ),
    );
  }

  /// Build Google Sign In button
  Widget _buildGoogleSignInButton(AuthController authController) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        label: 'Sign in with ADDU Google',
        onPressed: () => _handleGoogleSignIn(authController),
        isLoading: _isLoadingGoogle,
        leftIcon: FontAwesomeIcons.google,
        backgroundColor: Colors.white,
        textColor: Colors.black87,
        borderColor: Colors.grey[300],
        iconColor: const Color(0xFF4285F4),
        height: 52,
        isOutlined: true,
      ),
    );
  }

  /// Build Guest button
  Widget _buildGuestButton(AuthController authController) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        label: AppConstants.loginGuest,
        onPressed: () => _handleGuestSignIn(authController),
        isLoading: _isLoadingGuest,
        leftIcon: Icons.person_outline,
        backgroundColor: Colors.grey[200]!,
        textColor: Colors.black87,
        height: 52,
      ),
    );
  }

  /// Build divider
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text("or", style: TextStyle(color: Colors.grey[600])),
        ),
        Expanded(child: Container(height: 1, color: Colors.grey[300])),
      ],
    );
  }

  /// Build toggle sign up button
  Widget _buildToggleSignUpButton() {
    return Center(
      child: GestureDetector(
        onTap: () {
          _formKey.currentState?.reset();
          _emailController.clear();
          _passwordController.clear();
          _displayNameController.clear();
          setState(() {
            _isSignUpMode = !_isSignUpMode;
          });
          // Clear any error messages
          context.read<AuthController>().clearErrorMessage();
        },
        child: RichText(
          text: TextSpan(
            text: _isSignUpMode
                ? "Already have an account? "
                : "Don't have an account? ",
            style: TextStyle(color: Colors.grey[600]),
            children: [
              TextSpan(
                text: _isSignUpMode ? "Sign In" : "Sign Up",
                style: const TextStyle(
                  color: Color(0xFF1F41BB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle email/password sign in
  Future<void> _handleSignIn(AuthController authController) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoadingSignIn = true; // Set only the button to loading
    });

    try {
      if (_isSignUpMode) {
        final success = await authController.signUpWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
        );
        if (success) {
          _showSuccessMessage("Account created successfully!");
          _navigateToDashboard();
        }
      } else {
        final success = await authController.signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (success) {
          _showSuccessMessage(AppConstants.successLoginEmail);
          _navigateToDashboard();
        }
      }
    } finally {
      setState(() {
        _isLoadingSignIn = false; // ← Stop loading
      });
    }
  }

  /// Handle Google sign in
  Future<void> _handleGoogleSignIn(AuthController authController) async {
    setState(() {
      _isLoadingGoogle = true; // ← Set ONLY this button to loading
    });

    try {
      final success = await authController.signInWithGoogle();
      if (success) {
        _showSuccessMessage(AppConstants.successLoginGoogle);
        _navigateToDashboard();
      }
    } finally {
      setState(() {
        _isLoadingGoogle = false; // ← Stop loading
      });
    }
  }

  /// Handle guest sign in
  Future<void> _handleGuestSignIn(AuthController authController) async {
    setState(() {
      _isLoadingGuest = true; // ← Set ONLY this button to loading
    });

    try {
      final success = await authController.signInAsGuest();
      if (success) {
        _showSuccessMessage(AppConstants.successLoginGuest);
        _navigateToDashboard();
      }
    } finally {
      setState(() {
        _isLoadingGuest = false; // ← Stop loading
      });
    }
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Navigate to dashboard/home screen
  void _navigateToDashboard() {
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }
}
