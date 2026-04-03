import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import '../../../main.dart';
import '../../../pages/result_page.dart';
import 'twilio_service.dart';

class WhatsAppMonitorService {
  static const String _whatsappPkg = 'com.whatsapp';
  final TwilioService _twilioService = TwilioService();

  void init() {
    NotificationListenerService.notificationsStream
        .listen((ServiceNotificationEvent event) {
      if (event.packageName == _whatsappPkg) {
        final String? phone = _extractPhone(event.title ?? '');
        if (phone != null) {
          _processSecurityAnalysis(phone);
        }
      }
    });
  }

  Future<void> _processSecurityAnalysis(String phone) async {
    try {
      final result = await _twilioService.checkSimSwap(phone);

      if (result['success'] == true) {
        if (result['isSwapped'] == true) {
          _triggerFraudAlert(phone, result['last_swap'] ?? 'recentemente');
        } else {
          debugPrint('[WhatsApp Monitor] Número $phone verificado e seguro.');
        }
      } else {
        debugPrint('[WhatsApp Monitor] Erro na API Twilio: ${result['error']}');
      }
    } catch (e) {
      debugPrint('[WhatsApp Monitor] Erro: $e');
    }
  }

  String? _extractPhone(String text) {
    final regex = RegExp(r'\+?\d{10,15}');
    return regex.firstMatch(text)?.group(0);
  }

  void _triggerFraudAlert(String phone, String date) {
    debugPrint('[WhatsApp Monitor] ALERTA DE FRAUDE: $phone trocou de chip em $date');

    final context = navigatorKey.currentContext;
    if (context == null) return;

    final fraudResult = <String, dynamic>{
      'risco': 95,
      'classificacao': 'golpe',
      'tipo_golpe': 'Troca de Chip (SIM Swap)',
      'explicacao':
          'O número $phone trocou de chip $date. Golpistas fazem isso para interceptar '
          'códigos de verificação bancária e assumir contas. NÃO faça nenhum PIX '
          'para este contato antes de confirmar a identidade por outro canal.',
      'sinais_alerta': [
        'Chip trocado $date',
        'Possível interceptação de SMS e tokens bancários',
        'Risco alto de sequestro de conta bancária',
      ],
      'acao_imediata':
          'Ligue para seu banco agora e bloqueie transferências. Contate a pessoa por videochamada para confirmar identidade.',
      'nivel_urgencia': 'extremo',
      'confianca': 90,
      'golpe_conhecido': true,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 ALERTA: $phone trocou de chip $date'),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'VER DETALHES',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ResultPage(result: fraudResult),
              ),
            );
          },
        ),
      ),
    );
  }
}
