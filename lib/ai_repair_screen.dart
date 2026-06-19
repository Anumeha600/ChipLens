import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'backend/repair/repair.dart';
import 'models/design_spec.dart';
import 'theme/app_theme.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class AiRepairScreen extends StatefulWidget {
  final DesignResult originalResult;
  const AiRepairScreen({super.key, required this.originalResult});

  @override
  State<AiRepairScreen> createState() => _AiRepairScreenState();
}

// ─── Screen state ─────────────────────────────────────────────────────────────

enum _Phase { ready, applying, done }

class _AiRepairScreenState extends State<AiRepairScreen>
    with TickerProviderStateMixin {
  late List<RepairSuggestion> _suggestions;
  final Set<String> _selected = {};
  _Phase _phase = _Phase.ready;
  RepairResult? _result;
  TabController? _tabCtrl;

  @override
  void initState() {
    super.initState();
    _suggestions = RepairEngine.suggest(
      rtlSource:      widget.originalResult.rtl,
      warnings:       widget.originalResult.quality.warnings,
      coverageReport: widget.originalResult.coverageReport,
    );
    // Pre-select all auto-fixable suggestions
    for (final s in _suggestions) {
      if (s.isAutoFixable) _selected.add(s.ruleId + s.originalCode.hashCode.toString());
    }
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    super.dispose();
  }

  String _keyOf(RepairSuggestion s) =>
      s.ruleId + s.originalCode.hashCode.toString();

  bool _isSelected(RepairSuggestion s) => _selected.contains(_keyOf(s));

  void _toggle(RepairSuggestion s) {
    if (!s.isAutoFixable) return;
    setState(() {
      if (!_selected.remove(_keyOf(s))) _selected.add(_keyOf(s));
    });
  }

  List<RepairSuggestion> get _chosenSuggestions =>
      _suggestions.where((s) => _isSelected(s)).toList();

  Future<void> _applyRepair() async {
    final chosen = _chosenSuggestions;
    if (chosen.isEmpty) return;

    setState(() => _phase = _Phase.applying);

    final result = await RepairEngine.repair(
      originalRtl:   widget.originalResult.rtl,
      suggestions:   chosen,
      spec:          widget.originalResult.spec,
      qualityBefore: widget.originalResult.quality,
    );

    if (!mounted) return;
    final tc = TabController(length: 2, vsync: this);
    setState(() {
      _result   = result;
      _phase    = _Phase.done;
      _tabCtrl  = tc;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildQualityHeader(context)),
          if (_phase == _Phase.ready || _phase == _Phase.applying) ...[
            SliverToBoxAdapter(child: _buildSuggestionList(context)),
          ],
          if (_phase == _Phase.done && _result != null) ...[
            SliverToBoxAdapter(child: _buildResultPanel(context)),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _phase != _Phase.done
          ? _buildApplyBar(context)
          : null,
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: context.isDark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.auto_fix_high_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text('AI Repair',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              )),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: context.border),
      ),
    );
  }

  // ── Quality header ─────────────────────────────────────────────────────────

  Widget _buildQualityHeader(BuildContext context) {
    final before = widget.originalResult.quality.total;
    final after  = _result?.qualityAfter.round();
    final fixed  = _result?.issuesFixed ?? 0;
    final remain = _result?.remainingIssues ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          children: [
            _QualityPill(score: before, label: 'Before', color: _scoreColor(before)),
            if (_result != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: context.textSecondary),
              ),
              _QualityPill(
                  score: after!, label: 'After',
                  color: _scoreColor(after)),
            ] else ...[
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_suggestions.length} suggestions generated',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: context.textPrimary)),
                    const SizedBox(height: 3),
                    Text('${_suggestions.where((s) => s.isAutoFixable).length} auto-fixable  ·  '
                        '${widget.originalResult.quality.warningCount} issues',
                        style: TextStyle(
                            fontSize: 12, color: context.textSecondary)),
                  ],
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.check_circle_rounded,
                          size: 13, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('$fixed fixed',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600,
                              color: AppColors.success)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 13,
                          color: remain == 0 ? AppColors.success : AppColors.warning),
                      const SizedBox(width: 4),
                      Text('$remain remaining',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600,
                              color: remain == 0
                                  ? AppColors.success
                                  : AppColors.warning)),
                    ]),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Suggestion list ────────────────────────────────────────────────────────

  Widget _buildSuggestionList(BuildContext context) {
    if (_suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.border),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 36, color: AppColors.success),
              const SizedBox(height: 12),
              Text('No issues detected',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: context.textPrimary)),
              const SizedBox(height: 6),
              Text('The RTL passed all quality checks.',
                  style: TextStyle(
                      fontSize: 13, color: context.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 20,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text('Suggested Repairs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.3,
                  )),
              const Spacer(),
              Text('${_chosenSuggestions.length}/${_suggestions.length} selected',
                  style: TextStyle(
                      fontSize: 12, color: context.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ..._suggestions.map((s) => _RepairCard(
            suggestion:  s,
            isSelected:  _isSelected(s),
            onToggle:    () => _toggle(s),
            isApplying:  _phase == _Phase.applying,
          )),

          // Original RTL section
          const SizedBox(height: 8),
          _OriginalRtlSection(rtl: widget.originalResult.rtl),
        ],
      ),
    );
  }

  // ── Result panel ───────────────────────────────────────────────────────────

  Widget _buildResultPanel(BuildContext context) {
    final r = _result!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quality delta banner
          _QualityDeltaBanner(result: r),
          const SizedBox(height: 16),

          // Tabs: Diff | Repaired RTL
          Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border),
            ),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: false,
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
              tabs: const [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.compare_arrows_rounded, size: 14),
                  SizedBox(width: 5), Text('Diff View'),
                ])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.code_rounded, size: 14),
                  SizedBox(width: 5), Text('Repaired RTL'),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 480,
            child: TabBarView(
              controller: _tabCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DiffViewer(
                    before: widget.originalResult.rtl,
                    after:  r.repairedRTL),
                _CodeViewer(code: r.repairedRTL, label: 'Repaired RTL'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Apply bar (bottom) ─────────────────────────────────────────────────────

  Widget _buildApplyBar(BuildContext context) {
    final count = _chosenSuggestions.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: _phase == _Phase.applying
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
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Text('Re-running analysis…',
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
                    gradient: count > 0
                        ? AppGradients.primary
                        : LinearGradient(
                            colors: [
                              context.textSecondary.withValues(alpha: 0.3),
                              context.textSecondary.withValues(alpha: 0.3),
                            ]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: count > 0
                        ? AppShadows.glow(AppColors.primary)
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: count > 0 ? _applyRepair : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_fix_high_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              count > 0
                                  ? 'Apply $count Repair${count > 1 ? "s" : ""}'
                                  : 'Select repairs to apply',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  static Color _scoreColor(int s) {
    if (s >= 90) return AppColors.success;
    if (s >= 75) return AppColors.teal;
    if (s >= 60) return AppColors.warning;
    if (s >= 40) return AppColors.orange;
    return AppColors.error;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Repair suggestion card
// ═══════════════════════════════════════════════════════════════════════════════

class _RepairCard extends StatefulWidget {
  final RepairSuggestion suggestion;
  final bool isSelected;
  final VoidCallback onToggle;
  final bool isApplying;

  const _RepairCard({
    required this.suggestion,
    required this.isSelected,
    required this.onToggle,
    required this.isApplying,
  });

  @override
  State<_RepairCard> createState() => _RepairCardState();
}

class _RepairCardState extends State<_RepairCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s       = widget.suggestion;
    final canFix  = s.isAutoFixable;
    final conf    = s.confidence;
    final confColor = conf >= 0.85
        ? AppColors.success
        : conf >= 0.60
            ? AppColors.warning
            : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected && canFix
                ? AppColors.primary.withValues(alpha: 0.35)
                : context.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            InkWell(
              onTap: canFix && !widget.isApplying ? widget.onToggle : null,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (canFix)
                      Padding(
                        padding: const EdgeInsets.only(top: 1, right: 10),
                        child: Icon(
                          widget.isSelected
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 18,
                          color: widget.isSelected
                              ? AppColors.primary
                              : context.textSecondary,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 1, right: 10),
                        child: Icon(Icons.info_outline_rounded,
                            size: 18, color: AppColors.info),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              )),
                          const SizedBox(height: 4),
                          Text(s.explanation,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                  height: 1.45),
                              maxLines: _expanded ? 100 : 2,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: confColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                color: confColor.withValues(alpha: 0.3)),
                          ),
                          child: Text('${s.confidenceLabel} '
                              '(${(conf * 100).round()}%)',
                              style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: confColor)),
                        ),
                        if (!canFix) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text('Manual',
                                style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.info)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Code diff preview (auto-fixable only) ───────────────────
            if (canFix) ...[
              Container(height: 1, color: context.border),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Text('Code change',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 14, color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                Container(height: 1, color: context.border),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _InlineDiff(
                      before: s.originalCode,
                      after:  s.replacementCode),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Inline diff (before/after for a single suggestion)
// ═══════════════════════════════════════════════════════════════════════════════

class _InlineDiff extends StatelessWidget {
  final String before;
  final String after;
  const _InlineDiff({required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DiffSection(label: 'Before', code: before,
            color: AppColors.error, isDark: isDark),
        const SizedBox(height: 6),
        _DiffSection(label: 'After', code: after,
            color: AppColors.success, isDark: isDark),
      ],
    );
  }
}

class _DiffSection extends StatelessWidget {
  final String label;
  final String code;
  final Color color;
  final bool isDark;
  const _DiffSection({
    required this.label, required this.code,
    required this.color, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 3),
            child: Text(label,
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.4)),
          ),
          Container(height: 1, color: color.withValues(alpha: 0.15)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Text(
              code.trim(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                height: 1.55,
                color: isDark
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Original RTL section (collapsible)
// ═══════════════════════════════════════════════════════════════════════════════

class _OriginalRtlSection extends StatefulWidget {
  final String rtl;
  const _OriginalRtlSection({required this.rtl});

  @override
  State<_OriginalRtlSection> createState() => _OriginalRtlSectionState();
}

class _OriginalRtlSectionState extends State<_OriginalRtlSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Icon(Icons.code_rounded, size: 14, color: context.textSecondary),
                  const SizedBox(width: 8),
                  Text('Original RTL',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: context.textPrimary)),
                  const Spacer(),
                  Text('${widget.rtl.split('\n').length} lines',
                      style: TextStyle(
                          fontSize: 11, color: context.textSecondary)),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16, color: context.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Container(height: 1, color: context.border),
            SizedBox(
              height: 280,
              child: _CodeViewer(code: widget.rtl, label: 'Original RTL'),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Quality delta banner (shown after repair)
// ═══════════════════════════════════════════════════════════════════════════════

class _QualityDeltaBanner extends StatelessWidget {
  final RepairResult result;
  const _QualityDeltaBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final delta    = result.qualityDelta;
    final improved = delta > 0;
    final color    = improved ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            improved
                ? Icons.trending_up_rounded
                : Icons.trending_flat_rounded,
            size: 28, color: color,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  improved
                      ? 'Quality improved by ${delta.abs().round()} points'
                      : 'Quality unchanged',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.issuesFixed} issue${result.issuesFixed != 1 ? "s" : ""} fixed  ·  '
                  '${result.remainingIssues} remaining',
                  style: TextStyle(
                      fontSize: 12.5, color: context.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${result.qualityBefore.round()}',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: _scoreColor(result.qualityBefore.round()))),
              Icon(Icons.arrow_downward_rounded,
                  size: 12, color: context.textSecondary),
              Text('${result.qualityAfter.round()}',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900,
                      color: _scoreColor(result.qualityAfter.round()))),
            ],
          ),
        ],
      ),
    );
  }

  static Color _scoreColor(int s) {
    if (s >= 90) return AppColors.success;
    if (s >= 75) return AppColors.teal;
    if (s >= 60) return AppColors.warning;
    if (s >= 40) return AppColors.orange;
    return AppColors.error;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Full diff viewer (LCS-based line diff)
// ═══════════════════════════════════════════════════════════════════════════════

enum _DiffType { same, added, removed }

class _DiffEntry {
  final String line;
  final _DiffType type;
  const _DiffEntry(this.line, this.type);
}

class _DiffViewer extends StatelessWidget {
  final String before;
  final String after;
  const _DiffViewer({required this.before, required this.after});

  static List<_DiffEntry> _computeDiff(String a, String b) {
    final aLines = a.split('\n');
    final bLines = b.split('\n');
    final n = aLines.length, m = bLines.length;

    // LCS table — O(n*m) — fine for typical RTL sizes
    final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        dp[i][j] = aLines[i - 1] == bLines[j - 1]
            ? dp[i - 1][j - 1] + 1
            : math.max(dp[i - 1][j], dp[i][j - 1]);
      }
    }

    // Backtrack
    final result = <_DiffEntry>[];
    var i = n, j = m;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && aLines[i - 1] == bLines[j - 1]) {
        result.add(_DiffEntry(aLines[i - 1], _DiffType.same));
        i--; j--;
      } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
        result.add(_DiffEntry(bLines[j - 1], _DiffType.added));
        j--;
      } else {
        result.add(_DiffEntry(aLines[i - 1], _DiffType.removed));
        i--;
      }
    }
    return result.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final diff   = _computeDiff(before, after);
    final isDark = context.isDark;
    final added   = diff.where((d) => d.type == _DiffType.added).length;
    final removed = diff.where((d) => d.type == _DiffType.removed).length;

    return Column(
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2030) : const Color(0xFFF1F5F9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: context.border),
          ),
          child: Row(
            children: [
              Text('+$added', style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.success, fontFamily: 'monospace')),
              const SizedBox(width: 10),
              Text('-$removed', style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.error, fontFamily: 'monospace')),
              const Spacer(),
              Text('${diff.length} lines total',
                  style: TextStyle(
                      fontSize: 11, color: context.textSecondary)),
            ],
          ),
        ),
        // Lines
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
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: diff.length,
              itemBuilder: (_, idx) {
                final entry = diff[idx];
                Color? bg;
                String prefix;
                Color textColor;

                switch (entry.type) {
                  case _DiffType.added:
                    bg       = AppColors.success.withValues(alpha: 0.10);
                    prefix   = '+ ';
                    textColor = isDark
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFF166534);
                  case _DiffType.removed:
                    bg       = AppColors.error.withValues(alpha: 0.08);
                    prefix   = '- ';
                    textColor = isDark
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFF991B1B);
                  case _DiffType.same:
                    bg        = null;
                    prefix    = '  ';
                    textColor = isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B);
                }

                return Container(
                  color: bg,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 1),
                  child: Text(
                    '$prefix${entry.line}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.6,
                      color: textColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Simple code viewer with copy button
// ═══════════════════════════════════════════════════════════════════════════════

class _CodeViewer extends StatelessWidget {
  final String code;
  final String label;
  const _CodeViewer({required this.code, required this.label});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label copied to clipboard'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final lines  = code.split('\n').length;

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2030) : const Color(0xFFF1F5F9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: context.border),
          ),
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600,
                      color: context.textSecondary)),
              const Spacer(),
              Text('$lines lines',
                  style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondary.withValues(alpha: 0.7))),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _copy(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 11, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Copy',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Code body
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
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.65,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Quality pill badge
// ═══════════════════════════════════════════════════════════════════════════════

class _QualityPill extends StatelessWidget {
  final int score;
  final String label;
  final Color color;
  const _QualityPill(
      {required this.score, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$score',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}
