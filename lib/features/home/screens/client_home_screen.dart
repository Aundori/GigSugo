import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: _Drawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting and Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hello, Client',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            color: AppColors.sub,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final name = snapshot.data?.get('name') ?? 'Client';
                            return Text(
                              name,
                              style: const TextStyle(
                                fontFamily: 'Cormorant Garamond',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // GigSugo Logo - Functional
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
                            colors: [AppColors.violet, Color(0xFF6B4FFF)],
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
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              const SizedBox(width: 1),
                              // Bar 2 — medium, opacity 0.70
                              Container(
                                width: 2,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.70),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              const SizedBox(width: 1),
                              // Bar 3 — tallest, full opacity, slightly thicker
                              Container(
                                width: 2,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              const SizedBox(width: 1),
                              // Bar 4 — medium, opacity 0.70
                              Container(
                                width: 2,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.70),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              const SizedBox(width: 1),
                              // Bar 5 — short, opacity 0.45
                              Container(
                                width: 2,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.45),
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
            ),
            
            // Stats Overview
           Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _ClientOverview(),
            ),
            
            const SizedBox(height: 24),
            
            // Active Listings Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'ACTIVE LISTINGS',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.muted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Listings
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ActiveListings(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/post-gig'),
        backgroundColor: AppColors.amber,
        shape: const CircleBorder(),
        elevation: 0,
        mini: true,
        child: const Icon(
          Icons.add,
          size: 12,
          color: AppColors.bg,
        ),
      ),
      bottomNavigationBar: const BottomNavBar(activeTab: 'home', userType: 'client'),
    );
  }
}

class _ClientOverview extends ConsumerWidget {
  const _ClientOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock data for demonstration - replace with real data when ready
    final mockActiveGigs = 5;
    final mockTotalHired = 13;
    final mockPending = 5;
    final mockCompleted = 28;
    
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
                    Icons.analytics_outlined,
                    size: 20,
                    color: AppColors.bg,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Business Overview',
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
              _OverviewMetric(
                value: mockActiveGigs.toString(),
                label: 'Active Gigs',
                color: AppColors.amber,
                icon: Icons.live_tv_outlined,
              ),
              
              // Vertical divider
              Container(
                width: 1,
                height: 40,
                color: AppColors.border.withOpacity(0.3),
              ),
              
              _OverviewMetric(
                value: mockTotalHired.toString(),
                label: 'Total Hired',
                color: const Color(0xFF00C896),
                icon: Icons.person_add_outlined,
              ),
              
              // Vertical divider
              Container(
                width: 1,
                height: 40,
                color: AppColors.border.withOpacity(0.3),
              ),
              
              _OverviewMetric(
                value: mockPending.toString(),
                label: 'Pending',
                color: const Color(0xFFFFD166),
                icon: Icons.hourglass_empty_outlined,
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
                context.push('/my-gigs');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 16,
                    color: AppColors.bg,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'View My Gigs',
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

class _OverviewMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _OverviewMetric({
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
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
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

class _ActiveListings extends StatelessWidget {
  const _ActiveListings();

  @override
  Widget build(BuildContext context) {
    // Mock listings for demonstration
    final mockListings = [
      {
        'id': '1',
        'title': 'Jazz Trio for Wedding Reception',
        'location': 'New York, NY',
        'date': 'Dec 15, 2024',
        'budget': '\$1,500',
        'applicantCount': 8,
      },
      {
        'id': '2', 
        'title': 'Rock Band for Corporate Event',
        'location': 'Los Angeles, CA',
        'date': 'Dec 20, 2024',
        'budget': '\$2,000',
        'applicantCount': 12,
      },
      {
        'id': '3',
        'title': 'Acoustic Duo for Restaurant',
        'location': 'Chicago, IL', 
        'date': 'Dec 18, 2024',
        'budget': '\$800',
        'applicantCount': 5,
      },
    ];
    
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: mockListings.length,
      itemBuilder: (context, index) {
        final gig = mockListings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ListingCard(
            gigId: gig['id'] as String,
            title: gig['title'] as String,
            location: gig['location'] as String,
            date: gig['date'] as String,
            budget: gig['budget'] as String,
            applicantCount: gig['applicantCount'] as int,
          ),
        );
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  final String gigId;
  final String title;
  final String location;
  final String date;
  final String budget;
  final int applicantCount;

  const _ListingCard({
    required this.gigId,
    required this.title,
    required this.location,
    required this.date,
    required this.budget,
    required this.applicantCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/applicants/$gigId?title=${Uri.encodeComponent(title)}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1424),
          border: Border.all(color: const Color(0xFF1C2338)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            
            // Location and Date
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 12,
                  color: AppColors.sub,
                ),
                const SizedBox(width: 4),
                Text(
                  '$location • $date',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: AppColors.sub,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Bottom row: applicant count + budget
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '$applicantCount applicant${applicantCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: AppColors.sub,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C89618),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Open',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00C896),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  budget,
                  style: const TextStyle(
                    fontFamily: 'Cormorant Garamond',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Drawer Widget
class _Drawer extends StatefulWidget {
  const _Drawer();

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
                          'Log Out',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            color: Colors.white,
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
      print('Starting client drawer logout process...');
      
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
                colors: [AppColors.violet, Color(0xFF6B4FFF)],
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
              context.go('/client-profile');
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
              'Logout',
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
