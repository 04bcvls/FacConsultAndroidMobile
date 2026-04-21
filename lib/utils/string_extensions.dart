/// String extension utilities
extension StringExtension on String {
  /// Capitalize the first letter of a string
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  /// Mask ID for privacy: show first half, asterisk second half
  /// Example: "TlmnIImQyeXF123456" becomes "TlmnIImQyeXF*******"
  String maskId() {
    if (isEmpty) return this;
    final midpoint = (length / 2).ceil();
    final firstHalf = substring(0, midpoint);
    final secondHalf = '*' * (length - midpoint);
    return firstHalf + secondHalf;
  }
}
