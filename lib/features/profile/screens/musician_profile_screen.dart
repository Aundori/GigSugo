import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class MusicianProfile {
  final String uid;
  final String name;
  final String role;
  final String city;
  final List<String> genres;
  final String about;
  final double rating;
  final int gigsCompleted;
  final double totalEarned;
  final String profileImageUrl;

  MusicianProfile({
    required this.uid,
    required this.name,
    required this.role,
    required this.city,
    required this.genres,
    required this.about,
    required this.rating,
    required this.gigsCompleted,
    required this.totalEarned,
    this.profileImageUrl = '',
  });

  factory MusicianProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MusicianProfile(
      uid: doc.id,
      name: data['name'] ?? 'Musician',
      role: data['role'] ?? 'Musician',
      city: data['city'] ?? 'City',
      genres: List<String>.from(data['genres'] ?? []),
      about: data['about'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      gigsCompleted: data['gigsCompleted'] ?? 0,
      totalEarned: (data['totalEarned'] ?? 0.0).toDouble(),
      profileImageUrl: data['profileImageUrl'] ?? '',
    );
  }
}

class Review {
  final String id;
  final String reviewerName;
  final String reviewerId;
  final String revieweeId;
  final double rating;
  final String comment;
  final Timestamp createdAt;

  Review({
    required this.id,
    required this.reviewerName,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      reviewerName: data['reviewerName'] ?? 'Anonymous',
      reviewerId: data['reviewerId'] ?? '',
      revieweeId: data['revieweeId'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}

// Riverpod providers
final musicianProfileProvider = StreamProvider<MusicianProfile?>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('musician_profiles')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.exists ? MusicianProfile.fromFirestore(doc) : null);
});

final reviewsProvider = StreamProvider<List<Review>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('reviews')
      .where('revieweeId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(5)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList());
});

class MusicianProfileScreen extends ConsumerWidget {
  const MusicianProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(musicianProfileProvider);
    final reviewsAsync = ref.watch(reviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _ProfileHeader(profileAsync: profileAsync),
            
            // About Section
            profileAsync.when(
              data: (profile) => profile != null 
                  ? _AboutSection(about: profile.about)
                  : const SizedBox(),
              loading: () => _AboutSection(about: ''),
              error: (_, __) => const SizedBox(),
            ),
            
            // Recent Reviews Section
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'RECENT REVIEWS',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: AppColors.muted,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Reviews List
            reviewsAsync.when(
              data: (reviews) => _ReviewsList(reviews: reviews),
              loading: () => _ReviewsLoadingState(),
              error: (_, __) => _ReviewsErrorState(),
            ),
            
            const SizedBox(height: 100), // Bottom nav padding
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(activeTab: 'profile'),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final AsyncValue<MusicianProfile?> profileAsync;

  const _ProfileHeader({required this.profileAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C0800), // Dark warm tone
      child: Stack(
        children: [
          // Subtle radial amber glow behind logo
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.amber.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top amber accent line
                Container(
                  width: double.infinity,
                  height: 1,
                  color: AppColors.amber.withOpacity(0.35),
                ),
                
                const SizedBox(height: 24),
                
                // GigSugo Logo Box
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
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
                              color: const Color(0xFF07080E).withOpacity(0.45),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 2),
                          // Bar 2 — medium, opacity 0.70
                          Container(
                            width: 2,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF07080E).withOpacity(0.70),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 2),
                          // Bar 3 — tallest, full opacity, slightly thicker
                          Container(
                            width: 3,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFF07080E),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                          const SizedBox(width: 2),
                          // Bar 4 — medium, opacity 0.70
                          Container(
                            width: 2,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF07080E).withOpacity(0.70),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 2),
                          // Bar 5 — short, opacity 0.45
                          Container(
                            width: 2,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF07080E).withOpacity(0.45),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Name and Role/City
                profileAsync.when(
                  data: (profile) => Column(
                    children: [
                      Text(
                        profile?.name ?? 'Musician',
                        style: const TextStyle(
                          fontFamily: 'Cormorant Garamond',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile?.role ?? 'Musician'} • ${profile?.city ?? 'City'}',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: AppColors.sub,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Column(
                    children: [
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontFamily: 'Cormorant Garamond',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Musician • City',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: AppColors.sub,
                        ),
                      ),
                    ],
                  ),
                  error: (_, __) => const Column(
                    children: [
                      Text(
                        'Musician',
                        style: TextStyle(
                          fontFamily: 'Cormorant Garamond',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Musician • City',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: AppColors.sub,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Genre Tags
                profileAsync.when(
                  data: (profile) => profile != null && profile.genres.isNotEmpty
                      ? _GenreTags(genres: profile.genres)
                      : const SizedBox(),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                
                const SizedBox(height: 20),
                
                // Stats Row
                profileAsync.when(
                  data: (profile) => profile != null
                      ? _StatsRow(
                          rating: profile.rating,
                          gigsCompleted: profile.gigsCompleted,
                          totalEarned: profile.totalEarned,
                        )
                      : _StatsRow(
                          rating: 0.0,
                          gigsCompleted: 0,
                          totalEarned: 0.0,
                        ),
                  loading: () => _StatsRow(
                    rating: 0.0,
                    gigsCompleted: 0,
                    totalEarned: 0.0,
                  ),
                  error: (_, __) => _StatsRow(
                    rating: 0.0,
                    gigsCompleted: 0,
                    totalEarned: 0.0,
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // Edit Profile Button
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () {
                  // TODO: Navigate to edit profile
                },
                icon: const Icon(
                  Icons.edit,
                  size: 18,
                  color: AppColors.amber,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreTags extends StatelessWidget {
  final List<String> genres;

  const _GenreTags({required this.genres});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: genres.map((genre) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                genre,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amber,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final double rating;
  final int gigsCompleted;
  final double totalEarned;

  const _StatsRow({
    required this.rating,
    required this.gigsCompleted,
    required this.totalEarned,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            label: 'Rating',
            value: rating.toStringAsFixed(1),
          ),
          _StatItem(
            label: 'Gigs',
            value: gigsCompleted.toString(),
          ),
          _StatItem(
            label: 'Earned',
            value: '₱${totalEarned.toInt().toString()}',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.amber,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            color: AppColors.sub,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String about;

  const _AboutSection({required this.about});

  @override
  Widget build(BuildContext context) {
    if (about.isEmpty) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ABOUT',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: AppColors.muted,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            about,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: AppColors.sub,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsList extends StatelessWidget {
  final List<Review> reviews;

  const _ReviewsList({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'No reviews yet',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            color: AppColors.sub,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: reviews.map((review) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReviewCard(review: review),
          );
        }).toList(),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer name and rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.reviewerName,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating
                        ? Icons.star
                        : Icons.star_border,
                    size: 12,
                    color: AppColors.amber,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Review comment
          Text(
            review.comment,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: AppColors.sub,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsLoadingState extends StatelessWidget {
  const _ReviewsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
          ),
        )),
      ),
    );
  }
}

class _ReviewsErrorState extends StatelessWidget {
  const _ReviewsErrorState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Error loading reviews',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          color: AppColors.sub,
        ),
      ),
    );
  }
}
