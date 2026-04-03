import 'package:flutter/material.dart';
import '../constants/antigolpe_constants.dart';
import 'widgets/analysis_log_tile.dart';

class MonitorView extends StatelessWidget {
  const MonitorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoramento AntiGolpe'),
        backgroundColor: AntiGolpeConstants.colorSafe,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView( 
          // Obrigatório Protocolo Master 2026: Conteúdo nunca invade o rodapé
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.radar,
                size: 80,
                color: AntiGolpeConstants.colorSafe,
              ),
              const SizedBox(height: 24),
              Text(
                AntiGolpeConstants.keyMonitoringActive, // Chave .arb
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Monitoramento silencioso de notificações ativo. Capturando apenas metadados (números) para análise de fraude.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.6), 
                ),
              ),
              const Divider(height: 40),
              // Simulação de Logs de Auditoria
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Log de Segurança (Auditoria)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              buildAnalysisTile('+55 (11) 99999-9999', false),
              buildAnalysisTile('+55 (11) 98888-8888', true),
              buildAnalysisTile('+55 (21) 97777-7777', false),
            ],
          ),
        ),
      ),
    );
  }
}
