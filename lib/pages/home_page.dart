import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/activity_counter.dart';
import '../features/antigolpeia/data/models/analysis_stats_model.dart';
import '../services/api_service.dart';
import '../services/foreground_task_service.dart';
import '../services/notification_service.dart';
import '../services/sms_monitor_service.dart';
import '../services/gmail_service.dart';
import '../features/antigolpe/constants/antigolpe_constants.dart';
import '../features/antigolpeia/presentation/dashboard_view.dart';
import '../features/antigolpeia/presentation/whitelist_view.dart';
import 'result_page.dart';
import 'stats_page.dart';
import 'history_page.dart';
import 'alerts_page.dart';
import 'paywall_page.dart';
import 'backup_settings_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_use_page.dart';
import 'about_page.dart';
import 'account_page.dart';
import 'help_page.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _apiService = ApiService();
  bool _isAnalyzing = false;
  bool _isPrivate = false;
  bool _isNotificationEnabled = false;
  bool _isSmsEnabled = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkNotificationStatus();
    _checkSmsStatus();
    _syncHistoryOnce();
    ForegroundTaskService.start();
  }

  Future<void> _checkSmsStatus() async {
    try {
      final granted = await SmsMonitorService().isPermissionGranted;
      if (granted) SmsMonitorService().startListening();
      if (mounted) setState(() => _isSmsEnabled = granted);
    } catch (e) {
      debugPrint('[HomePage] _checkSmsStatus erro: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _syncHistoryOnce() async {
    final s = ActivityCounter().stats.value;
    if (s != null && s.historyLoaded) return;
    try {
      final rows = await _apiService.getHistory();
      ActivityCounter().backfillFromHistory(rows);
    } catch (e) {
      debugPrint('[HomePage] Erro ao sincronizar histórico: $e');
    }
  }

  Future<void> _checkNotificationStatus() async {
    try {
      final status = await NotificationListenerService.isPermissionGranted();
      if (status) await NotificationService().init();
      if (mounted) setState(() => _isNotificationEnabled = status);
    } catch (e) {
      debugPrint('[HomePage] _checkNotificationStatus erro: $e');
    }
  }

  Future<void> _analyze(String type, String content) async {
    if (content.isEmpty) return;
    setState(() => _isAnalyzing = true);
    try {
      final data = await _apiService.analyzeContent(type, content,
          skipSave: _isPrivate);
      final isSuspicious = (data['risco'] as num? ?? 0) >= 50;
      ActivityCounter().add(AnalysisType.manual, wasSuspicious: isSuspicious);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultPage(result: data)),
      );
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('PAYWALL_TRIGGER')) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const PaywallPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não conseguimos analisar agora. Verifique sua conexão e tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _navigate(Widget page) {
    Navigator.pop(context); // fecha drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('images/logo.png', height: 36),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HistoryPage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),

      // ── Drawer ─────────────────────────────────────────────────────────────
      drawer: NavigationDrawer(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: BoxDecoration(
              color: AntiGolpeConstants.colorRisk.withValues(alpha: 0.15),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.security,
                    size: 36, color: AntiGolpeConstants.colorSafe),
                SizedBox(height: 8),
                Text(
                  'AntiGolpeia',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                Text(
                  'Proteção inteligente contra golpes',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Análise (home — fecha drawer apenas)
          _DrawerItem(
            icon: Icons.search,
            label: 'Analisar Mensagem',
            color: Colors.deepPurpleAccent,
            onTap: () => Navigator.pop(context),
          ),

          // Estatísticas
          _DrawerItem(
            icon: Icons.insights,
            label: 'Estatísticas & Inteligência',
            color: Colors.cyanAccent,
            onTap: () => _navigate(const StatsPage()),
          ),

          // Dashboard
          _DrawerItem(
            icon: Icons.bar_chart_rounded,
            label: 'Dashboard de Proteção',
            color: AntiGolpeConstants.colorSafe,
            onTap: () => _navigate(const DashboardView()),
          ),

          // Histórico
          _DrawerItem(
            icon: Icons.history,
            label: 'Histórico de Ameaças',
            color: Colors.blueAccent,
            onTap: () => _navigate(const HistoryPage()),
          ),

          // Contatos confiáveis
          _DrawerItem(
            icon: Icons.verified_user_outlined,
            label: 'Contatos Confiáveis',
            color: Colors.tealAccent,
            onTap: () => _navigate(const WhitelistView()),
          ),

          // Alertas
          _DrawerItem(
            icon: Icons.campaign_outlined,
            label: 'Alertas de Golpes',
            color: Colors.orangeAccent,
            onTap: () => _navigate(const AlertsPage()),
          ),

          const Divider(indent: 16, endIndent: 16),

          // Backup & Configurações
          _DrawerItem(
            icon: Icons.cloud_sync_outlined,
            label: 'Backup & Configurações',
            color: Colors.white54,
            onTap: () => _navigate(const BackupSettingsPage()),
          ),

          // Minha Conta
          _DrawerItem(
            icon: Icons.account_circle_outlined,
            label: 'Minha Conta',
            color: Colors.white54,
            onTap: () => _navigate(const AccountPage()),
          ),

          const Divider(indent: 16, endIndent: 16),

          // AntiGolpeia Pro — abre paywall RC (desativado no beta)
          _DrawerItem(
            icon: Icons.workspace_premium_rounded,
            label: 'AntiGolpeia Pro',
            color: Colors.amber,
            onTap: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await RevenueCatUI.presentPaywall(displayCloseButton: true);
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Assinaturas em breve!')),
                );
              }
            },
          ),

          // Gerenciar Assinatura — Customer Center RC (desativado no beta)
          _DrawerItem(
            icon: Icons.subscriptions_outlined,
            label: 'Gerenciar Assinatura',
            color: Colors.white54,
            onTap: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await RevenueCatUI.presentCustomerCenter();
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Assinaturas em breve!')),
                );
              }
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // Política de Privacidade
          _DrawerItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Política de Privacidade',
            color: Colors.white38,
            onTap: () => _navigate(const PrivacyPolicyPage()),
          ),

          // Termos de Uso
          _DrawerItem(
            icon: Icons.description_outlined,
            label: 'Termos de Uso',
            color: Colors.white38,
            onTap: () => _navigate(const TermsOfUsePage()),
          ),

          // Ajuda
          _DrawerItem(
            icon: Icons.help_outline,
            label: 'Ajuda',
            color: Colors.white38,
            onTap: () => _navigate(const HelpPage()),
          ),

          // Sobre
          _DrawerItem(
            icon: Icons.info_outline,
            label: 'Sobre o AntiGolpeia',
            color: Colors.white38,
            onTap: () => _navigate(const AboutPage()),
          ),

          const Divider(indent: 16, endIndent: 16),

          // Sair
          _DrawerItem(
            icon: Icons.exit_to_app,
            label: 'Sair',
            color: Colors.redAccent,
            onTap: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
          ),

          const SizedBox(height: 8),
        ],
      ),

      // ── Body ───────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 80.0),
        child: Column(
          children: [
            // Banner de alerta
            InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AlertsPage())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'Alerta: Novo golpe do Pix no WhatsApp. Veja mais',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                    Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Confira antes de fazer qualquer PIX',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
            ),
            const SizedBox(height: 8),
            const Text(
              'Evite golpes e proteja seu dinheiro em segundos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // Indicador de atividade
            ValueListenableBuilder<AnalysisStats?>(
              valueListenable: ActivityCounter().stats,
              builder: (_, s, __) {
                final stats = s ?? AnalysisStats();
                final isActive = _isNotificationEnabled || _isSmsEnabled;
                final total = stats.smsTotal + stats.waTotal + stats.gmailTotal + stats.manualTotal;
                final suspicious = stats.smsSuspicious + stats.waSuspicious + stats.gmailSuspicious + stats.manualSuspicious;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: suspicious > 0
                          ? Colors.red.withValues(alpha: 0.5)
                          : isActive
                              ? Colors.green.withValues(alpha: 0.4)
                              : Colors.grey.shade800,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linha de status
                      Row(
                        children: [
                          if (isActive)
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (_, __) => Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withValues(alpha: _pulseAnimation.value),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isActive
                                  ? (total == 0
                                      ? 'Monitorando... aguardando mensagens'
                                      : '$total ${total == 1 ? 'análise' : 'análises'} no total')
                                  : 'Monitores desativados',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.green.shade300 : Colors.grey,
                              ),
                            ),
                          ),
                          if (suspicious > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$suspicious suspeita${suspicious > 1 ? 's' : ''}',
                                style: const TextStyle(fontSize: 11, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      // Tabela de totais por canal — sempre visível
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Colors.white10),
                      const SizedBox(height: 8),
                      _AnalysisTable(stats: stats),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Campo de texto
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.deepPurple.shade300, width: 2),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText:
                      'Cole a mensagem suspeita aqui...\n(Ex: Oi mãe, mudei de número...)',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botão analisar texto
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing
                    ? null
                    : () => _analyze('text', _textController.text.trim()),
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.deepPurple))
                    : const Icon(Icons.search, size: 28),
                label: Text(
                    _isAnalyzing ? 'Analisando...' : 'Analisar risco',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Modo Privado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Modo Privado',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Não salva no histórico',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Switch(
                  value: _isPrivate,
                  onChanged: (v) => setState(() => _isPrivate = v),
                  activeThumbColor: Colors.deepPurpleAccent,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Monitor de notificações
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _isNotificationEnabled
                        ? Colors.green.withValues(alpha: 0.5)
                        : Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _isNotificationEnabled
                            ? Icons.check_circle
                            : Icons.error_outline,
                        color: _isNotificationEnabled
                            ? Colors.green
                            : Colors.orange,
                      ),
                      if (_isNotificationEnabled) ...[
                        const SizedBox(width: 6),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (_, __) => Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green
                                  .withValues(alpha: _pulseAnimation.value),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Monitor de WhatsApp & Gmail',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!_isNotificationEnabled)
                        TextButton(
                          onPressed: () async {
                            await NotificationService().requestPermission();
                            _checkNotificationStatus();
                          },
                          child: const Text('ATIVAR'),
                        ),
                    ],
                  ),
                  if (!_isNotificationEnabled)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Ative para detectar golpes automaticamente assim que a mensagem chegar.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Monitor de SMS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _isSmsEnabled
                        ? Colors.green.withValues(alpha: 0.5)
                        : Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _isSmsEnabled
                            ? Icons.check_circle
                            : Icons.sms_failed_outlined,
                        color: _isSmsEnabled ? Colors.green : Colors.orange,
                      ),
                      if (_isSmsEnabled) ...[
                        const SizedBox(width: 6),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (_, __) => Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green
                                  .withValues(alpha: _pulseAnimation.value),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Monitor de SMS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!_isSmsEnabled)
                        TextButton(
                          onPressed: () async {
                            final granted =
                                await SmsMonitorService().requestPermission();
                            if (granted) SmsMonitorService().startListening();
                            if (mounted) {
                              setState(() => _isSmsEnabled = granted);
                            }
                          },
                          child: const Text('ATIVAR'),
                        ),
                    ],
                  ),
                  if (!_isSmsEnabled)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Detecta golpes via SMS: links falsos, centrais bancárias e SIM Swap.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Proteção de e-mail
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Proteção de E-mail (Gmail)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Escaneando e-mails recentes...')),
                      );
                      try {
                        await GmailService().scanEmails();
                      } catch (e) {
                        debugPrint('[HomePage] scanEmails erro: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Não foi possível escanear e-mails agora.')),
                          );
                        }
                      }
                    },
                    child: const Text('ESCANEAR'),
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

// ── Drawer item ──────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}

class _AnalysisTable extends StatelessWidget {
  final AnalysisStats stats;

  const _AnalysisTable({required this.stats});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54);
    const labelStyle = TextStyle(fontSize: 12, color: Colors.white70);

    Widget cell(String text, {Color color = Colors.white70}) => Expanded(
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: color)),
        );

    Widget row(IconData icon, String label, int total, int sus) {
      final ok = total - sus;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 13, color: Colors.white54),
            const SizedBox(width: 4),
            SizedBox(width: 70, child: Text(label, style: labelStyle)),
            cell('$total'),
            cell('$sus', color: sus > 0 ? Colors.orangeAccent : Colors.white38),
            cell('$ok', color: ok > 0 ? Colors.greenAccent : Colors.white38),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 87),
            Expanded(child: Text('Lidas', textAlign: TextAlign.center, style: headerStyle)),
            Expanded(child: Text('Suspeitas', textAlign: TextAlign.center, style: headerStyle)),
            Expanded(child: Text('OK', textAlign: TextAlign.center, style: headerStyle)),
          ],
        ),
        const SizedBox(height: 4),
        row(Icons.sms_outlined, 'SMS', stats.smsTotal, stats.smsSuspicious),
        row(Icons.chat_outlined, 'WhatsApp', stats.waTotal, stats.waSuspicious),
        row(Icons.email_outlined, 'Gmail', stats.gmailTotal, stats.gmailSuspicious),
      ],
    );
  }
}
