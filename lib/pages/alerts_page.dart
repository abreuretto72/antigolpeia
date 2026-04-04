import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas Ativos')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _apiService.getAlerts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar os alertas.\nTente novamente mais tarde.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            );
          }
          final data = snapshot.data;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
               const Text('Golpes circulando no Whatsapp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
               const SizedBox(height: 16),
               if (data != null && data.isNotEmpty)
                 ...data.map((alert) => _buildAlertCard(alert['title'], alert['description'], alert['risk_level']))
               else ...[
                 _buildAlertCard(
                   '⚠️ Golpe do PIX Agendado Falso',
                   'Criminosos enviam prints falsos de PIX agendado e exigem a devolução do dinheiro imediatamente.',
                   'Extremo'
                 ),
                 _buildAlertCard(
                   '💣 Falsa Central de Segurança',
                   'Ligação informando compra aprovada pedindo para baixar aplicativo remoto para cancelamento.',
                   'Alto'
                 )
               ]
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(String title, String desc, String risk) {
     return Container(
       margin: const EdgeInsets.only(bottom: 16),
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent)),
           const SizedBox(height: 8),
           Text(desc, style: const TextStyle(fontSize: 14)),
           const SizedBox(height: 12),
           Row(
             children: [
                const Icon(Icons.trending_up, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text('Risco $risk - Em Acensão', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
             ],
           )
         ],
       ),
     );
  }
}
