import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';

class Gig {
  final String id;
  final String title;
  final String location;
  final String date;
  final String budget;
  final String? tag;
  final Timestamp createdAt;

  Gig({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.budget,
    this.tag,
    required this.createdAt,
  });

  factory Gig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gig(
      id: doc.id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      date: data['date'] ?? '',
      budget: data['budget'] ?? '',
      tag: data['tag'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}

class UserStats {
  final int applied;
  final int accepted;
  final double rating;

  UserStats({
    required this.applied,
    required this.accepted,
    required this.rating,
  });
}

// Riverpod Providers
final featuredGigProvider = StreamProvider<Gig?>((ref) {
  return FirebaseFirestore.instance
      .collection('gigs')
      .where('status', isEqualTo: 'open')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isNotEmpty 
          ? Gig.fromFirestore(snapshot.docs.first) 
          : null);
});

final nearbyGigsProvider = StreamProvider<List<Gig>>((ref) {
  return FirebaseFirestore.instance
      .collection('gigs')
      .where('status', isEqualTo: 'open')
      .orderBy('createdAt', descending: true)
      .limit(3)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Gig.fromFirestore(doc))
          .toList());
});

final userStatsProvider = StreamProvider<UserStats>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value(UserStats(applied: 0, accepted: 0, rating: 0.0));
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) {
        final data = doc.data()!;
        return UserStats(
          applied: data['appliedCount'] ?? 0,
          accepted: data['acceptedCount'] ?? 0,
          rating: (data['rating'] ?? 0.0).toDouble(),
        );
      });
});

final userNameProvider = FutureProvider<String>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return 'Musician';
  
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();
  
  return doc.data()?['name'] ?? 'Musician';
});

// Mock providers for development - remove when real data is available
final mockFeaturedGigProvider = FutureProvider<Gig?>((ref) async {
  return Gig(
    id: '1',
    title: 'Live Band - Wedding Reception',
    location: 'Iloilo City',
    date: 'Jan 25, 2025',
    budget: '₱10,000',
    tag: null,
    createdAt: Timestamp.now(),
  );
});

final mockNearbyGigsProvider = FutureProvider<List<Gig>>((ref) async {
  return [
    Gig(
      id: '2',
      title: 'Acoustic Set - Coffee Shop',
      location: 'Koronadal',
      date: 'Jan 28, 2025',
      budget: '₱2,500',
      tag: 'CAFÉ',
      createdAt: Timestamp.now(),
    ),
    Gig(
      id: '3',
      title: 'Corporate Event Band',
      location: 'GenSan',
      date: 'Feb 2, 2025',
      budget: '₱15,000',
      tag: 'CORPORATE',
      createdAt: Timestamp.now(),
    ),
    Gig(
      id: '4',
      title: 'Birthday Party Acoustic',
      location: 'Tacurong',
      date: 'Feb 5, 2025',
      budget: '₱5,000',
      tag: 'PARTY',
      createdAt: Timestamp.now(),
    ),
  ];
});

final mockUserStatsProvider = FutureProvider<UserStats>((ref) async {
  return UserStats(
    applied: 5,
    accepted: 2,
    rating: 4.8,
  );
});

final mockUserNameProvider = FutureProvider<String>((ref) async {
  return 'Juan dela Cruz';
});

class MusicianHomeScreen extends ConsumerStatefulWidget {
  const MusicianHomeScreen({super.key});

  @override
  ConsumerState<MusicianHomeScreen> createState() => _MusicianHomeScreenState();
}

class _MusicianHomeScreenState extends ConsumerState<MusicianHomeScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _refresh() async {
    // Trigger refresh by invalidating providers
    ref.invalidate(featuredGigProvider);
    ref.invalidate(nearbyGigsProvider);
    ref.invalidate(userStatsProvider);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    // Use mock providers for development - switch to real providers when data is available
    final userNameAsync = ref.watch(mockUserNameProvider);
    final featuredGigAsync = ref.watch(mockFeaturedGigProvider);
    final nearbyGigsAsync = ref.watch(mockNearbyGigsProvider);
    final userStatsAsync = ref.watch(mockUserStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refresh,
        color: AppColors.amber,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 80.0,
            bottom: 100.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 9,
                          color: AppColors.sub,
                        ),
                      ),
                      const SizedBox(height: 4),
                      userNameAsync.when(
                        data: (name) => Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Cormorant Garamond',
                            fontSize: 18,
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        loading: () => const SizedBox(
                          width: 120,
                          height: 28,
                          child: Skeleton(),
                        ),
                        error: (_, __) => const Text(
                          'Musician',
                          style: TextStyle(
                            fontFamily: 'Cormorant Garamond',
                            fontSize: 22,
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.amber, AppColors.copper],
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bar 1 — short, opacity 0.45
                          Container(
                            width: 2,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.bg.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 2),
                          // Bar 2 — medium, opacity 0.70
                          Container(
                            width: 2,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.bg.withOpacity(0.70),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 2),
                          // Bar 3 — tallest, full opacity, slightly thicker
                          Container(
                            width: 3,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                          const SizedBox(width: 2),
                          // Bar 4 — medium, opacity 0.70
                          Container(
                            width: 2,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.bg.withOpacity(0.70),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 2),
                          // Bar 5 — short, opacity 0.45
                          Container(
                            width: 2,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.bg.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats Row
              userStatsAsync.when(
                  data: (stats) => Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'APPLIED',
                          value: stats.applied.toString(),
                          color: AppColors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'ACCEPTED',
                          value: stats.accepted.toString(),
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'RATING',
                          value: stats.rating.toStringAsFixed(1),
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  loading: () => Row(
                    children: List.generate(3, (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                        child: const Skeleton(height: 80),
                      ),
                    )),
                  ),
                  error: (_, _) => const SizedBox(),
                ),
              const SizedBox(height: 16),
              // Featured Gig
              featuredGigAsync.when(
                data: (gig) => gig != null ? _FeaturedGigCard(gig: gig) : const SizedBox(),
                loading: () => const Skeleton(height: 140),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),
              // Near You Section
              Text(
                'NEAR YOU',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: AppColors.muted,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // Nearby Gigs List
              nearbyGigsAsync.when(
                  data: (gigs) => Column(
                    children: gigs.map((gig) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NearbyGigCard(gig: gig),
                    )).toList(),
                  ),
                  loading: () => Column(
                    children: List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: const Skeleton(height: 80),
                    )),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              color: AppColors.muted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cormorant Garamond',
              fontSize: 22,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedGigCard extends StatelessWidget {
  final Gig gig;

  const _FeaturedGigCard({required this.gig});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.amber, AppColors.copper],
        ),
      ),
      child: Stack(
        children: [
          // Dark circle decoration
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 8,
                      color: AppColors.bg,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gig.title,
                  style: const TextStyle(
                    fontFamily: 'Cormorant Garamond',
                    fontSize: 16,
                    color: AppColors.bg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: AppColors.bg.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${gig.location} • ${gig.date}',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: AppColors.bg.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  gig.budget,
                  style: const TextStyle(
                    fontFamily: 'Cormorant Garamond',
                    fontSize: 18,
                    color: AppColors.bg,
                    fontWeight: FontWeight.w600,
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

class _NearbyGigCard extends StatelessWidget {
  final Gig gig;

  const _NearbyGigCard({required this.gig});

  Color _getTagColor(String tag) {
    switch (tag.toUpperCase()) {
      case 'CAFÉ':
        return const Color(0xFF00C896).withOpacity(0.2); // Green
      case 'CORPORATE':
        return const Color(0xFFF5A623).withOpacity(0.2); // Amber
      case 'PARTY':
        return const Color(0xFF8B6FFF).withOpacity(0.2); // Violet
      default:
        return AppColors.amberDim;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // No fixed height — let content determine height
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    gig.title,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (gig.tag != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTagColor(gig.tag!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        gig.tag!,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 9,
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 10,
                        color: AppColors.sub,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        gig.location,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          color: AppColors.sub,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              gig.budget,
              style: const TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize: 15,
                color: AppColors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            iconData: Icons.home,
            label: 'Home',
            isActive: true,
            onTap: () {},
          ),
          _NavItem(
            iconData: Icons.work,
            label: 'Gigs',
            isActive: false,
            onTap: () => context.go('/gigs'),
          ),
          _NavItem(
            iconData: Icons.send,
            label: 'Applied',
            isActive: false,
            onTap: () => context.go('/applications'),
          ),
          _NavItem(
            iconData: Icons.person,
            label: 'Profile',
            isActive: false,
            onTap: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData iconData;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconData,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 24,
            color: isActive ? AppColors.text : AppColors.sub,
          ),
          const SizedBox(height: 4),
          Container(
            width: 14,
            height: 2,
            decoration: BoxDecoration(
              color: isActive ? AppColors.amber : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

// SVG Icons
class _HomeIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _HomeIconPainter(),
    );
  }
}

class _HomeIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.amber
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(12, 3);
    path.lineTo(3, 12);
    path.lineTo(3, 21);
    path.lineTo(9, 21);
    path.lineTo(9, 15);
    path.lineTo(15, 15);
    path.lineTo(15, 21);
    path.lineTo(21, 21);
    path.lineTo(21, 12);
    path.lineTo(12, 3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GigsIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _GigsIconPainter(),
    );
  }
}

class _GigsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.muted.withOpacity(0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Music note
    final path = Path();
    path.moveTo(8, 3);
    path.lineTo(8, 17);
    path.moveTo(8, 5);
    path.lineTo(16, 3);
    path.lineTo(16, 15);
    
    // Note heads
    canvas.drawCircle(const Offset(8, 19), 3, paint);
    canvas.drawCircle(const Offset(16, 17), 3, paint);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppliedIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _AppliedIconPainter(),
    );
  }
}

class _AppliedIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.muted.withOpacity(0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(4, 6);
    path.lineTo(4, 20);
    path.lineTo(20, 20);
    path.lineTo(20, 6);
    path.lineTo(4, 6);
    path.moveTo(4, 10);
    path.lineTo(20, 10);
    path.moveTo(8, 3);
    path.lineTo(8, 6);
    path.lineTo(16, 6);
    path.lineTo(16, 3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _ProfileIconPainter(),
    );
  }
}

class _ProfileIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.muted.withOpacity(0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Head
    canvas.drawCircle(const Offset(12, 8), 4, paint);
    
    // Body
    final path = Path();
    path.moveTo(4, 21);
    path.quadraticBezierTo(12, 16, 20, 21);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Skeleton extends StatelessWidget {
  final double? height;
  final double? width;

  const Skeleton({super.key, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
