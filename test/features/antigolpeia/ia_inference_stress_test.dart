import 'package:flutter_test/flutter_test.dart';
import 'package:antigolpeia/features/antigolpeia/core/utils/similarity_engine.dart';
import 'package:antigolpeia/features/antigolpeia/services/ai_engine_logic.dart';

void main() {
  group('SimilarityEngine — Stress Test', () {
    const String golpeBase =
        'seu protocolo de segurança expira em 5 minutos acesse o link para regularizar';

    test('100 comparações em sequência devem completar em < 500ms', () {
      final variations = List.generate(100, (i) =>
          '$golpeBase [ID-$i] bit.ly/fraude${i + 1}');

      final sw = Stopwatch()..start();

      for (final msg in variations) {
        SimilarityEngine.compareNormalized(golpeBase, msg);
      }

      sw.stop();
      final totalMs = sw.elapsedMilliseconds;
      final avgMs = totalMs / 100;

      // ignore: avoid_print
      print('SimilarityEngine — 100 msgs: ${totalMs}ms (${avgMs.toStringAsFixed(1)}ms/msg)');

      // No SM A256E, a comparação local deve ser < 5ms por mensagem.
      expect(avgMs, lessThan(5.0), reason: 'Fuzzy matching muito lento para a UI thread');
    });

    test('Mensagens idênticas devem retornar 1.0', () {
      const msg = 'oi mãe novo número faz um pix urgente';
      expect(SimilarityEngine.compareNormalized(msg, msg), equals(1.0));
    });

    test('Mensagens completamente diferentes devem retornar < 0.3', () {
      expect(
        SimilarityEngine.compareNormalized(
          'bom dia tudo bem',
          'pix vencido clique no link',
        ),
        lessThan(0.3),
      );
    });

    test('Variação leve do golpe deve ser detectada como similar (> 0.75)', () {
      expect(
        SimilarityEngine.compareNormalized(
          'seu boleto vence hoje clique aqui para pagar',
          'seu boleto venceu ontem clique aqui para regularizar',
        ),
        greaterThan(0.75),
      );
    });
  });

  group('AiEngineLogic — Cálculo de Risco', () {
    test('VoIP + link deve elevar risco acima de 70', () {
      final risk = AiEngineLogic.calculateRisk(
        apiScore: 30,
        isVoip: true,
        hasLink: true,
        isShortCode: false,
        communityReports: 0,
      );
      expect(risk, greaterThanOrEqualTo(70));
    });

    test('Short code bancário deve reduzir risco mesmo com link', () {
      final risk = AiEngineLogic.calculateRisk(
        apiScore: 50,
        isVoip: false,
        hasLink: true,
        isShortCode: true,
        communityReports: 0,
      );
      expect(risk, lessThan(50));
    });

    test('3 reports comunitários devem sobrepor API neutra', () {
      final risk = AiEngineLogic.calculateRisk(
        apiScore: 10,
        isVoip: false,
        hasLink: false,
        isShortCode: false,
        communityReports: 3,
      );
      expect(risk, greaterThanOrEqualTo(55));
    });

    test('Risco máximo nunca ultrapassa 100', () {
      final risk = AiEngineLogic.calculateRisk(
        apiScore: 100,
        isVoip: true,
        hasLink: true,
        isShortCode: false,
        communityReports: 10,
      );
      expect(risk, equals(100.0));
    });

    test('classify() deve retornar categorias corretas', () {
      expect(AiEngineLogic.classify(80), equals('golpe'));
      expect(AiEngineLogic.classify(50), equals('suspeito'));
      expect(AiEngineLogic.classify(20), equals('seguro'));
    });
  });
}
