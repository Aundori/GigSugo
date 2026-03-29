import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';

class BottomNavBar extends StatelessWidget {
  final String activeTab;

  const BottomNavBar({this.activeTab = 'home', super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              NavItem(
                icon: HomeIcon(isActive: activeTab == 'home'),
                label: 'Home',
                isActive: activeTab == 'home',
                onTap: () {
                  if (activeTab != 'home') context.go('/musician-home');
                },
              ),
              NavItem(
                icon: GigsIcon(isActive: activeTab == 'gigs'),
                label: 'Gigs',
                isActive: activeTab == 'gigs',
                onTap: () {
                  if (activeTab != 'gigs') context.go('/gigs');
                },
              ),
              NavItem(
                icon: AppliedIcon(isActive: activeTab == 'applied'),
                label: 'Applied',
                isActive: activeTab == 'applied',
                onTap: () {
                  if (activeTab != 'applied') context.go('/applications');
                },
              ),
              NavItem(
                icon: ProfileIcon(isActive: activeTab == 'profile'),
                label: 'Profile',
                isActive: activeTab == 'profile',
                onTap: () {
                  if (activeTab != 'profile') context.go('/profile');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const NavItem({
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
          icon,
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

class HomeIcon extends StatelessWidget {
  final bool isActive;
  const HomeIcon({this.isActive = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      isActive ? Icons.home_rounded : Icons.home_outlined,
      color: isActive ? AppColors.amber : AppColors.sub,
      size: 24,
    );
  }
}

class GigsIcon extends StatelessWidget {
  final bool isActive;
  const GigsIcon({this.isActive = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      isActive ? Icons.music_note : Icons.music_note_outlined,
      color: isActive ? AppColors.amber : AppColors.sub,
      size: 24,
    );
  }
}

class AppliedIcon extends StatelessWidget {
  final bool isActive;
  const AppliedIcon({this.isActive = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      isActive ? Icons.description_rounded : Icons.description_outlined,
      color: isActive ? AppColors.amber : AppColors.sub,
      size: 24,
    );
  }
}

class ProfileIcon extends StatelessWidget {
  final bool isActive;
  const ProfileIcon({this.isActive = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      isActive ? Icons.person_rounded : Icons.person_outline_rounded,
      color: isActive ? AppColors.amber : AppColors.sub,
      size: 24,
    );
  }
}
