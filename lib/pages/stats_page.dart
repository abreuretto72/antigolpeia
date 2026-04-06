import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../features/antigolpeia/data/models/analysis_stats_model.dart';
import '../features/antigolpeia/data/models/stats_models.dart';
import '../features/antigolpeia/services/stats_intelligence_service.dart';
import '../services/activity_counter.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _service = StatsIntelligenceService();

  bool   _cloudLoading = true;
  String? _cloudError;

  List<DailyCount>       _trend7d        = [];
  Map<String, int>       _riskBuckets    = {};
  List<ScamTypeCount>    _topScamTypes   = [];
  CommunityStats?        _communityStats;
  int                    _peakHour       = -1;
  List<SmartInsight>     _insights       = [];
  List<RadarChannelData> _radarData      = [];
  List<SunburstNode>     _sunburstData   = [];
  List<BubblePoint>      _bubbleData     = [];

  @override
  void initState() {
    super.initState();
    _loadCloudData();
  }

  Future<void> _loadCloudData() async {
    setState(() { _cloudLoading = true; _cloudError = null; });
    try {
      final hive  = _service.computeHiveMetrics(
          ActivityCounter().stats.value ?? AnalysisStats());
      final cloud = await _service.loadCloudStats();
      final ins   = _service.generateInsights(
        channels:        hive.channels,
        totalAnalyzed:   hive.totalAnalyzed,
        totalSuspicious: hive.totalSuspicious,
        trend7d:         cloud.trend7d,
        topScamTypes:    cloud.topScamTypes,
        communityStats:  cloud.communityStats,
        peakHour:        cloud.peakHour,
      );
      if (!mounted) return;
      setState(() {
        _trend7d        = cloud.trend7d;
        _riskBuckets    = cloud.riskBuckets;
        _topScamTypes   = cloud.topScamTypes;
        _communityStats = cloud.communityStats;
        _peakHour       = cloud.peakHour;
        _insights       = ins;
        _radarData      = cloud.radarData;
        _sunburstData   = cloud.sunburstData;
        _bubbleData     = cloud.bubbleData;
        _cloudLoading   = false;
      });
    } catch (e) {
      if (mounted) setState(() { _cloudLoading = false; _cloudError = '$e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Inteligência AntiGolpeia',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCloudData),
        ],
      ),
      body: ValueListenableBuilder<AnalysisStats?>(
        valueListenable: ActivityCounter().stats,
        builder: (_, rawStats, __) {
          final stats = rawStats ?? AnalysisStats();
          final hive  = _service.computeHiveMetrics(stats);
          return RefreshIndicator(
            onRefresh: _loadCloudData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Escudo ──────────────────────────────────────────────
                  _ShieldHero(
                    totalAnalyzed:   hive.totalAnalyzed,
                    totalSuspicious: hive.totalSuspicious,
                  ),
                  const SizedBox(height: 14),

                  // ── Contadores rápidos ───────────────────────────────────
                  _QuickStatsRow(
                    totalAnalyzed:   hive.totalAnalyzed,
                    totalSuspicious: hive.totalSuspicious,
                    myReports:       _communityStats?.myReports ?? 0,
                  ),
                  const SizedBox(height: 24),

                  // ── Canais (pizza + barras de risco) ─────────────────────
                  if (hive.channels.isNotEmpty) ...[
                    const _SectionHeader(title: 'CANAIS DE ATAQUE', icon: Icons.cell_tower),
                    const SizedBox(height: 10),
                    _ChannelPieCard(channels: hive.channels),
                    const SizedBox(height: 24),
                  ],

                  // ── Radar ────────────────────────────────────────────────
                  const _SectionHeader(title: 'RADAR DE EXPOSIÇÃO', icon: Icons.radar),
                  const SizedBox(height: 10),
                  _cloudLoading
                      ? const _Skeleton(height: 240)
                      : _cloudError != null
                          ? _ErrorCard(onRetry: _loadCloudData)
                          : _RadarCard(channels: _radarData),
                  const SizedBox(height: 24),

                  // ── Tendência 7 dias ─────────────────────────────────────
                  const _SectionHeader(title: 'TENDÊNCIA — 7 DIAS', icon: Icons.show_chart),
                  const SizedBox(height: 10),
                  _cloudLoading
                      ? const _Skeleton(height: 190)
                      : _TrendBarChart(days: _trend7d),
                  const SizedBox(height: 24),

                  // ── Bubble Scatter ────────────────────────────────────────
                  const _SectionHeader(title: 'PADRÃO TEMPORAL DE ATAQUES', icon: Icons.bubble_chart),
                  const SizedBox(height: 10),
                  _cloudLoading
                      ? const _Skeleton(height: 230)
                      : _BubbleScatterCard(points: _bubbleData),
                  const SizedBox(height: 24),

                  // ── Distribuição de risco ────────────────────────────────
                  const _SectionHeader(title: 'DISTRIBUIÇÃO DE RISCO', icon: Icons.donut_small),
                  const SizedBox(height: 10),
                  _cloudLoading
                      ? const _Skeleton(height: 160)
                      : _RiskDonutCard(buckets: _riskBuckets),
                  const SizedBox(height: 24),

                  // ── Tipos de golpe ───────────────────────────────────────
                  const _SectionHeader(title: 'GOLPES MAIS COMUNS', icon: Icons.psychology),
                  const SizedBox(height: 10),
                  _cloudLoading
                      ? const _Skeleton(height: 180)
                      : _TopScamBarChart(types: _topScamTypes),
                  const SizedBox(height: 24),

                  // ── Sunburst ──────────────────────────────────────────────
                  const _SectionHeader(title: 'HIERARQUIA DE FRAUDES', icon: Icons.hub_outlined),
                  const SizedBox(height: 10),
                  _cloudLoading
                      ? const _Skeleton(height: 320)
                      : _SunburstCard(nodes: _sunburstData),
                  const SizedBox(height: 24),

                  // ── Escudo comunitário ───────────────────────────────────
                  const _SectionHeader(title: 'ESCUDO COMUNITÁRIO', icon: Icons.gavel_rounded),
                  const SizedBox(height: 10),
                  _cloudLoading
                      ? const _Skeleton(height: 90)
                      : _CommunityCard(stats: _communityStats, peakHour: _peakHour),
                  const SizedBox(height: 24),

                  // ── Insights ─────────────────────────────────────────────
                  if (!_cloudLoading && _insights.isNotEmpty) ...[
                    const _SectionHeader(title: 'INTELIGÊNCIA ANTIGOLPEIA', icon: Icons.lightbulb_outline),
                    const SizedBox(height: 10),
                    ..._insights.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _InsightCard(insight: i),
                    )),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white38,
                letterSpacing: 1.5)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shield hero (arc painter)
// ─────────────────────────────────────────────────────────────────────────────

class _ShieldHero extends StatelessWidget {
  final int totalAnalyzed;
  final int totalSuspicious;

  const _ShieldHero({required this.totalAnalyzed, required this.totalSuspicious});

  @override
  Widget build(BuildContext context) {
    final riskPct = totalAnalyzed == 0
        ? 0
        : (totalSuspicious / totalAnalyzed * 100).round();

    final (label, color) = switch (riskPct) {
      < 10 => ('PROTEGIDO',      Colors.green.shade400),
      < 30 => ('ATENÇÃO',        Colors.yellow.shade600),
      < 60 => ('RISCO MODERADO', Colors.orange.shade400),
      _    => ('RISCO ALTO',     Colors.red.shade400),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade900, Colors.black],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: riskPct.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: _ArcPainter(riskPct: v),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${v.round()}%',
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: color,
                              height: 1)),
                      const SizedBox(height: 2),
                      const Text('RISCO',
                          style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: color, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(
            totalAnalyzed == 0
                ? 'Nenhuma análise ainda'
                : '$totalAnalyzed mensagens · $totalSuspicious ameaças',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double riskPct;
  const _ArcPainter({required this.riskPct});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const start  = 135 * pi / 180;
    const sweep  = 270 * pi / 180;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start, sweep, false,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    final color = riskPct < 10
        ? Colors.green.shade400
        : riskPct < 30
            ? Colors.yellow.shade600
            : riskPct < 60
                ? Colors.orange.shade400
                : Colors.red.shade400;

    final filled = sweep * (riskPct / 100);
    if (filled > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start, filled, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.riskPct != riskPct;
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick stats row
// ─────────────────────────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final int totalAnalyzed;
  final int totalSuspicious;
  final int myReports;

  const _QuickStatsRow({
    required this.totalAnalyzed,
    required this.totalSuspicious,
    required this.myReports,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniStat(v: totalAnalyzed,   label: 'Analisadas', icon: Icons.search,        color: Colors.cyanAccent),
        const SizedBox(width: 8),
        _MiniStat(v: totalSuspicious, label: 'Ameaças',    icon: Icons.warning_amber, color: Colors.orangeAccent),
        const SizedBox(width: 8),
        _MiniStat(v: myReports,       label: 'Denúncias',  icon: Icons.gavel,         color: Colors.purpleAccent),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final int v;
  final String label;
  final IconData icon;
  final Color color;

  const _MiniStat({required this.v, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: v),
              duration: const Duration(milliseconds: 900),
              builder: (_, val, __) => Text('$val',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            ),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Channel pie + risk bars
// ─────────────────────────────────────────────────────────────────────────────

class _ChannelPieCard extends StatefulWidget {
  final List<ChannelMetrics> channels;
  const _ChannelPieCard({required this.channels});

  @override
  State<_ChannelPieCard> createState() => _ChannelPieCardState();
}

class _ChannelPieCardState extends State<_ChannelPieCard> {
  int _touched = -1;

  static const _colors = [
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
  ];

  @override
  Widget build(BuildContext context) {
    final channels = widget.channels;
    final total    = channels.fold(0, (s, c) => s + c.total);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          SizedBox(
            width: 130, height: 130,
            child: PieChart(PieChartData(
              pieTouchData: PieTouchData(touchCallback: (ev, resp) {
                if (!ev.isInterestedForInteractions || resp?.touchedSection == null) {
                  setState(() => _touched = -1);
                  return;
                }
                setState(() => _touched = resp!.touchedSection!.touchedSectionIndex);
              }),
              sections: channels.asMap().entries.map((e) {
                final idx = e.key; final ch = e.value;
                final isTouched = idx == _touched;
                return PieChartSectionData(
                  value: ch.total.toDouble(),
                  color: _colors[idx % _colors.length],
                  radius: isTouched ? 48 : 40,
                  title: isTouched ? '${(ch.total / total * 100).round()}%' : '',
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
              centerSpaceRadius: 28,
              sectionsSpace: 2,
            )),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: channels.asMap().entries.map((e) {
                final idx = e.key; final ch = e.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: _colors[idx % _colors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    SizedBox(width: 62, child: Text(ch.label,
                        style: const TextStyle(fontSize: 12, color: Colors.white70))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: ch.riskFraction, minHeight: 7,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation(ch.riskPct >= 30
                              ? Colors.red.shade400
                              : ch.riskPct >= 15 ? Colors.orange.shade400 : Colors.green.shade600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${ch.riskPct}%',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: ch.riskPct >= 30 ? Colors.red.shade300 : Colors.white38)),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Radar chart (fl_chart)
// ─────────────────────────────────────────────────────────────────────────────

class _RadarCard extends StatelessWidget {
  final List<RadarChannelData> channels;
  const _RadarCard({required this.channels});

  static const _axisLabels = ['Volume', 'Risco %', 'Golpes %', 'Score', 'Atividade 7d'];

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const _EmptyCard(msg: 'Mínimo 3 análises por canal para exibir o radar');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                dataSets: channels.map((c) => RadarDataSet(
                  fillColor:   c.color.withValues(alpha: 0.15),
                  borderColor: c.color,
                  borderWidth: 2,
                  entryRadius: 4,
                  dataEntries: c.values.map((v) => RadarEntry(value: v)).toList(),
                )).toList(),
                radarBackgroundColor: Colors.transparent,
                borderData:      FlBorderData(show: false),
                radarBorderData: const BorderSide(color: Colors.transparent),
                titleTextStyle:  const TextStyle(color: Colors.white54, fontSize: 10),
                titlePositionPercentageOffset: 0.2,
                getTitle: (index, _) =>
                    RadarChartTitle(text: _axisLabels[index % _axisLabels.length], angle: 0),
                tickCount:        4,
                ticksTextStyle:   const TextStyle(color: Colors.transparent),
                tickBorderData:   const BorderSide(color: Colors.white10),
                gridBorderData:   const BorderSide(color: Colors.white12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16, runSpacing: 6,
            children: channels.map((c) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 14, height: 3,
                    decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 5),
                Text(c.label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7-day trend bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _TrendBarChart extends StatelessWidget {
  final List<DailyCount> days;
  const _TrendBarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    if (days.every((d) => d.total == 0)) {
      return const _EmptyCard(msg: 'Aguardando dados para exibir tendência');
    }

    bool trendUp = false, trendDown = false;
    if (days.length >= 7) {
      double avgSus(List<DailyCount> d) {
        final t = d.fold(0, (s, e) => s + e.total);
        if (t == 0) return 0;
        return d.fold(0, (s, e) => s + e.suspicious) / t * 100;
      }
      final recent = avgSus(days.sublist(4));
      final prior  = avgSus(days.sublist(0, 4));
      trendUp   = recent > prior + 5;
      trendDown = prior  > recent + 5;
    }

    final maxY = days.map((d) => d.total).fold(0, max).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trendUp || trendDown)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (trendUp ? Colors.red : Colors.green).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: trendUp ? Colors.red.shade700 : Colors.green.shade700),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(trendUp ? Icons.trending_up : Icons.trending_down, size: 14,
                      color: trendUp ? Colors.red.shade300 : Colors.green.shade300),
                  const SizedBox(width: 4),
                  Text(trendUp ? 'Risco em alta esta semana' : 'Risco em queda esta semana',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: trendUp ? Colors.red.shade300 : Colors.green.shade300)),
                ]),
              ),
            ),
          SizedBox(
            height: 155,
            child: BarChart(BarChartData(
              maxY: maxY == 0 ? 5 : maxY * 1.3,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.grey.shade800,
                  getTooltipItem: (group, _, rod, __) {
                    final d = days[group.x];
                    return BarTooltipItem(
                      '${d.label}\n${d.total} msgs · ${d.suspicious} susp.',
                      const TextStyle(fontSize: 11, color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(days[idx].label,
                          style: const TextStyle(fontSize: 10, color: Colors.white38)),
                    );
                  },
                )),
              ),
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: days.asMap().entries.map((e) {
                final d    = e.value;
                final safe = (d.total - d.suspicious).toDouble();
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: d.total.toDouble(), width: 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    rodStackItems: [
                      BarChartRodStackItem(0,    safe,              Colors.blue.shade700),
                      BarChartRodStackItem(safe, d.total.toDouble(), Colors.red.shade600),
                    ],
                  ),
                ]);
              }).toList(),
            )),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _Legend(color: Colors.blue.shade700, label: 'Seguras'),
            const SizedBox(width: 14),
            _Legend(color: Colors.red.shade600,  label: 'Suspeitas'),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bubble Scatter — hora × risco × volume (fl_chart ScatterChart)
// ─────────────────────────────────────────────────────────────────────────────

class _BubbleScatterCard extends StatelessWidget {
  final List<BubblePoint> points;
  const _BubbleScatterCard({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _EmptyCard(msg: 'Sem dados temporais suficientes');
    }

    final maxCount = points.map((p) => p.count).reduce(max);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hora do dia  ×  Risco médio  ×  Volume de mensagens',
              style: TextStyle(fontSize: 10, color: Colors.white38)),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ScatterChart(ScatterChartData(
              scatterSpots: points.map((p) {
                final color = p.avgRisk >= 70
                    ? Colors.red.shade400
                    : p.avgRisk >= 40
                        ? Colors.orange.shade400
                        : Colors.green.shade400;
                final radius = 6 + (maxCount == 0 ? 0.0 : p.count / maxCount * 14);
                return ScatterSpot(
                  p.hour.toDouble(), p.avgRisk,
                  dotPainter: FlDotCirclePainter(
                    radius: radius,
                    color: color.withValues(alpha: 0.75),
                    strokeWidth: 1.5,
                    strokeColor: color,
                  ),
                );
              }).toList(),
              minX: 0, maxX: 23,
              minY: 0, maxY: 100,
              scatterTouchData: ScatterTouchData(
                enabled: true,
                touchTooltipData: ScatterTouchTooltipData(
                  getTooltipColor: (_) => Colors.grey.shade800,
                  getTooltipItems: (spot) => ScatterTooltipItem(
                    '${spot.x.toInt()}h  ·  Risco: ${spot.y.round()}%',
                    textStyle: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 30, interval: 25,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: const TextStyle(fontSize: 9, color: Colors.white38)),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, interval: 4,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}h',
                      style: const TextStyle(fontSize: 9, color: Colors.white38)),
                )),
              ),
              gridData: FlGridData(
                show: true, drawVerticalLine: true,
                getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10, strokeWidth: 1),
                getDrawingVerticalLine:   (_) => const FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
            )),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _Legend(color: Colors.green.shade400,  label: 'Baixo risco'),
            const SizedBox(width: 14),
            _Legend(color: Colors.orange.shade400, label: 'Médio risco'),
            const SizedBox(width: 14),
            _Legend(color: Colors.red.shade400,    label: 'Alto risco'),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Risk donut (fl_chart PieChart)
// ─────────────────────────────────────────────────────────────────────────────

class _RiskDonutCard extends StatefulWidget {
  final Map<String, int> buckets;
  const _RiskDonutCard({required this.buckets});

  @override
  State<_RiskDonutCard> createState() => _RiskDonutCardState();
}

class _RiskDonutCardState extends State<_RiskDonutCard> {
  int _touched = -1;

  static const _bucketColors = [
    Color(0xFF4CAF50), Color(0xFFFFEB3B), Color(0xFFFF9800), Color(0xFFF44336),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.buckets.entries.toList();
    final total   = entries.fold(0, (s, e) => s + e.value);
    if (total == 0) return const _EmptyCard(msg: 'Sem dados de risco no período');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          SizedBox(
            width: 130, height: 130,
            child: PieChart(PieChartData(
              pieTouchData: PieTouchData(touchCallback: (ev, resp) {
                if (!ev.isInterestedForInteractions || resp?.touchedSection == null) {
                  setState(() => _touched = -1); return;
                }
                setState(() => _touched = resp!.touchedSection!.touchedSectionIndex);
              }),
              sections: entries.asMap().entries.map((e) {
                final idx = e.key; final count = e.value.value;
                final isTouched = idx == _touched;
                return PieChartSectionData(
                  value: count.toDouble(), color: _bucketColors[idx],
                  radius: isTouched ? 50 : 42,
                  title: isTouched ? '${(count / total * 100).round()}%' : '',
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
              centerSpaceRadius: 28, sectionsSpace: 2,
            )),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: entries.asMap().entries.map((e) {
                final idx = e.key; final label = e.value.key.split('\n').first;
                final count = e.value.value;
                final pct = total == 0 ? 0 : (count / total * 100).round();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: _bucketColors[idx], shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(label,
                        style: const TextStyle(fontSize: 12, color: Colors.white70))),
                    Text('$pct%', style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700, color: _bucketColors[idx])),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top scam types ranked bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopScamBarChart extends StatelessWidget {
  final List<ScamTypeCount> types;
  const _TopScamBarChart({required this.types});

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const _EmptyCard(msg: 'Nenhum tipo de golpe identificado ainda');

    const rankColors = [
      Color(0xFFFFD700), Color(0xFFB0BEC5), Color(0xFFCD7F32),
      Colors.white38, Colors.white38,
    ];
    final maxCount = types.first.count;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: types.asMap().entries.map((e) {
          final idx  = e.key; final type = e.value;
          final frac = maxCount == 0 ? 0.0 : type.count / maxCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${idx + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: rankColors[idx])),
                const SizedBox(width: 8),
                Expanded(child: Text(type.tipo, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500))),
                Text('${type.count}×', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: rankColors[idx])),
              ]),
              const SizedBox(height: 5),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: frac),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Stack(children: [
                  Container(height: 6, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3))),
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(height: 6, decoration: BoxDecoration(
                        color: rankColors[idx] == Colors.white38 ? Colors.white38 : rankColors[idx],
                        borderRadius: BorderRadius.circular(3))),
                  ),
                ]),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sunburst — canal → classificação (CustomPainter + toque)
// ─────────────────────────────────────────────────────────────────────────────

class _SunburstCard extends StatefulWidget {
  final List<SunburstNode> nodes;
  const _SunburstCard({required this.nodes});

  @override
  State<_SunburstCard> createState() => _SunburstCardState();
}

class _SunburstCardState extends State<_SunburstCard> {
  static const double _size = 260;
  String? _selectedLabel;
  int?    _selectedValue;

  late List<_SunburstHit> _hits;

  @override
  void initState() {
    super.initState();
    _buildHits();
  }

  @override
  void didUpdateWidget(_SunburstCard old) {
    super.didUpdateWidget(old);
    if (old.nodes != widget.nodes) _buildHits();
  }

  void _buildHits() {
    _hits = [];
    final total = widget.nodes.fold(0, (s, n) => s + n.value);
    if (total == 0) return;

    const center = Offset(_size / 2, _size / 2);
    const maxR   = _size / 2 - 6;
    const r1in   = maxR * 0.28;
    const r1out  = maxR * 0.56;
    const r2out  = maxR;

    double a = -pi / 2;
    for (final node in widget.nodes) {
      final sweep = node.value / total * 2 * pi;
      _hits.add(_SunburstHit(center, r1in, r1out, a, sweep, node.label, node.value));

      if (node.children.isNotEmpty) {
        final ct  = node.children.fold(0, (s, c) => s + c.value);
        double ca = a;
        for (final child in node.children) {
          final cs = child.value / ct * sweep;
          _hits.add(_SunburstHit(center, r1out + 2, r2out, ca, cs,
              '${node.label} › ${child.label}', child.value));
          ca += cs;
        }
      }
      a += sweep;
    }
  }

  void _onTap(TapDownDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local  = box.globalToLocal(details.globalPosition);
    final offset = Offset(
      local.dx - (box.size.width  - _size) / 2,
      local.dy - (box.size.height - _size) / 2,
    );

    for (final hit in _hits.reversed) {
      if (hit.contains(offset)) {
        setState(() { _selectedLabel = hit.label; _selectedValue = hit.value; });
        return;
      }
    }
    setState(() { _selectedLabel = null; _selectedValue = null; });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return const _EmptyCard(msg: 'Dados insuficientes para o gráfico hierárquico');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        GestureDetector(
          onTapDown: _onTap,
          child: Center(
            child: SizedBox(
              width: _size, height: _size,
              child: CustomPaint(
                painter: _SunburstPainter(nodes: widget.nodes),
                child: Center(
                  child: _selectedLabel != null
                      ? Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_selectedLabel!.split(' › ').last,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                          Text('$_selectedValue',
                              style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w900)),
                        ])
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.touch_app, size: 18, color: Colors.white24),
                          const SizedBox(height: 2),
                          const Text('toque\npara ver', textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.white24, height: 1.3)),
                        ]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Legend
        Wrap(
          spacing: 12, runSpacing: 6, alignment: WrapAlignment.center,
          children: widget.nodes.map((n) => Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: n.color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(n.label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ])).toList(),
        ),
        const SizedBox(height: 6),
        const Text('Anel interno: canal  ·  Anel externo: classificação',
            style: TextStyle(fontSize: 10, color: Colors.white24)),
      ]),
    );
  }
}

class _SunburstHit {
  final Offset center;
  final double innerR, outerR, startAngle, sweepAngle;
  final String label;
  final int value;

  const _SunburstHit(this.center, this.innerR, this.outerR,
      this.startAngle, this.sweepAngle, this.label, this.value);

  bool contains(Offset p) {
    final dx = p.dx - center.dx, dy = p.dy - center.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < innerR || dist > outerR) return false;

    double norm(double a) {
      while (a < 0) { a += 2 * pi; }
      while (a >= 2 * pi) { a -= 2 * pi; }
      return a;
    }

    final angle = norm(atan2(dy, dx));
    final s     = norm(startAngle);
    final e     = norm(startAngle + sweepAngle);
    return s <= e ? (angle >= s && angle <= e) : (angle >= s || angle <= e);
  }
}

class _SunburstPainter extends CustomPainter {
  final List<SunburstNode> nodes;
  const _SunburstPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR   = min(size.width, size.height) / 2 - 6;
    final r1in   = maxR * 0.28;
    final r1out  = maxR * 0.56;
    final r2out  = maxR;

    final total = nodes.fold(0, (s, n) => s + n.value);
    if (total == 0) return;

    final sepPaint = Paint()..color = Colors.black..strokeWidth = 1.5..style = PaintingStyle.stroke;

    double a = -pi / 2;
    for (final node in nodes) {
      final sweep = node.value / total * 2 * pi;

      // Inner ring segment
      _sector(canvas, center, r1in, r1out, a, sweep, node.color);

      // Outer ring (children)
      if (node.children.isNotEmpty) {
        final ct = node.children.fold(0, (s, c) => s + c.value);
        double ca = a;
        for (final child in node.children) {
          final cs = child.value / ct * sweep;
          _sector(canvas, center, r1out + 2, r2out, ca, cs, child.color);
          // Child separator
          canvas.drawLine(
            Offset(center.dx + (r1out + 2) * cos(ca), center.dy + (r1out + 2) * sin(ca)),
            Offset(center.dx + r2out * cos(ca), center.dy + r2out * sin(ca)),
            sepPaint,
          );
          ca += cs;
        }
      }

      // Main separator
      canvas.drawLine(
        Offset(center.dx + r1in * cos(a), center.dy + r1in * sin(a)),
        Offset(center.dx + r2out * cos(a), center.dy + r2out * sin(a)),
        Paint()..color = Colors.black..strokeWidth = 2..style = PaintingStyle.stroke,
      );

      // Label on inner ring (only if large enough)
      if (sweep > 0.35) {
        _label(canvas, center, (r1in + r1out) / 2, a + sweep / 2, node.label);
      }

      a += sweep;
    }

    // Center hole
    canvas.drawCircle(center, r1in, Paint()..color = Colors.black);
  }

  void _sector(Canvas canvas, Offset c, double ri, double ro,
      double start, double sweep, Color color) {
    if (sweep < 0.004) return;
    final path = Path()
      ..moveTo(c.dx + ri * cos(start), c.dy + ri * sin(start))
      ..lineTo(c.dx + ro * cos(start), c.dy + ro * sin(start))
      ..arcTo(Rect.fromCircle(center: c, radius: ro), start, sweep, false)
      ..lineTo(c.dx + ri * cos(start + sweep), c.dy + ri * sin(start + sweep))
      ..arcTo(Rect.fromCircle(center: c, radius: ri), start + sweep, -sweep, false)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _label(Canvas canvas, Offset c, double r, double angle, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas
      ..save()
      ..translate(c.dx + r * cos(angle), c.dy + r * sin(angle));
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SunburstPainter old) => old.nodes != nodes;
}

// ─────────────────────────────────────────────────────────────────────────────
// Community card
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityCard extends StatelessWidget {
  final CommunityStats? stats;
  final int peakHour;

  const _CommunityCard({required this.stats, required this.peakHour});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Row(children: [
          _CommStat(v: s?.myReports ?? 0,           label: 'Denúncias',  color: Colors.purpleAccent),
          _CommStat(v: s?.uniqueOffenders ?? 0,     label: 'Golpistas',  color: Colors.redAccent),
          _CommStat(v: s?.avgIpqsScore.round() ?? 0, label: 'Score médio', color: Colors.orangeAccent),
        ]),
        if (peakHour >= 0) ...[
          const Divider(height: 20, color: Colors.white10),
          Row(children: [
            const Icon(Icons.access_time, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            Text('Horário de pico de ataques: ${peakHour}h',
                style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ]),
        ],
        if ((s?.last7dCount ?? 0) > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.new_releases, size: 14, color: Colors.purpleAccent),
              const SizedBox(width: 6),
              Text('${s!.last7dCount} denúncia${s.last7dCount > 1 ? 's' : ''} esta semana',
                  style: const TextStyle(fontSize: 12, color: Colors.purpleAccent, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _CommStat extends StatelessWidget {
  final int v; final String label; final Color color;
  const _CommStat({required this.v, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text('$v', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
    Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
  ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// Insight card
// ─────────────────────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final SmartInsight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: insight.color, width: 3)),
      ),
      child: Row(children: [
        Icon(insight.icon, size: 18, color: insight.color),
        const SizedBox(width: 12),
        Expanded(child: Text(insight.text,
            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility
// ─────────────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final Color color; final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
  ]);
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(14)),
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)),
  );
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      const Icon(Icons.wifi_off, size: 16, color: Colors.white38),
      const SizedBox(width: 8),
      const Text('Sem conexão', style: TextStyle(fontSize: 12, color: Colors.white38)),
      const Spacer(),
      TextButton(onPressed: onRetry,
          child: const Text('Tentar novamente', style: TextStyle(fontSize: 11))),
    ]),
  );
}

class _EmptyCard extends StatelessWidget {
  final String msg;
  const _EmptyCard({required this.msg});

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(14)),
    child: Center(child: Text(msg,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Colors.white38))),
  );
}
