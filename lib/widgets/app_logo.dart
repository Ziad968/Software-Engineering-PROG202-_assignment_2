import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// Displays the Limkokwing logo image at any specified size.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showBorder;

  const AppLogo({
    super.key,
    this.size = 72,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: showBorder
            ? Border.all(color: AppColors.primaryRed.withOpacity(0.25), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.14),
        child: Image.asset(
          AppConstants.logoAssetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.school,
            size: size * 0.55,
            color: AppColors.primaryRed,
          ),
        ),
      ),
    );
  }
}