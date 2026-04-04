import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../features/antigolpe/constants/antigolpe_constants.dart';
import '../features/antigolpeia/services/cloud_backup_service.dart';
import '../features/antigolpeia/data/models/app_settings.dart';

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  final _backup = CloudBackupService();
  bool _loadingBackup = false;
  bool _loadingRestore = false;
  String? _statusMsg;
  Color _statusColor = AntiGolpeConstants.colorSafe;
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _loadLastSync();
  }

  Future<void> _loadLastSync() async {
    final t = await _backup.lastSyncAt();
    if (mounted) setState(() => _lastSync = t);
  }

  Future<void> _runBackup() async {
    setState(() {
      _loadingBackup = true;
      _statusMsg = null;
    });
    final result = await _backup.runBackup();
    if (!mounted) return;
    setState(() {
      _loadingBackup = false;
      _lastSync = result.syncedAt;
      _statusMsg = result.success
          ? 'Backup salvo na nuvem com sucesso.'
          : (result.error ?? 'Erro desconhecido.');
      _statusColor = result.success
          ? AntiGolpeConstants.colorSafe
          : AntiGolpeConstants.colorRisk;
    });
  }

  Future<void> _runRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar dados?'),
        content: const Text(
          'Os dados locais atuais serão substituídos pelo backup na nuvem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AntiGolpeConstants.colorRisk),
            child: const Text('Restaurar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _loadingRestore = true;
      _statusMsg = null;
    });
    final result = await _backup.runRestore();
    if (!mounted) return;
    setState(() {
      _loadingRestore = false;
      _statusMsg = result.success
          ? 'Dados restaurados com sucesso.'
          : (result.error == 'antigolpeia_backup_not_found'
              ? 'Nenhum backup encontrado. Clique em "Salvar na Nuvem" para criar o primeiro.'
              : result.error ?? 'Algo deu errado. Tente novamente.');
      _statusColor = result.success
          ? AntiGolpeConstants.colorSafe
          : AntiGolpeConstants.colorRisk;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BACKUP & CONFIGURAÇÕES')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Backup ──────────────────────────────────────────────────────
            const _SectionHeader(label: 'BACKUP NA NUVEM'),
            const SizedBox(height: 12),

            if (_lastSync != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done,
                        size: 16, color: AntiGolpeConstants.colorSafe),
                    const SizedBox(width: 6),
                    Text(
                      'Último backup: ${_formatDate(_lastSync!)}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
              ),

            if (_statusMsg != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(_statusMsg!,
                    style: TextStyle(color: _statusColor, fontSize: 13)),
              ),

            _ActionButton(
              label: 'SALVAR NA NUVEM',
              icon: Icons.cloud_upload_outlined,
              color: AntiGolpeConstants.colorSafe,
              loading: _loadingBackup,
              onTap: _runBackup,
            ),
            const SizedBox(height: 10),
            _ActionButton(
              label: 'RESTAURAR DADOS',
              icon: Icons.cloud_download_outlined,
              color: Colors.blueAccent,
              loading: _loadingRestore,
              onTap: _runRestore,
            ),

            const SizedBox(height: 32),

            // ── Configurações ────────────────────────────────────────────────
            const _SectionHeader(label: 'CONFIGURAÇÕES'),
            const SizedBox(height: 12),

            ValueListenableBuilder(
              valueListenable:
                  Hive.box<AppSettings>('app_settings').listenable(),
              builder: (context, box, _) {
                final settings = box.isEmpty
                    ? AppSettings()
                    : (box.getAt(0) ?? AppSettings());
                return Column(
                  children: [
                    _ToggleTile(
                      label: 'Alertas Sonoros Críticos',
                      subtitle: 'Som ao detectar golpe confirmado',
                      icon: Icons.volume_up_outlined,
                      value: settings.enableCriticalSounds,
                      onChanged: (v) {
                        settings.enableCriticalSounds = v;
                        settings.save();
                      },
                    ),
                    const SizedBox(height: 8),
                    _ToggleTile(
                      label: 'Vibração de Alerta',
                      subtitle: 'Haptic feedback triplo em golpes',
                      icon: Icons.vibration,
                      value: settings.enableHapticFeedback,
                      onChanged: (v) {
                        settings.enableHapticFeedback = v;
                        settings.save();
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}  '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Colors.white54,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AntiGolpeConstants.colorSafe,
          ),
        ],
      ),
    );
  }
}
