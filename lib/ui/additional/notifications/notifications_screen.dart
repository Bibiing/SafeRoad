import 'package:saferoad/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/status_helper.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../domain/model/enums.dart';
import '../../../domain/model/notification_model.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/notification_repository.dart';
import '../../user/report_detail/report_detail_screen.dart';

/// Layar daftar notifikasi perubahan status laporan milik user.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifRepo = context.read<NotificationRepository>();
    final uid = context.read<AuthRepository>().currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () => notifRepo.markAllAsRead(uid),
              child: Text(
                'Tandai dibaca',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: uid == null
          ? const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Belum masuk.',
            )
          : StreamBuilder<List<AppNotification>>(
              stream: notifRepo.watchNotifications(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.notifications_none_outlined,
                    title: 'Belum ada notifikasi.',
                    subtitle: 'Pembaruan status laporanmu akan muncul di sini.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _NotificationTile(
                    notification: items[index],
                    onTap: () {
                      notifRepo.markAsRead(uid, items[index].id);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportDetailScreen(
                            reportId: items[index].reportId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = ReportStatus.fromFirestore(notification.newStatus);
    final color = StatusHelper.colorOf(status);

    return Material(
      color: notification.isRead
          ? context.appColors.surface
          : context.appColors.primaryTint.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(StatusHelper.iconOf(status), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title, style: AppTextStyles.subtitle),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: AppTextStyles.caption,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormatter.relative(notification.createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: context.appColors.textHint),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
