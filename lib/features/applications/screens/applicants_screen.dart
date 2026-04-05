import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class ApplicantsScreen extends ConsumerStatefulWidget {
  final String gigId;
  final String gigTitle;
  
  const ApplicantsScreen({
    super.key,
    required this.gigId,
    required this.gigTitle,
  });

  @override
  ConsumerState<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends ConsumerState<ApplicantsScreen> {
  String _selectedFilter = 'All';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.go('/client-home'),
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1C2338)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: AppColors.amber,
            ),
          ),
        ),
        title: const Text(
          'Applicants',
          style: TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('gigId', isEqualTo: widget.gigId)
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_search,
                    size: 64,
                    color: AppColors.sub,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No applicants yet',
                    style: TextStyle(
                      fontFamily: 'Cormorant Garamond',
                      fontSize: 18,
                      color: AppColors.sub,
                    ),
                  ),
                ],
              ),
            );
          }

          final applications = snapshot.data!.docs;
          final allCount = applications.length;
          final pendingCount = applications.where((doc) => doc.get('status') == 'pending').length;
          final acceptedCount = applications.where((doc) => doc.get('status') == 'accepted').length;

          final filteredApplications = applications.where((doc) {
            if (_selectedFilter == 'All') return true;
            return doc.get('status') == _selectedFilter.toLowerCase();
          }).toList();

          return Column(
            children: [
              // Subtitle
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                child: Text(
                  '${widget.gigTitle} • $allCount applicant${allCount != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Filter tabs
              _buildFilterTabs(allCount, pendingCount, acceptedCount),
              
              const SizedBox(height: 16),
              
              // Applicant list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredApplications.length,
                  itemBuilder: (context, index) {
                    final application = filteredApplications[index];
                    return _ApplicantCard(
                      application: application,
                      gigId: widget.gigId,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(activeTab: 'my-gigs', userType: 'client'),
    );
  }

  Widget _buildFilterTabs(int allCount, int pendingCount, int acceptedCount) {
    final filters = [
      {'name': 'All', 'count': allCount},
      {'name': 'Pending', 'count': pendingCount},
      {'name': 'Accepted', 'count': acceptedCount},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter['name'] == _selectedFilter;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter['name'] as String;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(left: 20, right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.amber : AppColors.card2,
                border: Border.all(
                  color: isSelected ? AppColors.amber : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${filter['name']} (${filter['count']})',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.bg : AppColors.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ApplicantCard extends ConsumerWidget {
  final DocumentSnapshot application;
  final String gigId;

  const _ApplicantCard({
    required this.application,
    required this.gigId,
  });

  Future<void> _acceptApplication() async {
    try {
      await application.reference.update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // TODO: Send FCM notification to musician
      // TODO: Reveal contact info to both parties
    } catch (e) {
      debugPrint('Error accepting application: $e');
    }
  }

  Future<void> _declineApplication() async {
    try {
      await application.reference.update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // TODO: Send FCM notification to musician
    } catch (e) {
      debugPrint('Error declining application: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = application.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'pending';
    final isAccepted = status == 'accepted';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1424),
        border: Border.all(
          color: isAccepted ? const Color(0xFF00C89644) : const Color(0xFF1C2338),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and name
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [AppColors.amber, AppColors.copper],
                  ),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: AppColors.bg,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Name and genre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          data['musicianName'] as String? ?? 'Musician',
                          style: const TextStyle(
                            fontFamily: 'Cormorant Garamond',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF4EFEA),
                          ),
                        ),
                        if (isAccepted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C896),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '✓ Accepted',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 9,
                                color: AppColors.bg,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['genre'] as String? ?? 'Genre not specified',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: Color(0xFF7E8BA8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Rate and rating
          Row(
            children: [
              Text(
                '₱${data['rate'] ?? '0'}/hour',
                style: const TextStyle(
                  fontFamily: 'Cormorant Garamond',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '⭐ ${data['rating']?.toStringAsFixed(1) ?? '0.0'}',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Cover message
          Text(
            data['coverMessage'] as String? ?? 'No cover message provided.',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: Color(0xFF7E8BA8),
            ),
          ),
          
          // Action buttons for pending applications
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _acceptApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C89618),
                      side: const BorderSide(color: Color(0xFF00C89655)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: Color(0xFF00C896),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _declineApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5A5F18),
                      side: const BorderSide(color: Color(0xFFFF5A5F55)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: Color(0xFFFF5A5F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
