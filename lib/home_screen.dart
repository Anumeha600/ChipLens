import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'inspector_screen.dart';
import 'hierarchy_screen.dart';
import 'nl_to_rtl_screen.dart';
import 'config/app_config.dart';
import 'theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _editorKey = GlobalKey();

  late AnimationController _heroCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  // ── Sample code ──────────────────────────────────────────────────────────────

  static const _counterSample = '''module counter(
  input  wire       clk,
  input  wire       enable,
  output reg  [3:0] count
);
  always @(posedge clk) begin
    if (enable)
      count = count + 1;
  end
endmodule''';

  static const _aluSample = '''module alu(
  input  [3:0] a,
  input  [3:0] b,
  input  [1:0] op,
  output reg [3:0] result
);
  wire unused_signal;
  always @(*) begin
    case (op)
      2'b00: result = a + b;
      2'b01: result = a - b;
      2'b10: result = a & b;
    endcase
  end
endmodule''';

  static const _fsmSample = '''module fsm(
  input  wire       clk,
  input  wire       start,
  output reg  [1:0] state
);
  parameter IDLE = 0, FETCH = 1, EXECUTE = 2, WRITEBACK = 3;

  always @(posedge clk) begin
    case (state)
      IDLE:      if (start) state = FETCH;
      FETCH:     state = EXECUTE;
      EXECUTE:   state = WRITEBACK;
      WRITEBACK: state = IDLE;
    endcase
  end
endmodule''';

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heroFade  = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));
    _heroCtrl.forward();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _codeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── File helpers ──────────────────────────────────────────────────────────────

  bool _isTextContent(List<int> bytes) {
    final sample = bytes.length > 512 ? bytes.sublist(0, 512) : bytes;
    int nonPrint = 0;
    for (final b in sample) {
      if (b < 32 && b != 9 && b != 10 && b != 13) nonPrint++;
    }
    return nonPrint < (sample.length * 0.05);
  }

  bool _isAllowedExtension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot == -1) return false;
    return AppConfig.allowedExtensions
        .contains(filename.substring(dot).toLowerCase());
  }

  bool _isReferenceExtension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot == -1) return false;
    return AppConfig.referenceExtensions
        .contains(filename.substring(dot).toLowerCase());
  }

  void _showUnsupportedFileDialog(String filename) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.errorBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.block_outlined, color: AppColors.error, size: 24),
        ),
        title: const Text(
          'Unsupported File Type',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"$filename" cannot be loaded.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Supported formats:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 8),
                  for (final ext in AppConfig.allowedExtensions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(ext,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  Future<void> _pickSingleFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null) return;
    final file  = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    if (!_isAllowedExtension(file.name) || !_isTextContent(bytes)) {
      _showUnsupportedFileDialog(file.name);
      return;
    }

    setState(() => _codeCtrl.text = String.fromCharCodes(bytes));
    _scrollToEditor();
  }

  Future<void> _pickMultipleFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    final rejected  = <String>[];
    final verilog   = <Map<String, String>>[];
    final reference = <ReferenceFile>[];

    for (final f in result.files) {
      final bytes = f.bytes;
      if (bytes == null) continue;

      if (_isReferenceExtension(f.name)) {
        reference.add(ReferenceFile(name: f.name, bytes: Uint8List.fromList(bytes)));
      } else if (_isAllowedExtension(f.name) && _isTextContent(bytes)) {
        verilog.add({'name': f.name, 'content': String.fromCharCodes(bytes)});
      } else {
        rejected.add(f.name);
      }
    }

    if (rejected.isNotEmpty && verilog.isEmpty && reference.isEmpty) {
      _showUnsupportedFileDialog(rejected.first);
      return;
    }

    if (rejected.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${rejected.length} unsupported file(s) skipped: ${rejected.join(', ')}'),
        ),
      );
    }

    if (verilog.isEmpty && reference.isEmpty) return;

    // Single Verilog file with no reference attachments → open in editor
    if (verilog.length == 1 && reference.isEmpty) {
      setState(() => _codeCtrl.text = verilog.first['content']!);
      _scrollToEditor();
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      slideRoute(HierarchyScreen(files: verilog, referenceFiles: reference)),
    );
  }

  void _loadSample(String code) {
    setState(() => _codeCtrl.text = code);
    _scrollToEditor();
  }

  void _analyzeCode(String code) {
    setState(() => _codeCtrl.text = code);
    Navigator.push(context, slideRoute(InspectorScreen(code: code)));
  }

  void _goToInspector() {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No RTL code found. Paste Verilog or upload a .v / .sv file.'),
        ),
      );
      return;
    }
    Navigator.push(context, slideRoute(InspectorScreen(code: code)));
  }

  void _scrollToEditor() {
    final ctx = _editorKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.bgColor,
        body: SingleChildScrollView(
          controller: _scrollCtrl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader('Capabilities'),
                    const SizedBox(height: 12),
                    _buildFeatureGrid(isDark),
                    const SizedBox(height: 16),
                    _buildNlRtlBanner(isDark),
                    const SizedBox(height: 28),
                    _buildSectionHeader('Quick Start Examples'),
                    const SizedBox(height: 12),
                    _buildQuickStart(isDark),
                    const SizedBox(height: 28),
                    _buildArchBanner(isDark),
                    const SizedBox(height: 28),
                    _buildUploadSection(isDark),
                    const SizedBox(height: 28),
                    _buildEditorSection(isDark),
                    const SizedBox(height: 28),
                    _buildTipsSection(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero(bool isDark) {
    final gradient = isDark ? AppGradients.heroDark : AppGradients.hero;
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _heroFade,
          child: SlideTransition(
            position: _heroSlide,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: welcome + theme toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          _StatusChip(
                            dot: true,
                            dotColor: AppColors.success,
                            label: 'RTL Ready',
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              themeNotifier.value =
                                  isDark ? ThemeMode.light : ThemeMode.dark;
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Title
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Chip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        TextSpan(
                          text: 'Lens',
                          style: TextStyle(
                            color: Color(0xFFA5B4FC),
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'AI-Powered RTL Analysis Workspace',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Analyze Verilog code, detect RTL issues, visualize FSMs,\n'
                    'and understand hardware behavior with AI explanations.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12.5,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Status chips row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: const [
                      _StatusChip(
                        icon: Icons.check_circle_outline,
                        label: 'RTL Ready',
                      ),
                      _StatusChip(
                        icon: Icons.storage_outlined,
                        label: 'Local Analysis',
                      ),
                      _StatusChip(
                        icon: Icons.smart_toy_outlined,
                        label: 'AI Explain Enabled',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 2. Section header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String text) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: context.border,
          ),
        ),
      ],
    );
  }

  // ── 3. Feature grid (2×2) ────────────────────────────────────────────────────

  static const _features = [
    (
      icon: Icons.search_outlined,
      gradient: AppGradients.teal,
      title: 'RTL Inspector',
      desc: 'Static analysis & quality scoring',
      count: '6 checks',
    ),
    (
      icon: Icons.account_tree_outlined,
      gradient: AppGradients.primary,
      title: 'FSM Visualizer',
      desc: 'Extract & visualize state machines',
      count: '4 metrics',
    ),
    (
      icon: Icons.smart_toy_outlined,
      gradient: LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      title: 'AI Explain',
      desc: 'Natural-language RTL explanations',
      count: '4 modes',
    ),
    (
      icon: Icons.device_hub_outlined,
      gradient: AppGradients.amber,
      title: 'Architecture',
      desc: 'Multi-file module hierarchy',
      count: 'Multi-file',
    ),
  ];

  Widget _buildFeatureGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _features.map((f) => _FeatureCard(
        isDark: isDark,
        icon: f.icon,
        gradient: f.gradient,
        title: f.title,
        desc: f.desc,
        count: f.count,
      )).toList(),
    );
  }

  // ── 4. Quick start ───────────────────────────────────────────────────────────

  Widget _buildQuickStart(bool isDark) {
    return Column(
      children: [
        _QuickStartCard(
          isDark: isDark,
          title: 'Counter',
          subtitle: '4-bit up counter with enable',
          qualityScore: 90,
          qualityLabel: '90/100',
          qualityColor: AppColors.success,
          qualityBg: AppColors.successBg,
          difficulty: 'Beginner',
          estimatedTime: '~4s',
          issues: 1,
          icon: Icons.bolt,
          iconColor: AppColors.teal,
          iconBg: AppColors.tealBg,
          hint: 'Clean baseline — no latches, proper sensitivity list',
          code: _counterSample,
          onLoad: () => _loadSample(_counterSample),
          onAnalyze: () => _analyzeCode(_counterSample),
        ),
        const SizedBox(height: 10),
        _QuickStartCard(
          isDark: isDark,
          title: 'ALU (with bugs)',
          subtitle: '4-bit ALU · 3 ops · intentional issues',
          qualityScore: 72,
          qualityLabel: '~72/100',
          qualityColor: AppColors.warningDark,
          qualityBg: AppColors.warningBg,
          difficulty: 'Beginner',
          estimatedTime: '~6s',
          issues: 3,
          icon: Icons.calculate_outlined,
          iconColor: AppColors.orange,
          iconBg: const Color(0xFFFFEDD5),
          hint: 'Spot the bugs: unused signal, missing default case',
          code: _aluSample,
          onLoad: () => _loadSample(_aluSample),
          onAnalyze: () => _analyzeCode(_aluSample),
        ),
        const SizedBox(height: 10),
        _QuickStartCard(
          isDark: isDark,
          title: 'FSM Controller',
          subtitle: '4-state processor pipeline FSM',
          qualityScore: 80,
          qualityLabel: '4 states',
          qualityColor: AppColors.secondary,
          qualityBg: const Color(0xFFEDE9FE),
          difficulty: 'Intermediate',
          estimatedTime: '~5s',
          issues: 0,
          icon: Icons.account_tree_outlined,
          iconColor: AppColors.secondary,
          iconBg: const Color(0xFFEDE9FE),
          hint: 'Tap Analyze → then open FSM Visualizer to see the diagram',
          code: _fsmSample,
          onLoad: () => _loadSample(_fsmSample),
          onAnalyze: () => _analyzeCode(_fsmSample),
        ),
      ],
    );
  }

  // ── 5. Architecture Explorer banner ─────────────────────────────────────────

  Widget _buildArchBanner(bool isDark) {
    return PressableCard(
      onTap: _pickMultipleFiles,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25),
          ),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.glow(AppColors.primary),
              ),
              child: const Icon(Icons.device_hub, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Architecture Explorer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Upload multiple .v / .sv / .vh files to visualize the full module hierarchy.',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryLighter
                    .withValues(alpha: isDark ? 0.15 : 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 5b. NL → RTL Designer banner ────────────────────────────────────────────

  Widget _buildNlRtlBanner(bool isDark) {
    return PressableCard(
      onTap: () => Navigator.push(context, slideRoute(const NlToRtlScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E1B4B), const Color(0xFF1E1030)]
                : [const Color(0xFFEEF2FF), const Color(0xFFF5F0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.2),
          ),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.glow(AppColors.primary),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'NL → RTL Designer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('NEW',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Describe hardware in English — get RTL, FSM & testbench.',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color:
                    AppColors.primaryLighter.withValues(alpha: isDark ? 0.15 : 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_right,
                  color: AppColors.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── 6. Upload RTL section ────────────────────────────────────────────────────

  Widget _buildUploadSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Upload RTL Design'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.border,
              style: BorderStyle.solid,
            ),
            boxShadow: context.cardShadow,
          ),
          child: Column(
            children: [
              // Drop zone visual
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter
                      .withValues(alpha: isDark ? 0.08 : 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter
                            .withValues(alpha: isDark ? 0.15 : 1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Drag & drop your Verilog file',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'or browse to upload',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: AppConfig.allowedExtensions
                          .map((e) => _ExtChip(label: e))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _UploadButton(
                      icon: Icons.upload_file_outlined,
                      label: 'Upload File',
                      subtitle: 'Single module',
                      color: AppColors.teal,
                      isDark: isDark,
                      onTap: _pickSingleFile,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _UploadButton(
                      icon: Icons.folder_open_outlined,
                      label: 'Multi-file',
                      subtitle: 'Hierarchy view',
                      color: AppColors.secondary,
                      isDark: isDark,
                      onTap: _pickMultipleFiles,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 7. Editor section ────────────────────────────────────────────────────────

  Widget _buildEditorSection(bool isDark) {
    return Column(
      key: _editorKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Code Editor'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13141F) : const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            children: [
              // Editor toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF252637),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        _DotButton(color: const Color(0xFFFF5F57)),
                        const SizedBox(width: 6),
                        _DotButton(color: const Color(0xFFFFBD2E)),
                        const SizedBox(width: 6),
                        _DotButton(color: const Color(0xFF28C840)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.code, size: 12, color: Color(0xFF6366F1)),
                          SizedBox(width: 5),
                          Text(
                            'verilog',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _codeCtrl.clear()),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Text field
              TextField(
                controller: _codeCtrl,
                maxLines: 14,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFFE2E8F0),
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  hintText:
                      'module example(\n  input clk,\n  output reg q\n);\n  // Your Verilog here...\nendmodule',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _AnalyzeButton(onTap: _goToInspector),
      ],
    );
  }

  // ── 8. Tips section ──────────────────────────────────────────────────────────

  static const _tips = [
    (q: 'What is a blocking assignment?', a: 'Using = in sequential always blocks causes simulation mismatches. Use <= (non-blocking) instead.'),
    (q: 'Why is a default case important?', a: 'Without default, a case statement can infer latches in synthesis, causing unintended storage elements.'),
    (q: 'What does an FSM dead state mean?', a: 'A state with no outgoing transitions. Once entered, the FSM is stuck until reset.'),
    (q: 'What is one-hot encoding?', a: 'Each state uses one flip-flop with exactly one bit set. Faster decode, uses more area.'),
  ];

  Widget _buildTipsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('RTL Concepts'),
        const SizedBox(height: 12),
        ..._tips.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TipCard(question: t.q, answer: t.a, isDark: isDark),
          ),
        ),
      ],
    );
  }
}

// ─── Status chip (used in hero) ───────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final IconData? icon;
  final bool dot;
  final Color? dotColor;
  final String label;

  const _StatusChip({
    this.icon,
    this.dot = false,
    this.dotColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor ?? Colors.white,
                shape: BoxShape.circle,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature card ─────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String desc;
  final String count;

  const _FeatureCard({
    required this.isDark,
    required this.icon,
    required this.gradient,
    required this.title,
    required this.desc,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border),
          boxShadow: context.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark3
                        : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.border),
                  ),
                  child: Text(
                    count,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(
                fontSize: 11,
                color: context.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick start card ─────────────────────────────────────────────────────────
class _QuickStartCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final int qualityScore;
  final String qualityLabel;
  final Color qualityColor;
  final Color qualityBg;
  final String difficulty;
  final String estimatedTime;
  final int issues;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String hint;
  final String code;
  final VoidCallback onLoad;
  final VoidCallback onAnalyze;

  const _QuickStartCard({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.qualityScore,
    required this.qualityLabel,
    required this.qualityColor,
    required this.qualityBg,
    required this.difficulty,
    required this.estimatedTime,
    required this.issues,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.hint,
    required this.code,
    required this.onLoad,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        children: [
          // Main row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? iconColor.withValues(alpha: 0.18) : iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary)),
                      const SizedBox(height: 1),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? qualityColor.withValues(alpha: 0.15)
                        : qualityBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    qualityLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: qualityColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Metadata row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _MetaChip(
                    icon: Icons.school_outlined,
                    label: difficulty,
                    color: context.textSecondary),
                const SizedBox(width: 8),
                _MetaChip(
                    icon: Icons.timer_outlined,
                    label: estimatedTime,
                    color: context.textSecondary),
                if (issues > 0) ...[
                  const SizedBox(width: 8),
                  _MetaChip(
                      icon: Icons.warning_amber_outlined,
                      label: '$issues issue${issues > 1 ? 's' : ''}',
                      color: AppColors.warning),
                ] else ...[
                  const SizedBox(width: 8),
                  _MetaChip(
                      icon: Icons.check_circle_outline,
                      label: 'Clean',
                      color: AppColors.success),
                ],
              ],
            ),
          ),
          // Hint row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark2
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: context.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 13, color: context.textSecondary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(hint,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: context.textSecondary,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
          // Action row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onLoad,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textPrimary,
                      side: BorderSide(color: context.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Load Code'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onAnalyze,
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Analyze →'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upload button ────────────────────────────────────────────────────────────
class _UploadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _UploadButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.08) : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Extension chip ───────────────────────────────────────────────────────────
class _ExtChip extends StatelessWidget {
  final String label;
  const _ExtChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─── Meta chip ────────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

// ─── Editor dot button ────────────────────────────────────────────────────────
class _DotButton extends StatelessWidget {
  final Color color;
  const _DotButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── Analyze button ───────────────────────────────────────────────────────────
class _AnalyzeButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnalyzeButton({required this.onTap});

  @override
  State<_AnalyzeButton> createState() => _AnalyzeButtonState();
}

class _AnalyzeButtonState extends State<_AnalyzeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.glow(AppColors.primary),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Analyze RTL',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Expandable tip card ──────────────────────────────────────────────────────
class _TipCard extends StatefulWidget {
  final String question;
  final String answer;
  final bool isDark;
  const _TipCard(
      {required this.question, required this.answer, required this.isDark});

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withValues(alpha: 0.4)
              : context.border,
        ),
        boxShadow: context.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.help_outline,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: context.textSecondary,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.answer,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: context.textSecondary,
                        height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
