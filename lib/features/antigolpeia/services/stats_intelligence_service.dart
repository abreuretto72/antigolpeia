import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/stats_models.dart';
import '../data/models/analysis_stats_model.dart';

/// Carrega e computa todas as métricas da página de Estatísticas.
class StatsIntelligenceService {
  static const _dayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  static const _channelColors = {
    'SMS':      Color(0xFF00BCD4),
    'WhatsApp': Color(0xFF4CAF50),
    'Gmail':    Color(0xFFF44336),
    'Manual':   Color(0xFF9C27B0),
  };

  // ── Hive (instantâneo) ────────────────────────────────────────────────────

  ({
    List<ChannelMetrics> channels,
    int totalAnalyzed,
    int totalSuspicious,
  })
  computeHiveMetrics(AnalysisStats s) {
    final channels = <ChannelMetrics>[
      ChannelMetrics(label: 'SMS',      icon: Icons.sms_outlined,   total: s.smsTotal,    suspicious: s.smsSuspicious),
      ChannelMetrics(label: 'WhatsApp', icon: Icons.chat_outlined,  total: s.waTotal,     suspicious: s.waSuspicious),
      ChannelMetrics(label: 'Gmail',    icon: Icons.email_outlined, total: s.gmailTotal,  suspicious: s.gmailSuspicious),
      ChannelMetrics(label: 'Manual',   icon: Icons.search,         total: s.manualTotal, suspicious: s.manualSuspicious),
    ].where((c) => c.total > 0).toList();

    return (
      channels: channels,
      totalAnalyzed:   s.smsTotal  + s.waTotal  + s.gmailTotal  + s.manualTotal,
      totalSuspicious: s.smsSuspicious + s.waSuspicious + s.gmailSuspicious + s.manualSuspicious,
    );
  }

  // ── Supabase (assíncrono) ─────────────────────────────────────────────────

  Future<({
    List<DailyCount>       trend7d,
    Map<String, int>       riskBuckets,
    List<ScamTypeCount>    topScamTypes,
    CommunityStats         communityStats,
    int                    peakHour,
    List<RadarChannelData> radarData,
    List<SunburstNode>     sunburstData,
    List<BubblePoint>      bubbleData,
  })>
  loadCloudStats() async {
    final client = Supabase.instance.client;

    final results = await Future.wait([
      client
          .from('analyses')
          .select('created_at, classification, input_type, risk, result')
          .gte('created_at',
              DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .order('created_at', ascending: true)
          .limit(500),
      client
          .from('authority_reports')
          .select('offender_phone, ipqs_score, created_at'),
    ]);

    final analyses = List<Map<String, dynamic>>.from(results[0] as List);
    final reports  = List<Map<String, dynamic>>.from(results[1] as List);

    return (
      trend7d:        _computeTrend7d(analyses),
      riskBuckets:    _computeRiskBuckets(analyses),
      topScamTypes:   _computeTopScamTypes(analyses),
      communityStats: _computeCommunityStats(reports),
      peakHour:       _computePeakHour(analyses),
      radarData:      computeRadarData(analyses),
      sunburstData:   computeSunburst(analyses),
      bubbleData:     computeBubbles(analyses),
    );
  }

  // ── Processamentos: gráficos base ─────────────────────────────────────────

  List<DailyCount> _computeTrend7d(List<Map<String, dynamic>> analyses) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day      = now.subtract(Duration(days: 6 - i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd   = dayStart.add(const Duration(days: 1));

      final slice = analyses.where((r) {
        final dt = DateTime.tryParse(r['created_at'] as String? ?? '');
        return dt != null && !dt.isBefore(dayStart) && dt.isBefore(dayEnd);
      });

      return DailyCount(
        label:      _dayLabels[day.weekday % 7],
        total:      slice.length,
        suspicious: slice.where((r) => (r['risk'] as num? ?? 0).toInt() >= 50).length,
      );
    });
  }

  Map<String, int> _computeRiskBuckets(List<Map<String, dynamic>> analyses) {
    final b = {'Seguro\n0–25': 0, 'Baixo\n26–50': 0, 'Médio\n51–75': 0, 'Alto\n76–100': 0};
    for (final r in analyses) {
      final risk = (r['risk'] as num? ?? 0).toInt();
      if (risk <= 25)      { b['Seguro\n0–25']  = b['Seguro\n0–25']!  + 1; }
      else if (risk <= 50) { b['Baixo\n26–50']  = b['Baixo\n26–50']!  + 1; }
      else if (risk <= 75) { b['Médio\n51–75']  = b['Médio\n51–75']!  + 1; }
      else                 { b['Alto\n76–100']  = b['Alto\n76–100']!  + 1; }
    }
    return b;
  }

  List<ScamTypeCount> _computeTopScamTypes(List<Map<String, dynamic>> analyses) {
    final counts = <String, int>{};
    for (final r in analyses) {
      try {
        final result = r['result'];
        final tipo = (result is Map ? result['tipo_golpe'] : null) as String?;
        if (tipo == null || tipo.trim().isEmpty || tipo == 'N/A') continue;
        counts[tipo.trim()] = (counts[tipo.trim()] ?? 0) + 1;
      } catch (_) {}
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => ScamTypeCount(tipo: e.key, count: e.value)).toList();
  }

  CommunityStats _computeCommunityStats(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) {
      return const CommunityStats(myReports: 0, uniqueOffenders: 0, avgIpqsScore: 0, last7dCount: 0);
    }
    final phones = <String>{};
    var totalScore = 0;
    var last7d = 0;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));

    for (final r in reports) {
      final phone = r['offender_phone'] as String? ?? '';
      if (phone.isNotEmpty) phones.add(phone);
      totalScore += (r['ipqs_score'] as num? ?? 0).toInt();
      final dt = DateTime.tryParse(r['created_at'] as String? ?? '');
      if (dt != null && dt.isAfter(cutoff)) last7d++;
    }

    return CommunityStats(
      myReports:       reports.length,
      uniqueOffenders: phones.length,
      avgIpqsScore:    totalScore / reports.length,
      last7dCount:     last7d,
    );
  }

  int _computePeakHour(List<Map<String, dynamic>> analyses) {
    final hours = <int, int>{};
    for (final r in analyses) {
      if ((r['risk'] as num? ?? 0).toInt() < 50) continue;
      final dt = DateTime.tryParse(r['created_at'] as String? ?? '');
      if (dt == null) continue;
      hours[dt.hour] = (hours[dt.hour] ?? 0) + 1;
    }
    if (hours.isEmpty) return -1;
    return hours.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // ── Radar (gráfico aranha) ─────────────────────────────────────────────────

  List<RadarChannelData> computeRadarData(List<Map<String, dynamic>> analyses) {
    final byChannel = <String, List<Map<String, dynamic>>>{};
    for (final r in analyses) {
      final key = _channelKey(r['input_type'] as String? ?? '');
      byChannel.putIfAbsent(key, () => []).add(r);
    }

    // Mínimo de 3 análises por canal para aparecer no radar
    final qualified = byChannel.entries.where((e) => e.value.length >= 3).toList();
    if (qualified.isEmpty) return [];

    final now = DateTime.now();
    final week7ago = now.subtract(const Duration(days: 7));

    final rawMetrics = qualified.map((e) {
      final rows = e.value;
      final total      = rows.length;
      final suspicious = rows.where((r) => (r['risk'] as num? ?? 0).toInt() >= 50).length;
      final golpes     = rows.where((r) => r['classification'] == 'golpe').length;
      final avgRisk    = rows.fold(0.0, (s, r) => s + (r['risk'] as num? ?? 0).toDouble()) / total;
      final recent     = rows.where((r) {
        final dt = DateTime.tryParse(r['created_at'] as String? ?? '');
        return dt != null && dt.isAfter(week7ago);
      }).length;
      return (label: e.key, total: total, suspicious: suspicious, golpes: golpes, avgRisk: avgRisk, recent: recent);
    }).toList();

    final maxTotal  = rawMetrics.map((r) => r.total).reduce(max);
    final maxRecent = rawMetrics.map((r) => r.recent).reduce(max);

    return rawMetrics.map((r) => RadarChannelData(
      label:  r.label,
      color:  _channelColors[r.label] ?? Colors.white,
      values: [
        r.total  / maxTotal  * 100,                                 // Volume
        r.total == 0 ? 0 : r.suspicious / r.total * 100,           // Risco %
        r.total == 0 ? 0 : r.golpes     / r.total * 100,           // Golpes %
        r.avgRisk,                                                  // Score médio
        maxRecent == 0 ? 0 : r.recent  / maxRecent * 100,          // Atividade 7d
      ],
    )).toList();
  }

  // ── Sunburst (explosão solar) ──────────────────────────────────────────────

  List<SunburstNode> computeSunburst(List<Map<String, dynamic>> analyses) {
    // canal → classificação → count
    final tree = <String, Map<String, int>>{};
    for (final r in analyses) {
      final ch = _channelKey(r['input_type'] as String? ?? '');
      final cl = r['classification'] as String? ?? 'seguro';
      tree.putIfAbsent(ch, () => {})[cl] = (tree[ch]![cl] ?? 0) + 1;
    }
    if (tree.isEmpty) return [];

    const classOpacity = {'seguro': 0.35, 'suspeito': 0.65, 'golpe': 1.0};

    return tree.entries.map((ch) {
      final base     = _channelColors[ch.key] ?? Colors.grey;
      final total    = ch.value.values.fold(0, (s, v) => s + v);
      final children = ch.value.entries.map((cl) {
        final opacity = classOpacity[cl.key] ?? 0.5;
        return SunburstNode(
          label: cl.key,
          value: cl.value,
          color: base.withValues(alpha: opacity),
        );
      }).toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return SunburstNode(
        label:    ch.key,
        value:    total,
        color:    base,
        children: children,
      );
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  // ── Bubble Scatter ────────────────────────────────────────────────────────

  List<BubblePoint> computeBubbles(List<Map<String, dynamic>> analyses) {
    final hourData = <int, ({int count, double riskSum})>{};
    for (final r in analyses) {
      final dt   = DateTime.tryParse(r['created_at'] as String? ?? '');
      if (dt == null) continue;
      final risk = (r['risk'] as num? ?? 0).toDouble();
      final cur  = hourData[dt.hour] ?? (count: 0, riskSum: 0.0);
      hourData[dt.hour] = (count: cur.count + 1, riskSum: cur.riskSum + risk);
    }
    return hourData.entries
        .where((e) => e.value.count > 0)
        .map((e) => BubblePoint(
              hour:    e.key,
              avgRisk: e.value.riskSum / e.value.count,
              count:   e.value.count,
            ))
        .toList()
      ..sort((a, b) => a.hour.compareTo(b.hour));
  }

  // ── Insights ──────────────────────────────────────────────────────────────

  List<SmartInsight> generateInsights({
    required List<ChannelMetrics> channels,
    required int totalAnalyzed,
    required int totalSuspicious,
    required List<DailyCount>    trend7d,
    required List<ScamTypeCount> topScamTypes,
    required CommunityStats      communityStats,
    required int peakHour,
  }) {
    final all = <SmartInsight>[];
    final riskPct = totalAnalyzed == 0
        ? 0
        : (totalSuspicious / totalAnalyzed * 100).round();

    if (totalAnalyzed == 0) {
      all.add(const SmartInsight(
        severity: InsightSeverity.info,
        icon: Icons.radar,
        text: 'Nenhuma análise ainda. Ative os monitores ou cole uma mensagem suspeita na tela inicial.',
      ));
      return all;
    }

    if (riskPct >= 30) {
      all.add(SmartInsight(
        severity: InsightSeverity.critical,
        icon: Icons.warning_amber_rounded,
        text: 'Atenção: $riskPct% das mensagens analisadas são suspeitas. Seu nível de exposição está alto.',
      ));
    }

    if (totalAnalyzed >= 20 && riskPct < 5) {
      all.add(SmartInsight(
        severity: InsightSeverity.info,
        icon: Icons.verified_user,
        text: 'Excelente! Apenas $riskPct% de risco. Sua rede de contatos parece segura.',
      ));
    }

    final qualified = channels.where((c) => c.total >= 5).toList()
      ..sort((a, b) => b.riskFraction.compareTo(a.riskFraction));
    if (qualified.isNotEmpty && qualified.first.riskPct >= 25) {
      final ch = qualified.first;
      all.add(SmartInsight(
        severity: InsightSeverity.warning,
        icon: Icons.cell_tower,
        text: '${ch.label} é seu canal mais vulnerável: ${ch.riskPct}% das mensagens são suspeitas.',
      ));
    }

    if (trend7d.length >= 7) {
      double avgSus(List<DailyCount> d) {
        final t = d.fold(0, (s, e) => s + e.total);
        if (t == 0) return 0;
        return d.fold(0, (s, e) => s + e.suspicious) / t * 100;
      }
      final recent = avgSus(trend7d.sublist(4));
      final prior  = avgSus(trend7d.sublist(0, 4));
      final delta  = (recent - prior).abs().round();
      if (recent > prior + 5) {
        all.add(SmartInsight(
          severity: InsightSeverity.critical,
          icon: Icons.trending_up,
          text: 'Tendência de alta: risco aumentou ${delta}pp nos últimos 3 dias vs semana anterior.',
        ));
      } else if (prior > recent + 5) {
        all.add(SmartInsight(
          severity: InsightSeverity.info,
          icon: Icons.trending_down,
          text: 'Boa notícia: risco caiu ${delta}pp nos últimos dias. Continue protegido.',
        ));
      }
    }

    if (peakHour >= 0) {
      all.add(SmartInsight(
        severity: InsightSeverity.warning,
        icon: Icons.access_time,
        text: 'Golpistas preferem agir às ${peakHour}h. Fique mais atento nesse horário.',
      ));
    }

    if (topScamTypes.isNotEmpty) {
      final top = topScamTypes.first;
      all.add(SmartInsight(
        severity: InsightSeverity.warning,
        icon: Icons.psychology,
        text: 'Golpe mais comum: "${top.tipo}" — já foram ${top.count} tentativas detectadas.',
      ));
    }

    if (communityStats.myReports >= 3) {
      all.add(SmartInsight(
        severity: InsightSeverity.info,
        icon: Icons.gavel,
        text: 'Você já denunciou ${communityStats.myReports} golpistas. Sua contribuição protege outros usuários.',
      ));
    }

    if (communityStats.uniqueOffenders >= 5) {
      all.add(SmartInsight(
        severity: InsightSeverity.warning,
        icon: Icons.groups,
        text: '${communityStats.uniqueOffenders} números diferentes já tentaram aplicar golpes em você.',
      ));
    }

    return all.take(5).toList();
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String _channelKey(String inputType) => switch (inputType) {
        'whatsapp' => 'WhatsApp',
        'email'    => 'Gmail',
        'sms'      => 'SMS',
        _          => 'Manual',
      };
}
