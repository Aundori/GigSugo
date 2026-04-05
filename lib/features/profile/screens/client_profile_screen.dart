import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class ClientProfile {
  final String uid;
  final String name;
  final String role;
  final String location;
  final String bio;
  final List<String> eventTypes;
  final String phone;
  final String email;
  final double rating;
  final int gigsPosted;
  final int hired;
  final bool corporate;

  ClientProfile({
    required this.uid,
    required this.name,
    required this.role,
    required this.location,
    required this.bio,
    required this.eventTypes,
    required this.phone,
    required this.email,
    required this.rating,
    required this.gigsPosted,
    required this.hired,
    required this.corporate,
  });

  factory ClientProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ClientProfile(
      uid: doc.id,
      name: data['name'] ?? 'Client',
      role: data['role'] ?? 'Client',
      location: data['location'] ?? 'Location not set',
      bio: data['bio'] ?? '',
      eventTypes: List<String>.from(data['eventTypes'] ?? []),
      phone: data['phone'] ?? 'Phone not set',
      email: data['email'] ?? 'Email not set',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      gigsPosted: (data['gigsPosted'] as num?)?.toInt() ?? 0,
      hired: (data['hired'] as num?)?.toInt() ?? 0,
      corporate: data['corporate'] ?? false,
    );
  }
}

class Review {
  final String id;
  final String reviewerName;
  final double rating;
  final String reviewText;
  final Timestamp createdAt;

  Review({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      reviewerName: data['reviewerName'] ?? 'Anonymous',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewText: data['reviewText'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}

// Riverpod providers
final clientProfileProvider = StreamProvider<ClientProfile?>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('client_profiles')
      .doc(userId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return ClientProfile.fromFirestore(doc);
      });
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

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clientProfileProvider);
    final reviewsAsync = ref.watch(reviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header with timeout fallback
            profileAsync.when(
              data: (profile) => _ProfileHeader(
                profileAsync: profileAsync,
                ref: ref,
              ),
              loading: () => _LoadingHeader(),
              error: (_, __) => _ProfileHeader(
                profileAsync: const AsyncValue.data(null),
                ref: ref,
              ),
            ),
            
            // About Section
            profileAsync.when(
              data: (profile) => profile != null 
                  ? _AboutSection(about: profile.bio)
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
  final AsyncValue<ClientProfile?> profileAsync;
  final WidgetRef ref;

  _ProfileHeader({
    required this.profileAsync,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C0800), // Dark warm tone
      child: Stack(
        children: [
          // Subtle radial violet glow behind logo
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.violet.withOpacity(0.15),
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
                // Top violet accent line
                Container(
                  width: double.infinity,
                  height: 1,
                  color: AppColors.violet.withOpacity(0.35),
                ),
                
                const SizedBox(height: 64),
                
                // Profile Picture
                Center(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.violet, Color(0xFF6B4FFF)],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: profileAsync.when(
                        data: (profile) {
                          return Container(
                            width: 180,
                            height: 180,
                            color: const Color(0xFF07080E).withOpacity(0.3),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 80,
                            ),
                          );
                        },
                        loading: () => Container(
                          width: 180,
                          height: 180,
                          color: const Color(0xFF07080E).withOpacity(0.3),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        error: (_, __) => Container(
                          width: 180,
                          height: 180,
                          color: const Color(0xFF07080E).withOpacity(0.3),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Name and Role
                profileAsync.when(
                  data: (profile) => Column(
                    children: [
                      Text(
                        profile?.name ?? 'Client',
                        style: const TextStyle(
                          fontFamily: 'Cormorant Garamond',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (profile?.corporate == true) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C896).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00C896).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Corporate',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  color: Color(0xFF00C896),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  loading: () => Column(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.violet.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.violet.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  error: (_, __) => Column(
                    children: [
                      Text(
                        'Client',
                        style: TextStyle(
                          fontFamily: 'Cormorant Garamond',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.violet.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.violet.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Client',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.violet,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
                color: AppColors.violet.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () {
                  _showEditProfileDialog(context, ref);
                },
                icon: const Icon(
                  Icons.edit,
                  size: 18,
                  color: AppColors.violet,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.read(clientProfileProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.violet),
              title: const Text(
                'Edit Profile Picture',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  color: AppColors.text,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement image picker for client
              },
            ),
            // Complete Profile Edit Option
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.violet),
              title: const Text(
                'Edit Profile Information',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  color: AppColors.text,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                profileAsync.when(
                  data: (profile) {
                    if (profile != null) {
                      _showComprehensiveEditDialog(context, profile);
                    }
                  },
                  loading: () => Navigator.pop(context),
                  error: (_, __) => Navigator.pop(context),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showComprehensiveEditDialog(BuildContext context, ClientProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    final locationController = TextEditingController(text: profile.location);
    final aboutController = TextEditingController(text: profile.bio);
    final List<String> eventTypes = List.from(profile.eventTypes);
    final TextEditingController eventTypeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name Field
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: AppColors.muted),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.violet),
                    ),
                  ),
                  style: const TextStyle(color: AppColors.text),
                ),
                const SizedBox(height: 16),
                
                // Location Field
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    labelStyle: TextStyle(color: AppColors.muted),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.violet),
                    ),
                  ),
                  style: const TextStyle(color: AppColors.text),
                ),
                const SizedBox(height: 16),
                
                // Event Types
                const Text(
                  'Event Types',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: eventTypes.map((eventType) {
                    return Chip(
                      label: Text(eventType),
                      backgroundColor: AppColors.violet.withOpacity(0.2),
                      deleteIconColor: AppColors.violet,
                      onDeleted: () {
                        setState(() {
                          eventTypes.remove(eventType);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: eventTypeController,
                  decoration: InputDecoration(
                    hintText: 'Add event type',
                    hintStyle: const TextStyle(color: AppColors.muted),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add, color: AppColors.violet),
                      onPressed: () {
                        if (eventTypeController.text.isNotEmpty) {
                          setState(() {
                            eventTypes.add(eventTypeController.text);
                            eventTypeController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  style: const TextStyle(color: AppColors.text),
                ),
                const SizedBox(height: 16),
                
                // About Field (moved to bottom)
                TextField(
                  controller: aboutController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'About',
                    labelStyle: TextStyle(color: AppColors.muted),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.violet),
                    ),
                  ),
                  style: const TextStyle(color: AppColors.text),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _updateProfile(
                  profile.uid,
                  nameController.text,
                  locationController.text,
                  aboutController.text,
                  eventTypes,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violet,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateProfile(String uid, String name, String location, String bio, List<String> eventTypes) {
    FirebaseFirestore.instance.collection('client_profiles').doc(uid).update({
      'name': name,
      'location': location,
      'bio': bio,
      'eventTypes': eventTypes,
      'updatedAt': Timestamp.now(),
    });
  }
}


class _AboutSection extends StatelessWidget {
  final String about;

  _AboutSection({required this.about});

  @override
  Widget build(BuildContext context) {
    if (about.isEmpty) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
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
              fontSize: 14,
              color: AppColors.text,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}


class _ReviewsList extends StatelessWidget {
  final List<Review> reviews;

  _ReviewsList({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'No reviews yet.',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            color: AppColors.muted,
          ),
        ),
      );
    }

    return Column(
      children: reviews.map((review) => _ReviewCard(review: review)).toList(),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.violet.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [AppColors.violet, Color(0xFF6B4FFF)],
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '⭐ ${review.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.violet,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.createdAt),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${review.reviewText}"',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.text,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _ReviewsLoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.violet.withOpacity(0.2),
              width: 1,
            ),
          ),
        )),
      ),
    );
  }
}

class _ReviewsErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Unable to load reviews.',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C0800), // Dark warm tone
      child: Stack(
        children: [
          // Subtle radial violet glow behind logo
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.violet.withOpacity(0.15),
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
                // Top violet accent line
                Container(
                  width: double.infinity,
                  height: 1,
                  color: AppColors.violet.withOpacity(0.35),
                ),
                
                const SizedBox(height: 64),
                
                // Profile Picture
                Center(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.violet, Color(0xFF6B4FFF)],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 180,
                        height: 180,
                        color: const Color(0xFF07080E).withOpacity(0.3),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Name and Role loading
                Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.violet.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.violet.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
