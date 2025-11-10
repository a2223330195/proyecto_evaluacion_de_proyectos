import 'package:coachhub/models/dashboard_models.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentActivityCard extends StatelessWidget {
  final List<DashboardActivity> activities;
  final bool isRefreshing;

  const RecentActivityCard({
    super.key,
    required this.activities,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Actividad Reciente',
                style: AppStyles.title,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              if (isRefreshing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            const Center(child: Text('No hay actividad reciente.'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityItem(activity);
              },
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    }
    return DateFormat('dd/MM').format(time);
  }

  Widget _buildActivityItem(DashboardActivity activity) {
    const icon = Icons.check_circle;
    const color = Colors.green;
    final text =
        'Marcaste la asistencia de ${activity.asesoradoNombre} (${activity.rutinaNombre}).';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border(left: BorderSide(color: color, width: 2)),
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(6),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppStyles.normal.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(activity.timestamp),
                    style: AppStyles.secondary.copyWith(fontSize: 11),
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
