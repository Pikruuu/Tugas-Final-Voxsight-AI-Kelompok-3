import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Alert', 'Info', 'System'];

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Battery Low!',
      'message': 'VoxSight AI battery is at 15%. Please charge the device.',
      'time': '10 min ago',
      'type': 'Alert',
      'icon': Icons.battery_alert_outlined,
      'color': AppColors.accentRed,
      'isRead': false,
    },
    {
      'title': 'Obstacle Detected',
      'message': 'A wall was detected 0.8 m in front. Audio alert sent.',
      'time': '25 min ago',
      'type': 'Alert',
      'icon': Icons.warning_amber_outlined,
      'color': AppColors.accentOrange,
      'isRead': false,
    },
    {
      'title': 'Location Updated',
      'message': 'Device is now at SLB A YPAB, Surabaya.',
      'time': '1 hour ago',
      'type': 'Info',
      'icon': Icons.location_on_outlined,
      'color': AppColors.accent,
      'isRead': true,
    },
    {
      'title': 'Camera Calibrated',
      'message': 'Auto-calibration complete. Object detection accuracy: 94%',
      'time': '2 hours ago',
      'type': 'Info',
      'icon': Icons.camera_outlined,
      'color': AppColors.accent,
      'isRead': true,
    },
    {
      'title': 'System Update Available',
      'message': 'VoxSight Firmware v2.3.1 is available. Tap to update.',
      'time': '3 hours ago',
      'type': 'System',
      'icon': Icons.system_update_outlined,
      'color': AppColors.primary,
      'isRead': true,
    },
    {
      'title': 'Device Connected',
      'message': 'VoxSight AI-001 connected successfully via Bluetooth.',
      'time': 'Yesterday',
      'type': 'System',
      'icon': Icons.bluetooth_connected_outlined,
      'color': AppColors.primary,
      'isRead': true,
    },
    {
      'title': 'High Temperature Warning',
      'message': 'Device temperature reached 58°C. Allow device to cool down.',
      'time': 'Yesterday',
      'type': 'Alert',
      'icon': Icons.thermostat_outlined,
      'color': AppColors.accentRed,
      'isRead': true,
    },
    {
      'title': 'Data Sync Complete',
      'message': 'All device data has been synced to the cloud successfully.',
      'time': '2 days ago',
      'type': 'Info',
      'icon': Icons.cloud_done_outlined,
      'color': AppColors.accentGreen,
      'isRead': true,
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_selectedFilter == 'All') return _notifications;
    return _notifications
        .where((n) => n['type'] == _selectedFilter)
        .toList();
  }

  int get _unreadCount =>
      _notifications.where((n) => !(n['isRead'] as bool)).length;

  void _markAllRead() {
    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (_unreadCount > 0)
                              Text(
                                '$_unreadCount unread notifications',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        if (_unreadCount > 0)
                          TextButton(
                            onPressed: _markAllRead,
                            child: Text(
                              'Mark all read',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
              filters: _filters,
              selected: _selectedFilter,
              onSelect: (f) => setState(() => _selectedFilter = f),
            ),
          ),

          _filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_off_outlined,
                            size: 56, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _NotifTile(
                        data: _filtered[i],
                        onTap: () {
                          setState(() => _filtered[i]['isRead'] = true);
                        },
                      ),
                      childCount: _filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  _FilterHeaderDelegate({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final bool sel = f == selected;
            return GestureDetector(
              onTap: () => onSelect(f),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  f,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: sel ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate old) =>
      old.selected != selected;
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _NotifTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isRead = data['isRead'] as bool;
    final Color color = data['color'] as Color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? AppColors.white : AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? AppColors.border
                : AppColors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data['icon'] as IconData, color: color, size: 22),
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
                          data['title'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['message'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data['type'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data['time'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textHint,
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
    );
  }
}
