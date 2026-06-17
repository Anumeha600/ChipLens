import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'fsm_screen.dart';
import 'explain_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum _StepStatus { pending, running, done }

class _AnalysisStep {
  final String label;
  _StepStatus status = _StepStatus.pending;
  _AnalysisStep(this.label);
}

class _ModuleStats {
  final int wires;
  final int registers;
  final int alwaysBlocks;
  final int parameters;
  final int assigns;

  const _ModuleStats({
    required this.wires,
    required this.registers,
    required this.alwaysBlocks,
    required this.parameters,
    required this.assigns,
  });

  static _ModuleStats parse(String code) {
    final clean = code
        .replaceAll(RegExp(r'//.*$', multiLine: true), '')
        .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    int count(String keyword) =>
        RegExp('\\b$keyword\\b').allMatches(clean).length;
    return _ModuleStats(
      wires:        count('wire'),
      registers:    count('reg'),
      alwaysBlocks: count('always'),
      parameters:   count('parameter') + count('localparam'),
      assigns:      count('assign'),
    );
  }
}

enum _Severity { critical, warning, info }

_Severity _warningToSeverity(String type) => switch (type) {
  'inferred_latch' || 'multiple_drivers' => _Severity.critical,
  'missing_default' || 'blocking_assignment' => _Severity.warning,
  _ => _Severity.info,
};

// ─── Screen ───────────────────────────────────────────────────────────────────

class InspectorScreen extends StatefulWidget {
  final String code;
  const InspectorScreen({super.key, required this.code});

  @override
  State<InspectorScreen> createState() => _InspectorScreenState();
}

class _InspectorScreenState extends State<InspectorScreen> {
  bool _loading = true;
  bool _isConnectionError = false;
  String? _error;
  Map<String, dynamic>? _result;

  final List<_AnalysisStep> _steps = [
    _AnalysisStep('Parsing RTL'),
    _AnalysisStep('Running Static Analysis'),
    _AnalysisStep('Extracting FSM Data'),
    _AnalysisStep('Computing Quality Score'),
  ];

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
      _isConnectionError = false;
      for (final s in _steps) { s.status = _StepStatus.pending; }
    });

    final apiCall = RtlApiService.analyze(widget.code);
    _animateSteps();

    try {
      final data = await apiCall;
      if (!mounted) return;
      setState(() {
        for (final s in _steps) { s.status = _StepStatus.done; }
      });
      await Future.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      setState(() { _result = data; _loading = false; });
    } on ChipLensApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.userMessage;
        _isConnectionError = e.isConnectionError;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _animateSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() => _steps[i].status = _StepStatus.running);
      await Future.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;
      setState(() => _steps[i].status = _StepStatus.done);
    }
  }

  // ── Accessors ─────────────────────────────────────────────────────────────────

  int get _total =>
      (_result!['total'] as num?)?.toInt() ??
      (_result!['score'] as num?)?.toInt() ?? 0;

  String get _grade => _result!['grade'] as String? ?? '?';

  Map<String, dynamic>? get _categories =>
      _result!['categories'] as Map<String, dynamic>?;

  List<Map<String, dynamic>> get _warnings =>
      List<Map<String, dynamic>>.from(_result?['warnings'] ?? []);

  Color _gradeColor(int score) {
    if (score >= 90) return AppColors.successDark;
    if (score >= 75) return AppColors.success;
    if (score >= 60) return AppColors.warningDark;
    if (score >= 40) return AppColors.orange;
    return AppColors.errorDark;
  }

  String _gradeLabel(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    if (score >= 40) return 'Poor';
    return 'Critical';
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('RTL Inspector'),
        actions: [
          if (!_loading && _result != null)
            IconButton(
              icon: const Icon(Icons.smart_toy_outlined),
              tooltip: 'AI Explain',
              onPressed: () => Navigator.push(
                context,
                slideRoute(ExplainScreen(
                  code: widget.code,
                  warnings: _warnings,
                  scoreData: _categories != null
                      ? {'total': _total, 'grade': _grade, 'categories': _categories}
                      : null,
                )),
              ),
            ),
        ],
      ),
      body: _loading
          ? _buildLoadingView()
          : _error != null
              ? _buildErrorView()
              : _buildResults(),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────────

  Widget _buildLoadingView() {
    final isDark = context.isDark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          // Icon + title
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.glow(AppColors.primary),
                  ),
                  child: const Icon(Icons.memory, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'Analyzing Design',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Running RTL analysis engine…',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Step list
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border),
              boxShadow: context.cardShadow,
            ),
            child: Column(
              children: _steps.map(_buildStep).toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Skeleton preview cards
          _buildSkeletonCard(isDark),
          const SizedBox(height: 12),
          _buildSkeletonCard(isDark, compact: true),
          const SizedBox(height: 12),
          _buildSkeletonCard(isDark, compact: true),
        ],
      ),
    );
  }

  Widget _buildStep(_AnalysisStep step) {
    final isDone    = step.status == _StepStatus.done;
    final isRunning = step.status == _StepStatus.running;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: isDone
                ? Container(
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  )
                : isRunning
                    ? const SizedBox(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: context.border, width: 2),
                        ),
                      ),
          ),
          const SizedBox(width: 14),
          Text(
            step.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isRunning ? FontWeight.w600 : FontWeight.w400,
              color: isDone
                  ? AppColors.success
                  : isRunning
                      ? AppColors.primary
                      : context.textSecondary,
            ),
          ),
          if (isDone) ...[
            const Spacer(),
            const Icon(Icons.check_circle, color: AppColors.success, size: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(bool isDark, {bool compact = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppShimmer(height: 36, width: 36, radius: 9),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppShimmer(height: 14, width: 120),
                    const SizedBox(height: 6),
                    AppShimmer(height: 10, width: 80),
                  ],
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 14),
            AppShimmer(height: 10),
            const SizedBox(height: 6),
            AppShimmer(height: 10),
            const SizedBox(height: 6),
            const AppShimmer(height: 10, width: 200),
          ],
        ],
      ),
    );
  }

  // ── Error view ────────────────────────────────────────────────────────────────

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _isConnectionError
                    ? AppColors.warningBg
                    : AppColors.errorBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                _isConnectionError
                    ? Icons.wifi_off_outlined
                    : Icons.error_outline,
                size: 34,
                color: _isConnectionError ? AppColors.warning : AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isConnectionError
                  ? 'Analysis Service Unavailable'
                  : 'Analysis Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Text(
                _isConnectionError
                    ? 'Unable to connect to the analysis engine.\n\n'
                      'Please check:\n'
                      '• Backend server is running\n'
                      '• Network connection is active'
                    : _error ?? 'An unexpected error occurred.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _analyze,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry Analysis'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Results ───────────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final moduleName = _result!['moduleName'] as String? ?? 'Unknown';
    final inputs  = List<String>.from(_result!['inputs']  ?? []);
    final outputs = List<String>.from(_result!['outputs'] ?? []);
    final warnings = _warnings;
    final score = _total;
    final color = _gradeColor(score);
    final stats = _ModuleStats.parse(widget.code);

    final critical = warnings
        .where((w) => _warningToSeverity(w['type'] as String? ?? '') == _Severity.critical)
        .toList();
    final warnLevel = warnings
        .where((w) => _warningToSeverity(w['type'] as String? ?? '') == _Severity.warning)
        .toList();
    final info = warnings
        .where((w) => _warningToSeverity(w['type'] as String? ?? '') == _Severity.info)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModuleCard(moduleName, inputs, outputs, stats),
        const SizedBox(height: 12),
        _buildScoreCard(score, color),
        const SizedBox(height: 12),
        if (_categories != null) ...[
          _buildCategoryCard(_categories!),
          const SizedBox(height: 12),
        ],
        _buildSeveritySummary(critical.length, warnLevel.length, info.length),
        const SizedBox(height: 12),
        if (warnings.isNotEmpty) ...[
          if (critical.isNotEmpty) ...[
            _buildWarningSection('Critical Issues', critical, AppColors.errorDark, Icons.error_outline),
            const SizedBox(height: 8),
          ],
          if (warnLevel.isNotEmpty) ...[
            _buildWarningSection('Warnings', warnLevel, AppColors.orange, Icons.warning_amber_outlined),
            const SizedBox(height: 8),
          ],
          if (info.isNotEmpty) ...[
            _buildWarningSection('Info', info, AppColors.info, Icons.info_outline),
            const SizedBox(height: 8),
          ],
          _buildRecommendationsCard(warnings),
          const SizedBox(height: 12),
        ] else ...[
          _buildAllClearCard(),
          const SizedBox(height: 12),
        ],
        _buildInsightsCard(score, warnings, stats),
        const SizedBox(height: 16),
        _buildActionButtons(),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Module card ───────────────────────────────────────────────────────────────

  Widget _buildModuleCard(
    String name,
    List<String> inputs,
    List<String> outputs,
    _ModuleStats stats,
  ) {
    return _InspCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppShadows.glow(AppColors.primary),
                ),
                child: const Icon(Icons.memory, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary),
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '${inputs.length} inputs · ${outputs.length} outputs',
                      style: TextStyle(
                          fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter
                      .withValues(alpha: context.isDark ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('module',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: context.border, height: 1),
          const SizedBox(height: 12),
          _portRow('Inputs', inputs, AppColors.teal),
          const SizedBox(height: 8),
          _portRow('Outputs', outputs, AppColors.secondary),
          const SizedBox(height: 14),
          Divider(color: context.border, height: 1),
          const SizedBox(height: 12),
          _buildStatsGrid(stats),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(_ModuleStats stats) {
    final items = [
      ('Wires', stats.wires, AppColors.teal),
      ('Registers', stats.registers, AppColors.secondary),
      ('Always', stats.alwaysBlocks, AppColors.info),
      ('Params', stats.parameters, AppColors.warningDark),
      ('Assigns', stats.assigns, AppColors.textSecondary),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final color = item.$3;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: context.isDark ? 0.12 : 0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${item.$2}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color)),
              const SizedBox(width: 5),
              Text(item.$1,
                  style: TextStyle(
                      fontSize: 11, color: context.textSecondary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _portRow(String label, List<String> ports, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: ports.isEmpty
                ? [
                    Text('—',
                        style: TextStyle(
                            color: context.textSecondary, fontSize: 12))
                  ]
                : ports
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: color.withValues(alpha: 0.25)),
                          ),
                          child: Text(p,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
          ),
        ),
      ],
    );
  }

  // ── Score card ────────────────────────────────────────────────────────────────

  Widget _buildScoreCard(int score, Color color) {
    final label = _gradeLabel(score);
    return _InspCard(
      color: color.withValues(alpha: context.isDark ? 0.08 : 0.04),
      borderColor: color.withValues(alpha: 0.25),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RTL Health Score',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$score',
                        style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: color,
                            height: 1)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5, left: 2),
                      child: Text('/100',
                          style: TextStyle(
                              fontSize: 16,
                              color: color.withValues(alpha: 0.5))),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: context.isDark ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: score / 100.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder: (context, v, child) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Circular gauge
          _ScoreGauge(score: score, grade: _grade, color: color),
        ],
      ),
    );
  }

  // ── Category breakdown ────────────────────────────────────────────────────────

  static const _categoryConfig = [
    ('correctness',      'Correctness',      35, AppColors.error),
    ('synthesizability', 'Synthesizability', 30, AppColors.orange),
    ('maintainability',  'Maintainability',  20, AppColors.info),
    ('fsm',              'FSM Quality',      10, AppColors.secondary),
    ('documentation',    'Documentation',     5, AppColors.teal),
  ];

  Widget _buildCategoryCard(Map<String, dynamic> cats) {
    return _InspCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InspCardHeader(
            icon: Icons.analytics_outlined,
            iconColor: AppColors.primary,
            title: 'Score Breakdown',
          ),
          const SizedBox(height: 14),
          ..._categoryConfig.map((cfg) {
            final score = (cats[cfg.$1] as num?)?.toInt() ?? 0;
            return _buildBar(cfg.$2, score, cfg.$3, cfg.$4);
          }),
        ],
      ),
    );
  }

  Widget _buildBar(String label, int score, int max, Color color) {
    final pct = max > 0 ? (score / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5, color: context.textPrimary)),
              Text('$score / $max',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, v, child) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor:
                    color.withValues(alpha: context.isDark ? 0.12 : 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Severity summary ──────────────────────────────────────────────────────────

  Widget _buildSeveritySummary(int critical, int warning, int info) {
    return _InspCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InspCardHeader(
            icon: Icons.bar_chart_outlined,
            iconColor: AppColors.primary,
            title: 'Issue Summary',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SeverityTile(
                    'Critical', critical, AppColors.errorDark, Icons.error_outline),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SeverityTile(
                    'Warning', warning, AppColors.orange, Icons.warning_amber),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SeverityTile(
                    'Info', info, AppColors.info, Icons.info_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Warnings section ──────────────────────────────────────────────────────────

  Widget _buildWarningSection(
    String title,
    List<Map<String, dynamic>> items,
    Color color,
    IconData icon,
  ) {
    return _InspCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InspCardHeader(icon: icon, iconColor: color, title: title),
          const SizedBox(height: 10),
          ...items.map((w) => _ExpandableWarning(warning: w, isDark: context.isDark)),
        ],
      ),
    );
  }

  // ── All-clear card ────────────────────────────────────────────────────────────

  Widget _buildAllClearCard() {
    return _InspCard(
      color: context.isDark
          ? AppColors.success.withValues(alpha: 0.08)
          : AppColors.successBg,
      borderColor: AppColors.success.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_outlined,
                color: AppColors.successDark, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('All checks passed',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successDark)),
                const SizedBox(height: 2),
                Text('No static analysis issues detected.',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.success.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Recommendations card ──────────────────────────────────────────────────────

  Widget _buildRecommendationsCard(List<Map<String, dynamic>> warnings) {
    final recs = _generateRecommendations(warnings);
    if (recs.isEmpty) return const SizedBox.shrink();

    return _InspCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InspCardHeader(
            icon: Icons.auto_fix_high_outlined,
            iconColor: AppColors.secondary,
            title: 'Recommended Improvements',
          ),
          const SizedBox(height: 12),
          ...recs.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.value,
                        style: TextStyle(
                            fontSize: 13,
                            color: context.textPrimary,
                            height: 1.45)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _generateRecommendations(List<Map<String, dynamic>> warnings) {
    final recs  = <String>[];
    final types = warnings.map((w) => w['type'] as String? ?? '').toSet();
    if (types.contains('blocking_assignment')) {
      recs.add('Use non-blocking assignments (<=) in sequential always blocks to avoid race conditions.');
    }
    if (types.contains('missing_default')) {
      recs.add('Add a default case to every case statement to prevent inferred latches.');
    }
    if (types.contains('inferred_latch')) {
      recs.add('Ensure all outputs are driven in every branch of combinational logic to eliminate latches.');
    }
    if (types.contains('unused_signal')) {
      recs.add('Remove or connect unused signals — they increase synthesis noise and may mask errors.');
    }
    if (types.contains('multiple_drivers')) {
      recs.add('Resolve multiple drivers: only one always block or assign should drive each signal.');
    }
    return recs;
  }

  // ── Engineering insights ──────────────────────────────────────────────────────

  Widget _buildInsightsCard(
      int score, List<Map<String, dynamic>> warnings, _ModuleStats stats) {
    final insights = _buildInsights(score, warnings, stats);
    return _InspCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InspCardHeader(
            icon: Icons.school_outlined,
            iconColor: AppColors.teal,
            title: 'Engineering Insights',
          ),
          const SizedBox(height: 12),
          ...insights.map(
            (ins) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: ins.$3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ins.$1,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ins.$3)),
                        const SizedBox(height: 2),
                        Text(ins.$2,
                            style: TextStyle(
                                fontSize: 12.5,
                                color: context.textSecondary,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<(String, String, Color)> _buildInsights(
    int score, List<Map<String, dynamic>> warnings, _ModuleStats stats) {
    final insights = <(String, String, Color)>[];
    final types = warnings.map((w) => w['type'] as String? ?? '').toSet();

    insights.add((
      'Design Health',
      score >= 75
          ? 'This design meets the basic quality bar for synthesis readiness.'
          : 'This design has issues that should be resolved before tape-out.',
      score >= 75 ? AppColors.success : AppColors.warningDark,
    ));

    if (stats.alwaysBlocks > 0) {
      insights.add((
        'Sequential Logic',
        'Detected ${stats.alwaysBlocks} always block(s) — '
            '${stats.registers} register(s) likely synthesized.',
        AppColors.info,
      ));
    }

    if (types.contains('blocking_assignment')) {
      insights.add((
        'Blocking Assignment Risk',
        'Blocking (=) in sequential blocks is a common source of simulation-synthesis mismatch — a real silicon risk.',
        AppColors.errorDark,
      ));
    }

    if (types.contains('missing_default')) {
      insights.add((
        'Latch Inference Risk',
        'Incomplete case statements synthesize latches, which are timing-sensitive and hard to constrain in STA.',
        AppColors.orange,
      ));
    }

    if (insights.length < 3) {
      insights.add((
        'Design Practice',
        'Clean, synthesizable RTL reduces iterations, speeds timing closure, and simplifies DFT insertion.',
        AppColors.info,
      ));
    }

    return insights;
  }

  // ── Action buttons ────────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    final scoreData = _categories != null
        ? <String, dynamic>{
            'total': _total,
            'grade': _grade,
            'categories': _categories,
          }
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GradientButton(
          label: 'View FSM Diagram',
          icon: Icons.account_tree,
          gradient: AppGradients.primary,
          glowColor: AppColors.primary,
          onTap: () => Navigator.push(
            context,
            slideRoute(FsmScreen(code: widget.code)),
          ),
        ),
        const SizedBox(height: 10),
        _GradientButton(
          label: 'AI Explain',
          icon: Icons.smart_toy,
          gradient: AppGradients.teal,
          glowColor: AppColors.teal,
          onTap: () => Navigator.push(
            context,
            slideRoute(ExplainScreen(
              code: widget.code,
              warnings: _warnings,
              scoreData: scoreData,
            )),
          ),
        ),
      ],
    );
  }
}

// ─── Circular score gauge ─────────────────────────────────────────────────────

class _ScoreGauge extends StatelessWidget {
  final int score;
  final String grade;
  final Color color;
  const _ScoreGauge({required this.score, required this.grade, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (context, v, child) => CustomPaint(
              size: const Size(100, 100),
              painter: _ArcPainter(value: v, color: color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                grade,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  const _ArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.grey.withValues(alpha: 0.15)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * value,
        false,
        Paint()
          ..color = color
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.value != value || old.color != color;
}

// ─── Expandable warning card ──────────────────────────────────────────────────

class _ExpandableWarning extends StatefulWidget {
  final Map<String, dynamic> warning;
  final bool isDark;
  const _ExpandableWarning({required this.warning, required this.isDark});

  @override
  State<_ExpandableWarning> createState() => _ExpandableWarningState();
}

class _ExpandableWarningState extends State<_ExpandableWarning> {
  bool _expanded = false;

  static const _details = <String, Map<String, String>>{
    'blocking_assignment': {
      'title': 'Blocking Assignment',
      'why': 'Using = in sequential always blocks causes simulation–synthesis mismatch, a real silicon risk.',
      'fix': 'Replace = with <= (non-blocking assignment) in all sequential always @(posedge clk) blocks.',
      'snippet': 'always @(posedge clk) begin\n  count <= count + 1; // ✓ non-blocking\nend',
    },
    'missing_default': {
      'title': 'Missing Default Case',
      'why': 'Without a default, synthesis infers latches to hold state — timing-sensitive and hard to constrain in STA.',
      'fix': 'Add default: <register> = <safe_value>; inside every case statement.',
      'snippet': 'case (op)\n  2\'b00: result = a + b;\n  default: result = 0; // ✓\nendcase',
    },
    'inferred_latch': {
      'title': 'Inferred Latch',
      'why': 'Level-sensitive latches are problematic in synchronous designs — they cause hold-time violations.',
      'fix': 'Assign all outputs in every branch of your combinational logic.',
      'snippet': 'always @(*) begin\n  // Drive all outputs in every branch\n  result = 0; // default\n  if (en) result = a + b;\nend',
    },
    'unused_signal': {
      'title': 'Unused Signal',
      'why': 'Unused signals increase synthesis noise and can mask connection bugs in larger designs.',
      'fix': 'Remove the declaration or connect the signal to logic that uses it.',
      'snippet': '// Remove or use:\n// wire unused_signal; ✗\n// Connects correctly to output instead',
    },
    'multiple_drivers': {
      'title': 'Multiple Drivers',
      'why': 'Multiple drivers on a net cause X-propagation in simulation and short-circuits in real silicon.',
      'fix': 'Ensure only one always block or assign statement drives each signal.',
      'snippet': '// Only one driver per signal:\nassign data_out = sel ? a : b; // ✓',
    },
  };

  @override
  Widget build(BuildContext context) {
    final type   = widget.warning['type'] as String? ?? '';
    final msg    = widget.warning['message'] as String? ?? '';
    final sig    = widget.warning['signal'] as String?;
    final sev    = _warningToSeverity(type);
    final color  = _sevColor(sev);
    final detail = _details[type];
    final isDark = widget.isDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _expanded
            ? color.withValues(alpha: isDark ? 0.08 : 0.04)
            : color.withValues(alpha: isDark ? 0.05 : 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _expanded
              ? color.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.18),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: detail != null ? () => setState(() => _expanded = !_expanded) : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(_sevIcon(sev), color: color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail?['title'] ?? type,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          if (sig != null)
                            Text(
                              'Signal: $sig',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textSecondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (detail != null)
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: context.textSecondary,
                      ),
                  ],
                ),
                if (!_expanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 40),
                    child: Text(
                      msg,
                      style: TextStyle(
                          fontSize: 12, color: context.textSecondary, height: 1.4),
                    ),
                  ),
                if (_expanded && detail != null) ...[
                  const SizedBox(height: 12),
                  Divider(color: color.withValues(alpha: 0.2), height: 1),
                  const SizedBox(height: 10),
                  _DetailRow(label: 'Why it matters', body: detail['why']!, isDark: isDark),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Suggested fix', body: detail['fix']!, isDark: isDark),
                  if (detail['snippet'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF13141F)
                            : const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        detail['snippet']!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          color: Color(0xFFE2E8F0),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _sevColor(_Severity s) => switch (s) {
    _Severity.critical => AppColors.errorDark,
    _Severity.warning  => AppColors.orange,
    _Severity.info     => AppColors.info,
  };

  IconData _sevIcon(_Severity s) => switch (s) {
    _Severity.critical => Icons.error_outline,
    _Severity.warning  => Icons.warning_amber,
    _Severity.info     => Icons.info_outline,
  };
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String body;
  final bool isDark;
  const _DetailRow({required this.label, required this.body, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.textSecondary,
                letterSpacing: 0.4)),
        const SizedBox(height: 3),
        Text(body,
            style: TextStyle(
                fontSize: 12.5,
                color: context.textPrimary,
                height: 1.45)),
      ],
    );
  }
}

// ─── Severity tile ────────────────────────────────────────────────────────────

class _SeverityTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _SeverityTile(this.label, this.count, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: context.isDark ? 0.1 : 0.06)
            : context.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? color.withValues(alpha: 0.3)
              : context.border,
        ),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 16,
              color: active ? color : context.textSecondary),
          const SizedBox(height: 4),
          Text('$count',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: active ? color : context.textSecondary)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: active ? color : context.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Gradient button ──────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.glow(glowColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared card + header ─────────────────────────────────────────────────────

class _InspCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? borderColor;

  const _InspCard({required this.child, this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? context.border),
        boxShadow: context.cardShadow,
      ),
      child: child,
    );
  }
}

class _InspCardHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _InspCardHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: context.isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 9),
        Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.textPrimary)),
      ],
    );
  }
}
