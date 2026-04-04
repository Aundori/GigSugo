import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class Application {
  final String id;
  final String gigId;
  final String gigTitle;
  final String gigLocation;
  final String gigDate;
  final String clientName;
  final String clientPhone;
  final String clientEmail;
  final String proposedRate;
  final String message;
  final String status;
  final Timestamp createdAt;
  final bool contactRevealed;

  Application({
    required this.id,
    required this.gigId,
    required this.gigTitle,
    required this.gigLocation,
    required this.gigDate,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.proposedRate,
    required this.message,
    required this.status,
    required this.createdAt,
    this.contactRevealed = false,
  });

  factory Application.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Application(
      id: doc.id,
      gigId: data['gigId'] ?? '',
      gigTitle: data['gigTitle'] ?? '',
      gigLocation: data['gigLocation'] ?? '',
      gigDate: data['gigDate'] ?? '',
      clientName: data['clientName'] ?? '',
      clientPhone: data['clientPhone'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      proposedRate: data['proposedRate'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      contactRevealed: data['contactRevealed'] ?? false,
    );
  }
}

// Riverpod StreamProvider for real-time updates
final applicationsProvider = StreamProvider<List<Application>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('applications')
      .where('musicianId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Application.fromFirestore(doc))
          .toList());
});

class AppliedScreen extends ConsumerStatefulWidget {
  const AppliedScreen({super.key});

  @override
  ConsumerState<AppliedScreen> createState() => _AppliedScreenState();
}

class _AppliedScreenState extends ConsumerState<AppliedScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(applicationsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Applications',
                    style: TextStyle(
                      fontFamily: 'Cormorant Garamond',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track your gig applications',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.sub,
                    ),
                  ),
                ],
              ),
            ),
            
            // Stats Row
            applicationsAsync.when(
              data: (applications) => _StatsRow(applications: applications),
              loading: () => _StatsRow(applications: []),
              error: (_, __) => _StatsRow(applications: []),
            ),
            
            const SizedBox(height: 16),
            
            // Filter Pills
            applicationsAsync.when(
              data: (applications) => _FilterPills(
                applications: applications,
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
              ),
              loading: () => _FilterPills(
                applications: [],
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
              ),
              error: (_, __) => _FilterPills(
                applications: [],
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Applications List
            Expanded(
              child: applicationsAsync.when(
                data: (applications) {
                  final filteredApplications = _getFilteredApplications(applications);
                  
                  if (filteredApplications.isEmpty) {
                    return _EmptyState();
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredApplications.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ApplicationCard(
                          application: filteredApplications[index],
                        ),
                      );
                    },
                  );
                },
                loading: () => _LoadingState(),
                error: (_, __) => _ErrorState(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(activeTab: 'applied'),
    );
  }

  List<Application> _getFilteredApplications(List<Application> applications) {
    switch (_selectedFilter) {
      case 'Pending':
        return applications.where((app) => app.status == 'pending').toList();
      case 'Accepted':
        return applications.where((app) => app.status == 'accepted').toList();
      case 'Rejected':
        return applications.where((app) => app.status == 'rejected').toList();
      default:
        return applications;
    }
  }
}

class _StatsRow extends StatelessWidget {
  final List<Application> applications;

  const _StatsRow({required this.applications});

  @override
  Widget build(BuildContext context) {
    final total = applications.length;
    final accepted = applications.where((app) => app.status == 'accepted').length;
    final pending = applications.where((app) => app.status == 'pending').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _StatCard(
              label: 'TOTAL',
              value: total.toString(),
              color: AppColors.amber,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _StatCard(
              label: 'ACCEPTED',
              value: accepted.toString(),
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _StatCard(
              label: 'PENDING',
              value: pending.toString(),
              color: AppColors.amber,
            ),
          ),
        ],
      ),
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
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 8,
                color: color,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPills extends StatelessWidget {
  final List<Application> applications;
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const _FilterPills({
    required this.applications,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final total = applications.length;
    final pending = applications.where((app) => app.status == 'pending').length;
    final accepted = applications.where((app) => app.status == 'accepted').length;
    final rejected = applications.where((app) => app.status == 'rejected').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _FilterPill(
            label: 'All',
            count: total,
            isActive: selectedFilter == 'All',
            onTap: () => onFilterChanged('All'),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Pending',
            count: pending,
            isActive: selectedFilter == 'Pending',
            onTap: () => onFilterChanged('Pending'),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Accepted',
            count: accepted,
            isActive: selectedFilter == 'Accepted',
            onTap: () => onFilterChanged('Accepted'),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Rejected',
            count: rejected,
            isActive: selectedFilter == 'Rejected',
            onTap: () => onFilterChanged('Rejected'),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
          '$label ($count)',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.bg : AppColors.sub,
          ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Application application;

  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: application.status == 'rejected' ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: application.status == 'accepted'
                ? const Color(0xFF00C89644)
                : AppColors.border,
            width: application.status == 'accepted' ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: title + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    application.gigTitle,
                    style: const TextStyle(
                      fontFamily: 'Cormorant Garamond',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
                _StatusBadge(status: application.status),
              ],
            ),
            const SizedBox(height: 6),
            
            // Second row: location + date
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 12,
                  color: AppColors.sub,
                ),
                const SizedBox(width: 4),
                Text(
                  '${application.gigLocation} • ${application.gigDate}',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: AppColors.sub,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Third row: rate + applied date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your rate: ${application.proposedRate}',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Applied ${_formatDate(application.createdAt)}',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            
            // Status-specific content
            if (application.status == 'accepted') ...[
              const SizedBox(height: 12),
              _ContactSection(application: application),
            ] else if (application.status == 'pending') ...[
              const SizedBox(height: 8),
              Text(
                application.message.length > 60
                    ? '${application.message.substring(0, 60)}...'
                    : application.message,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: AppColors.sub,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              _WaitingNotice(),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    String text;
    String icon;

    switch (status) {
      case 'accepted':
        backgroundColor = const Color(0xFF00C89618);
        borderColor = const Color(0xFF00C89633);
        text = 'Accepted';
        icon = '✓ ';
        break;
      case 'pending':
        backgroundColor = const Color(0xFFF5A62318);
        borderColor = const Color(0xFFF5A62333);
        text = 'Pending';
        icon = '⏳ ';
        break;
      case 'rejected':
        backgroundColor = const Color(0xFFFF5A5F18);
        borderColor = const Color(0xFFFF5A5F33);
        text = 'Declined';
        icon = '✕ ';
        break;
      default:
        backgroundColor = const Color(0xFFF5A62318);
        borderColor = const Color(0xFFF5A62333);
        text = 'Pending';
        icon = '⏳ ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$icon$text',
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  final Application application;

  const _ContactSection({required this.application});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF00C89610),
        border: Border.all(color: const Color(0xFF00C89630)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CLIENT CONTACT',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: AppColors.green,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          
          // Phone row
          Row(
            children: [
              Icon(
                Icons.phone,
                size: 14,
                color: AppColors.green,
              ),
              const SizedBox(width: 8),
              Text(
                application.clientPhone,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          
          // Email row
          Row(
            children: [
              Icon(
                Icons.email,
                size: 14,
                color: AppColors.green,
              ),
              const SizedBox(width: 8),
              Text(
                application.clientEmail,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: AppColors.sub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Call button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () => _makePhoneCall(application.clientPhone),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
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
                    Icons.phone,
                    size: 14,
                    color: AppColors.bg,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Call Client',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _WaitingNotice extends StatelessWidget {
  const _WaitingNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          '⏳ Waiting for client response',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: AppColors.sub,
          ),
          const SizedBox(height: 16),
          const Text(
            'No applications yet',
            style: TextStyle(
              fontFamily: 'Cormorant Garamond',
              fontSize: 18,
              color: AppColors.sub,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse gigs and start applying!',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Error loading applications',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          color: AppColors.sub,
        ),
      ),
    );
  }
}
