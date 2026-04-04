/// Motor de cruzamento de dados para cálculo de risco final.
/// Combina score das APIs, metadados de rede e reputação comunitária.
class AiEngineLogic {
  // Pesos de cada camada — ajustáveis sem alterar lógica de callers.
  static const double _voipLinkPenalty = 40.0;
  static const double _communityReportWeight = 15.0;
  static const double _shortCodeDiscount = 30.0;

  /// Calcula o risco final (0–100) cruzando as três camadas de dados.
  ///
  /// - [apiScore]          Média dos scores das APIs externas (Twilio/IPQS).
  /// - [isVoip]            Número VoIP detectado pela AbstractAPI.
  /// - [hasLink]           Mensagem contém URL suspeita.
  /// - [isShortCode]       Remetente é short code bancário homologado.
  /// - [communityReports]  Quantidade de reports comunitários confirmados.
  static double calculateRisk({
    required double apiScore,
    required bool isVoip,
    required bool hasLink,
    required bool isShortCode,
    required int communityReports,
  }) {
    double risk = apiScore;

    // Camada 1 — Dissonância de metadados:
    // VoIP + link = fraude de identidade clássica (+40%).
    if (isVoip && hasLink) risk += _voipLinkPenalty;

    // Camada 2 — Short code bancário homologado:
    // Reduz risco mesmo com link (bancos usam domínios próprios).
    if (isShortCode) risk -= _shortCodeDiscount;

    // Camada 3 — Reputação comunitária:
    // Cada report adiciona peso — a IA sobrepõe as APIs comerciais.
    risk += communityReports * _communityReportWeight;

    return risk.clamp(0.0, 100.0);
  }

  /// Classifica o risco em string canônica usada pelo restante do app.
  static String classify(double risk) {
    if (risk >= 70) return 'golpe';
    if (risk >= 40) return 'suspeito';
    return 'seguro';
  }

  /// Motivos de risco para exibição no [RiskDetailsSheet].
  static List<RiskReason> buildReasons({
    required bool isVoip,
    required bool hasLink,
    required bool isShortCode,
    required int communityReports,
    required double localSimilarity,
  }) {
    return [
      RiskReason(
        key: 'antigolpeia_reason_voip',
        icon: 'router',
        active: isVoip && !isShortCode,
      ),
      RiskReason(
        key: 'antigolpeia_reason_link',
        icon: 'link',
        active: hasLink,
      ),
      RiskReason(
        key: 'antigolpeia_reason_community',
        icon: 'group',
        active: communityReports > 0,
      ),
      RiskReason(
        key: 'antigolpeia_reason_pattern',
        icon: 'pattern',
        active: localSimilarity >= 0.85,
      ),
    ];
  }
}

/// Motivo de risco individual para renderização no UI.
class RiskReason {
  final String key;   // Chave .arb
  final String icon;  // Nome semântico do ícone
  final bool active;  // Se o motivo se aplica a esta análise

  const RiskReason({
    required this.key,
    required this.icon,
    required this.active,
  });
}
