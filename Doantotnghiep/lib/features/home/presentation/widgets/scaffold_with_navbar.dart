/// Custom Scaffold with Modern Bottom Navigation Bar
/// 
/// **Purpose:**
/// - Provides main app navigation with floating bottom bar
/// - Implements glassmorphism design (blurred glass effect)
/// - Auto-hides navigation bar when scrolling down
/// - Modern iOS-like navigation experience
/// - **NEW**: Expandable Center FAB with "Gear" rotation effect for Quick Actions
/// 
/// **Features:**
/// - 4 main navigation items (Home, Search, Messages, Profile) - Middle replaced by FAB
/// - Expandable Radial Menu in the center
/// - Smooth animations for show/hide
/// - Gradient background with decorative elements
/// - Backdrop blur effect for modern look
/// 
/// **Usage:**
/// Used as shell route in GoRouter to wrap main app screens.
/// Automatically handles navigation state and visual feedback.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/features/chat/data/chat_provider.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'dart:math' as math;

/// Scaffold with custom floating navigation bar
class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  /// Navigation shell widget from GoRouter
  final Widget navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

final bottomNavVisibilityProvider = StateProvider<bool>((ref) => true);

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _closeMenu() {
    if (_isMenuOpen) {
      setState(() {
        _isMenuOpen = false;
        _animationController.reverse();
      });
    }
  }

  /// Builds a sub-menu button that pops out at a specific angle
  Widget _buildSubMenuButton({
    required double angle, 
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    required Color color,
    bool isDisabled = false,
  }) {
    final double rad = angle * (math.pi / 180);
    const double radius = 75.0; // Reduced radius (closer to FAB)
    
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final double dist = _expandAnimation.value * radius;
        final double x = dist * math.sin(rad);
        final double y = -dist * math.cos(rad);

        // Fix: Clamp opacity to avoid crash with elastic curves
        final double opacity = _expandAnimation.value.clamp(0.0, 1.0);
        // Fix: Use a safer scale calculation for the bounce
        final double scale = _expandAnimation.value;

        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity: isDisabled ? 0.5 : opacity,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14), // Larger touch target
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), 
                    blurRadius: 12, 
                    offset: const Offset(0, 6)
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08), 
                    blurRadius: 8, 
                    offset: const Offset(0, 2)
                  )
                ],
              ),
              child: Text(
                label, 
                style: const TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w600, 
                  color: Colors.black87
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
     return Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFE4E9F2)], // More neutral, less saturated background
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ],
      );
  }

  // ... (keeping _buildNavItem and others)

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);
    final isNavVisible = ref.watch(bottomNavVisibilityProvider);

    return Scaffold(
      extendBody: true,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Background
          _buildBackground(),
          
          // 2. Main Content
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
               final isVisible = ref.read(bottomNavVisibilityProvider);
               if (notification.direction == ScrollDirection.reverse) {
                 if (isVisible) {
                   _closeMenu();
                   ref.read(bottomNavVisibilityProvider.notifier).state = false;
                 }
               } else if (notification.direction == ScrollDirection.forward) {
                 if (!isVisible) {
                   ref.read(bottomNavVisibilityProvider.notifier).state = true;
                 }
               }
               return false;
            },
            child: GestureDetector(
              onTap: _closeMenu,
              behavior: HitTestBehavior.translucent,
              child: widget.navigationShell,
            ),
          ),

          // 3. Dark Overlay
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isMenuOpen ? 1.0 : 0.0,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // Increased blur
                    child: Container(
                      color: Colors.black.withOpacity(0.2), // Reduced opacity
                    ),
                  ),
                ),
              ),
            ),

          // 4. Sub-Menu
          if (isNavVisible)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              bottom: isNavVisible ? 90 : -200, // Lowered closer to FAB (was 110)
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 300, 
                  height: 180,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      _buildSubMenuButton(
                        angle: -35, // Adjusted angle
                        icon: Icons.calendar_month_rounded, 
                        label: 'Lịch học',
                        color: const Color(0xFFEF6C00), // Custom Orange
                        onTap: () { _closeMenu(); context.go('/schedule'); }
                      ),
                      // Diễn đàn was here, now hidden
                       _buildSubMenuButton(
                        angle: 35, // Adjusted angle
                        icon: Icons.groups_rounded, // Changed from qr_code to groups
                        label: 'Nhóm của tôi', // Changed from Scan QR
                        color: const Color(0xFF7B1FA2), // Custom Purple
                        onTap: () { _closeMenu(); context.push('/my-study-groups'); } // Route to My Groups
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Navigation Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            bottom: isNavVisible ? 24 : -100,
            left: 24,
            right: 24,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Glass Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9), // Higher opacity for cleaner look
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05), // Softer shadow
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                            spreadRadius: 0,
                          ),
                        ],
                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(context, icon: Icons.home_outlined, activeIcon: Icons.home_rounded, index: 0, currentIndex: selectedIndex),
                          _buildNavItem(context, icon: Icons.search_outlined, activeIcon: Icons.search_rounded, index: 1, currentIndex: selectedIndex),
                          const SizedBox(width: 48), 
                          _buildNavItem(context, icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble_rounded, index: 3, currentIndex: selectedIndex),
                          _buildNavItem(context, icon: Icons.person_outline, activeIcon: Icons.person_rounded, index: 4, currentIndex: selectedIndex),
                        ],
                      ),
                    ),
                  ),
                ),

                // Center FAB - Refined Design (No Neon)
                Positioned(
                  top: -24, 
                  child: GestureDetector(
                    onTap: _toggleMenu,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 68, // Slightly larger
                      height: 68,
                      decoration: BoxDecoration(
                        // Clean gradient, avoiding "Neon"
                        gradient: LinearGradient(
                          colors: _isMenuOpen 
                            ? [const Color(0xFFDC2626), const Color(0xFFEF4444)] // Red
                            : [const Color(0xFF2563EB), const Color(0xFF3B82F6)], // Standard Blue
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isMenuOpen ? Colors.red : Colors.blue).withOpacity(0.3), // Lower opacity
                            blurRadius: 12,
                            spreadRadius: 2, // Reduced spread
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 4), // Thicker white border
                      ),
                      child: RotationTransition(
                        turns: Tween(begin: 0.0, end: 0.125).animate(_rotateAnimation), // 45 degrees (plus to x)
                        child: const Icon(
                          Icons.add_rounded, 
                          color: Colors.white, 
                          size: 40,
                        ),
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

  Widget _buildNavItem(BuildContext context, {required IconData icon, required IconData activeIcon, required int index, required int currentIndex}) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(context, index),
        behavior: HitTestBehavior.translucent,
        child: Container(
          alignment: Alignment.center,
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildIconWithBadge(context, isSelected, icon, activeIcon, index),
          ),
          ),
        ),
    );
  }

  Widget _buildIconWithBadge(BuildContext context, bool isSelected, IconData icon, IconData activeIcon, int index) {
      Widget iconWidget = Icon(
        isSelected ? activeIcon : icon,
        size: 26,
        color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade500,
      );

      // Chat Badge (Index 3)
      if (index == 3) {
        final unreadAsync = ref.watch(totalUnreadChatCountProvider);
        return unreadAsync.when(
          data: (count) => count > 0 ? Badge(label: Text('$count'), backgroundColor: Colors.red, child: iconWidget) : iconWidget,
          loading: () => iconWidget,
          error: (_, __) => iconWidget,
        );
      }
      return iconWidget;
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/')) {
      if (location == '/') return 0;
      if (location.startsWith('/search')) return 1;
      if (location.startsWith('/schedule')) return 2;
      if (location.startsWith('/messages')) return 3;
      if (location.startsWith('/profile') || location.startsWith('/wallet')) return 4;
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    if (_isMenuOpen) {
      _closeMenu();
    }
    
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/search'); break;
      case 2: context.go('/schedule'); break; // Still reachable, but not via nav bar button directly
      case 3: context.go('/messages'); break;
      case 4: context.go('/profile'); break;
    }
  }
}
