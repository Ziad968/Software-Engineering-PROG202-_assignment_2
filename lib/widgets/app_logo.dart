import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// Displays the Limkokwing logo large with minimal framing inside a clean shape.
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
    final radius = BorderRadius.circular(size * 0.18);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.02),
      decoration: ShapeDecoration(
        color: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: showBorder
              ? BorderSide(
                  color: AppColors.primaryRed.withOpacity(0.35),
                  width: 1,
                )
              : BorderSide.none,
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.15),
        child: Transform.scale(
          scale: 1.15,
          child: Image.asset(
            AppConstants.logoAssetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.image_not_supported_outlined,
              size: size * 0.5,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}