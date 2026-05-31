import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/user_notification.dart';
import '../services/user_notification_service.dart';
import '../widgets/form_navigation.dart';

class ProfileNotificationsScreen extends StatefulWidget {
  const ProfileNotificationsScreen({super.key, required this.userId});

  final int userId;

  @override
  State<ProfileNotificationsScreen> createState() =>
      _ProfileNotificationsScreenState();
}

class _ProfileNotificationsScreenState extends State<ProfileNotificationsScreen> {
  static const _pollInterval = Duration(seconds: 12);

  final _service = UserNotificationService();
  Timer? _pollTimer;
  List<UserNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final items = await _service.getMy();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent) {
          _error = e.toString().replaceFirst('Exception: ', '');
        }
        _loading = false;
      });
    }
  }

  Future<void> _markRead(UserNotification n) async {
    if (n.isRead) return;
    try {
      await _service.markAsRead(n.id);
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  static String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Upravo sada';
    if (diff.inMinutes < 60) return 'Prije ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return h == 1 ? 'Prije 1 sat' : 'Prije $h sati';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return d == 1 ? 'Jučer' : 'Prije $d dana';
    }
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}. ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final s = context.s;
        return Scaffold(
          appBar: formScreenAppBar(context, title: s.notificationsTitle),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    )
                  : _items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Nema obavještenja.\nNove poruke se automatski učitavaju.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final n = _items[index];
                            return _NotificationTile(
                              notification: n,
                              time: _formatTime(n.createdAt),
                              onTap: () => _markRead(n),
                            );
                          },
                        ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.time,
    required this.onTap,
  });

  final UserNotification notification;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final read = notification.isRead;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: read
          ? Colors.white
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notifications,
                color: read ? Colors.grey : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (!read)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Novo',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification.body),
                    const SizedBox(height: 6),
                    Text(
                      time,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (!read) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Dodirni za označavanje kao pročitano',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
