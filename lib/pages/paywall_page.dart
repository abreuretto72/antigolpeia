import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../features/antigolpe/constants/antigolpe_constants.dart';
import '../services/revenue_cat_service.dart';

/// Abre o Paywall nativo do RevenueCat (configurado no dashboard RC).
/// Chame [PaywallPage.present] em vez de navegar diretamente para esta página.
class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  // ── API pública ───────────────────────────────────────────────────────────

  /// Exibe o paywall. Retorna `true` se o usuário assinou.
  static Future<bool> present(BuildContext context) async {
    final result = await RevenueCatUI.presentPaywall(
      displayCloseButton: true,
    );
    return result == PaywallResult.purchased || result == PaywallResult.restored;
  }

  /// Exibe o paywall SOMENTE se o usuário não tem o entitlement.
  /// Retorna `true` se o usuário JÁ ERA pro (não precisou do paywall)
  /// ou se acabou de assinar.
  static Future<bool> presentIfNeeded(BuildContext context) async {
    final result = await RevenueCatUI.presentPaywallIfNeeded(
      RevenueCatService.entitlementId,
      displayCloseButton: true,
    );
    return result == PaywallResult.notPresented  // já era pro
        || result == PaywallResult.purchased
        || result == PaywallResult.restored;
  }

  // ── Fallback widget (usado como rota normal se necessário) ─────────────

  @override
  Widget build(BuildContext context) {
    return const _FallbackPaywallScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tela de fallback — exibida quando o Paywall RC não carrega
// (sem internet, offering não configurado no dashboard, etc.)
// ─────────────────────────────────────────────────────────────────────────────

class _FallbackPaywallScreen extends StatefulWidget {
  const _FallbackPaywallScreen();

  @override
  State<_FallbackPaywallScreen> createState() => _FallbackPaywallScreenState();
}

class _FallbackPaywallScreenState extends State<_FallbackPaywallScreen> {
  bool _restoring = false;

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final info = await RevenueCatService.instance.restorePurchases();
    if (!mounted) return;
    setState(() => _restoring = false);

    final isPro = info?.entitlements.active
            .containsKey(RevenueCatService.entitlementId) ??
        false;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isPro
          ? 'Assinatura restaurada com sucesso!'
          : 'Nenhuma assinatura ativa encontrada.'),
      backgroundColor:
          isPro ? AntiGolpeConstants.colorSafe : AntiGolpeConstants.colorRisk,
      behavior: SnackBarBehavior.floating,
    ));

    if (isPro && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AntiGolpeia Pro'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.shield_rounded, size: 80,
                    color: AntiGolpeConstants.colorSafe),
              ),
              const SizedBox(height: 32),
              const Text(
                'Proteja seu dinheiro todos os dias',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2),
              ),
              const SizedBox(height: 16),
              const Text(
                'Análises ilimitadas, proteção automática em tempo real '
                'e base comunitária atualizada.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ...[
                'Análises ilimitadas 24h',

                'Monitor automático de WhatsApp e SMS',
                'Proteção contra novos golpes em tempo real',
                'Base comunitária AntiGolpeia',
                'Backup seguro na nuvem',
              ].map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      const Icon(Icons.check_circle,
                          color: AntiGolpeConstants.colorSafe, size: 20),
                      const SizedBox(width: 10),
                      Text(f, style: const TextStyle(fontSize: 16)),
                    ]),
                  )),
              const Spacer(),
              const Center(
                child: Text(
                  'Carregando planos... Verifique sua conexão.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _restoring ? null : _restore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _restoring
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Restaurar compra anterior'),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Cancele a qualquer momento. Sem fidelidade.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
