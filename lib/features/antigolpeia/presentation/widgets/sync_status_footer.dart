import 'package:flutter/material.dart';
import '../../../antigolpe/constants/antigolpe_constants.dart';

/// Rodapé de status da última sincronização comunitária.
/// Ergonomia SM A256E: nunca invade a barra de gestos do sistema.
class SyncStatusFooter extends StatelessWidget {
  final DateTime? lastSyncAt;

  const SyncStatusFooter({super.key, this.lastSyncAt});

  @override
  Widget build(BuildContext context) {
    final label = lastSyncAt != null
        ? '${AntiGolpeConstants.keyStatsSyncUpdated}: ${_formatDate(lastSyncAt!)}'
        : AntiGolpeConstants.keyIaScanning;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              lastSyncAt != null ? Icons.cloud_done : Icons.cloud_sync,
              color: AntiGolpeConstants.colorSafe,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
