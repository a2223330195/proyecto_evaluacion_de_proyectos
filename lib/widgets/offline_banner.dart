import 'package:flutter/material.dart';

/// Banner para indicar que se está mostrando datos offline/caché
///
/// 🛡️ MÓDULO 4: Error Handling - Indicador visual de fallback a cache
class OfflineBanner extends StatelessWidget {
  final String? message;
  final DateTime? cacheTime;
  final VoidCallback? onDismiss;

  const OfflineBanner({
    super.key,
    this.message,
    this.cacheTime,
    this.onDismiss,
  });

  String _formatCacheTime() {
    if (cacheTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(cacheTime!);

    if (difference.inSeconds < 60) {
      return 'hace ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours}h';
    } else {
      return 'hace ${difference.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatCacheTime();
    final displayMessage = message ?? 'Mostrando datos offline (caché)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade400, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayMessage,
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
