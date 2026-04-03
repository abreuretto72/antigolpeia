import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'result_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _apiService = ApiService();

  Widget _getOriginIcon(String? inputType) {
    switch (inputType?.toLowerCase()) {
      case 'whatsapp':
        return const Icon(Icons.chat, color: Color(0xFF25D366), size: 20);
      case 'sms':
        return const Icon(Icons.sms, color: Colors.blueAccent, size: 20);
      case 'email':
        return const Icon(Icons.email, color: Colors.orangeAccent, size: 20);
      case 'phone':
        return const Icon(Icons.phone, color: Colors.purpleAccent, size: 20);
      case 'text':
      default:
        return const Icon(Icons.edit_note, color: Colors.grey, size: 20);
    }
  }

  Color _getColorFromClassificacao(String? classificacao) {
    if (classificacao == null) return Colors.grey;
    if (classificacao.toLowerCase() == 'seguro') return Colors.green;
    if (classificacao.toLowerCase() == 'suspeito') return Colors.orange;
    if (classificacao.toLowerCase() == 'golpe') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _apiService.getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar histórico.'));
          }
          final raw = snapshot.data;
          if (raw == null || raw.isEmpty) {
            return const Center(child: Text('Nenhuma análise encontrada.'));
          }

          // Deduplica por conteúdo — mantém só o primeiro (mais recente) de cada texto
          final seen = <String>{};
          final data = raw.where((item) {
            final key = item['content']?.toString().trim() ?? '';
            if (key.isEmpty || seen.contains(key)) return false;
            seen.add(key);
            return true;
          }).toList();

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final risk = item['risk'] as int;
              final classificacao = item['classification'] ?? item['result']?['classificacao'];
              final color = _getColorFromClassificacao(classificacao);
              
              return ListTile(
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.2),
                      child: Text(
                        risk.toString(),
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -6,
                      child: _getOriginIcon(item['input_type']?.toString()),
                    ),
                  ],
                ),
                title: Text(() {
                  final tipo = item['result']?['tipo_golpe']?.toString() ?? '';
                  if (tipo.isNotEmpty && tipo != 'N/A') return tipo;
                  return classificacao?.toString().toUpperCase() ?? 'Análise';
                }()),
                subtitle: Text(
                  item['content']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  final result = Map<String, dynamic>.from(
                    item['result'] as Map? ?? {},
                  );
                  // Injeta metadados no result para exibição na ResultPage
                  result['_content'] = item['content'];
                  result['_input_type'] = item['input_type'];
                  result['_created_at'] = item['created_at'];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResultPage(result: result),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
