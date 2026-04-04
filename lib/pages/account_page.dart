import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/antigolpe/constants/antigolpe_constants.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _client = Supabase.instance.client;
  bool _deleting = false;

  String get _userId =>
      _client.auth.currentUser?.id ?? '—';

  bool get _isAnonymous =>
      _client.auth.currentUser?.isAnonymous ?? true;

  // ── Exclusão de conta ─────────────────────────────────────────────────────

  Future<void> _deleteAccount() async {
    // Confirmação em dois passos
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Esta ação é permanente e irreversível.\n\n'
          'Todos os seus dados serão apagados:\n'
          '• Histórico de análises\n'
          '• Backup de contatos (whitelist/blacklist)\n'
          '• Denúncias registradas\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AntiGolpeConstants.colorRisk),
            child: const Text('Sim, excluir'),
          ),
        ],
      ),
    );
    if (step1 != true || !mounted) return;

    // Segunda confirmação — digitar "EXCLUIR"
    final confirmController = TextEditingController();
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmação final'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Digite EXCLUIR para confirmar a exclusão permanente da sua conta:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'EXCLUIR',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, confirmController.text.trim() == 'EXCLUIR'),
            style: TextButton.styleFrom(
                foregroundColor: AntiGolpeConstants.colorRisk),
            child: const Text('EXCLUIR CONTA'),
          ),
        ],
      ),
    );
    if (step2 != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      // 1. Chamar Edge Function que deleta dados e usuário server-side
      final res = await _client.functions.invoke('delete-account');
      final data = res.data as Map<String, dynamic>? ?? {};

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Erro desconhecido');
      }

      // 2. Limpar Hive local completamente
      await Hive.deleteFromDisk();

      // 3. Signout local (a sessão já foi invalidada no servidor)
      await _client.auth.signOut();

      // A AuthGate cuida do redirecionamento após signOut
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao excluir conta: $e'),
        backgroundColor: AntiGolpeConstants.colorRisk,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    await _client.auth.signOut();
    // AuthGate redireciona automaticamente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info da conta ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_circle,
                          size: 32,
                          color: _isAnonymous
                              ? Colors.white38
                              : AntiGolpeConstants.colorSafe),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isAnonymous ? 'Conta Anônima' : 'Conta Autenticada',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${_userId.length > 16 ? '${_userId.substring(0, 16)}…' : _userId}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isAnonymous) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Conta anônima — seus dados são vinculados a este dispositivo. '
                        'Se desinstalar o app sem fazer backup, os dados são perdidos.',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Seção LGPD ──────────────────────────────────────────────────
            const Text(
              'SEUS DIREITOS (LGPD)',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white54),
            ),
            const SizedBox(height: 12),

            _ActionTile(
              icon: Icons.logout,
              label: 'Sair da conta',
              subtitle: 'Encerra a sessão neste dispositivo',
              color: Colors.white70,
              onTap: _logout,
            ),

            const SizedBox(height: 8),

            _ActionTile(
              icon: Icons.delete_forever_rounded,
              label: 'Excluir minha conta',
              subtitle:
                  'Remove permanentemente todos os seus dados dos nossos servidores',
              color: AntiGolpeConstants.colorRisk,
              onTap: _deleting ? null : _deleteAccount,
              loading: _deleting,
            ),

            const SizedBox(height: 24),

            // ── Nota legal ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Em conformidade com a LGPD (Lei nº 13.709/2018), '
                'você tem o direito de solicitar a exclusão de todos os seus '
                'dados pessoais a qualquer momento. A exclusão é permanente '
                'e não pode ser desfeita.\n\n'
                'Padrões de fraude anonimizados contribuídos para a base '
                'comunitária são mantidos sem vínculo a você (dados anonimizados '
                'não são dados pessoais — LGPD art. 5º, III).',
                style: TextStyle(fontSize: 11, color: Colors.white38, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color))
                : Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white54)),
                ],
              ),
            ),
            if (!loading) Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
