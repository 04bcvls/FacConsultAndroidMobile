/// App-wide constants
class AppConstants {
  // User Roles
  static const String roleStudent = "student";
  static const String roleGuest = "guest";
  static const String roleEditor = "editor";
  static const String roleAdmin = "admin";
  static const String roleViewer = "viewer"; // Legacy

  // Login Methods
  static const String loginMethodGoogle = "google";
  static const String loginMethodEmail = "email";
  static const String loginMethodGuest = "guest";

  // Firebase Collections
  static const String usersCollection = "users";
  static const String rolesCollection = "roles";
  static const String facultyCollection = "faculty";
  static const String departmentsCollection = "departments";
  static const String schedulesCollection = "schedules";
  static const String bookingsCollection = "bookings";
  static const String appointmentsCollection = "appointments";
  static const String notificationsCollection = "notifications";

  // Firestore Document Fields
  static const String fieldUid = "uid";
  static const String fieldEmail = "email";
  static const String fieldDisplayName = "displayName";
  static const String fieldPhotoUrl = "photoUrl";
  static const String fieldRole = "role";
  static const String fieldLoginMethod = "loginMethod";
  static const String fieldCreatedAt = "createdAt";

  // Google Sign-In Configuration
  static const String googleServerClientId =
      ""; // TODO: Add your Google Server Client ID for ADDU Mail
  static const List<String> allowedEmailDomains = [
    '@addu.edu.ph'
  ];

  // App Strings
  static const String appName = "AndFac Consult";
  static const String appTitle = "AndFac Consultation";

  // Login Screen Strings
  static const String loginWelcome = "JuCi Faculty Consultation Scheduler";
  static const String loginSubtitle = "Sign in to your account";
  static const String loginEmail = "Email";
  static const String loginPassword = "Password";
  static const String loginButton = "Sign In";
  static const String loginGoogle = "Sign in with Google";
  static const String loginGuest = "Continue as Guest";
  static const String loginForgotPassword = "Forgot Password?";
  static const String loginNoAccount = "Don't have an account? Sign up";

  // Error Messages
  static const String errorInvalidEmail = "Please enter a valid email";
  static const String errorPasswordTooShort =
      "Password must be at least 6 characters";
  static const String errorEmptyEmail = "Email cannot be empty";
  static const String errorEmptyPassword = "Password cannot be empty";
  static const String errorUnauthorizedEmail =
      "Only Ateneo de Davao University (ADDU) Google accounts are allowed";
  static const String errorLoginFailed = "Login failed. Please try again.";
  static const String errorGoogleSignInFailed =
      "Google Sign-In failed. Please try again.";
  static const String errorNetworkError =
      "Network error. Please check your connection.";
  static const String errorUnknownError = "An unknown error occurred.";

  // Success Messages
  static const String successLoginGoogle = "Successfully signed in with ADDU Google";
  static const String successLoginEmail = "Successfully signed in with Email";
  static const String successLoginGuest = "Logged in as Guest";

  // Duration Constants (in milliseconds)
  static const int toastDuration = 2000;
  static const int loadingAnimationDuration = 800;
  static const int navigationDelay = 500;
}
