import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../benchmarks/models/benchmark_models.dart';
import '../../benchmarks/reports/benchmark_report_generator.dart';
import '../../benchmarks/reports/report.dart';

// ── Fixtures ───────────────────────────────────────────────────────────────────

final _suite = BenchmarkSuiteResult(
  results: [
    const BenchmarkResult(
      designName: 'counter', runtimeMs: 30,
      diagnosticCount: 1, repairCount: 1, success: true,
    ),
    const BenchmarkResult(
      designName: 'fsm', runtimeMs: 45,
      diagnosticCount: 2, repairCount: 2, success: true,
    ),
    const BenchmarkResult(
      designName: 'alu', runtimeMs: 20,
      diagnosticCount: 0, repairCount: 0, success: true,
    ),
  ],
  totalDesigns:      3,
  successfulDesigns: 3,
  failedDesigns:     0,
);

final _suiteWithFailure = BenchmarkSuiteResult(
  results: [
    const BenchmarkResult(
      designName: 'counter', runtimeMs: 30,
      diagnosticCount: 1, repairCount: 1, success: true,
    ),
    const BenchmarkResult(
      designName: 'bad', runtimeMs: 0,
      diagnosticCount: 0, repairCount: 0, success: false,
      notes: 'File not found.',
    ),
  ],
  totalDesigns:      2,
  successfulDesigns: 1,
  failedDesigns:     1,
);

const _generator = BenchmarkReportGenerator();

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Markdown content ─────────────────────────────────────────────────────────

  group('BenchmarkReportGenerator — markdown structure', () {
    late String report;

    setUpAll(() {
      report = _generator.generate(_suite);
    });

    test('contains main heading', () {
      expect(report, contains('# ChipLens Benchmark Results'));
    });

    test('contains Design Analysis section', () {
      expect(report, contains('## Design Analysis'));
    });

    test('contains Summary section', () {
      expect(report, contains('## Summary'));
    });

    test('contains table header row', () {
      expect(report, contains('| Design | Diagnostics | Repairs'));
    });

    test('contains separator row', () {
      expect(report, contains('|--------|-------------|'));
    });

    test('contains date when includeDate=true', () {
      expect(report, contains('**Date:**'));
    });
  });

  // ── Design table values ───────────────────────────────────────────────────────

  group('BenchmarkReportGenerator — design table values', () {
    late String report;

    setUpAll(() {
      report = _generator.generate(_suite);
    });

    test('counter row is present', () {
      expect(report, contains('| counter |'));
    });

    test('fsm row is present', () {
      expect(report, contains('| fsm |'));
    });

    test('alu row is present', () {
      expect(report, contains('| alu |'));
    });

    test('counter diagnosticCount appears in table', () {
      expect(report, contains('| counter | 1 |'));
    });

    test('alu with 0 diagnostics appears correctly', () {
      expect(report, contains('| alu | 0 | 0 |'));
    });

    test('success Yes appears in table', () {
      expect(report, contains('Yes'));
    });
  });

  // ── Summary values ────────────────────────────────────────────────────────────

  group('BenchmarkReportGenerator — summary values', () {
    late String report;

    setUpAll(() {
      report = _generator.generate(_suite);
    });

    test('total designs value is present', () {
      expect(report, contains('| Total Designs | 3 |'));
    });

    test('successful runs value is present', () {
      expect(report, contains('| Successful Runs | 3 |'));
    });

    test('failed runs value is present', () {
      expect(report, contains('| Failed Runs | 0 |'));
    });

    test('total diagnostics computed correctly (1+2+0=3)', () {
      expect(report, contains('| Total Diagnostics | 3 |'));
    });

    test('total repairs computed correctly (1+2+0=3)', () {
      expect(report, contains('| Total Repairs | 3 |'));
    });

    test('average runtime computed and present', () {
      // avg of 30,45,20 = 95/3 ≈ 32ms
      expect(report, contains('| Average Runtime (ms) |'));
    });
  });

  // ── Configuration ─────────────────────────────────────────────────────────────

  group('BenchmarkReportGenerator — config options', () {
    test('includeDate=false omits date line', () {
      final r = _generator.generate(
        _suite,
        config: const ReportConfig(includeDate: false),
      );
      expect(r, isNot(contains('**Date:**')));
    });

    test('includeNotes=true adds Notes column', () {
      final r = _generator.generate(
        _suiteWithFailure,
        config: const ReportConfig(includeNotes: true),
      );
      expect(r, contains('| Notes |'));
    });

    test('includeNotes=true shows failure note text', () {
      final r = _generator.generate(
        _suiteWithFailure,
        config: const ReportConfig(includeNotes: true),
      );
      expect(r, contains('File not found.'));
    });

    test('failure row shows No in Success column', () {
      final r = _generator.generate(_suiteWithFailure);
      expect(r, contains('No'));
    });
  });

  // ── File writing ─────────────────────────────────────────────────────────────

  group('BenchmarkReportGenerator — writeToFile', () {
    test('creates file at specified outputPath', () {
      final tempPath =
          'D:/temp/claude/chiplens_benchmark_test_${DateTime.now().millisecondsSinceEpoch}.md';
      _generator.writeToFile(
        _suite,
        config: ReportConfig(outputPath: tempPath),
      );
      final file = File(tempPath);
      expect(file.existsSync(), isTrue);
      file.deleteSync();
    });

    test('file content contains main heading', () {
      final tempPath =
          'D:/temp/claude/chiplens_benchmark_content_${DateTime.now().millisecondsSinceEpoch}.md';
      _generator.writeToFile(
        _suite,
        config: ReportConfig(outputPath: tempPath),
      );
      final content = File(tempPath).readAsStringSync();
      expect(content, contains('# ChipLens Benchmark Results'));
      File(tempPath).deleteSync();
    });

    test('creates parent directories that do not exist', () {
      final tempDir =
          'D:/temp/claude/benchmark_test_nested_${DateTime.now().millisecondsSinceEpoch}';
      final tempPath = '$tempDir/sub/report.md';
      _generator.writeToFile(
        _suite,
        config: ReportConfig(outputPath: tempPath),
      );
      expect(File(tempPath).existsSync(), isTrue);
      Directory(tempDir).deleteSync(recursive: true);
    });
  });

  // ── Standalone helpers ────────────────────────────────────────────────────────

  group('Standalone summary helpers', () {
    test('averageRuntimeMs computes correctly', () {
      final results = _suite.results;
      expect(averageRuntimeMs(results), 32); // (30+45+20)/3 = 31.67 → 32
    });

    test('averageRuntimeMs on empty list returns 0', () {
      expect(averageRuntimeMs(<BenchmarkResult>[]), 0);
    });

    test('totalDiagnostics sums correctly', () {
      expect(totalDiagnostics(_suite.results), 3); // 1+2+0
    });

    test('totalRepairs sums correctly', () {
      expect(totalRepairs(_suite.results), 3); // 1+2+0
    });

    test('totalDiagnostics on empty list returns 0', () {
      expect(totalDiagnostics(<BenchmarkResult>[]), 0);
    });
  });
}
