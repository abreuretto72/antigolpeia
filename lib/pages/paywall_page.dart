import 'package:flutter/material.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Icon(Icons.shield_rounded, size: 80, color: Colors.blueAccent)),
              const SizedBox(height: 32),
              const Text(
                '🔒 Proteja seu dinheiro todos os dias',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
              ),
              const SizedBox(height: 16),
              const Text(
                'Você atingiu o limite ou identificamos um alto risco. Continue verificando o que quiser sem perder tempo nem dinheiro.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _buildFeature('✔ Análises ilimitadas 24h'),
              _buildFeature('✔ Proteção contra novos golpes'),
              _buildFeature('✔ Segurança para sua família'),
              const Spacer(),
              Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueAccent)),
                 child: const Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text('Plano Mensal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     Text('R\$ 19,90/mês', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                   ],
                 )
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                     // TODO: Implement RevenueCat / Stripe Integration here.
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Integração de pagamento pendente.')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('🚀 Ativar proteção agora'),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Cancele a qualquer momento. Suporte 24/7.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
