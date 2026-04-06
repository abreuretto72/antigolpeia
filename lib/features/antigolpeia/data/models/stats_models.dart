import 'package:flutter/material.dart';

// ── Canais ───────────────────────────────────────────────────────────────────

class ChannelMetrics {
  final String label;
  final IconData icon;
  final int total;
  final int suspicious;

  const ChannelMetrics({
    required this.label,
    required this.icon,
    required this.total,
    required this.suspicious,
  });

  int get safe => total - suspicious;
  double get riskFraction => total == 0 ? 0.0 : suspicious / total;
  int get riskPct => (riskFraction * 100).round();
}

// ── Tendência ─────────────────────────────────────────────────────────────────

class DailyCount {
  final String label; // 'Seg', 'Ter', ...
  final int total;
  final int suspicious;

  const DailyCount({
    required this.label,
    required this.total,
    required this.suspicious,
  });
}

// ── Tipos de golpe ────────────────────────────────────────────────────────────

class ScamTypeCount {
  final String tipo;
  final int count;

  const ScamTypeCount({required this.tipo, required this.count});
}

// ── Denúncias ─────────────────────────────────────────────────────────────────

class CommunityStats {
  final int myReports;
  final int uniqueOffenders;
  final double avgIpqsScore;
  final int last7dCount;

  const CommunityStats({
    required this.myReports,
    required this.uniqueOffenders,
    required this.avgIpqsScore,
    required this.last7dCount,
  });
}

// ── Insights ──────────────────────────────────────────────────────────────────

enum InsightSeverity { info, warning, critical }

class SmartInsight {
  final InsightSeverity severity;
  final IconData icon;
  final String text;

  const SmartInsight({
    required this.severity,
    required this.icon,
    required this.text,
  });

  Color get color => switch (severity) {
        InsightSeverity.critical => Colors.red.shade400,
        InsightSeverity.warning  => Colors.orange.shade400,
        InsightSeverity.info     => Colors.cyan.shade400,
      };
}

// ── Radar (gráfico aranha) ────────────────────────────────────────────────────
// 5 eixos por canal: Volume · Risco% · Golpes% · Score médio · Atividade 7d

class RadarChannelData {
  final String label;
  final Color color;
  final List<double> values; // todos normalizados 0–100

  const RadarChannelData({
    required this.label,
    required this.color,
    required this.values,
  });
}

// ── Sunburst (explosão solar) ─────────────────────────────────────────────────
// Anel interno: canal · Anel externo: classificação dentro do canal

class SunburstNode {
  final String label;
  final int value;
  final Color color;
  final List<SunburstNode> children;

  const SunburstNode({
    required this.label,
    required this.value,
    required this.color,
    this.children = const [],
  });
}

// ── Bubble Scatter ────────────────────────────────────────────────────────────
// X = hora · Y = risco médio · tamanho = volume

class BubblePoint {
  final int hour;
  final double avgRisk;
  final int count;

  const BubblePoint({
    required this.hour,
    required this.avgRisk,
    required this.count,
  });
}
