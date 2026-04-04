import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../features/antigolpeia/presentation/widgets/report_authority_card.dart';
import 'paywall_page.dart';

class ResultPage extends StatefulWidget {
  final Map<String, dynamic> result;

  const ResultPage({super.key, required this.result});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  static List<String> _safeStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<String>().toList();
  }

  Color _getColorFromClassificacao(String classificacao) {
    if (classificacao.toLowerCase() == 'seguro') return Colors.green;
    if (classificacao.toLowerCase() == 'suspeito') return Colors.orange;
    if (classificacao.toLowerCase() == 'golpe') return Colors.red;
    return Colors.grey;
  }

  String _getTitleFromClassificacao(String classificacao) {
    if (classificacao.toLowerCase() == 'seguro') return '🟢 PARECE SEGURO';
    if (classificacao.toLowerCase() == 'suspeito') return '🟡 MENSAGEM SUSPEITA';
    if (classificacao.toLowerCase() == 'golpe') return '⚠️ ALTO RISCO DE GOLPE';
    return 'ANÁLISE';
  }

  void _share() {
    final type = widget.result['tipo_golpe'] ?? 'golpe';
    final risk = widget.result['risco'] ?? 0;

    final text = '''
Quase caí em um golpe 😳

Detectei um $type de $risk% de risco.
Esse app analisou a mensagem antes de eu fazer um PIX.

Vale muito a pena usar. Analise antes de fazer PIX:
https://confereantes.app/download
''';
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _showDetailsBottomSheet(BuildContext context, Color color) {
    final tipoGolpe = widget.result['tipo_golpe']?.toString();
    final explicacao = widget.result['explicacao']?.toString();
    final acaoImediata = widget.result['acao_imediata']?.toString();
    final nivelUrgencia = widget.result['nivel_urgencia']?.toString();
    final sinais = _safeStringList(widget.result['sinais_alerta']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Detalhes da Análise', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 20),
              if (tipoGolpe != null && tipoGolpe != 'N/A') ...[
                _buildDetailRow(Icons.category_outlined, 'Tipo', tipoGolpe, color),
                const SizedBox(height: 16),
              ],
              if (nivelUrgencia != null) ...[
                _buildDetailRow(Icons.warning_amber_outlined, 'Urgência', nivelUrgencia.toUpperCase(), color),
                const SizedBox(height: 16),
              ],
              if (explicacao != null) ...[
                const Text('O QUE É ISSO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(explicacao, style: const TextStyle(fontSize: 16, height: 1.5)),
                const SizedBox(height: 16),
              ],
              if (sinais.isNotEmpty) ...[
                const Text('SINAIS DE ALERTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                ...sinais.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 15, height: 1.4))),
                  ]),
                )),
                const SizedBox(height: 16),
              ],
              if (acaoImediata != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AÇÃO IMEDIATA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text(acaoImediata, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final risk = (widget.result['risco'] as num?)?.toInt() ?? 0;
      if (risk > 70) _showViralLoopModal();
    });
  }

  void _showViralLoopModal() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Ajude a prevenir!'),
        content: const Text('Você pode salvar alguém da sua família ou amigos de cair nesse mesmo golpe avisando-os agora.'),
        actions: [
          TextButton(
            onPressed: () { if (ctx.mounted) Navigator.pop(ctx); },
            child: const Text('Depois'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctx.mounted) Navigator.pop(ctx);
              _share();
            },
            child: const Text('📤 Compartilhar Alerta'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final risk = widget.result['risco'] as int? ?? 0;
    final classificacao = widget.result['classificacao']?.toString() ?? 'Desconhecido';
    final color = _getColorFromClassificacao(classificacao);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatório de Risco')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              color: color.withValues(alpha:0.1),
              child: Column(
                children: [
                  Text(_getTitleFromClassificacao(classificacao), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
                  const SizedBox(height: 24),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140, height: 140,
                        child: CircularProgressIndicator(value: risk / 100, strokeWidth: 12, valueColor: AlwaysStoppedAnimation<Color>(color), backgroundColor: color.withValues(alpha:0.2)),
                      ),
                      Text('$risk%', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('risco', style: TextStyle(fontSize: 18, color: color)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.result['_content'] != null || widget.result['_input_type'] != null) ...[
                    _buildMetaSection(),
                    const SizedBox(height: 16),
                  ],
                   if (widget.result['golpe_conhecido'] == true) 
                     Container(
                       padding: const EdgeInsets.all(12),
                       margin: const EdgeInsets.only(bottom: 24),
                       decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(8)),
                       child: const Row(
                         children: [
                           Icon(Icons.warning, color: Colors.white), SizedBox(width: 8),
                           Expanded(child: Text("Esse golpe já afetou mais de 1.200 pessoas este mês.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                         ],
                       ),
                     ),
                  
                  _buildSection('O que é isso', widget.result['explicacao']),
                  const SizedBox(height: 16),
                  if (widget.result['sinais_alerta'] != null)
                     _buildListSection('Sinais de Alerta', _safeStringList(widget.result['sinais_alerta'])),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showDetailsBottomSheet(context, color),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: color.withValues(alpha:0.15), border: Border.all(color: color, width: 2), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('O QUE FAZER AGORA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(widget.result['acao_imediata'] ?? 'Bloqueie', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Toque para saber mais', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              Icon(Icons.info_outline, size: 16, color: color),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (risk > 60) ...[
                    ReportAuthorityCard(
                      rawPhone: widget.result['_sender']?.toString() ?? '',
                      rawMessage: widget.result['_content']?.toString() ?? '',
                      ipqsScore: risk,
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  const Text('Milhares de pessoas perdem dinheiro todos os dias com golpes como esse.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share, size: 28),
                    label: const Text('Compartilhar alerta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (risk > 70) ...[
                     const SizedBox(height: 16),
                     TextButton(
                       onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallPage())),
                       child: const Text('Como me proteger de todos os golpes?', style: TextStyle(decoration: TextDecoration.underline)),
                     )
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildMetaSection() {
    final inputType = widget.result['_input_type']?.toString() ?? '';
    final content = widget.result['_content']?.toString() ?? '';
    final createdAt = widget.result['_created_at']?.toString() ?? '';

    IconData icon;
    String label;
    Color iconColor;
    switch (inputType.toLowerCase()) {
      case 'whatsapp':
        icon = Icons.chat; label = 'WhatsApp'; iconColor = const Color(0xFF25D366);
      case 'sms':
        icon = Icons.sms; label = 'SMS'; iconColor = Colors.blueAccent;
      case 'email':
        icon = Icons.email; label = 'E-mail'; iconColor = Colors.orangeAccent;
      case 'phone':
        icon = Icons.phone; label = 'Telefone'; iconColor = Colors.purpleAccent;
      case 'text':
        icon = Icons.edit_note; label = 'Texto colado'; iconColor = Colors.grey;
      default:
        icon = Icons.edit_note; label = 'Texto colado'; iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 13)),
              if (widget.result['_sender'] != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '· ${widget.result['_sender']}',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              if (createdAt.length >= 16)
                Text(
                  createdAt.substring(0, 16).replaceFirst('T', ' '),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, dynamic content) {
    if (content == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(content.toString(), style: const TextStyle(fontSize: 16, height: 1.4)),
      ],
    );
  }

  Widget _buildListSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        ...items.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Expanded(child: Text(e, style: const TextStyle(fontSize: 16, height: 1.4))),
          ]),
        )),
      ],
    );
  }
}
