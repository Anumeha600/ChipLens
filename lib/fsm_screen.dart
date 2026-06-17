import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/local_fsm_extractor.dart';
import 'theme/app_theme.dart';

class FsmScreen extends StatefulWidget {
  final String code;
  const FsmScreen({super.key, required this.code});

  @override
  State<FsmScreen> createState() => _FsmScreenState();
}

class _FsmScreenState extends State<FsmScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _result;

  final TransformationController _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _fetchFsm();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchFsm() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await RtlApiService.fetchFsm(widget.code);
      if (!mounted) return;
      setState(() { _result = data; _loading = false; });
    } catch (_) {
      // Backend unavailable or returned no FSM — fall back to on-device extraction.
      if (!mounted) return;
      final local = LocalFsmExtractor.extract(widget.code);
      setState(() { _result = local; _loading = false; });
    }
  }

  // ── Accessors ──────────────────────────────────────────────────────────────

  List<String> get _states =>
      List<String>.from(_result?['states'] ?? []);

  List<Map<String, dynamic>> get _edges =>
      ((_result?['edges'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  Set<String> get _unreachable =>
      Set<String>.from(_result?['unreachableStates'] ?? []);

  Set<String> get _dead =>
      Set<String>.from(_result?['deadStates'] ?? []);

  String? get _entryState => _result?['entryState'] as String?;

  Map<String, dynamic>? get _complexity =>
      _result?['complexity'] as Map<String, dynamic>?;

  String get _encodingStyle =>
      (_result?['encodingStyle'] as String?) ?? 'unknown';

  List<Map<String, dynamic>> get _stateStats =>
      ((_result?['stateStats'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  // ── Zoom helpers ───────────────────────────────────────────────────────────

  void _zoom(double factor) {
    final m = _transformCtrl.value.clone();
    final s = m.getMaxScaleOnAxis();
    final newS = (s * factor).clamp(0.3, 4.0);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    _transformCtrl.value = Matrix4.identity()
      ..setEntry(0, 0, newS)
      ..setEntry(1, 1, newS)
      ..setEntry(0, 3, (w / 2) * (1 - newS))
      ..setEntry(1, 3, (h / 2) * (1 - newS));
  }

  void _resetZoom() => _transformCtrl.value = Matrix4.identity();

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('FSM Visualizer'),
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'State details',
              onPressed: _showStatsSheet,
            ),
        ],
      ),
      body: _loading
          ? _buildLoadingView()
          : _error != null
              ? _buildErrorView()
              : _buildGraph(),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.glow(AppColors.primary),
            ),
            child: const Icon(Icons.account_tree, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            'Extracting State Machine',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Analyzing FSM transitions…',
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error view ─────────────────────────────────────────────────────────────

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
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.wifi_off_outlined,
                  size: 34, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(
              'FSM Extraction Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
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
                _error ?? 'An unexpected error occurred.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: context.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetchFsm,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
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

  // ── Graph view ─────────────────────────────────────────────────────────────

  Widget _buildGraph() {
    final states     = _states;
    final edges      = _edges;
    final unreachable = _unreachable;
    final dead       = _dead;
    final entry      = _entryState;

    if (states.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.border),
              ),
              child: Icon(Icons.account_tree_outlined,
                  size: 38, color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'No FSM Detected',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Declare state names with parameter or localparam.',
              style: TextStyle(
                  color: context.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Count self-loops
    final selfLoops = edges.where((e) => e['from'] == e['to']).length;

    return Column(
      children: [
        // Alert banners
        if (unreachable.isNotEmpty)
          _AlertBanner(
            icon: Icons.block_outlined,
            text: 'Unreachable: ${unreachable.join(', ')}',
            color: AppColors.errorDark,
          ),
        if (dead.isNotEmpty)
          _AlertBanner(
            icon: Icons.warning_amber_outlined,
            text: 'Dead states (no outgoing): ${dead.join(', ')}',
            color: AppColors.orange,
          ),

        // FSM overview stats
        _buildOverviewRow(
          states.length,
          edges.length,
          entry != null ? 1 : 0,
          dead.length,
          selfLoops,
        ),

        // Diagram card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Container(
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border),
                boxShadow: context.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _transformCtrl,
                      boundaryMargin: const EdgeInsets.all(120),
                      minScale: 0.3,
                      maxScale: 4.0,
                      child: Center(
                        child: SizedBox(
                          width: 540,
                          height: 540,
                          child: CustomPaint(
                            painter: FsmPainter(
                              states: states,
                              edges: edges,
                              unreachableStates: unreachable,
                              deadStates: dead,
                              entryState: entry,
                              isDark: context.isDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Zoom controls
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _buildZoomControls(),
                    ),
                    // Pinch hint
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.surface2,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: context.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_outlined,
                                size: 12, color: context.textSecondary),
                            const SizedBox(width: 4),
                            Text('Pinch & drag',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: context.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Footer
        _buildFooter(states.length, edges.length),

        // Legend
        _buildLegend(entry != null, dead.isNotEmpty, unreachable.isNotEmpty),

        const SizedBox(height: 8),
      ],
    );
  }

  // ── Overview stats row ─────────────────────────────────────────────────────

  Widget _buildOverviewRow(int states, int transitions, int entry, int dead, int selfLoops) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(child: _StatCard(label: 'States', value: '$states', color: AppColors.primary, icon: Icons.circle_outlined)),
          const SizedBox(width: 8),
          Expanded(child: _StatCard(label: 'Transitions', value: '$transitions', color: AppColors.teal, icon: Icons.arrow_forward_outlined)),
          const SizedBox(width: 8),
          Expanded(child: _StatCard(label: 'Entry', value: '$entry', color: AppColors.success, icon: Icons.play_circle_outline)),
          const SizedBox(width: 8),
          Expanded(child: _StatCard(label: 'Dead', value: '$dead', color: dead > 0 ? AppColors.orange : context.textSecondary, icon: Icons.block_outlined)),
          const SizedBox(width: 8),
          Expanded(child: _StatCard(label: 'Self-loops', value: '$selfLoops', color: AppColors.info, icon: Icons.loop_outlined)),
        ],
      ),
    );
  }

  // ── Zoom controls ──────────────────────────────────────────────────────────

  Widget _buildZoomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomBtn(icon: Icons.add, tooltip: 'Zoom in',   onTap: () => _zoom(1.3)),
        const SizedBox(height: 4),
        _ZoomBtn(icon: Icons.remove, tooltip: 'Zoom out', onTap: () => _zoom(0.77)),
        const SizedBox(height: 4),
        _ZoomBtn(icon: Icons.fit_screen, tooltip: 'Reset', onTap: _resetZoom),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(int stateCount, int edgeCount) {
    final label = _complexity?['label'] as String? ?? '';
    final cyclo = _complexity?['cyclomatic'];
    final enc   = _encodingStyle;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 4,
        children: [
          _FooterChip('$stateCount states', Icons.circle_outlined),
          _FooterChip('$edgeCount transitions', Icons.arrow_forward_outlined),
          if (label.isNotEmpty)
            _FooterChip(
              cyclo != null ? '$label · CC=$cyclo' : label,
              Icons.analytics_outlined,
            ),
          if (enc != 'unknown') _FooterChip(enc, Icons.memory_outlined),
        ],
      ),
    );
  }

  // ── Legend ─────────────────────────────────────────────────────────────────

  Widget _buildLegend(bool hasEntry, bool hasDead, bool hasUnreachable) {
    if (!hasEntry && !hasDead && !hasUnreachable) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      color: context.surface,
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          if (hasEntry)
            _LegendDot('Entry state', AppColors.success),
          if (hasDead)
            _LegendDot('Dead state', AppColors.orange),
          if (hasUnreachable)
            _LegendDot('Unreachable', AppColors.errorDark),
        ],
      ),
    );
  }

  // ── State details bottom sheet ─────────────────────────────────────────────

  void _showStatsSheet() {
    final stats = _stateStats;
    final entry = _entryState;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.88,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Text('State Details',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                  const Spacer(),
                  if (_complexity != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter
                            .withValues(alpha: context.isDark ? 0.15 : 1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${_complexity!['label']} · CC=${_complexity!['cyclomatic']}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            Divider(color: context.border, height: 1),
            Expanded(
              child: stats.isEmpty
                  ? Center(
                      child: Text('No state data',
                          style: TextStyle(color: context.textSecondary)),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      itemCount: stats.length,
                      separatorBuilder: (_, i) =>
                          Divider(height: 1, indent: 16, endIndent: 16, color: context.border),
                      itemBuilder: (_, i) =>
                          _buildStatRow(stats[i], entry),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(Map<String, dynamic> stat, String? entry) {
    final name      = stat['name']          as String? ?? '';
    final isEntry   = stat['isEntry']       as bool?   ?? false;
    final isDead    = stat['isDead']        as bool?   ?? false;
    final isUnreach = stat['isUnreachable'] as bool?   ?? false;
    final inDeg     = stat['inDegree']      as int?    ?? 0;
    final outDeg    = stat['outDegree']     as int?    ?? 0;

    Color nodeColor;
    if (isUnreach) {
      nodeColor = AppColors.errorDark;
    } else if (isDead) {
      nodeColor = AppColors.orange;
    } else if (isEntry) {
      nodeColor = AppColors.success;
    } else {
      nodeColor = AppColors.primary;
    }

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: nodeColor,
          shape: BoxShape.circle,
          boxShadow: AppShadows.glow(nodeColor),
        ),
        child: Center(
          child: Text(
            name.length > 3 ? name.substring(0, 2) : name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(name,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: context.textPrimary)),
          ),
          const SizedBox(width: 6),
          if (isEntry)
            _StateBadge('ENTRY', AppColors.success),
          if (isDead)
            _StateBadge('DEAD', AppColors.orange),
          if (isUnreach)
            _StateBadge('UNREACHABLE', AppColors.errorDark),
        ],
      ),
      subtitle: Text(
        'In: $inDeg  ·  Out: $outDeg',
        style: TextStyle(fontSize: 12, color: context.textSecondary),
      ),
    );
  }
}

// ─── Overview stat card ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: TextStyle(fontSize: 9, color: context.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Alert banner ─────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _AlertBanner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ─── Zoom button ──────────────────────────────────────────────────────────────

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.surface,
        borderRadius: BorderRadius.circular(9),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

// ─── Footer chip ──────────────────────────────────────────────────────────────

class _FooterChip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _FooterChip(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: context.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: context.textSecondary)),
      ],
    );
  }
}

// ─── Legend dot ───────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(fontSize: 11, color: context.textSecondary)),
      ],
    );
  }
}

// ─── State badge ──────────────────────────────────────────────────────────────

class _StateBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StateBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }
}

// ─── CustomPainter ────────────────────────────────────────────────────────────

class FsmPainter extends CustomPainter {
  final List<String> states;
  final List<Map<String, dynamic>> edges;
  final Set<String> unreachableStates;
  final Set<String> deadStates;
  final String? entryState;
  final bool isDark;

  static const double _r     = 32.0;
  static const double _arrow = 10.0;

  const FsmPainter({
    required this.states,
    required this.edges,
    required this.unreachableStates,
    this.deadStates = const {},
    this.entryState,
    this.isDark = false,
  });

  Map<String, Offset> _positions(Size size) {
    final n = states.length;
    final positions = <String, Offset>{};
    if (n == 0) return positions;
    if (n == 1) {
      positions[states[0]] = Offset(size.width / 2, size.height / 2);
      return positions;
    }
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - _r - 20;
    for (int i = 0; i < n; i++) {
      final angle = 2 * math.pi * i / n - math.pi / 2;
      positions[states[i]] = Offset(
        cx + radius * math.cos(angle),
        cy + radius * math.sin(angle),
      );
    }
    return positions;
  }

  Color _nodeColor(String state) {
    if (unreachableStates.contains(state)) { return AppColors.errorDark; }
    if (deadStates.contains(state))        { return AppColors.orange; }
    if (state == entryState)               { return AppColors.success; }
    return AppColors.primary;
  }

  void _arrowHead(Canvas canvas, Offset tip, double angle, Color color) {
    const spread = math.pi / 7;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - _arrow * math.cos(angle - spread),
               tip.dy - _arrow * math.sin(angle - spread))
      ..lineTo(tip.dx - _arrow * math.cos(angle + spread),
               tip.dy - _arrow * math.sin(angle + spread))
      ..close();
    canvas.drawPath(
        path, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _edgeLabel(Canvas canvas, String text, Offset pos) {
    final style = TextStyle(
      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF374151),
      fontSize: 9.5,
      fontWeight: FontWeight.w500,
    );
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = Rect.fromCenter(
      center: pos,
      width: tp.width + 10,
      height: tp.height + 5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()..color = isDark ? const Color(0xFF1E2030) : Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()
        ..color = isDark ? const Color(0xFF2A2D3E) : const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawEdge(
    Canvas canvas,
    Offset fromCenter,
    Offset toCenter,
    String? condition, {
    required bool curve,
    required bool flipCurve,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final dx   = toCenter.dx - fromCenter.dx;
    final dy   = toCenter.dy - fromCenter.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return;
    final nx = dx / dist;
    final ny = dy / dist;

    final start = Offset(fromCenter.dx + nx * _r, fromCenter.dy + ny * _r);
    final end   = Offset(toCenter.dx - nx * _r, toCenter.dy - ny * _r);
    final tip   = Offset(toCenter.dx - nx * (_r - 1), toCenter.dy - ny * (_r - 1));

    if (curve) {
      final midX    = (start.dx + end.dx) / 2;
      final midY    = (start.dy + end.dy) / 2;
      final perpMag = flipCurve ? -52.0 : 52.0;
      final ctrl    = Offset(midX - ny * perpMag, midY + nx * perpMag);

      canvas.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy),
        paint,
      );
      final headAngle = math.atan2(end.dy - ctrl.dy, end.dx - ctrl.dx);
      _arrowHead(canvas, tip, headAngle, color);

      if (condition != null && condition.isNotEmpty) {
        _edgeLabel(canvas, condition, Offset(
          (start.dx + 2 * ctrl.dx + end.dx) / 4,
          (start.dy + 2 * ctrl.dy + end.dy) / 4 - 12,
        ));
      }
    } else {
      canvas.drawLine(start, end, paint);
      _arrowHead(canvas, tip, math.atan2(dy, dx), color);
      if (condition != null && condition.isNotEmpty) {
        _edgeLabel(canvas, condition,
            Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 - 12));
      }
    }
  }

  void _drawSelfLoop(Canvas canvas, Offset center, String? condition, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final loopCenter = Offset(center.dx, center.dy - _r - 22);
    canvas.drawCircle(loopCenter, 18, paint);
    _arrowHead(canvas, Offset(center.dx + 3, center.dy - _r - 5),
        math.pi / 2 + 0.5, color);
    if (condition != null && condition.isNotEmpty) {
      _edgeLabel(canvas, condition, Offset(center.dx, center.dy - _r - 48));
    }
  }

  void _drawNode(Canvas canvas, String state, Offset center) {
    final fill    = _nodeColor(state);
    final isEntry = state == entryState;
    final isDead2 = deadStates.contains(state);

    // Shadow
    canvas.drawCircle(
      center + const Offset(1, 2),
      _r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Entry ring
    if (isEntry) {
      canvas.drawCircle(
        center,
        _r + 7,
        Paint()
          ..color = AppColors.success
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Dead ring
    if (isDead2 && !unreachableStates.contains(state)) {
      canvas.drawCircle(
        center,
        _r + 6,
        Paint()
          ..color = AppColors.orange.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }

    // Fill
    canvas.drawCircle(center, _r, Paint()..color = fill);

    // Shine
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center.dx, center.dy - 4), radius: _r),
      -math.pi * 0.9,
      math.pi * 0.8,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: state,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: _r * 2 - 8);
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pos = _positions(size);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = isDark ? const Color(0xFF161822) : const Color(0xFFF8FAFC),
    );

    // Subtle grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final edgeKeys  = <String>{};
    for (final e in edges) { edgeKeys.add('${e['from']}->${e['to']}'); }

    final drawnPairs = <String>{};
    final edgeColor  = AppColors.primary.withValues(alpha: 0.75);

    for (final edge in edges) {
      final from      = edge['from']      as String;
      final to        = edge['to']        as String;
      final condition = edge['condition'] as String?;
      final fromPos   = pos[from];
      final toPos     = pos[to];
      if (fromPos == null || toPos == null) continue;

      if (from == to) {
        _drawSelfLoop(canvas, fromPos, condition, edgeColor);
        continue;
      }

      final hasReverse = edgeKeys.contains('$to->$from');
      final pairKey    = ([from, to]..sort()).join('|');
      final isSecond   = drawnPairs.contains(pairKey);
      drawnPairs.add(pairKey);

      _drawEdge(canvas, fromPos, toPos, condition,
          curve: hasReverse, flipCurve: isSecond, color: edgeColor);
    }

    for (final state in states) {
      final p = pos[state];
      if (p != null) _drawNode(canvas, state, p);
    }
  }

  @override
  bool shouldRepaint(covariant FsmPainter old) =>
      old.states != states ||
      old.edges != edges ||
      old.unreachableStates != unreachableStates ||
      old.deadStates != deadStates ||
      old.entryState != entryState ||
      old.isDark != isDark;
}
