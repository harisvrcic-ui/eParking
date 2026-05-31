import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/login_response.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/dialog_helpers.dart';
import '../widgets/profile_image_helper.dart';
import 'login_screen.dart';
import 'profile_edit_screen.dart';
import 'profile_notifications_screen.dart';
import 'vehicles_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.user});

  final LoginResponse user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userService = UserService();
  String? _picture;
  bool _loadingPicture = true;

  @override
  void initState() {
    super.initState();
    _picture = widget.user.picture;
    _loadPicture();
  }

  Future<void> _loadPicture() async {
    try {
      final profile = await _userService.getMyProfile();
      if (mounted) {
        setState(() {
          _picture = profile.picture;
          _loadingPicture = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final initial = widget.user.firstName.isNotEmpty
        ? widget.user.firstName[0].toUpperCase()
        : widget.user.username[0].toUpperCase();

    final s = context.s;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(s.profile),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _loadingPicture
                    ? CircleAvatar(
                        radius: 48,
                        backgroundColor: primary.withValues(alpha: 0.15),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ProfileAvatar(
                        picture: _picture,
                        initial: initial,
                        radius: 48,
                      ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified, color: primary, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              widget.user.fullName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              widget.user.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _ProfileMenuCard(
            children: [
              _ProfileMenuTile(
                icon: Icons.edit_outlined,
                title: s.editProfile,
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const ProfileEditScreen(),
                    ),
                  );
                  if (updated == true) {
                    if (!context.mounted) return;
                    await _loadPicture();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.profileUpdated)),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              _ProfileMenuTile(
                icon: Icons.directions_car_outlined,
                title: s.myVehicles,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VehiclesPage(userId: widget.user.id),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _ProfileMenuTile(
                icon: Icons.notifications_outlined,
                title: s.notifications,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProfileNotificationsScreen(userId: widget.user.id),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              final s = context.s;
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: dialogTitleBar(ctx, s.signOut),
                  content: Text('Jeste li sigurni da se želite odjaviti?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(s.no),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(s.signOut),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: Text(s.signOut),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade600),
      onTap: onTap,
    );
  }
}
