import 'package:coachhub/models/asesorado_model.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/widgets/optimized_cached_image.dart';
import 'package:flutter/material.dart';

class DeudoresCard extends StatefulWidget {
  final List<Asesorado> deudores;
  final bool isRefreshing;

  const DeudoresCard({
    super.key,
    required this.deudores,
    required this.isRefreshing,
  });

  @override
  State<DeudoresCard> createState() => _DeudoresCardState();
}

class _DeudoresCardState extends State<DeudoresCard> {
  Color _getUrgencyColor(int daysOverdue) {
    if (daysOverdue > 30) return Colors.redAccent;
    if (daysOverdue > 14) return Colors.orange;
    if (daysOverdue > 0) return Colors.amber;
    return Colors.blueGrey;
  }

  String _formatDueMessage(int daysOverdue) {
    if (daysOverdue > 1) {
      return 'Vencido hace $daysOverdue días';
    }
    if (daysOverdue == 1) {
      return 'Vencido hace 1 día';
    }
    if (daysOverdue == 0) {
      return 'Vence hoy';
    }
    final remaining = daysOverdue.abs();
    if (remaining == 1) {
      return 'Vence mañana';
    }
    return 'Vence en $remaining días';
  }

  @override
  Widget build(BuildContext context) {
    final deudores = widget.deudores;

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
                  'Pagos Pendientes',
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
          if (deudores.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(child: Text('No hay pagos pendientes.')),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                itemCount: deudores.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final asesorado = deudores[index];

                  // Si no tiene fecha de vencimiento, no mostrar
                  if (asesorado.dueDate == null) {
                    return const SizedBox.shrink();
                  }

                  final daysOverdue =
                      DateTime.now().difference(asesorado.dueDate!).inDays;
                  final urgencyColor = _getUrgencyColor(daysOverdue);

                  return _buildDeudorItem(
                    name: asesorado.name,
                    overdueText: _formatDueMessage(daysOverdue),
                    avatarUrl: asesorado.avatarUrl,
                    urgencyColor: urgencyColor,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeudorItem({
    required String name,
    required String overdueText,
    required String avatarUrl,
    required Color urgencyColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: urgencyColor.withValues(alpha: 0.08),
          border: Border(left: BorderSide(color: urgencyColor, width: 3)),
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
                    overdueText,
                    style: AppStyles.secondary.copyWith(
                      fontSize: 12,
                      color: urgencyColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.warning_rounded, color: urgencyColor, size: 20),
          ],
        ),
      ),
    );
  }
}
