import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../main.dart' as main;

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
      drawer: _Drawer(),
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
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Stats Dashboard
              userStatsAsync.when(
                  data: (stats) => _BusinessDashboard(
                    applied: stats.applied,
                    accepted: stats.accepted,
                    rating: stats.rating,
                  ),
                  loading: () => Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.violet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Skeleton(height: 120),
                  ),
                  error: (_, _) => const SizedBox(),
                ),
              const SizedBox(height: 24),
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
      bottomNavigationBar: const BottomNavBar(activeTab: 'home'),
    );
  }
}

class _MusicianMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _MusicianMetric({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: color.withOpacity(0.8),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _BusinessDashboard extends StatelessWidget {
  final int applied;
  final int accepted;
  final double rating;

  const _BusinessDashboard({
    required this.applied,
    required this.accepted,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header with title
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.amber, AppColors.copper],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    size: 20,
                    color: AppColors.bg,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Musician Overview',
                  style: TextStyle(
                    fontFamily: 'Cormorant Garamond',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MusicianMetric(
                value: applied >= 1000 ? '${(applied / 1000).toStringAsFixed(1)}K' : applied.toString(),
                label: 'Applied',
                color: AppColors.amber,
                icon: Icons.send_rounded,
              ),
              
              // Vertical divider
              Container(
                width: 1,
                height: 40,
                color: AppColors.border.withOpacity(0.3),
              ),
              
              _MusicianMetric(
                value: accepted >= 1000 ? '${(accepted / 1000).toStringAsFixed(1)}K' : accepted.toString(),
                label: 'Accepted',
                color: const Color(0xFF00C896),
                icon: Icons.check_circle_outline_rounded,
              ),
              
              // Vertical divider
              Container(
                width: 1,
                height: 40,
                color: AppColors.border.withOpacity(0.3),
              ),
              
              _MusicianMetric(
                value: rating.toStringAsFixed(1),
                label: 'Rating',
                color: AppColors.violet,
                icon: Icons.star_border_rounded,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                context.go('/applications');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: AppColors.bg,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'View Applications',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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

class _Drawer extends StatefulWidget {
  const _Drawer({super.key});

  @override
  State<_Drawer> createState() => _DrawerState();
}

class _DrawerState extends State<_Drawer> {
  Future<void> _logout(BuildContext context) async {
    // Check if context is valid before proceeding
    if (!context.mounted) return;
    
    // Capture the root navigator context BEFORE
    // showing the dialog — this stays valid even
    // after the drawer and dialog are both closed
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final rootContext = rootNavigator.context;

    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.red,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to logout?',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    color: AppColors.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldLogout == true) {
      print('Starting drawer logout process...');
      
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      print('Firebase sign out completed');
      
      // Navigate immediately using root context
      print('Attempting navigation to login screen...');
      
      try {
        rootContext.go('/login');
        print('GoRouter navigation successful using root context');
      } catch (e) {
        print('GoRouter failed with root context: $e');
        try {
          GoRouter.of(rootContext).go('/login');
          print('GoRouter.of navigation successful using root context');
        } catch (e2) {
          print('GoRouter.of failed with root context: $e2');
          // Last resort - use root navigator
          rootNavigator.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
          print('Root navigator navigation attempted');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.card,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.amber, AppColors.copper],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // GigSugo Logo
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.bg,
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
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.bg.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 1),
                        // Bar 2 — medium, opacity 0.70
                        Container(
                          width: 2,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.bg.withOpacity(0.70),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 1),
                        // Bar 3 — tallest, full opacity, slightly thicker
                        Container(
                          width: 2,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 1),
                        // Bar 4 — medium, opacity 0.70
                        Container(
                          width: 2,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.bg.withOpacity(0.70),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 1),
                        // Bar 5 — short, opacity 0.45
                        Container(
                          width: 2,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.bg.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'GigSugo',
                  style: TextStyle(
                    fontFamily: 'Cormorant Garamond',
                    fontSize: 18,
                    color: AppColors.bg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.text),
            title: const Text(
              'Profile',
              style: TextStyle(
                fontFamily: 'DM Sans',
                color: AppColors.text,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              // Navigate to profile - you can add router navigation here
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppColors.text),
            title: const Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'DM Sans',
                color: AppColors.text,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings - you can add router navigation here
            },
          ),
          const Divider(color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.red),
            title: const Text(
              'Log Out',
              style: TextStyle(
                fontFamily: 'DM Sans',
                color: AppColors.red,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _logout(context);
            },
          ),
        ],
      ),
    );
  }
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
