import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/antigolpe/constants/antigolpe_constants.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _version = '1.0.2';
  static const String _build = '3';
  static const String _company = 'Multiverso Digital';
  static const String _email = 'contato@multiversodigital.com.br';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
        child: Column(
          children: [
            // ── Logo / ícone ─────────────────────────────────────────────────
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AntiGolpeConstants.colorRisk.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AntiGolpeConstants.colorSafe.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.security,
                size: 52,
                color: AntiGolpeConstants.colorSafe,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'AntiGolpeia',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            const Text(
              'Versão $_version (build $_build)',
              style: TextStyle(fontSize: 13, color: Colors.white54),
            ),

            const SizedBox(height: 32),

            // ── Info card ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  const _InfoRow(
                    icon: Icons.business,
                    label: 'Desenvolvido por',
                    value: _company,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Contato',
                    value: _email,
                    onTap: () {
                      Clipboard.setData(
                          const ClipboardData(text: _email));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('E-mail copiado!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Descrição ────────────────────────────────────────────────────
            const Text(
              'O AntiGolpeia usa inteligência artificial para analisar mensagens '
              'suspeitas em tempo real, detectar padrões de fraude e alertar você '
              'antes de qualquer prejuízo. Seus dados são protegidos pela LGPD e '
              'nunca compartilhados com terceiros sem sua autorização.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.white60, height: 1.6),
            ),

            const SizedBox(height: 40),

            // ── Direitos ─────────────────────────────────────────────────────
            Text(
              '© ${DateTime.now().year} $_company. Todos os direitos reservados.',
              style:
                  const TextStyle(fontSize: 11, color: Colors.white38),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, size: 18, color: AntiGolpeConstants.colorSafe),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white54)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(Icons.copy, size: 16, color: Colors.white38),
      ],
    );

    return onTap != null
        ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: row)
        : row;
  }
}
