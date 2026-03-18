import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0C0800),
              Color(0xFF07080E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text(
                  'I am a...',
                  style: TextStyle(
                    fontFamily: 'Cormorant Garamond',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF4EFEA),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose your role on GigSugo',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: Color(0xFF7E8BA8),
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoleCard(
                        title: 'Musician',
                        description: 'Find gigs and get hired for events',
                        icon: _buildWaveformIcon(),
                        isSelected: selectedRole == 'musician',
                        onTap: () => setState(() => selectedRole = 'musician'),
                        selectedColor: const Color(0xFFF5A623),
                        unselectedBorderColor: const Color(0xFFF5A623).withOpacity(0.3),
                        unselectedBgColor: const Color(0xFFF5A623).withOpacity(0.05),
                      ),
                      const SizedBox(height: 20),
                      _RoleCard(
                        title: 'Client',
                        description: 'Hire musicians for your events',
                        icon: _buildBriefcaseIcon(),
                        isSelected: selectedRole == 'client',
                        onTap: () => setState(() => selectedRole = 'client'),
                        selectedColor: const Color(0xFF8B6FFF),
                        unselectedBorderColor: const Color(0xFF8B6FFF).withOpacity(0.3),
                        unselectedBgColor: const Color(0xFF8B6FFF).withOpacity(0.05),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: selectedRole != null ? _handleContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedRole == 'musician' 
                          ? const Color(0xFFF5A623) 
                          : selectedRole == 'client'
                              ? const Color(0xFF8B6FFF)
                              : const Color(0xFF3A4560),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      selectedRole == 'musician' 
                          ? 'Continue as Musician →'
                          : selectedRole == 'client'
                              ? 'Continue as Client →'
                              : 'Select a role to continue',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF4EFEA),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveformIcon() {
    return Container(
      width: 30,
      height: 30,
      child: CustomPaint(
        painter: WaveformPainter(),
      ),
    );
  }

  Widget _buildBriefcaseIcon() {
    return Icon(
      Icons.work_outline,
      size: 28,
      color: const Color(0xFF8B6FFF),
    );
  }

  Future<void> _handleContinue() async {
    if (selectedRole == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'role': selectedRole});
      }

      if (mounted) {
        if (selectedRole == 'musician') {
          context.go('/musician-home');
        } else {
          context.go('/client-home');
        }
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving role: $e'),
            backgroundColor: const Color(0xFFFF5A5F),
          ),
        );
      }
    }
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedBorderColor;
  final Color unselectedBgColor;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedBorderColor,
    required this.unselectedBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.1) : unselectedBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? selectedColor : unselectedBorderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor.withOpacity(0.2) : unselectedBgColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? selectedColor : unselectedBorderColor,
                  width: 1,
                ),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cormorant Garamond',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF4EFEA),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: Color(0xFF7E8BA8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(
                        colors: [selectedColor, selectedColor.withOpacity(0.8)],
                      )
                    : null,
                color: isSelected ? null : const Color(0xFF1C2338),
                border: Border.all(
                  color: isSelected ? selectedColor : const Color(0xFF3A4560),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Color(0xFFF4EFEA),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5A623)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    final barWidth = 4.0;
    final spacing = 6.0;
    final totalWidth = (barWidth * 5) + (spacing * 4);
    final startX = (size.width - totalWidth) / 2;

    final heights = [0.4, 0.6, 1.0, 0.6, 0.4];
    final opacities = [0.45, 0.70, 1.0, 0.70, 0.45];

    for (int i = 0; i < 5; i++) {
      final barHeight = size.height * heights[i];
      final barX = startX + (i * (barWidth + spacing));
      final barY = (size.height - barHeight) / 2;

      paint.color = const Color(0xFFF5A623).withOpacity(opacities[i]);
      canvas.drawLine(
        Offset(barX, barY + barHeight),
        Offset(barX, barY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
