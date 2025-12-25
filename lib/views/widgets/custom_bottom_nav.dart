import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // The main white background bar
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, -4),
                blurRadius: 20,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Ana Sayfa'),
                _buildNavItem(1, Icons.messenger, 'Sohbet'),
                // Placeholder for the center item (it will be positioned absolutely)
                const SizedBox(width: 70),
                _buildNavItem(3, Icons.swap_horiz_rounded, 'Takaslarım'),
                _buildNavItem(4, Icons.person_rounded, 'Hesap'),
              ],
            ),
          ),
        ),
        // The Floating Center Item
        Positioned(
          top: -30, // Raise it above the bar
          child: _buildCenterItem(2, Icons.swap_horiz_rounded, 'İlan Ekle'),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? AppTheme.primary : const Color(0xFF94A3B8);

    return Expanded(
      child: InkWell(
        onTap: () => onItemSelected(index),
        splashColor: AppTheme.primary.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.safePoppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterItem(int index, IconData icon, String label) {
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3), // Border effect
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.safePoppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
