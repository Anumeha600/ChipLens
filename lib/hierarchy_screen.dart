import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

// ─── Reference file model ─────────────────────────────────────────────────────

class ReferenceFile {
  final String name;
  final Uint8List bytes;
  const ReferenceFile({required this.name, required this.bytes});

  String get ext {
    final idx = name.lastIndexOf('.');
    return idx < 0 ? '' : name.substring(idx).toLowerCase();
  }

  bool get isImage => const {'.jpg', '.jpeg', '.png'}.contains(ext);
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _ModuleDef {
  final String name;
  final String fileName;
  final int portCount;
  final int inputCount;
  final int outputCount;
  final List<_InstanceRef> instances;

  const _ModuleDef({
    required this.name,
    required this.fileName,
    required this.portCount,
    required this.inputCount,
    required this.outputCount,
    required this.instances,
  });

  factory _ModuleDef.fromMap(Map<String, dynamic> m) => _ModuleDef(
        name:        m['name']        as String? ?? '',
        fileName:    m['fileName']    as String? ?? '',
        portCount:   (m['portCount']  as num?)?.toInt() ?? 0,
        inputCount:  (m['inputCount'] as num?)?.toInt() ?? 0,
        outputCount: (m['outputCount'] as num?)?.toInt() ?? 0,
        instances:   ((m['instances'] as List?) ?? [])
            .map((e) => _InstanceRef.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class _InstanceRef {
  final String moduleName;
  final String instanceName;
  const _InstanceRef({required this.moduleName, required this.instanceName});
  factory _InstanceRef.fromMap(Map<String, dynamic> m) => _InstanceRef(
        moduleName:   m['moduleName']   as String? ?? '',
        instanceName: m['instanceName'] as String? ?? '',
      );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class HierarchyScreen extends StatefulWidget {
  final List<Map<String, String>> files;
  final List<ReferenceFile> referenceFiles;
  const HierarchyScreen({
    super.key,
    required this.files,
    this.referenceFiles = const [],
  });

  @override
  State<HierarchyScreen> createState() => _HierarchyScreenState();
}

class _HierarchyScreenState extends State<HierarchyScreen> {
  bool _loading = true;
  String? _error;
  Map<String, _ModuleDef> _modules = {};
  List<String> _roots = [];
  int _edgeCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await RtlApiService.fetchHierarchy(widget.files);
      final rawModules = (data['modules'] as Map?) ?? {};
      final modules = <String, _ModuleDef>{};
      for (final entry in rawModules.entries) {
        modules[entry.key as String] =
            _ModuleDef.fromMap(Map<String, dynamic>.from(entry.value as Map));
      }
      if (!mounted) return;
      setState(() {
        _modules   = modules;
        _roots     = List<String>.from(data['roots'] ?? []);
        _edgeCount = (data['edges'] as List?)?.length ?? 0;
        _loading   = false;
      });
    } on ChipLensApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.userMessage; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load hierarchy: $e'; _loading = false; });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Architecture Explorer'),
        actions: [
          if (_modules.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_modules.length} modules',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.referenceFiles.isNotEmpty) _buildReferenceStrip(),
          Expanded(
            child: _loading
                ? _buildLoadingView()
                : _error != null
                    ? _buildErrorView()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          AppShimmer(height: 100, radius: 16),
          const SizedBox(height: 12),
          AppShimmer(height: 60,  radius: 12),
          const SizedBox(height: 8),
          AppShimmer(height: 60,  radius: 12),
          const SizedBox(height: 8),
          const AppShimmer(height: 60, width: 250, radius: 12),
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
              child: const Icon(Icons.error_outline,
                  color: AppColors.error, size: 34),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to Load Hierarchy',
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
              onPressed: _load,
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

  // ── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    if (_roots.isEmpty) {
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
              child: Icon(Icons.device_hub_outlined,
                  size: 38, color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'No Module Hierarchy',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Upload multiple .v / .sv / .vh / .svh files that instantiate each other.',
              style: TextStyle(
                  color: context.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Module Hierarchy',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: context.border)),
          ],
        ),
        const SizedBox(height: 10),
        ..._roots.map((root) => _buildModuleTree(root, null, {}, 0)),
      ],
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final items = [
      (value: '${_modules.length}', label: 'Modules',   icon: Icons.memory_outlined,          color: AppColors.primary),
      (value: '${_roots.length}',   label: 'Top-level', icon: Icons.account_tree_outlined,    color: AppColors.secondary),
      (value: '$_edgeCount',        label: 'Instances', icon: Icons.link_outlined,             color: AppColors.teal),
      (value: '${widget.files.length}', label: 'Files', icon: Icons.insert_drive_file_outlined, color: AppColors.warningDark),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: context.isDark ? AppGradients.heroDark : AppGradients.hero,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.device_hub, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Project Overview',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: items.map((item) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 17),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.value,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    Text(
                      item.label,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Recursive tree ─────────────────────────────────────────────────────────

  Widget _buildModuleTree(
    String moduleName,
    String? instanceName,
    Set<String> visitedAncestors,
    int depth,
  ) {
    if (visitedAncestors.contains(moduleName) || depth > 10) {
      return _buildCircularNode(moduleName, instanceName, depth);
    }

    final module   = _modules[moduleName];
    if (module == null) {
      return _buildExternalNode(moduleName, instanceName, depth);
    }

    final newVisited = {...visitedAncestors, moduleName};
    final children   = module.instances;

    if (children.isEmpty) {
      return _buildLeafNode(module, instanceName, depth);
    }

    return _buildExpandableNode(module, instanceName, depth, children, newVisited);
  }

  // ── Node variants ──────────────────────────────────────────────────────────

  Widget _buildExpandableNode(
    _ModuleDef module,
    String? instanceName,
    int depth,
    List<_InstanceRef> children,
    Set<String> visited,
  ) {
    final isRoot = depth == 0;
    return Padding(
      padding: EdgeInsets.only(left: depth * 14.0, bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRoot
                ? AppColors.primary.withValues(alpha: 0.4)
                : context.border,
            width: isRoot ? 1.5 : 1,
          ),
          boxShadow: isRoot ? context.cardShadow : null,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: AppColors.primary.withValues(alpha: 0.05),
          ),
          child: ExpansionTile(
            initiallyExpanded: depth == 0,
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: isRoot ? AppGradients.primary : null,
                color: isRoot
                    ? null
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.account_tree_outlined,
                size: 17,
                color: isRoot ? Colors.white : AppColors.primary,
              ),
            ),
            title: _ModuleTitle(
                name: module.name,
                instanceName: instanceName,
                isRoot: isRoot),
            subtitle: Text(
              '${module.inputCount} in · ${module.outputCount} out · ${children.length} sub-module${children.length != 1 ? 's' : ''}',
              style: TextStyle(fontSize: 11, color: context.textSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PortBadge(module.portCount),
                const SizedBox(width: 4),
                Icon(Icons.expand_more,
                    size: 18, color: context.textSecondary),
              ],
            ),
            childrenPadding:
                const EdgeInsets.fromLTRB(12, 0, 12, 8),
            children: children
                .map((inst) => _buildModuleTree(
                    inst.moduleName, inst.instanceName, visited, depth + 1))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLeafNode(
      _ModuleDef module, String? instanceName, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 14.0, bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.border),
        ),
        child: ListTile(
          dense: true,
          leading: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.memory, color: AppColors.teal, size: 16),
          ),
          title: _ModuleTitle(name: module.name, instanceName: instanceName),
          subtitle: Text(
            '${module.inputCount} in · ${module.outputCount} out',
            style: TextStyle(fontSize: 11, color: context.textSecondary),
          ),
          trailing: _PortBadge(module.portCount),
          onTap: () => _showDetails(module),
        ),
      ),
    );
  }

  Widget _buildExternalNode(
      String name, String? instanceName, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 14.0, bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.border),
        ),
        child: ListTile(
          dense: true,
          leading: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: context.border,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(Icons.help_outline,
                color: context.textSecondary, size: 15),
          ),
          title: _ModuleTitle(name: name, instanceName: instanceName),
          subtitle: Text('External — not uploaded',
              style: TextStyle(
                  fontSize: 11, color: context.textSecondary)),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: context.border,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('EXT',
                style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularNode(
      String name, String? instanceName, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 14.0, bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warningBorder),
        ),
        child: ListTile(
          dense: true,
          leading: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.warningDark.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child:
                const Icon(Icons.loop, color: AppColors.warningDark, size: 15),
          ),
          title: _ModuleTitle(name: name, instanceName: instanceName),
          subtitle: const Text('Circular reference detected',
              style: TextStyle(
                  fontSize: 11, color: AppColors.warningDark)),
        ),
      ),
    );
  }

  // ── Detail bottom sheet ────────────────────────────────────────────────────

  void _showDetails(_ModuleDef module) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
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
                      Text(module.name,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary)),
                      if (module.fileName.isNotEmpty)
                        Text(module.fileName,
                            style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                                fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: context.border),
            const SizedBox(height: 8),
            _detailRow('Total ports',  '${module.portCount}'),
            _detailRow('Input ports',  '${module.inputCount}'),
            _detailRow('Output ports', '${module.outputCount}'),
            _detailRow(
              'Sub-modules',
              module.instances.isEmpty
                  ? 'None'
                  : module.instances.map((i) => i.moduleName).join(', '),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: TextStyle(
                      color: context.textSecondary, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: context.textPrimary)),
            ),
          ],
        ),
      );

  // ── Reference files strip ──────────────────────────────────────────────────

  Widget _buildReferenceStrip() {
    return Container(
      decoration: BoxDecoration(
        color: context.surface2,
        border: Border(bottom: BorderSide(color: context.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined,
                    size: 14, color: context.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'REFERENCE FILES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.referenceFiles.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: widget.referenceFiles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _buildRefCard(widget.referenceFiles[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefCard(ReferenceFile f) {
    return GestureDetector(
      onTap: () => _showRefImage(f),
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (f.isImage)
                Image.memory(f.bytes, fit: BoxFit.cover)
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf,
                        color: AppColors.error, size: 30),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        f.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 9, color: context.textSecondary),
                      ),
                    ),
                  ],
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  color: Colors.black54,
                  child: Text(
                    f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRefImage(ReferenceFile f) {
    if (!f.isImage) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: InteractiveViewer(
                child: Image.memory(f.bytes),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Module title ─────────────────────────────────────────────────────────────

class _ModuleTitle extends StatelessWidget {
  final String name;
  final String? instanceName;
  final bool isRoot;

  const _ModuleTitle({
    required this.name,
    this.instanceName,
    this.isRoot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            style: TextStyle(
              fontWeight: isRoot ? FontWeight.w700 : FontWeight.w600,
              fontSize: isRoot ? 15 : 14,
              color: isRoot ? AppColors.primary : context.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (instanceName != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '[$instanceName]',
              style: TextStyle(
                fontSize: 11,
                color: context.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Port badge ───────────────────────────────────────────────────────────────

class _PortBadge extends StatelessWidget {
  final int count;
  const _PortBadge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter
            .withValues(alpha: context.isDark ? 0.15 : 1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$count ports',
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
