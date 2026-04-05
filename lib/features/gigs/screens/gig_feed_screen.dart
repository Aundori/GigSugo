import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';

class Gig {
  final String id;
  final String title;
  final String location;
  final String date;
  final String budget;
  final String? tag;
  final String? genre;
  final int applicantCount;
  final Timestamp createdAt;

  Gig({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.budget,
    this.tag,
    this.genre,
    required this.applicantCount,
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
      genre: data['genre'],
      applicantCount: data['applicantCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}

// Riverpod StreamProvider for real-time updates
final gigsProvider = StreamProvider<List<Gig>>((ref) {
  return FirebaseFirestore.instance
      .collection('gig_listings')
      .where('status', isEqualTo: 'open')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Gig.fromFirestore(doc))
          .toList());
});

class GigFeedScreen extends ConsumerStatefulWidget {
  const GigFeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GigFeedScreen> createState() => _GigFeedScreenState();
}

class _GigFeedScreenState extends ConsumerState<GigFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Wedding', 'Corporate', 'Bar', 'Party', 'Café'];

  Stream<QuerySnapshot> _getFilteredGigsStream() {
    Query query = FirebaseFirestore.instance
        .collection('gig_listings')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true);

    if (_selectedFilter != 'All') {
      query = query.where('tag', isEqualTo: _selectedFilter);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Browse Gigs',
                    style: TextStyle(
                      fontFamily: 'Cormorant Garamond',
                      fontSize: 24,
                      color: Color(0xFFF4EFEA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find your next performance',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: Color(0xFF7E8BA8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border)),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search gigs...',
                        hintStyle: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          color: AppColors.sub,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.sub,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter Pills
                  SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isActive = filter == _selectedFilter;
                        
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == _filters.length - 1 ? 0 : 8,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: isActive
                                    ? const LinearGradient(
                                        colors: [AppColors.amber, AppColors.copper],
                                      )
                                    : null,
                                border: isActive
                                    ? null
                                    : Border.all(color: AppColors.border),
                                color: isActive ? null : Colors.transparent,
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? AppColors.bg : AppColors.sub,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Gig List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFilteredGigsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading gigs',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          color: AppColors.sub,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.amber,
                      ),
                    );
                  }

                  final gigs = snapshot.data?.docs
                      .map((doc) => Gig.fromFirestore(doc))
                      .where((gig) => _searchController.text.isEmpty || 
                          gig.title.toLowerCase().contains(_searchController.text.toLowerCase()))
                      .toList() ?? [];

                  if (gigs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_note_outlined,
                            size: 48,
                            color: AppColors.sub,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No gigs found',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              color: AppColors.sub,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: gigs.length,
                    itemBuilder: (context, index) {
                      final gig = gigs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GigCard(gig: gig),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavigationBar(activeTab: 'gigs'),
    );
  }
}

class GigCard extends StatelessWidget {
  final Gig gig;

  const GigCard({required this.gig});

  Color _getTagColor(String? tag) {
    switch (tag?.toUpperCase()) {
      case 'WEDDING':
        return const Color(0xFFF5A623); // amber
      case 'BAR':
        return const Color(0xFF8B6FFF); // violet
      case 'CORPORATE':
        return const Color(0xFF00C896); // green
      case 'PARTY':
        return const Color(0xFFFFD166); // gold
      case 'CAFÉ':
        return const Color(0xFF00C896); // green
      default:
        return const Color(0xFFF5A623); // amber
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/gig-detail/${gig.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            // Left Accent Bar
            Container(
              width: 3,
              height: 80, // Fixed height instead of double.infinity
              color: _getTagColor(gig.tag),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Tag + Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (gig.tag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTagColor(gig.tag).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              gig.tag ?? '',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 9,
                                color: _getTagColor(gig.tag),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Text(
                          gig.date,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10,
                            color: AppColors.sub,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      gig.title,
                      style: const TextStyle(
                        fontFamily: 'Cormorant Garamond',
                        fontSize: 15,
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Meta Row: Location + Genre
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.sub,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          gig.location,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            color: AppColors.sub,
                          ),
                        ),
                        if (gig.genre != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 2,
                            height: 2,
                            decoration: const BoxDecoration(
                              color: AppColors.sub,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            gig.genre ?? '',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              color: AppColors.sub,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Bottom Row: Budget + Applicant Count + Apply Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱${gig.budget.replaceAll(RegExp(r'[^\d.]'), '')}',
                          style: const TextStyle(
                            fontFamily: 'Cormorant Garamond',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${gig.applicantCount} applied',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                color: AppColors.sub,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.amber, AppColors.copper],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: MaterialButton(
                                onPressed: () => context.go('/gig-detail/${gig.id}'),
                                height: 28,
                                minWidth: 60,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: const Text(
                                  'Apply',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    color: AppColors.bg,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  final String activeTab;

  const _BottomNavigationBar({required this.activeTab, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
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
            icon: Icons.home_outlined,
            label: 'Home',
            isActive: activeTab == 'home',
            onTap: () => context.go('/musician-home'),
          ),
          _NavItem(
            icon: Icons.music_note_outlined,
            label: 'Gigs',
            isActive: activeTab == 'gigs',
            onTap: () => context.go('/gigs'),
          ),
          _NavItem(
            icon: Icons.description_outlined,
            label: 'Applied',
            isActive: activeTab == 'applied',
            onTap: () => context.go('/applications'),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: activeTab == 'profile',
            onTap: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? AppColors.amber : AppColors.sub,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive ? AppColors.amber : AppColors.sub,
            ),
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
