import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'ai_repair_screen.dart';
import 'backend/coverage/coverage_report.dart';
import 'backend/diagnostics/diagnostic.dart';
import 'backend/diagnostics/icarus_parser.dart';
import 'backend/tools/icarus_service.dart';
import 'backend/tools/rtl_testbench_generator.dart';
import 'models/design_spec.dart';
import 'services/nl_pipeline/pipeline.dart';
import 'theme/app_theme.dart';

// ignore_for_file: prefer_const_constructors_in_immutables

// ─── Screen entry point ───────────────────────────────────────────────────────

class NlToRtlScreen extends StatefulWidget {
  const NlToRtlScreen({super.key});

  @override
  State<NlToRtlScreen> createState() => _NlToRtlScreenState();
}

class _NlToRtlScreenState extends State<NlToRtlScreen>
    with SingleTickerProviderStateMixin {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _outputKey = GlobalKey();

  bool _isGenerating = false;
  int _generatingStep = 0;
  DesignResult? _result;
  String? _errorMessage;
  TabController? _tabCtrl;

  static const _steps = [
    ('Extracting requirements',  Icons.search_rounded),
    ('Building FSM',             Icons.account_tree_rounded),
    ('Generating RTL',           Icons.code_rounded),
    ('Generating Testbench',     Icons.science_rounded),
    ('Running Analysis',         Icons.analytics_rounded),
  ];

  static const _examples = [
    'Design a vending machine that accepts ₹5 and ₹10 coins and dispenses a drink at ₹15',
    'Design a traffic light controller with 30-cycle green, 5-cycle yellow, 25-cycle red',
    'Design a sequence detector for 1011 with overlapping detection',
    'Design a 4-digit digital lock with combination 1234 and 3 max attempts',
    'Design an 8-bit PWM generator with 50% default duty cycle',
    'Design a UART transmitter at 9600 baud with 8 data bits',
    'Design a 4-floor elevator controller',
    'Design a parking gate controller with payment and sensor inputs',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _tabCtrl?.dispose();
    super.dispose();
  }

  // ─── Generation pipeline ────────────────────────────────────────────────────

  Future<void> _generate() async {
    final desc = _inputCtrl.text.trim();
    if (desc.isEmpty) return;

    _tabCtrl?.dispose();
    setState(() {
      _isGenerating = true;
      _generatingStep = 0;
      _result = null;
      _errorMessage = null;
    });

    // Kick off the local pipeline asynchronously
    final pipelineFuture = Future.microtask(() => LocalPipeline.run(desc));

    // Animate progress steps in parallel
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() => _generatingStep = i);
      await Future.delayed(const Duration(milliseconds: 480));
    }

    try {
      final result = await pipelineFuture;
      if (!mounted) return;
      final tc = TabController(length: 7, vsync: this);
      setState(() {
        _isGenerating = false;
        _result = result;
        _tabCtrl = tc;
      });
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted && _outputKey.currentContext != null) {
        Scrollable.ensureVisible(
          _outputKey.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Generation failed: ${e.toString()}';
      });
    }
  }

  void _reset() {
    _tabCtrl?.dispose();
    setState(() {
      _result = null;
      _errorMessage = null;
      _tabCtrl = null;
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildHero(context)),
          SliverToBoxAdapter(child: _buildInputCard(context)),
          if (_isGenerating)
            SliverToBoxAdapter(child: _buildProgress(context)),
          if (_errorMessage != null)
            SliverToBoxAdapter(child: _buildError(context)),
          if (_result != null)
            SliverToBoxAdapter(
              key: _outputKey,
              child: _buildOutput(context),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  // ─── App bar ────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(BuildContext context) {
    final isDark = context.isDark;
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text('NL → RTL Designer',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              )),
        ],
      ),
      actions: [
        if (_result != null)
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('New'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: context.border),
      ),
    );
  }

  // ─── Hero ────────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.heroDark : AppGradients.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers_rounded, size: 11, color: AppColors.primary),
                const SizedBox(width: 5),
                Text('Structured Generation — 100% On-Device',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 0.1,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Natural Language\nRTL Designer',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              height: 1.15,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Describe digital hardware in plain English.\nGet synthesizable RTL, testbench, FSM diagram,\nand quality analysis — instantly, no internet.',
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroBadge(Icons.account_tree_rounded,
                  'Intent → FSM → RTL', AppColors.teal),
              const SizedBox(width: 8),
              _HeroBadge(Icons.verified_rounded,
                  '8 Design Templates', AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Input card ──────────────────────────────────────────────────────────────

  Widget _buildInputCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.border),
              boxShadow: context.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Text('Design Description',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary,
                        letterSpacing: 0.5,
                      )),
                ),
                TextField(
                  controller: _inputCtrl,
                  maxLines: 4,
                  minLines: 4,
                  enabled: !_isGenerating,
                  style: TextStyle(
                    fontSize: 15,
                    color: context.textPrimary,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Design a vending machine that accepts ₹5 and ₹10 coins...',
                    hintStyle: TextStyle(
                        color: context.textSecondary.withValues(alpha: 0.6),
                        fontSize: 14),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  ),
                ),
                Container(height: 1, color: context.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('  Try an example:',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _examples
                              .map((e) => _ExampleChip(
                                    label: e.length > 40
                                        ? '${e.substring(0, 40)}…'
                                        : e,
                                    fullText: e,
                                    onTap: () {
                                      _inputCtrl.text = e;
                                      _inputCtrl.selection =
                                          TextSelection.fromPosition(
                                        TextPosition(offset: e.length),
                                      );
                                    },
                                    enabled: !_isGenerating,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _isGenerating
                ? Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Generating…',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            )),
                      ],
                    ),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppShadows.glow(AppColors.primary),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _generate,
                        borderRadius: BorderRadius.circular(14),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Generate RTL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Progress ────────────────────────────────────────────────────────────────

  Widget _buildProgress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('  Generation Pipeline',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
                letterSpacing: -0.2,
              )),
          const SizedBox(height: 12),
          ...List.generate(_steps.length, (i) {
            final (label, icon) = _steps[i];
            final done   = i < _generatingStep;
            final active = i == _generatingStep;
            return _StepCard(
              label: label,
              icon: icon,
              index: i + 1,
              isDone: done,
              isActive: active,
            );
          }),
        ],
      ),
    );
  }

  // ─── Error ───────────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Generation Failed',
                      style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(_errorMessage!,
                      style: TextStyle(
                          color: context.textSecondary, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Output tabs ─────────────────────────────────────────────────────────────

  Widget _buildOutput(BuildContext context) {
    final r  = _result!;
    final tc = _tabCtrl!;
    final isDark = context.isDark;

    const tabs = [
      (Icons.description_rounded,  'Spec'),
      (Icons.account_tree_rounded, 'FSM'),
      (Icons.code_rounded,         'RTL'),
      (Icons.science_rounded,      'Testbench'),
      (Icons.lightbulb_rounded,    'Explanation'),
      (Icons.analytics_rounded,    'Quality'),
      (Icons.bar_chart_rounded,    'Coverage'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(r.spec.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      letterSpacing: -0.4,
                    )),
              ),
              _GradeBadge(r.quality.grade, r.quality.total),
              if (r.quality.warningCount > 0) ...[
                const SizedBox(width: 8),
                _AiRepairButton(result: r),
              ],
            ],
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border),
            ),
            child: TabBar(
              controller: tc,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppColors.primary,
              unselectedLabelColor: context.textSecondary,
              labelStyle: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              tabs: tabs
                  .map((t) => Tab(
                        height: 38,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.$1, size: 14),
                            const SizedBox(width: 5),
                            Text(t.$2),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.60,
            child: TabBarView(
              controller: tc,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SpecTab(spec: r.spec),
                _FsmTab(
                  states: r.fsmStates,
                  edges: r.fsmEdges,
                  entryState: r.fsmEntryState,
                  deadStates: r.fsmDeadStates,
                  unreachableStates: r.fsmUnreachableStates,
                  stateDetails: r.spec.states,
                  transitions: r.spec.transitions,
                  isDark: isDark,
                ),
                _CodeTab(code: r.rtl, language: 'Verilog'),
                _TestbenchTab(code: r.testbench, spec: r.spec, rtl: r.rtl),
                _ExplanationTab(markdown: r.explanation),
                _QualityTab(quality: r.quality),
                _CoverageTab(report: r.coverageReport),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero badge ───────────────────────────────────────────────────────────────

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeroBadge(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

// ─── Example chip ─────────────────────────────────────────────────────────────

class _ExampleChip extends StatelessWidget {
  final String label;
  final String fullText;
  final VoidCallback onTap;
  final bool enabled;
  const _ExampleChip(
      {required this.label,
      required this.fullText,
      required this.onTap,
      required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: enabled ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: enabled ? 0.2 : 0.1)),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 11.5,
                color: enabled
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              )),
        ),
      ),
    );
  }
}

// ─── Step card ────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final int index;
  final bool isDone;
  final bool isActive;
  const _StepCard(
      {required this.label,
      required this.icon,
      required this.index,
      required this.isDone,
      required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : context.textSecondary.withValues(alpha: 0.35);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : context.border,
        ),
        boxShadow: isActive ? AppShadows.glow(AppColors.primary) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: isDone
                ? Icon(Icons.check_rounded, color: color, size: 14)
                : isActive
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Text(
            '$index. $label',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? context.textPrimary
                  : isDone
                      ? context.textPrimary
                      : context.textSecondary,
            ),
          ),
          const Spacer(),
          if (isDone)
            Text('Done',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success)),
          if (isActive)
            Text('Running…',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ─── Grade badge ──────────────────────────────────────────────────────────────

class _GradeBadge extends StatelessWidget {
  final String grade;
  final int score;
  const _GradeBadge(this.grade, this.score);

  Color get _color {
    if (score >= 90) return AppColors.success;
    if (score >= 75) return AppColors.teal;
    if (score >= 60) return AppColors.warning;
    if (score >= 40) return AppColors.orange;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(grade,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: c,
                  height: 1)),
          Text('$score/100',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: c.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AI Repair navigation button
// ═══════════════════════════════════════════════════════════════════════════════

class _AiRepairButton extends StatelessWidget {
  final DesignResult result;
  const _AiRepairButton({required this.result});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AiRepairScreen(originalResult: result),
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(9),
          boxShadow: AppShadows.glow(AppColors.primary),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 13),
            SizedBox(width: 5),
            Text('AI Repair',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — Specification
// ═══════════════════════════════════════════════════════════════════════════════

class _SpecTab extends StatelessWidget {
  final DesignSpecification spec;
  const _SpecTab({required this.spec});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SpecSection(
            icon: Icons.info_outline_rounded,
            title: 'Description',
            color: AppColors.primary,
            child: Text(spec.description,
                style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13.5,
                    height: 1.6)),
          ),
          _SpecSection(
            icon: Icons.input_rounded,
            title: 'Inputs',
            color: AppColors.teal,
            child: _SignalTable(signals: spec.inputs),
          ),
          _SpecSection(
            icon: Icons.output_rounded,
            title: 'Outputs',
            color: AppColors.success,
            child: _SignalTable(signals: spec.outputs),
          ),
          _SpecSection(
            icon: Icons.account_tree_rounded,
            title: 'States',
            color: AppColors.secondary,
            child: Column(
              children: spec.states.map((s) => _StateRow(state: s)).toList(),
            ),
          ),
          if (spec.assumptions.isNotEmpty)
            _SpecSection(
              icon: Icons.checklist_rounded,
              title: 'Design Assumptions',
              color: AppColors.warning,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: spec.assumptions
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.circle,
                                  size: 5,
                                  color: AppColors.warning),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(a,
                                    style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 13,
                                        height: 1.5)),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          _SpecSection(
            icon: Icons.memory_rounded,
            title: 'Module',
            color: AppColors.info,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(spec.moduleName,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Text('Entry: ',
                    style: TextStyle(
                        fontSize: 12.5, color: context.textSecondary)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(spec.entryState,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;
  const _SpecSection(
      {required this.icon,
      required this.title,
      required this.color,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(title.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SignalTable extends StatelessWidget {
  final List<SignalPort> signals;
  const _SignalTable({required this.signals});

  @override
  Widget build(BuildContext context) {
    if (signals.isEmpty) {
      return Text('None',
          style: TextStyle(
              color: context.textSecondary, fontSize: 12.5));
    }
    return Column(
      children: signals.map((s) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(s.name,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: 8),
              if (s.width > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('[${s.width - 1}:0]',
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.teal)),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.description,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: context.textSecondary,
                        height: 1.4)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StateRow extends StatelessWidget {
  final StateNode state;
  const _StateRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final dotColor = state.isEntry
        ? AppColors.success
        : state.isExit
            ? AppColors.orange
            : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${state.name}  ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: dotColor,
                    ),
                  ),
                  TextSpan(
                    text: state.description,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: context.textSecondary,
                        height: 1.4,
                        fontFamily: null),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — FSM Diagram (interactive)
// ═══════════════════════════════════════════════════════════════════════════════

class _FsmTab extends StatefulWidget {
  final List<String> states;
  final List<Map<String, dynamic>> edges;
  final String? entryState;
  final List<String> deadStates;
  final List<String> unreachableStates;
  final List<StateNode> stateDetails;
  final List<EdgeTransition> transitions;
  final bool isDark;

  const _FsmTab({
    required this.states,
    required this.edges,
    required this.entryState,
    required this.deadStates,
    required this.unreachableStates,
    required this.stateDetails,
    required this.transitions,
    required this.isDark,
  });

  @override
  State<_FsmTab> createState() => _FsmTabState();
}

class _FsmTabState extends State<_FsmTab> {
  String? _selectedState;

  StateNode? _detailFor(String name) {
    try {
      return widget.stateDetails.firstWhere((s) => s.name == name);
    } catch (_) {
      return null;
    }
  }

  Color _chipColor(String s) {
    if (widget.unreachableStates.contains(s)) return AppColors.error;
    if (widget.deadStates.contains(s))        return AppColors.orange;
    if (s == widget.entryState)               return AppColors.success;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.states.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree_outlined, size: 40,
                color: context.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No state machine detected',
                style: TextStyle(color: context.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    final isDark = widget.isDark;

    return Column(
      children: [
        // ── Diagram ──────────────────────────────────────────────────────
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161822) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? const Color(0xFF2A2D3E) : const Color(0xFFE8EAED)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                minScale: 0.4,
                maxScale: 4.0,
                child: CustomPaint(
                  painter: _NlFsmPainter(
                    states: widget.states,
                    edges: widget.edges,
                    unreachableStates: Set<String>.from(widget.unreachableStates),
                    deadStates: Set<String>.from(widget.deadStates),
                    entryState: widget.entryState,
                    selectedState: _selectedState,
                    isDark: isDark,
                  ),
                  child: const SizedBox(width: 520, height: 300),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── State selector chips ─────────────────────────────────────────
        SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.states.length,
            separatorBuilder: (_, idx) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final s       = widget.states[i];
              final color   = _chipColor(s);
              final selected = s == _selectedState;
              return GestureDetector(
                onTap: () => setState(
                    () => _selectedState = selected ? null : s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? color
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : color,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // ── Legend ────────────────────────────────────────────────────────
        Row(
          children: [
            _FsmLegendDot('Entry',       AppColors.success),
            const SizedBox(width: 10),
            _FsmLegendDot('Normal',      AppColors.primary),
            const SizedBox(width: 10),
            _FsmLegendDot('Dead end',    AppColors.orange),
            const SizedBox(width: 10),
            _FsmLegendDot('Unreachable', AppColors.error),
            const Spacer(),
            Text('${widget.states.length} states · ${widget.edges.length} transitions',
                style: TextStyle(fontSize: 11, color: context.textSecondary)),
          ],
        ),

        // ── State details panel ──────────────────────────────────────────
        if (_selectedState != null) ...[
          const SizedBox(height: 8),
          _StateDetailsCard(
            stateName: _selectedState!,
            node: _detailFor(_selectedState!),
            allTransitions: widget.transitions,
            color: _chipColor(_selectedState!),
          ),
        ],
      ],
    );
  }
}

// ── State details card ────────────────────────────────────────────────────────

class _StateDetailsCard extends StatelessWidget {
  final String stateName;
  final StateNode? node;
  final List<EdgeTransition> allTransitions;
  final Color color;

  const _StateDetailsCard({
    required this.stateName,
    required this.node,
    required this.allTransitions,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final outgoing = allTransitions.where((t) => t.from == stateName).toList();
    final incoming = allTransitions.where((t) => t.to == stateName && t.from != stateName).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(stateName,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  )),
              if (node != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(node!.description,
                      style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
          if (node?.outputs.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: node!.outputs.entries.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Text('${e.key} = ${e.value}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    )),
              )).toList(),
            ),
          ],
          if (outgoing.isNotEmpty) ...[
            const SizedBox(height: 6),
            _TransitionList(label: 'Outgoing', transitions: outgoing, color: AppColors.primary),
          ],
          if (incoming.isNotEmpty) ...[
            const SizedBox(height: 4),
            _TransitionList(label: 'Incoming', transitions: incoming, color: context.textSecondary),
          ],
        ],
      ),
    );
  }
}

class _TransitionList extends StatelessWidget {
  final String label;
  final List<EdgeTransition> transitions;
  final Color color;
  const _TransitionList({required this.label, required this.transitions, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                color: context.textSecondary, letterSpacing: 0.6)),
        const SizedBox(height: 3),
        ...transitions.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Icon(label == 'Outgoing' ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                  size: 11, color: color.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(label == 'Outgoing' ? t.to : t.from,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10.5,
                      fontWeight: FontWeight.w600, color: color)),
              const SizedBox(width: 6),
              if (t.condition.isNotEmpty)
                Expanded(
                  child: Text('when ${t.condition}',
                      style: TextStyle(fontSize: 10.5, color: context.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        )),
      ],
    );
  }
}

class _FsmLegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _FsmLegendDot(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10.5, color: context.textSecondary)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 & 4 — Code viewer
// ═══════════════════════════════════════════════════════════════════════════════

class _CodeTab extends StatelessWidget {
  final String code;
  final String language;
  const _CodeTab({required this.code, required this.language});

  @override
  Widget build(BuildContext context) =>
      _CodeTabContent(code: code, language: language, isDark: context.isDark);
}

// Shared code viewer used by _CodeTab and _TestbenchTab
class _CodeTabContent extends StatelessWidget {
  final String code;
  final String language;
  final bool isDark;
  const _CodeTabContent(
      {required this.code, required this.language, required this.isDark});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$language copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2030) : const Color(0xFFF1F5F9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: context.border),
          ),
          child: Row(
            children: [
              Container(width: 10, height: 10,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                      color: Color(0xFFEF4444), shape: BoxShape.circle)),
              Container(width: 10, height: 10,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B), shape: BoxShape.circle)),
              Container(width: 10, height: 10,
                  decoration: const BoxDecoration(
                      color: Color(0xFF10B981), shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(language,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                      color: context.textSecondary)),
              const Spacer(),
              Text('${lines.length} lines',
                  style: TextStyle(fontSize: 11,
                      color: context.textSecondary.withValues(alpha: 0.7))),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _copy(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 11, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Copy',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D0F17) : const Color(0xFFFAFBFF),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(10)),
              border: Border(
                left: BorderSide(color: context.border),
                right: BorderSide(color: context.border),
                bottom: BorderSide(color: context.border),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: _SyntaxHighlight(code: code, isDark: isDark),
            ),
          ),
        ),
      ],
    );
  }
}

class _SyntaxHighlight extends StatelessWidget {
  final String code;
  final bool isDark;
  const _SyntaxHighlight({required this.code, required this.isDark});

  static const _keywords = {
    'module', 'endmodule', 'input', 'output', 'inout', 'wire', 'reg',
    'always', 'begin', 'end', 'if', 'else', 'case', 'endcase', 'default',
    'assign', 'parameter', 'localparam', 'posedge', 'negedge', 'or',
    'and', 'not', 'initial', 'for', 'while', 'integer', 'timescale',
  };

  @override
  Widget build(BuildContext context) {
    final defaultColor  = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final commentColor  = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final keywordColor  = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);
    final numberColor   = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    final gutterColor   = isDark ? const Color(0xFF3D4152) : const Color(0xFFBCC3D0);
    final gutterBg      = isDark ? const Color(0xFF13151F) : const Color(0xFFF1F5F9);

    final lines = code.split('\n');
    final lineNumWidth = lines.length.toString().length;
    final spans = <TextSpan>[];

    for (int i = 0; i < lines.length; i++) {
      // Gutter: right-aligned line number
      final lineNum = (i + 1).toString().padLeft(lineNumWidth);
      spans.add(TextSpan(
        text: lineNum,
        style: TextStyle(
          color: gutterColor,
          backgroundColor: gutterBg,
          fontSize: 12.0,
          height: 1.65,
        ),
      ));
      // Separator column
      spans.add(TextSpan(
        text: '  ',
        style: TextStyle(color: gutterColor, backgroundColor: gutterBg),
      ));

      final line = lines[i];
      final commentIdx  = line.indexOf('//');
      final codePart    = commentIdx >= 0 ? line.substring(0, commentIdx) : line;
      final commentPart = commentIdx >= 0 ? line.substring(commentIdx) : null;

      int pos = 0;
      final wordRe = RegExp(r'\b(\w+)\b');
      for (final m in wordRe.allMatches(codePart)) {
        if (m.start > pos) {
          spans.add(TextSpan(
              text: codePart.substring(pos, m.start),
              style: TextStyle(color: defaultColor)));
        }
        final tok   = m.group(1)!;
        final color = _keywords.contains(tok)
            ? keywordColor
            : RegExp(r'^\d+$').hasMatch(tok)
                ? numberColor
                : defaultColor;
        spans.add(TextSpan(text: tok, style: TextStyle(color: color)));
        pos = m.end;
      }
      if (pos < codePart.length) {
        spans.add(TextSpan(
            text: codePart.substring(pos),
            style: TextStyle(color: defaultColor)));
      }
      if (commentPart != null) {
        spans.add(TextSpan(
            text: commentPart,
            style: TextStyle(color: commentColor, fontStyle: FontStyle.italic)));
      }
      spans.add(const TextSpan(text: '\n'));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          height: 1.65,
        ),
        children: spans,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 4 (Testbench) — Verification summary + raw code + "Generate Testbench"
// ═══════════════════════════════════════════════════════════════════════════════

class _TestbenchTab extends StatefulWidget {
  final String code;
  final DesignSpecification spec;
  final String rtl;
  const _TestbenchTab({required this.code, required this.spec, required this.rtl});

  @override
  State<_TestbenchTab> createState() => _TestbenchTabState();
}

class _TestbenchTabState extends State<_TestbenchTab> {
  // ── Simulation state ───────────────────────────────────────────────────────
  bool _isRunning = false;
  TestbenchResult? _tbResult;
  SimulationResult? _simResult;
  List<Diagnostic> _simDiags = [];
  String? _genError;

  // ── Generate testbench → compile → simulate ───────────────────────────────

  Future<void> _generateAndSimulate() async {
    setState(() {
      _isRunning = true;
      _genError  = null;
      _tbResult  = null;
      _simResult = null;
      _simDiags  = [];
    });

    try {
      final tbResult = RtlTestbenchGenerator.generate(widget.rtl);
      if (!mounted) return;
      setState(() => _tbResult = tbResult);

      if (!tbResult.success) {
        setState(() { _isRunning = false; _genError = tbResult.error; });
        return;
      }

      const svc = IcarusService();
      final simResult = await svc.simulate(widget.rtl, tbResult.source);
      if (!mounted) return;

      final combined = '${simResult.stdout}\n${simResult.stderr}';
      final diags    = IcarusParser.parse(combined);

      setState(() {
        _simResult = simResult;
        _simDiags  = diags;
        _isRunning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isRunning = false; _genError = e.toString(); });
    }
  }

  // ── Scenarios ─────────────────────────────────────────────────────────────

  List<_TestScenario> _scenarios() {
    final spec = widget.spec;
    switch (spec.designType) {
      case 'vending_machine':
        return [
          _TestScenario('Reset and idle',         'No coins → no dispense',           Icons.power_settings_new_rounded),
          _TestScenario('Exact payment',           'Coin sequence summing to price',    Icons.check_circle_outline_rounded),
          _TestScenario('Overpayment',             'Excess coin → dispense + change',   Icons.currency_exchange_rounded),
          _TestScenario('Mid-sequence reset',      'Assert rst_n mid-credit → IDLE',   Icons.restart_alt_rounded),
        ];
      case 'traffic_light':
        return [
          _TestScenario('Power-on reset',          'GREEN state after rst_n',           Icons.power_settings_new_rounded),
          _TestScenario('Phase timing',            'Each phase holds for exact cycles', Icons.timer_outlined),
          _TestScenario('Cyclic ordering',         'GREEN→YELLOW→RED→GREEN',           Icons.loop_rounded),
          _TestScenario('Reset from any phase',    'Always returns to GREEN',           Icons.restart_alt_rounded),
        ];
      case 'uart_transmitter':
        final isRx = spec.params['is_rx'] as bool? ?? false;
        return [
          _TestScenario('Frame structure',         isRx ? 'Detects valid start/stop bits' : 'Start=0, 8 data, stop=1', Icons.table_rows_rounded),
          _TestScenario('LSB-first ordering',      'Bit order verified against reference', Icons.sort_rounded),
          _TestScenario(isRx ? 'Framing error' : 'Back-to-back bytes',
              isRx ? 'frame_err asserted on bad stop bit' : 'tx_ready toggles correctly', Icons.error_outline_rounded),
          _TestScenario('Baud accuracy',           'Verified at ${spec.params["baud"]} baud', Icons.speed_rounded),
        ];
      case 'sequence_detector':
        return [
          _TestScenario('All-zero stream',         'No false detection',                Icons.block_rounded),
          _TestScenario('Target pattern',          'Detects "${spec.params["sequence"]}"', Icons.search_rounded),
          _TestScenario(spec.params['overlap'] == true ? 'Overlapping match' : 'Non-overlapping',
              spec.params['overlap'] == true ? 'Back-to-back patterns detected' : 'Resets to S_INIT after each match', Icons.repeat_rounded),
          _TestScenario('Reset clears prefix',     'State returns to S_INIT after rst_n', Icons.restart_alt_rounded),
        ];
      case 'digital_lock':
        return [
          _TestScenario('Correct combination',     'Enters UNLOCKED state',             Icons.lock_open_rounded),
          _TestScenario('Wrong first digit',       'Stays IDLE, attempt_cnt increments', Icons.close_rounded),
          _TestScenario('Max attempt lockout',     'LOCKOUT after ${spec.params["max_attempts"]} failures', Icons.lock_rounded),
          _TestScenario('Lockout persistence',     'LOCKOUT holds until rst_n',         Icons.lock_clock_rounded),
        ];
      case 'pwm_generator':
        return [
          _TestScenario('Enable / disable',        'Output LOW when enable=0',          Icons.toggle_off_rounded),
          _TestScenario('Duty cycle 0%',           'pwm_out permanently LOW',           Icons.horizontal_rule_rounded),
          _TestScenario('Duty cycle 50%',          'Symmetric waveform verified',       Icons.show_chart_rounded),
          _TestScenario('Duty cycle 100%',         'pwm_out permanently HIGH',          Icons.terrain_rounded),
        ];
      case 'elevator':
        return [
          _TestScenario('Single floor request',    'Door opens on requested floor',     Icons.door_front_door_rounded),
          _TestScenario('MOVE_UP to top',          'Cabin travels to highest req',      Icons.arrow_upward_rounded),
          _TestScenario('MOVE_DOWN to bottom',     'Cabin travels to lowest req',       Icons.arrow_downward_rounded),
          _TestScenario('Reset from any state',    'Returns to IDLE at floor 0',        Icons.restart_alt_rounded),
        ];
      default:
        return [
          _TestScenario('Reset behaviour',         'Registers initialise correctly',    Icons.power_settings_new_rounded),
          _TestScenario('Golden path',             'IDLE → ACTIVE → DONE',             Icons.check_rounded),
          _TestScenario('Hold in ACTIVE',          'Stays until done_condition true',   Icons.pause_rounded),
          _TestScenario('Back-to-back operations', 'Two consecutive start strobes',     Icons.repeat_rounded),
        ];
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scenarios = _scenarios();
    final isDark    = context.isDark;
    final showCode  = _tbResult?.success == true ? _tbResult!.source : widget.code;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Verification summary card ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.science_rounded, size: 14, color: AppColors.teal),
                    const SizedBox(width: 6),
                    Text('VERIFICATION PLAN',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                          letterSpacing: 0.8,
                        )),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Text('${scenarios.length} scenarios',
                          style: const TextStyle(
                              fontSize: 10.5, fontWeight: FontWeight.w600,
                              color: AppColors.success)),
                    ),
                    const SizedBox(width: 8),
                    // ── Generate Testbench button ─────────────────────
                    GestureDetector(
                      onTap: _isRunning ? null : _generateAndSimulate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: _isRunning ? 0.05 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isRunning)
                              const SizedBox(
                                width: 10, height: 10,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5, color: AppColors.primary),
                              )
                            else
                              const Icon(Icons.play_arrow_rounded,
                                  size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              _isRunning ? 'Running…' : 'Generate Testbench',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...scenarios.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Icon(s.icon, size: 13, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Text(s.name,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: context.textPrimary)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('— ${s.description}',
                            style: TextStyle(
                                fontSize: 11.5, color: context.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),

          // ── Simulation results ───────────────────────────────────────
          if (_genError != null) ...[
            const SizedBox(height: 8),
            _SimErrorCard(message: _genError!),
          ] else if (_simResult != null) ...[
            const SizedBox(height: 8),
            _SimResultCard(
              simResult: _simResult!,
              diags:     _simDiags,
            ),
          ],

          // ── Testbench code ───────────────────────────────────────────
          const SizedBox(height: 4),
          SizedBox(
            height: 360,
            child: _CodeTabContent(
              code: showCode, language: 'Testbench', isDark: isDark),
          ),
        ],
      ),
    );
  }
}

// ── Simulation result display widgets ─────────────────────────────────────────

class _SimErrorCard extends StatelessWidget {
  final String message;
  const _SimErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 12, color: AppColors.error, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _SimResultCard extends StatelessWidget {
  final SimulationResult simResult;
  final List<Diagnostic> diags;
  const _SimResultCard({required this.simResult, required this.diags});

  @override
  Widget build(BuildContext context) {
    final sim = simResult;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              _SimStatusChip(label: 'Compile', ok: sim.compileSuccess),
              if (sim.compileSuccess) ...[
                const SizedBox(width: 8),
                _SimStatusChip(label: 'Simulate', ok: sim.simulationSuccess),
              ],
            ],
          ),

          // Diagnostics
          if (diags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('DIAGNOSTICS',
                style: TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w700,
                    color: context.textSecondary, letterSpacing: 0.7)),
            const SizedBox(height: 6),
            ...diags.map((d) => _DiagRow(diag: d)),
          ],

          // Simulation output
          if (sim.stdout.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('OUTPUT',
                style: TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w700,
                    color: context.textSecondary, letterSpacing: 0.7)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xFF0D0F17)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: context.border),
              ),
              child: Text(
                sim.stdout.trim(),
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: context.textPrimary,
                    height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SimStatusChip extends StatelessWidget {
  final String label;
  final bool ok;
  const _SimStatusChip({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
              size: 11, color: color),
          const SizedBox(width: 4),
          Text('$label ${ok ? "✓" : "✗"}',
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  final Diagnostic diag;
  const _DiagRow({required this.diag});

  @override
  Widget build(BuildContext context) {
    final isError = diag.severity == 'error';
    final color   = isError ? AppColors.error : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
              size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(diag.title,
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
                Text(diag.description,
                    style: TextStyle(
                        fontSize: 11, color: context.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TestScenario {
  final String name;
  final String description;
  final IconData icon;
  const _TestScenario(this.name, this.description, this.icon);
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 5 — Engineering Explanation
// ═══════════════════════════════════════════════════════════════════════════════

class _ExplanationTab extends StatelessWidget {
  final String markdown;
  const _ExplanationTab({required this.markdown});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    if (markdown.isEmpty) {
      return Center(
        child: Text('No explanation available.',
            style: TextStyle(color: context.textSecondary)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Markdown(
        data: markdown,
        padding: const EdgeInsets.all(16),
        styleSheet: MarkdownStyleSheet(
          h2: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
          h3: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
          p: TextStyle(
            fontSize: 13,
            color: context.textPrimary,
            height: 1.65,
          ),
          strong: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
          code: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
          ),
          codeblockDecoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E2030)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.border),
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.4), width: 3),
            ),
          ),
          tableHead: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
          tableBody: TextStyle(
            fontSize: 12,
            color: context.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 6 — Quality Report
// ═══════════════════════════════════════════════════════════════════════════════

class _QualityTab extends StatelessWidget {
  final QualityReport quality;
  const _QualityTab({required this.quality});

  static Color _scoreColor(int s) {
    if (s >= 90) return AppColors.success;
    if (s >= 75) return AppColors.teal;
    if (s >= 60) return AppColors.warning;
    if (s >= 40) return AppColors.orange;
    return AppColors.error;
  }

  static Color _categoryColor(String name) {
    switch (name) {
      case 'Correctness':     return AppColors.error;
      case 'Synthesizability':return AppColors.warning;
      case 'Maintainability': return AppColors.info;
      default:                return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = quality.total;
    final sc    = _scoreColor(score);

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Overall score header ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border),
            ),
            child: Row(
              children: [
                _ScoreRing(score: score, color: sc),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Grade ${quality.grade}',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900,
                              color: sc)),
                      const SizedBox(height: 4),
                      Text(
                        score >= 90
                            ? 'Excellent — production-ready RTL'
                            : score >= 75
                                ? 'Good — minor improvements possible'
                                : score >= 60
                                    ? 'Fair — address warnings before synthesis'
                                    : 'Needs improvement — critical issues found',
                        style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12.5,
                            height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(
                          quality.warningCount == 0
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          size: 14,
                          color: quality.warningCount == 0
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          quality.warningCount == 0
                              ? 'No warnings'
                              : '${quality.warningCount} warning${quality.warningCount > 1 ? "s" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: quality.warningCount == 0
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Category detail cards ─────────────────────────────────────
          if (quality.categoryDetails.isNotEmpty)
            ...quality.categoryDetails.map((cat) =>
                _CategoryDetailCard(category: cat,
                    color: _categoryColor(cat.name)))
          else
            // Fallback: plain bar chart if no details available
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Score Breakdown',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: context.textSecondary, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  ...quality.categories.entries.map((e) {
                    const maxes = {
                      'correctness': 35, 'synthesizability': 30,
                      'maintainability': 20, 'fsm': 15,
                    };
                    return _CategoryBar(
                        label: e.key, value: e.value,
                        max: maxes[e.key] ?? 10,
                        color: _categoryColor(e.key));
                  }),
                ],
              ),
            ),

          // ── Warnings list ─────────────────────────────────────────────
          if (quality.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DIAGNOSTICS',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                          color: context.textSecondary, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  ...quality.warnings.map((w) => _WarningRow(warning: w)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Category detail card ──────────────────────────────────────────────────────

class _CategoryDetailCard extends StatefulWidget {
  final QualityCategory category;
  final Color color;
  const _CategoryDetailCard({required this.category, required this.color});

  @override
  State<_CategoryDetailCard> createState() => _CategoryDetailCardState();
}

class _CategoryDetailCardState extends State<_CategoryDetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cat   = widget.category;
    final color = widget.color;
    final pct   = cat.fraction.clamp(0.0, 1.0);
    final hasDetails = cat.issues.isNotEmpty || cat.recommendations.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(cat.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.8,
                          )),
                      const Spacer(),
                      Text('${cat.score} / ${cat.maxScore}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: color,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(cat.explanation,
                      style: TextStyle(
                          fontSize: 12.5, color: context.textSecondary, height: 1.5)),
                  if (hasDetails) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Row(
                        children: [
                          Text(
                            _expanded ? 'Hide details' : 'Show issues & recommendations',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 14, color: color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Expanded details
            if (_expanded && hasDetails) ...[
              Container(height: 1, color: context.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cat.issues.isNotEmpty) ...[
                      _DetailSection(
                        icon: Icons.error_outline_rounded,
                        label: 'Issues',
                        items: cat.issues,
                        iconColor: AppColors.error,
                        textColor: context.textPrimary,
                      ),
                      if (cat.recommendations.isNotEmpty)
                        const SizedBox(height: 8),
                    ],
                    if (cat.recommendations.isNotEmpty)
                      _DetailSection(
                        icon: Icons.lightbulb_outline_rounded,
                        label: 'Recommendations',
                        items: cat.recommendations,
                        iconColor: AppColors.warning,
                        textColor: context.textSecondary,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> items;
  final Color iconColor;
  final Color textColor;

  const _DetailSection({
    required this.icon,
    required this.label,
    required this.items,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 5),
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w700,
                    color: iconColor, letterSpacing: 0.6)),
          ],
        ),
        const SizedBox(height: 5),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('·  ', style: TextStyle(color: iconColor, fontSize: 13,
                  fontWeight: FontWeight.w700)),
              Expanded(
                child: Text(item,
                    style: TextStyle(fontSize: 12, color: textColor, height: 1.45)),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _RingPainter(
            score: score, color: color, bgColor: context.border),
        child: Center(
          child: Text('$score',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final int score;
  final Color color;
  final Color bgColor;
  const _RingPainter(
      {required this.score, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const strokeW = 6.0;
    final r = math.min(cx, cy) - strokeW;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      2 * math.pi * score / 100,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.score != score || old.color != color;
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  const _CategoryBar(
      {required this.label,
      required this.value,
      required this.max,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? value / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12.5,
                          color: context.textPrimary,
                          fontWeight: FontWeight.w500))),
              Text('$value / $max',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  final QualityWarning warning;
  const _WarningRow({required this.warning});

  static const _severityColor = <String, Color>{
    'critical': AppColors.error,
    'warning':  AppColors.warning,
    'info':     AppColors.info,
  };
  static const _severityIcon = <String, IconData>{
    'critical': Icons.error_rounded,
    'warning':  Icons.warning_amber_rounded,
    'info':     Icons.info_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = _severityColor[warning.severity] ?? AppColors.info;
    final icon  = _severityIcon[warning.severity] ?? Icons.info_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(warning.message,
                style: TextStyle(
                    fontSize: 12.5,
                    color: context.textPrimary,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FSM Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _NlFsmPainter extends CustomPainter {
  final List<String> states;
  final List<Map<String, dynamic>> edges;
  final Set<String> unreachableStates;
  final Set<String> deadStates;
  final String? entryState;
  final String? selectedState;
  final bool isDark;

  static const double _r     = 34.0;
  static const double _arrow = 10.0;

  const _NlFsmPainter({
    required this.states,
    required this.edges,
    required this.unreachableStates,
    this.deadStates    = const {},
    this.entryState,
    this.selectedState,
    this.isDark = false,
  });

  Map<String, Offset> _positions(Size size) {
    final n = states.length;
    final pos = <String, Offset>{};
    if (n == 0) return pos;
    if (n == 1) {
      pos[states[0]] = Offset(size.width / 2, size.height / 2);
      return pos;
    }
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = math.min(cx, cy) - _r - 24;
    for (int i = 0; i < n; i++) {
      final angle = 2 * math.pi * i / n - math.pi / 2;
      pos[states[i]] = Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    }
    return pos;
  }

  Color _nodeColor(String s) {
    if (unreachableStates.contains(s)) return AppColors.error;
    if (deadStates.contains(s))        return AppColors.orange;
    if (s == entryState)               return AppColors.success;
    return AppColors.primary;
  }

  void _arrowHead(Canvas c, Offset tip, double angle, Color color) {
    const spread = math.pi / 7;
    c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - _arrow * math.cos(angle - spread),
                 tip.dy - _arrow * math.sin(angle - spread))
        ..lineTo(tip.dx - _arrow * math.cos(angle + spread),
                 tip.dy - _arrow * math.sin(angle + spread))
        ..close(),
      Paint()..color = color..style = PaintingStyle.fill,
    );
  }

  void _label(Canvas c, String text, Offset pos) {
    final style = TextStyle(
      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF374151),
      fontSize: 9.5,
      fontWeight: FontWeight.w500,
    );
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final bg = Rect.fromCenter(
        center: pos, width: tp.width + 10, height: tp.height + 5);
    c.drawRRect(RRect.fromRectAndRadius(bg, const Radius.circular(4)),
        Paint()
          ..color = isDark ? const Color(0xFF1E2030) : Colors.white);
    c.drawRRect(RRect.fromRectAndRadius(bg, const Radius.circular(4)),
        Paint()
          ..color = isDark
              ? const Color(0xFF2A2D3E)
              : const Color(0xFFE5E7EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
    tp.paint(c, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawEdge(Canvas c, Offset from, Offset to, String? cond,
      {required bool curve, required bool flip, required Color color}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final dx   = to.dx - from.dx;
    final dy   = to.dy - from.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return;
    final nx = dx / dist;
    final ny = dy / dist;

    final start = Offset(from.dx + nx * _r, from.dy + ny * _r);
    final end   = Offset(to.dx - nx * _r, to.dy - ny * _r);
    final tip   = Offset(to.dx - nx * (_r - 1), to.dy - ny * (_r - 1));

    if (curve) {
      final mx   = (start.dx + end.dx) / 2;
      final my   = (start.dy + end.dy) / 2;
      final pm   = flip ? -52.0 : 52.0;
      final ctrl = Offset(mx - ny * pm, my + nx * pm);
      c.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy),
        paint,
      );
      _arrowHead(c, tip,
          math.atan2(end.dy - ctrl.dy, end.dx - ctrl.dx), color);
      if (cond != null && cond.isNotEmpty) {
        _label(c, cond,
            Offset((start.dx + 2 * ctrl.dx + end.dx) / 4,
                   (start.dy + 2 * ctrl.dy + end.dy) / 4 - 12));
      }
    } else {
      c.drawLine(start, end, paint);
      _arrowHead(c, tip, math.atan2(dy, dx), color);
      if (cond != null && cond.isNotEmpty) {
        _label(c, cond,
            Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 - 12));
      }
    }
  }

  void _selfLoop(Canvas c, Offset center, String? cond, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    c.drawCircle(Offset(center.dx, center.dy - _r - 22), 18, paint);
    _arrowHead(c, Offset(center.dx + 3, center.dy - _r - 5),
        math.pi / 2 + 0.5, color);
    if (cond != null && cond.isNotEmpty) {
      _label(c, cond, Offset(center.dx, center.dy - _r - 48));
    }
  }

  void _drawNode(Canvas c, String state, Offset center) {
    final fill     = _nodeColor(state);
    final entry    = state == entryState;
    final selected = state == selectedState;

    c.drawCircle(center + const Offset(1, 2), _r,
        Paint()
          ..color = Colors.black.withValues(alpha: selected ? 0.30 : 0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, selected ? 10 : 6));

    if (selected) {
      c.drawCircle(center, _r + 11,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5);
      c.drawCircle(center, _r + 6,
          Paint()
            ..color = fill
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    } else if (entry) {
      c.drawCircle(center, _r + 7,
          Paint()
            ..color = AppColors.success
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }

    c.drawCircle(center, _r, Paint()..color = fill);

    c.drawArc(
      Rect.fromCircle(center: Offset(center.dx, center.dy - 4), radius: _r),
      -math.pi * 0.9, math.pi * 0.8, false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: state,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: _r * 2 - 6);
    tp.paint(c, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  void paint(Canvas c, Size size) {
    final pos = _positions(size);

    c.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color =
            isDark ? const Color(0xFF161822) : const Color(0xFFF8FAFC),
    );

    final gp = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      c.drawLine(Offset(x, 0), Offset(x, size.height), gp);
    }
    for (double y = 0; y < size.height; y += 40) {
      c.drawLine(Offset(0, y), Offset(size.width, y), gp);
    }

    final edgeKeys = <String>{
      for (final e in edges) '${e['from']}->${e['to']}'
    };
    final drawn = <String>{};
    final ec    = AppColors.primary.withValues(alpha: 0.75);

    for (final edge in edges) {
      final from = edge['from'] as String;
      final to   = edge['to']   as String;
      final cond = edge['label'] as String?;
      final fp   = pos[from];
      final tp_  = pos[to];
      if (fp == null || tp_ == null) continue;

      if (from == to) { _selfLoop(c, fp, cond, ec); continue; }

      final hasRev = edgeKeys.contains('$to->$from');
      final key    = ([from, to]..sort()).join('|');
      final second = drawn.contains(key);
      drawn.add(key);
      _drawEdge(c, fp, tp_, cond, curve: hasRev, flip: second, color: ec);
    }

    for (final state in states) {
      final p = pos[state];
      if (p != null) _drawNode(c, state, p);
    }
  }

  @override
  bool shouldRepaint(covariant _NlFsmPainter old) =>
      old.states        != states        ||
      old.edges         != edges         ||
      old.selectedState != selectedState ||
      old.isDark        != isDark;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Coverage Dashboard tab
// ═══════════════════════════════════════════════════════════════════════════════

class _CoverageTab extends StatefulWidget {
  final CoverageReport? report;
  const _CoverageTab({required this.report});

  @override
  State<_CoverageTab> createState() => _CoverageTabState();
}

class _CoverageTabState extends State<_CoverageTab> {
  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    if (report == null) {
      return _buildEmpty(context);
    }

    final r = report.result;
    final m = report.metrics;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Overall grade banner ────────────────────────────────────────
          _buildGradeBanner(context, report),
          const SizedBox(height: 16),

          // ── Metric progress bars ────────────────────────────────────────
          _buildSectionHeader(context, Icons.speed_rounded, 'Coverage Metrics'),
          const SizedBox(height: 10),
          _CoverageBar(label: 'State',      value: r.stateCoverage,      covered: m.visitedStateCount,       total: m.totalStates),
          _CoverageBar(label: 'Transition', value: r.transitionCoverage, covered: m.executedTransitionCount, total: m.totalTransitions),
          _CoverageBar(label: 'Branch',     value: r.branchCoverage,     covered: m.coveredBranchCount,      total: m.totalBranches),
          _CoverageBar(label: 'Toggle',     value: r.toggleCoverage,     covered: m.toggledSignalCount,      total: m.totalSignals),
          _CoverageBar(label: 'Condition',  value: r.conditionCoverage,  covered: m.evaluatedConditionCount, total: m.totalConditions),
          _CoverageBar(label: 'Line',       value: r.lineCoverage,       covered: m.executedLineCount,       total: m.totalLines),
          const SizedBox(height: 20),

          // ── Gap lists ───────────────────────────────────────────────────
          if (r.unvisitedStates.isNotEmpty) ...[
            _buildSectionHeader(context, Icons.circle_outlined, 'Unvisited States'),
            const SizedBox(height: 8),
            _GapList(items: r.unvisitedStates, color: AppColors.warning),
            const SizedBox(height: 16),
          ],
          if (r.untakenTransitions.isNotEmpty) ...[
            _buildSectionHeader(context, Icons.arrow_forward_rounded, 'Missing Transitions'),
            const SizedBox(height: 8),
            _GapList(items: r.untakenTransitions, color: AppColors.orange),
            const SizedBox(height: 16),
          ],
          if (r.untoggledSignals.isNotEmpty) ...[
            _buildSectionHeader(context, Icons.toggle_off_rounded, 'Untoggled Signals'),
            const SizedBox(height: 8),
            _GapList(items: r.untoggledSignals, color: AppColors.info),
            const SizedBox(height: 16),
          ],
          if (r.uncoveredBranches.isNotEmpty) ...[
            _buildSectionHeader(context, Icons.call_split_rounded, 'Uncovered Branches'),
            const SizedBox(height: 8),
            _GapList(items: r.uncoveredBranches, color: AppColors.teal),
            const SizedBox(height: 16),
          ],
          if (r.uncoveredConditions.isNotEmpty) ...[
            _buildSectionHeader(context, Icons.rule_rounded, 'Partial Conditions'),
            const SizedBox(height: 8),
            _GapList(items: r.uncoveredConditions, color: AppColors.primary),
            const SizedBox(height: 16),
          ],

          // ── Heatmap ─────────────────────────────────────────────────────
          if (report.heatMap.stateHeat.isNotEmpty) ...[
            _buildSectionHeader(context, Icons.grid_view_rounded, 'State Heat Map'),
            const SizedBox(height: 10),
            _StateHeatMap(heatData: report.heatMap.stateHeat),
            const SizedBox(height: 16),
          ],

          // ── Export ──────────────────────────────────────────────────────
          _buildSectionHeader(context, Icons.download_rounded, 'Export Report'),
          const SizedBox(height: 10),
          _ExportBar(report: report),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 48,
              color: context.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No Coverage Data',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: context.textPrimary)),
          const SizedBox(height: 8),
          Text('Simulation did not produce coverage data.\nVerify Icarus Verilog is installed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildGradeBanner(BuildContext context, CoverageReport report) {
    final color = _coverageColor(report.overallCoverage);
    final pct   = (report.overallCoverage * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text('$pct%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                  )),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.grade,
                    style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 4),
                Text('${report.totalGaps} gap${report.totalGaps != 1 ? "s" : ""} · '
                    '${report.coverageWarnings.length} warning${report.coverageWarnings.length != 1 ? "s" : ""}',
                    style: TextStyle(fontSize: 12.5, color: context.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.textSecondary),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700,
              color: context.textSecondary, letterSpacing: 0.3)),
      ],
    );
  }

  static Color _coverageColor(double v) {
    if (v >= 0.95) return AppColors.success;
    if (v >= 0.80) return AppColors.teal;
    if (v >= 0.60) return AppColors.warning;
    if (v >= 0.40) return AppColors.orange;
    return AppColors.error;
  }
}

// ─── Coverage progress bar ────────────────────────────────────────────────────

class _CoverageBar extends StatelessWidget {
  final String label;
  final double value;
  final int covered;
  final int total;

  const _CoverageBar({
    required this.label,
    required this.value,
    required this.covered,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct   = (value * 100).toStringAsFixed(1);
    final color = _colorFor(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 76,
                child: Text(label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    )),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: context.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 48,
                child: Text('$pct%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
              ),
              const SizedBox(width: 8),
              Text('$covered/$total',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  static Color _colorFor(double v) {
    if (v >= 0.80) return AppColors.success;
    if (v >= 0.60) return AppColors.teal;
    if (v >= 0.40) return AppColors.warning;
    return AppColors.error;
  }
}

// ─── Gap list ─────────────────────────────────────────────────────────────────

class _GapList extends StatelessWidget {
  final List<String> items;
  final Color color;
  const _GapList({required this.items, required this.color});

  List<Widget> _buildRows(BuildContext context) {
    final visible = items.take(12).toList();
    final rows    = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(visible[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: context.textPrimary,
                  )),
            ),
          ],
        ),
      ));
      if (i < visible.length - 1 || items.length > 12) {
        rows.add(Container(height: 1, color: context.border));
      }
    }
    if (items.length > 12) {
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text('… and ${items.length - 12} more',
            style: TextStyle(
              fontSize: 11.5,
              color: context.textSecondary,
              fontStyle: FontStyle.italic,
            )),
      ));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: _buildRows(context),
      ),
    );
  }
}

// ─── State heat map ───────────────────────────────────────────────────────────

class _StateHeatMap extends StatelessWidget {
  final Map<String, double> heatData;
  const _StateHeatMap({required this.heatData});

  @override
  Widget build(BuildContext context) {
    final entries = heatData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) {
        final heat  = e.value.clamp(0.0, 1.0);
        final color = Color.lerp(AppColors.error, AppColors.success, heat)!;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(e.key,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  )),
              const SizedBox(width: 4),
              Text('${(heat * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.8),
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Export bar ───────────────────────────────────────────────────────────────

class _ExportBar extends StatelessWidget {
  final CoverageReport report;
  const _ExportBar({required this.report});

  void _copy(BuildContext context, String content, String label) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label copied to clipboard'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ExportButton(
          label: 'JSON',
          icon: Icons.data_object_rounded,
          color: AppColors.teal,
          onTap: () => _copy(context, report.toJson(), 'JSON report'),
        ),
        const SizedBox(width: 8),
        _ExportButton(
          label: 'CSV',
          icon: Icons.table_chart_rounded,
          color: AppColors.success,
          onTap: () => _copy(context, report.toCsv(), 'CSV report'),
        ),
        const SizedBox(width: 8),
        _ExportButton(
          label: 'Markdown',
          icon: Icons.article_rounded,
          color: AppColors.primary,
          onTap: () => _copy(context, report.toMarkdown(), 'Markdown report'),
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ExportButton({
    required this.label, required this.icon,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
