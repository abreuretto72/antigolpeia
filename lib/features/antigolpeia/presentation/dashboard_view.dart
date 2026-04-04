import 'package:flutter/material.dart';
import '../../antigolpe/constants/antigolpe_constants.dart';
import '../services/stats_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = StatsService().getDashboardStats();
  }

  void _refresh() =>
      setState(() => _statsFuture = StatsService().getDashboardStats());

  /// Formata com separador de milhar: 1284 → "1,284"
  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AntiGolpeia'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<DashboardStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AntiGolpeConstants.colorSafe),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Erro ao carregar estatísticas.',
                style: TextStyle(color: AntiGolpeConstants.colorRisk),
              ),
            );
          }
          return _buildContent(snapshot.data ?? DashboardStats.empty);
        },
      ),
    );
  }

  Widget _buildContent(DashboardStats stats) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ESTATÍSTICAS DE PROTEÇÃO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Contador principal ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: AntiGolpeConstants.colorRisk,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    _fmt(stats.totalBlocked),
                    style: const TextStyle(
                      fontSize: 72,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'GOLPES BLOQUEADOS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── SMS + WhatsApp ────────────────────────────────────────────────
            Row(
              children: [
                _ChannelCard(
                  icon: Icons.sms,
                  label: 'SMS:',
                  value: _fmt(stats.smsFraud),
                  iconColor: Colors.blueAccent,
                ),
                const SizedBox(width: 12),
                _ChannelCard(
                  icon: Icons.chat,
                  label: 'WhatsApp:',
                  value: _fmt(stats.whatsappFraud),
                  iconColor: const Color(0xFF25D366),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Suspeitos ─────────────────────────────────────────────────────
            if (stats.totalSuspicious > 0)
              _ChannelCard(
                icon: Icons.warning_amber_rounded,
                label: 'Suspeitos:',
                value: _fmt(stats.totalSuspicious),
                iconColor: Colors.orange,
                expand: true,
              ),

            const SizedBox(height: 20),

            // ── Eficiência (badge verde) ───────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AntiGolpeConstants.colorSafe,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${stats.efficiencyPct}%  SEGURO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool expand;

  const _ChannelCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.white60)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: card) : Expanded(child: card);
  }
}
