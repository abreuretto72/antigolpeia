import 'package:flutter/material.dart';
import '../features/antigolpe/constants/antigolpe_constants.dart';
import '../features/antigolpeia/services/guard_service.dart';
import '../features/antigolpeia/presentation/widgets/sync_status_footer.dart';
import '../services/api_service.dart';
import 'result_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _apiService = ApiService();
  final _guard = GuardService();

  Widget _originIcon(String? type) {
    return switch (type?.toLowerCase()) {
      'whatsapp' => const Icon(Icons.chat, color: Color(0xFF25D366), size: 18),
      'sms' => const Icon(Icons.sms, color: Colors.blueAccent, size: 18),
      'email' => const Icon(Icons.email, color: Colors.orangeAccent, size: 18),
      'phone' => const Icon(Icons.phone, color: Colors.purpleAccent, size: 18),
      _ => const Icon(Icons.edit_note, color: Colors.grey, size: 18),
    };
  }

  String _maskPhone(String? s) {
    if (s == null || s.length < 6) return s ?? '—';
    return '${s.substring(0, s.length - 4)}****';
  }

  Color _classColor(dynamic c) {
    return switch (c?.toString().toLowerCase()) {
      'golpe' => AntiGolpeConstants.colorRisk,
      'suspeito' => Colors.orange,
      _ => AntiGolpeConstants.colorSafe,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HISTÓRICO DE AMEAÇAS')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _apiService.getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AntiGolpeConstants.colorSafe),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ops! Não conseguimos carregar o histórico agora.\nVerifique sua conexão e tente novamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            );
          }

          final raw = snapshot.data;
          if (raw == null || raw.isEmpty) {
            return const Center(child: Text('Nenhuma análise encontrada.'));
          }

          // Deduplicar por conteúdo
          final seen = <String>{};
          final data = raw.where((item) {
            final key = item['content']?.toString().trim() ?? '';
            if (key.isEmpty || seen.contains(key)) return false;
            seen.add(key);
            return true;
          }).toList();

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
                  itemCount: data.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final classification = item['classification']
                        ?? item['result']?['classificacao'];
                    final sender = item['result']?['_sender']?.toString()
                        ?? item['input_type']?.toString();
                    final isTrusted = _guard.check(sender ?? '').isTrusted;
                    final inputType = item['input_type']?.toString();
                    final fraudType =
                        item['result']?['tipo_golpe']?.toString() ?? '';
                    final color = _classColor(classification);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: _originIcon(inputType),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isTrusted
                                  ? '${item['result']?['_sender'] ?? sender} (Whitelist)'
                                  : _maskPhone(sender),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            inputType?.toUpperCase() ?? '',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Badge(
                              label: isTrusted
                                  ? 'SEGURO'
                                  : switch (classification?.toString().toLowerCase()) {
                                      'golpe' => 'GOLPE CONFIRMADO',
                                      'suspeito' => 'SUSPEITO',
                                      _ => 'SEGURO',
                                    },
                              color: isTrusted
                                  ? AntiGolpeConstants.colorSafe
                                  : color,
                            ),
                            if (fraudType.isNotEmpty && fraudType != 'N/A')
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  item['content']?.toString() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.white54),
                                ),
                              ),
                          ],
                        ),
                      ),
                      isThreeLine: true,
                      onTap: () {
                        final result = Map<String, dynamic>.from(
                            item['result'] as Map? ?? {});
                        result['_content'] = item['content'];
                        result['_input_type'] = item['input_type'];
                        result['_created_at'] = item['created_at'];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ResultPage(result: result)),
                        );
                      },
                    );
                  },
                ),
              ),
              SyncStatusFooter(lastSyncAt: DateTime.now()),
            ],
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
