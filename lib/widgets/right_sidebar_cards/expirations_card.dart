import 'package:coachhub/models/asesorado_model.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/widgets/optimized_cached_image.dart';
import 'package:flutter/material.dart';

class ExpirationsCard extends StatefulWidget {
  final List<Asesorado> asesorados;
  final bool isRefreshing;

  const ExpirationsCard({
    super.key,
    required this.asesorados,
    required this.isRefreshing,
  });

  @override
  State<ExpirationsCard> createState() => _ExpirationsCardState();
}

class _ExpirationsCardState extends State<ExpirationsCard> {
  Color _getExpirationColor(int daysLeft) {
    if (daysLeft < 0) return Colors.redAccent;
    if (daysLeft == 0) return Colors.orange;
    if (daysLeft <= 3) return Colors.amber;
    if (daysLeft <= 7) return Colors.blue;
    return Colors.green;
  }

  String _getExpirationLabel(int daysLeft) {
    if (daysLeft < 0) return '🔴 Vencido';
    if (daysLeft == 0) return '⚠️ Hoy';
    if (daysLeft == 1) return '🟡 Mañana';
    if (daysLeft <= 7) return '🟡 En $daysLeft d.';
    return '🟢 En $daysLeft d.';
  }

  @override
  Widget build(BuildContext context) {
    final asesorados = widget.asesorados;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Próximos Vencimientos',
                  style: AppStyles.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isRefreshing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (asesorados.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(child: Text('No hay vencimientos próximos.')),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                itemCount: asesorados.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final asesorado = asesorados[index];

                  // Si no tiene fecha de vencimiento, no mostrar en la tarjeta
                  if (asesorado.dueDate == null) {
                    return const SizedBox.shrink();
                  }

                  final daysLeft =
                      asesorado.dueDate!.difference(DateTime.now()).inDays;
                  final expirationColor = _getExpirationColor(daysLeft);

                  return _buildExpirationItem(
                    name: asesorado.name,
                    daysLeftText: _getExpirationLabel(daysLeft),
                    avatarUrl: asesorado.avatarUrl,
                    expirationColor: expirationColor,
                    daysLeft: daysLeft,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpirationItem({
    required String name,
    required String daysLeftText,
    required String avatarUrl,
    required Color expirationColor,
    required int daysLeft,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: expirationColor.withValues(alpha: 0.08),
          border: Border(left: BorderSide(color: expirationColor, width: 3)),
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(6),
          ),
        ),
        child: Row(
          children: [
            OptimizedCachedCircleAvatar(
              imagePath: avatarUrl,
              radius: 20,
              placeholderIcon: Icons.person,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppStyles.normal.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    daysLeftText,
                    style: AppStyles.secondary.copyWith(
                      fontSize: 12,
                      color: expirationColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              daysLeft < 0 ? Icons.error : Icons.schedule,
              color: expirationColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
