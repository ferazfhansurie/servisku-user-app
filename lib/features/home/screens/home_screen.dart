import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../shared/widgets/nearby_services_map.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  Position? _currentPosition;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  late AnimationController _fadeController;
  late AnimationController _headerController;
  late AnimationController _floatingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initAnimations();

    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  void _initAnimations() {
    // Main fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    // Header slide animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );

    // Floating animation for decorative elements
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Start animations with stagger
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _headerController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerController.dispose();
    _floatingController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (kIsWeb) return;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      // Handle location error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // Animated background gradient
          _AnimatedBackground(scrollOffset: _scrollOffset),

          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Animated Header
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _headerSlideAnimation,
                    child: FadeTransition(
                      opacity: _headerFadeAnimation,
                      child: _AnimatedHeader(
                        searchController: _searchController,
                        onSearch: (query) {
                          if (query.isNotEmpty) {
                            context.go('/search?q=$query');
                          }
                        },
                        floatingController: _floatingController,
                      ),
                    ),
                  ),
                ),

                // Main Content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Nearby Services Map (shows providers near user)
                      NearbyServicesMap(
                        userLat: _currentPosition?.latitude,
                        userLng: _currentPosition?.longitude,
                      ),
                      const SizedBox(height: 20),

                      // Emergency Help Button
                      _AnimatedEmergencyButton(
                          onTap: () => context.go('/help')),
                      const SizedBox(height: 28),

                      // Services Section
                      _AnimatedSectionTitle(title: 'All Services', delay: 400),
                      const SizedBox(height: 16),
                      const _AnimatedServicesGrid(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Animated Background with gradient shift
class _AnimatedBackground extends StatelessWidget {
  final double scrollOffset;

  const _AnimatedBackground({required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    final progress = (scrollOffset / 300).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              const Color(0xFFF5F7FA),
              const Color(0xFFE8F4F8),
              progress,
            )!,
            Color.lerp(
              const Color(0xFFFFFFFF),
              const Color(0xFFFFF8E1),
              progress,
            )!,
          ],
        ),
      ),
    );
  }
}

// Animated Header with floating elements
class _AnimatedHeader extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final AnimationController floatingController;

  const _AnimatedHeader({
    required this.searchController,
    required this.onSearch,
    required this.floatingController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo and greeting
          Row(
            children: [
              // Animated Logo
              AnimatedBuilder(
                animation: floatingController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0,
                        math.sin(floatingController.value * math.pi * 2) * 2),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB800).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.handyman_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
                      ).createShader(bounds),
                      child: const Text(
                        'ServisKu',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const Text(
                      'Find the perfect service',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              _AnimatedIconButton(
                icon: Icons.notifications_outlined,
                onTap: () {},
                badge: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Animated Search Bar
          _AnimatedSearchBar(
            controller: searchController,
            onSubmitted: onSearch,
          ),
        ],
      ),
    );
  }
}

// Animated Icon Button with ripple
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _AnimatedIconButton({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: const Color(0xFF374151),
                size: 22,
              ),
            ),
            if (widget.badge)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Animated Search Bar with shine effect
class _AnimatedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;

  const _AnimatedSearchBar({
    required this.controller,
    required this.onSubmitted,
  });

  @override
  State<_AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<_AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? const Color(0xFFFFB800) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? const Color(0xFFFFB800).withOpacity(0.2)
                : Colors.black.withOpacity(0.06),
            blurRadius: _isFocused ? 20 : 12,
            offset: const Offset(0, 4),
            spreadRadius: _isFocused ? 2 : 0,
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        onTap: () {
          setState(() => _isFocused = true);
          _shineController.forward(from: 0);
        },
        onTapOutside: (_) {
          setState(() => _isFocused = false);
          FocusScope.of(context).unfocus();
        },
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          hintText: 'What service do you need?',
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: _isFocused
                  ? const Color(0xFFFFB800)
                  : const Color(0xFF9CA3AF),
              size: 24,
            ),
          ),
          suffixIcon: AnimatedScale(
            scale: _isFocused ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB800), Color(0xFFFF9500)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB800).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}

// Animated Emergency Button
class _AnimatedEmergencyButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedEmergencyButton({required this.onTap});

  @override
  State<_AnimatedEmergencyButton> createState() =>
      _AnimatedEmergencyButtonState();
}

class _AnimatedEmergencyButtonState extends State<_AnimatedEmergencyButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _shakeController.forward(from: 0).then((_) {
      _shakeController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.heavyImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _shakeController]),
        builder: (context, child) {
          final shakeOffset =
              math.sin(_shakeController.value * math.pi * 4) * 3;

          return Transform.translate(
            offset: Offset(shakeOffset, 0),
            child: AnimatedScale(
              scale: _isPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF6B6B),
                      Color(0xFFEE5A5A),
                      Color(0xFFD63031),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B)
                          .withOpacity(0.3 + (_pulseController.value * 0.2)),
                      blurRadius: 24 + (_pulseController.value * 12),
                      offset: const Offset(0, 10),
                      spreadRadius: _pulseController.value * 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Animated icon container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1 + _pulseController.value * 0.1,
                            child: const Icon(
                              Icons.emergency_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Help Now?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap for instant assistance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Section Title
class _AnimatedSectionTitle extends StatefulWidget {
  final String title;
  final int delay;

  const _AnimatedSectionTitle({required this.title, this.delay = 0});

  @override
  State<_AnimatedSectionTitle> createState() => _AnimatedSectionTitleState();
}

class _AnimatedSectionTitleState extends State<_AnimatedSectionTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Row(
                children: [
                  const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFB800),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: const Color(0xFFFFB800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Services Grid
class _AnimatedServicesGrid extends StatelessWidget {
  static const List<Map<String, dynamic>> _services = [
    {
      'name': 'Home',
      'icon': Icons.home_rounded,
      'gradient': [Color(0xFF4CAF50), Color(0xFF2E7D32)],
      'slug': 'home'
    },
    {
      'name': 'Transport',
      'icon': Icons.directions_car_rounded,
      'gradient': [Color(0xFF2196F3), Color(0xFF1565C0)],
      'slug': 'transport'
    },
    {
      'name': 'Beauty',
      'icon': Icons.spa_rounded,
      'gradient': [Color(0xFFE91E63), Color(0xFFC2185B)],
      'slug': 'personal-care'
    },
    {
      'name': 'Events',
      'icon': Icons.celebration_rounded,
      'gradient': [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
      'slug': 'events'
    },
    {
      'name': 'Business',
      'icon': Icons.business_center_rounded,
      'gradient': [Color(0xFF607D8B), Color(0xFF37474F)],
      'slug': 'business'
    },
    {
      'name': 'Tech',
      'icon': Icons.computer_rounded,
      'gradient': [Color(0xFF00BCD4), Color(0xFF0097A7)],
      'slug': 'tech'
    },
    {
      'name': 'Pets',
      'icon': Icons.pets_rounded,
      'gradient': [Color(0xFFFF9800), Color(0xFFF57C00)],
      'slug': 'pets'
    },
    {
      'name': 'Learning',
      'icon': Icons.school_rounded,
      'gradient': [Color(0xFF673AB7), Color(0xFF4527A0)],
      'slug': 'learning'
    },
  ];

  const _AnimatedServicesGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final item = _services[index];
        return _AnimatedServiceCard(
          name: item['name'] as String,
          icon: item['icon'] as IconData,
          gradient: item['gradient'] as List<Color>,
          slug: item['slug'] as String,
          index: index,
        );
      },
    );
  }
}

// Animated Service Card
class _AnimatedServiceCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final List<Color> gradient;
  final String slug;
  final int index;

  const _AnimatedServiceCard({
    required this.name,
    required this.icon,
    required this.gradient,
    required this.slug,
    required this.index,
  });

  @override
  State<_AnimatedServiceCard> createState() => _AnimatedServiceCardState();
}

class _AnimatedServiceCardState extends State<_AnimatedServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    Future.delayed(Duration(milliseconds: 300 + widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            HapticFeedback.lightImpact();
            context.go('/search?category=${widget.slug}');
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.9 : (_isHovered ? 1.05 : 1.0),
            duration: const Duration(milliseconds: 150),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.gradient,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient[0]
                            .withOpacity(_isHovered ? 0.5 : 0.3),
                        blurRadius: _isHovered ? 16 : 12,
                        offset: const Offset(0, 4),
                        spreadRadius: _isHovered ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
