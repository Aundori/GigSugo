import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../core/services/profile_image_service.dart';

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
    print('Parsing MusicianProfile from data: $data');
    
    try {
      return MusicianProfile(
        uid: doc.id,
        name: data['name'] ?? 'Musician',
        role: data['role'] ?? 'Musician',
        city: data['city'] ?? 'City',
        genres: List<String>.from(data['genres'] ?? []),
        about: data['about'] ?? '',
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        gigsCompleted: (data['gigsCompleted'] as num?)?.toInt() ?? 0,
        totalEarned: (data['totalEarned'] as num?)?.toDouble() ?? 0.0,
        profileImageUrl: data['profileImageUrl'] ?? '',
      );
    } catch (e) {
      print('Error parsing MusicianProfile: $e');
      print('Data keys: ${data.keys.toList()}');
      
      // Return a default profile if parsing fails
      return MusicianProfile(
        uid: doc.id,
        name: data['name'] ?? 'Musician',
        role: data['role'] ?? 'Musician',
        city: data['city'] ?? 'City',
        genres: List<String>.from(data['genres'] ?? []),
        about: data['about'] ?? '',
        rating: 0.0,
        gigsCompleted: 0,
        totalEarned: 0.0,
        profileImageUrl: data['profileImageUrl'] ?? '',
      );
    }
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
  
  print('Fetching profile for userId: $userId');
  
  // Create a stream that immediately tries to get the document once
  return FirebaseFirestore.instance
      .collection('musician_profiles')
      .doc(userId)
      .snapshots(includeMetadataChanges: true)
      .timeout(const Duration(seconds: 3))
      .map((doc) {
        print('Document snapshot received - exists: ${doc.exists}, fromCache: ${doc.metadata.isFromCache}');
        if (!doc.exists) {
          print('Profile document does not exist for user: $userId');
          return null;
        }
        
        try {
          final profile = MusicianProfile.fromFirestore(doc);
          print('Profile parsed successfully: ${profile.name}');
          return profile;
        } catch (e) {
          print('Error parsing profile: $e');
          return null;
        }
      })
      .handleError((error) {
        print('Stream error for musician profile: $error');
        return null;
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
      .timeout(const Duration(seconds: 10))
      .map((snapshot) => snapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList())
      .handleError((error) {
        print('Error fetching reviews: $error');
        return <Review>[];
      });
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
            // Profile Header with timeout fallback
            profileAsync.when(
              data: (profile) => _ProfileHeader(
                profileAsync: profileAsync,
                ref: ref,
              ),
              loading: () => const _LoadingHeader(),
              error: (_, __) => _ProfileHeader(
                profileAsync: const AsyncValue.data(null),
                ref: ref,
              ),
            ),
            
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
  final WidgetRef ref;

  const _ProfileHeader({
    required this.profileAsync,
    required this.ref,
  });

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
                width: 220,
                height: 220,
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
                        colors: [AppColors.amber, AppColors.copper],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: profileAsync.when(
                        data: (profile) {
                          if (profile?.profileImageUrl != null && profile!.profileImageUrl.isNotEmpty) {
                            return Image.network(
                              '${profile.profileImageUrl}?t=${DateTime.now().millisecondsSinceEpoch}',
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                              cacheWidth: 360, // 2x size for better quality
                              cacheHeight: 360,
                              filterQuality: FilterQuality.high, // Higher quality for larger image
                              errorBuilder: (context, error, stackTrace) {
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
                            );
                          } else {
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
                          }
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
                  _showEditProfileDialog(context);
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

  void _showEditProfileDialog(BuildContext context) {
    final profileAsync = ref.read(musicianProfileProvider);
    
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
            // Profile Picture Option
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.amber),
              title: const Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  color: AppColors.text,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showImagePicker(context);
              },
            ),
            // Complete Profile Edit Option
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.amber),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'DM Sans',
                color: AppColors.sub,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Update Profile Picture',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.amber),
            title: const Text(
              'Take Photo',
              style: TextStyle(
                fontFamily: 'DM Sans',
                color: AppColors.text,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _updateProfileImage(context, fromCamera: true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.amber),
            title: const Text(
              'Choose from Gallery',
              style: TextStyle(
                fontFamily: 'DM Sans',
                color: AppColors.text,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _updateProfileImage(context, fromCamera: false);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _updateProfileImage(BuildContext context, {required bool fromCamera}) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      );

      // Update profile image
      await ProfileImageService.updateProfileImage(fromCamera: fromCamera);

      // Close loading dialog
      Navigator.pop(context);

      // Force refresh the profile data to ensure immediate UI update
      if (context.mounted) {
        ref.invalidate(musicianProfileProvider);
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile picture updated successfully!',
              style: TextStyle(fontFamily: 'DM Sans'),
            ),
            backgroundColor: AppColors.amber,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's showing - check if navigator can pop
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile picture: $e',
              style: const TextStyle(fontFamily: 'DM Sans'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComprehensiveEditDialog(BuildContext context, MusicianProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    final cityController = TextEditingController(text: profile.city);
    final aboutController = TextEditingController(text: profile.about);
    final List<String> genres = List.from(profile.genres);
    final TextEditingController genreController = TextEditingController();
    
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
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Name
                  const Text(
                    'Profile Name',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      color: AppColors.text,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: TextStyle(
                        fontFamily: 'DM Sans',
                        color: AppColors.sub,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: AppColors.amber),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: AppColors.amber, width: 2),
                      ),
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                  
                  // City
                  const Text(
                    'City',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cityController,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      color: AppColors.text,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter your city',
                      hintStyle: TextStyle(
                        fontFamily: 'DM Sans',
                        color: AppColors.sub,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: AppColors.amber),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: AppColors.amber, width: 2),
                      ),
                    ),
                    maxLength: 30,
                  ),
                  const SizedBox(height: 16),
                  
                  // Genre Tags
                  const Text(
                    'Genre Tags',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: genreController,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      color: AppColors.text,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add new genre',
                      hintStyle: const TextStyle(
                        fontFamily: 'DM Sans',
                        color: AppColors.sub,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: AppColors.amber),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: AppColors.amber, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add, color: AppColors.amber),
                        onPressed: () {
                          final newGenre = genreController.text.trim();
                          if (newGenre.isNotEmpty && !genres.contains(newGenre)) {
                            setState(() {
                              genres.add(newGenre);
                              genreController.clear();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (genres.isNotEmpty) ...[
                    SizedBox(
                      width: double.maxFinite,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: genres.map((genre) => Chip(
                          label: Text(
                            genre,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10,
                              color: AppColors.amber,
                            ),
                          ),
                          backgroundColor: AppColors.amber.withOpacity(0.2),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.amber,
                          ),
                          onDeleted: () {
                            setState(() {
                              genres.remove(genre);
                            });
                          },
                        )).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // About Section
                  const Text(
                    'About',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: aboutController,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      color: AppColors.text,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Tell us about yourself...',
                      hintStyle: TextStyle(
                        fontFamily: 'DM Sans',
                        color: AppColors.sub,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: AppColors.amber),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: AppColors.amber, width: 2),
                      ),
                    ),
                    maxLines: 4,
                    maxLength: 500,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  color: AppColors.sub,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateComprehensiveProfile(
                  context,
                  nameController.text,
                  cityController.text,
                  aboutController.text,
                  genres,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Save All',
                style: TextStyle(fontFamily: 'DM Sans'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateComprehensiveProfile(
    BuildContext context,
    String name,
    String city,
    String about,
    List<String> genres,
  ) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      );

      // Update all profile fields in Firestore
      await FirebaseFirestore.instance
          .collection('musician_profiles')
          .doc(userId)
          .update({
            'name': name,
            'city': city,
            'about': about,
            'genres': genres,
          });

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully!',
            style: TextStyle(fontFamily: 'DM Sans'),
          ),
          backgroundColor: AppColors.amber,
        ),
      );
    } catch (e) {
      // Close loading dialog if it's showing
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile: $e',
            style: const TextStyle(fontFamily: 'DM Sans'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editAboutSection(BuildContext context, String currentAbout) {
    final TextEditingController controller = TextEditingController(text: currentAbout);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Edit About Section',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            color: AppColors.text,
          ),
          decoration: const InputDecoration(
            hintText: 'Tell us about yourself...',
            hintStyle: TextStyle(
              fontFamily: 'DM Sans',
              color: AppColors.sub,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppColors.amber),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppColors.amber, width: 2),
            ),
          ),
          maxLines: 4,
          maxLength: 500,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'DM Sans',
                color: AppColors.sub,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateAboutSection(context, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontFamily: 'DM Sans'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAboutSection(BuildContext context, String about) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      );

      // Update about section in Firestore
      await FirebaseFirestore.instance
          .collection('musician_profiles')
          .doc(userId)
          .update({'about': about});

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'About section updated successfully!',
            style: TextStyle(fontFamily: 'DM Sans'),
          ),
          backgroundColor: AppColors.amber,
        ),
      );
    } catch (e) {
      // Close loading dialog if it's showing
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update about section: $e',
            style: const TextStyle(fontFamily: 'DM Sans'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editProfileName(BuildContext context, String currentName) {
    final TextEditingController controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Edit Profile Name',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            color: AppColors.text,
          ),
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(
              fontFamily: 'DM Sans',
              color: AppColors.sub,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppColors.amber),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppColors.amber, width: 2),
            ),
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'DM Sans',
                color: AppColors.sub,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateProfileName(context, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontFamily: 'DM Sans'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfileName(BuildContext context, String name) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      );

      // Update profile name in Firestore
      await FirebaseFirestore.instance
          .collection('musician_profiles')
          .doc(userId)
          .update({'name': name});

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile name updated successfully!',
            style: TextStyle(fontFamily: 'DM Sans'),
          ),
          backgroundColor: AppColors.amber,
        ),
      );
    } catch (e) {
      // Close loading dialog if it's showing
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile name: $e',
            style: const TextStyle(fontFamily: 'DM Sans'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editCity(BuildContext context, String currentCity) {
    final TextEditingController controller = TextEditingController(text: currentCity);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Edit City',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            color: AppColors.text,
          ),
          decoration: const InputDecoration(
            hintText: 'Enter your city',
            hintStyle: TextStyle(
              fontFamily: 'DM Sans',
              color: AppColors.sub,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppColors.amber),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppColors.amber, width: 2),
            ),
          ),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'DM Sans',
                color: AppColors.sub,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateCity(context, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontFamily: 'DM Sans'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCity(BuildContext context, String city) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      );

      // Update city in Firestore
      await FirebaseFirestore.instance
          .collection('musician_profiles')
          .doc(userId)
          .update({'city': city});

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'City updated successfully!',
            style: TextStyle(fontFamily: 'DM Sans'),
          ),
          backgroundColor: AppColors.amber,
        ),
      );
    } catch (e) {
      // Close loading dialog if it's showing
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update city: $e',
            style: const TextStyle(fontFamily: 'DM Sans'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editGenreTags(BuildContext context, List<String> currentGenres) {
    final List<String> genres = List.from(currentGenres);
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text(
            'Edit Genre Tags',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add new genre
                TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    color: AppColors.text,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add new genre',
                    hintStyle: const TextStyle(
                      fontFamily: 'DM Sans',
                      color: AppColors.sub,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: AppColors.amber),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: AppColors.amber, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add, color: AppColors.amber),
                      onPressed: () {
                        final newGenre = controller.text.trim();
                        if (newGenre.isNotEmpty && !genres.contains(newGenre)) {
                          setState(() {
                            genres.add(newGenre);
                            controller.clear();
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Current genres
                if (genres.isNotEmpty) ...[
                  const Text(
                    'Current Genres:',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.sub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genres.map((genre) => Chip(
                      label: Text(
                        genre,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          color: AppColors.amber,
                        ),
                      ),
                      backgroundColor: AppColors.amber.withOpacity(0.2),
                      deleteIcon: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.amber,
                      ),
                      onDeleted: () {
                        setState(() {
                          genres.remove(genre);
                        });
                      },
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  color: AppColors.sub,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateGenreTags(context, genres);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontFamily: 'DM Sans'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateGenreTags(BuildContext context, List<String> genres) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      );

      // Update genres in Firestore
      await FirebaseFirestore.instance
          .collection('musician_profiles')
          .doc(userId)
          .update({'genres': genres});

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Genre tags updated successfully!',
            style: TextStyle(fontFamily: 'DM Sans'),
          ),
          backgroundColor: AppColors.amber,
        ),
      );
    } catch (e) {
      // Close loading dialog if it's showing
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update genre tags: $e',
            style: const TextStyle(fontFamily: 'DM Sans'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _GenreTags extends StatelessWidget {
  final List<String> genres;

  const _GenreTags({required this.genres});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: genres.map((genre) {
            return Container(
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
            );
          }).toList(),
        ),
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

class PerforatedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.copper.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw white background with rounded corners
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, backgroundPaint);

    // Draw perforated edge effect
    _drawPerforatedEdge(canvas, size, borderPaint);
  }

  void _drawPerforatedEdge(Canvas canvas, Size size, Paint paint) {
    final dotRadius = 2.0;
    final spacing = 6.0;
    final edgeOffset = 4.0;

    // Create clipping path for perforated edge
    final path = Path();
    
    // Top edge with perforations
    path.moveTo(edgeOffset, edgeOffset);
    for (double x = edgeOffset; x <= size.width - edgeOffset; x += spacing) {
      if (x + dotRadius * 2 <= size.width - edgeOffset) {
        path.addOval(Rect.fromCircle(
          center: Offset(x + dotRadius, edgeOffset + dotRadius),
          radius: dotRadius,
        ));
        path.moveTo(x + dotRadius * 2, edgeOffset);
      }
    }
    path.moveTo(size.width - edgeOffset, edgeOffset);

    // Right edge with perforations
    for (double y = edgeOffset; y <= size.height - edgeOffset; y += spacing) {
      if (y + dotRadius * 2 <= size.height - edgeOffset) {
        path.addOval(Rect.fromCircle(
          center: Offset(size.width - edgeOffset - dotRadius, y + dotRadius),
          radius: dotRadius,
        ));
        path.moveTo(size.width - edgeOffset, y + dotRadius * 2);
      }
    }
    path.moveTo(size.width - edgeOffset, size.height - edgeOffset);

    // Bottom edge with perforations
    for (double x = size.width - edgeOffset; x >= edgeOffset; x -= spacing) {
      if (x - dotRadius * 2 >= edgeOffset) {
        path.addOval(Rect.fromCircle(
          center: Offset(x - dotRadius, size.height - edgeOffset - dotRadius),
          radius: dotRadius,
        ));
        path.moveTo(x - dotRadius * 2, size.height - edgeOffset);
      }
    }
    path.moveTo(edgeOffset, size.height - edgeOffset);

    // Left edge with perforations
    for (double y = size.height - edgeOffset; y >= edgeOffset; y -= spacing) {
      if (y - dotRadius * 2 >= edgeOffset) {
        path.addOval(Rect.fromCircle(
          center: Offset(edgeOffset + dotRadius, y - dotRadius),
          radius: dotRadius,
        ));
        path.moveTo(edgeOffset, y - dotRadius * 2);
      }
    }
    path.close();

    // Draw the perforated border
    canvas.drawPath(path, paint);

    // Draw corner dots (larger, more prominent)
    final cornerPaint = Paint()
      ..color = AppColors.amber.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final cornerRadius = 3.0;
    final corners = [
      Offset(edgeOffset, edgeOffset),
      Offset(size.width - edgeOffset, edgeOffset),
      Offset(edgeOffset, size.height - edgeOffset),
      Offset(size.width - edgeOffset, size.height - edgeOffset),
    ];

    for (final corner in corners) {
      canvas.drawCircle(corner, cornerRadius, cornerPaint);
      // Add outer ring for corner dots
      canvas.drawCircle(corner, cornerRadius + 1, Paint()
        ..color = AppColors.amber.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

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
                      AppColors.amber.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7, 1.0],
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
                
                const SizedBox(height: 64),
                
                // Profile Picture with loading indicator
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.amber, AppColors.copper],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 64,
                        height: 64,
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
                
                // Loading name placeholder
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Loading role placeholder
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Loading city placeholder
                Container(
                  width: 60,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Loading stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _LoadingStatItem(),
                      _LoadingStatItem(),
                      _LoadingStatItem(),
                    ],
                  ),
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

class _LoadingStatItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
