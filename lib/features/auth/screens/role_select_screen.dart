import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  final bool fromSocial;
  final String prefillName;
  final String prefillEmail;
  final String uid;

  const RoleSelectScreen({
    super.key,
    this.fromSocial = false,
    this.prefillName = '',
    this.prefillEmail = '',
    this.uid = '',
  });

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  String? selectedRole;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name if coming from social login
    if (widget.fromSocial) {
      _nameController.text = widget.prefillName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String value) {
    // Remove all non-digit characters
    String digits = value.replaceAll(RegExp(r'\D'), '');
    
    // Limit to 11 digits
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }
    
    // Format as 09XX-XXX-XXXX
    if (digits.length >= 4) {
      String formatted = digits.substring(0, 4);
      if (digits.length > 4) {
        formatted += '-' + digits.substring(4, 7);
      }
      if (digits.length > 7) {
        formatted += '-' + digits.substring(7);
      }
      return formatted;
    }
    
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
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
                  if (widget.fromSocial) _buildSocialProfileFields(),
                  const SizedBox(height: 40),
                  _RoleCard(
                    title: 'Musician',
                    description: 'Find gigs and get hired for events',
                    icon: _buildWaveformIcon(),
                    isSelected: selectedRole == 'musician',
                    onTap: () => setState(() => selectedRole = 'musician'),
                    selectedColor: const Color(0xFFF5A623),
                    unselectedBorderColor: const Color(0xFFF5A623).withValues(alpha: 0.3),
                    unselectedBgColor: const Color(0xFFF5A623).withValues(alpha: 0.05),
                  ),
                  const SizedBox(height: 20),
                  _RoleCard(
                    title: 'Client',
                    description: 'Hire musicians for your events',
                    icon: _buildBriefcaseIcon(),
                    isSelected: selectedRole == 'client',
                    onTap: () => setState(() => selectedRole = 'client'),
                    selectedColor: const Color(0xFF8B6FFF),
                    unselectedBorderColor: const Color(0xFF8B6FFF).withValues(alpha: 0.3),
                    unselectedBgColor: const Color(0xFF8B6FFF).withValues(alpha: 0.05),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: selectedRole != null && !_isLoading
                        ? _handleContinue
                        : null,
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
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFF4EFEA),
                              ),
                            )
                          : Text(
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialProfileFields() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13192E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF5A623).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          const Text(
            'COMPLETE YOUR PROFILE',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5A623),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Full name field
          const Text(
            'NAME OR BUSINESS NAME',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3A4560),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              color: Color(0xFFF4EFEA),
              fontSize: 13,
              fontFamily: 'DM Sans',
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.person_outline,
                color: Color(0xFF7E8BA8),
                size: 18,
              ),
              hintText: 'Your name or business name',
              hintStyle: const TextStyle(
                color: Color(0xFF7E8BA8),
                fontSize: 13,
                fontFamily: 'DM Sans',
              ),
              filled: true,
              fillColor: const Color(0xFF0F1424),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF1C2338),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFF5A623),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFFF5A5F),
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFFF5A5F),
                  width: 1.5,
                ),
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFFF5A5F),
                fontSize: 11,
                fontFamily: 'DM Sans',
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name or business name';
              }
              if (value.trim().length < 3) {
                return 'Must be at least 3 characters';
              }
              if (value.trim().length > 60) {
                return 'Name is too long';
              }
              if (!RegExp(r"^[a-zA-Z0-9\s\&\'\.\,\-]+$")
                  .hasMatch(value.trim())) {
                return 'Please enter a valid name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Phone number field
          const Text(
            'PHONE NUMBER',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3A4560),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return TextEditingValue(
                  text: _formatPhoneNumber(newValue.text),
                  selection: TextSelection.collapsed(
                    offset: _formatPhoneNumber(newValue.text).length,
                  ),
                );
              }),
            ],
            style: const TextStyle(
              color: Color(0xFFF4EFEA),
              fontSize: 13,
              fontFamily: 'DM Sans',
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.phone_outlined,
                color: Color(0xFF7E8BA8),
                size: 18,
              ),
              hintText: '0917-XXX-XXXX',
              hintStyle: const TextStyle(
                color: Color(0xFF7E8BA8),
                fontSize: 13,
                fontFamily: 'DM Sans',
              ),
              filled: true,
              fillColor: const Color(0xFF0F1424),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1C2338)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFF5A623),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFFF5A5F)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFFF5A5F),
                  width: 1.5,
                ),
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFFF5A5F),
                fontSize: 11,
                fontFamily: 'DM Sans',
              ),
            ),
            validator: (value) {
              // Remove formatting for validation
              String cleanValue = value?.replaceAll(RegExp(r'\D'), '') ?? '';
              if (cleanValue.isEmpty) {
                return 'Phone number is required';
              }
              if (cleanValue.length != 11) {
                return 'Please enter a valid 11-digit Philippine phone number';
              }
              if (!RegExp(r'^09\d{9}$').hasMatch(cleanValue)) {
                return 'Phone number must start with 09 and be 11 digits';
              }
              return null;
            },
          ),
        ],
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
    if (widget.fromSocial) {
      if (!_formKey.currentState!.validate()) return;
    }

    if (selectedRole == null) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (widget.fromSocial) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'name': _nameController.text.trim(),
            'email': widget.prefillEmail,
            'phone': _phoneController.text.trim(),
            'role': selectedRole,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'role': selectedRole});
        }
      }

      if (mounted) {
        if (selectedRole == 'musician') {
          context.go('/musician-home');
        } else {
          context.go('/client-home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving role: $e'),
            backgroundColor: const Color(0xFFFF5A5F),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          color: isSelected ? selectedColor.withValues(alpha: 0.1) : unselectedBgColor,
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
                color: isSelected ? selectedColor.withValues(alpha: 0.2) : unselectedBgColor,
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
                        colors: [selectedColor, selectedColor.withValues(alpha: 0.8)],
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

      paint.color = const Color(0xFFF5A623).withValues(alpha: opacities[i]);
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
