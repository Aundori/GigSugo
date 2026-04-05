import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';

class GigDetailScreen extends StatelessWidget {
  final String gigId;

  const GigDetailScreen({super.key, required this.gigId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('gigs').doc(gigId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ShimmerLoading();
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gig not found',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 18,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/gigs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Back to Gigs'),
                  ),
                ],
              ),
            );
          }

          final gig = _Gig.fromFirestore(snapshot.data!);
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;

          return CustomScrollView(
            slivers: [
              // Hero Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.go('/gigs'),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.bookmark_border, color: Colors.white),
                      onPressed: () {
                        // TODO: Implement bookmark functionality
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Amber gradient background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.amber, Color(0xFFFF8C00)],
                          ),
                        ),
                      ),
                      // Large emoji watermark
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: const Center(
                            child: Text(
                              '🎵',
                              style: TextStyle(fontSize: 60),
                            ),
                          ),
                        ),
                      ),
                      // Subtle white overlay gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                      // Content
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Event type tag
                            if (gig.tag != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  gig.tag!,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            // Gig title
                            Text(
                              gig.title,
                              style: const TextStyle(
                                fontFamily: 'Cormorant Garamond',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Posted by + time ago
                            Text(
                              'Posted by Client • ${_getTimeAgo(gig.createdAt)}',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2x2 Info Grid
                      _InfoGrid(gig: gig, onLocationTap: (location) => _openLocationMap(context, location)),
                      const SizedBox(height: 24),
                      
                      // Genre Required
                      if (gig.genre != null)
                        _GenreSection(genre: gig.genre!),
                      const SizedBox(height: 24),
                      
                      // Description
                      _DescriptionSection(description: gig.description),
                      const SizedBox(height: 24),
                      
                      // About the Client
                      _ClientSection(clientId: gig.clientId),
                      const SizedBox(height: 32),
                      
                      // Apply Button (only for musicians, not for gig owner)
                      if (currentUserId != null && currentUserId != gig.clientId)
                        _ApplyButton(gigId: gigId),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final gigTime = timestamp.toDate();
    final difference = now.difference(gigTime);
    
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

  Future<void> _openLocationMap(BuildContext context, String location) async {
    if (location.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Create Google Maps URL for the location
      final Uri mapUri = Uri(
        scheme: 'https',
        host: 'www.google.com',
        path: '/maps/search/',
        queryParameters: {
          'api': '1',
          'query': location,
        },
      );

      print('Opening map for location: $location');
      print('Map URL: $mapUri');

      if (await canLaunchUrl(mapUri)) {
        await launchUrl(
          mapUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to generic search if Google Maps fails
        final Uri searchUri = Uri(
          scheme: 'https',
          host: 'www.google.com',
          path: '/search',
          queryParameters: {'q': location},
        );

        if (await canLaunchUrl(searchUri)) {
          await launchUrl(
            searchUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw 'Could not launch map or search';
        }
      }
    } catch (e) {
      print('Error opening map: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open map: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _InfoGrid extends StatelessWidget {
  final _Gig gig;
  final Function(String)? onLocationTap;

  const _InfoGrid({
    required this.gig,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _InfoCard(
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                '₱',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amber,
                ),
              ),
            ),
          ),
          label: 'Budget',
          value: '₱${gig.budget.replaceAll(RegExp(r'[^\d.]'), '')}',
        ),
        _InfoCard(
          icon: Icon(
            Icons.calendar_today,
            color: AppColors.amber,
            size: 24,
          ),
          label: 'Date',
          value: gig.date,
        ),
        _InfoCard(
          icon: Icon(
            Icons.location_on,
            color: AppColors.amber,
            size: 24,
          ),
          label: 'Location',
          value: gig.location,
          onTap: onLocationTap != null ? () => onLocationTap!(gig.location) : null,
        ),
        _InfoCard(
          icon: Icon(
            Icons.access_time,
            color: AppColors.amber,
            size: 24,
          ),
          label: 'Duration',
          value: gig.duration ?? 'Not specified',
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1424),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFF1C2338)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: Color(0xFF7E8BA8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (onTap != null)
                const SizedBox(height: 4),
              if (onTap != null)
                const Text(
                  'Tap to view map',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 9,
                    color: AppColors.amber,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenreSection extends StatelessWidget {
  final String genre;

  const _GenreSection({required this.genre});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Genre Required',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genre.split(',').map((g) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.amber, Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                g.trim(),
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String? description;

  const _DescriptionSection({required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1424),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFF1C2338)),
          ),
          child: Text(
            description ?? 'No description provided',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: Color(0xFF7E8BA8),
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClientSection extends StatelessWidget {
  final String clientId;

  const _ClientSection({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(clientId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.amber),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final clientData = snapshot.data!.data() as Map<String, dynamic>;
        final clientName = clientData['name'] ?? 'Unknown Client';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About the Client',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1424),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFF1C2338)),
              ),
              child: Row(
                children: [
                  // Amber gradient avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.amber, Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '4.8 (12 reviews)',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                color: Color(0xFF7E8BA8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final String gigId;

  const _ApplyButton({required this.gigId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.go('/apply?gigId=$gigId');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.amber, Color(0xFFFF8C00)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(13)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Apply Now ',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '🎵',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0E1A),
      body: Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
    );
  }
}

class _Gig {
  final String id;
  final String title;
  final String location;
  final String date;
  final String budget;
  final String? tag;
  final String? genre;
  final String? description;
  final String? duration;
  final int applicantCount;
  final String clientId;
  final Timestamp createdAt;

  _Gig({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.budget,
    this.tag,
    this.genre,
    this.description,
    this.duration,
    required this.applicantCount,
    required this.clientId,
    required this.createdAt,
  });

  factory _Gig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _Gig(
      id: doc.id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      date: data['date'] ?? '',
      budget: data['budget'] ?? '',
      tag: data['tag'],
      genre: data['genre'],
      description: data['description'],
      duration: data['duration'],
      applicantCount: data['applicantCount'] ?? 0,
      clientId: data['clientId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
