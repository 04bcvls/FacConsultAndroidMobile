import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? leftIcon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final double borderRadius;
  final double padding;
  final double height;
  final bool isOutlined;
  final Color? iconColor;

  const CustomButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.leftIcon,
    this.backgroundColor = const Color(0xFF1F41BB), // Primary blue
    this.textColor = Colors.white,
    this.borderColor,
    this.borderRadius = 12.0,
    this.padding = 16.0,
    this.height = 56.0,
    this.isOutlined = false,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: isOutlined ? _buildOutlinedButton() : _buildFilledButton(),
    );
  }

  /// Build filled button (solid background)
  Widget _buildFilledButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
      ),
      child: _buildButtonContent(),
    );
  }

  /// Build outlined button (transparent background with border)
  Widget _buildOutlinedButton() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor ?? backgroundColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: _buildButtonContent(isOutlined: true),
          ),
        ),
      ),
    );
  }

  /// Build button content (icon + text or loading indicator)
  Widget _buildButtonContent({bool isOutlined = false}) {
    if (isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
              strokeWidth: 2.5,
            ),
          ),
        ],
      );
    }

    if (leftIcon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            leftIcon,
            color: iconColor ?? textColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
