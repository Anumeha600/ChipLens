import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../benchmarks/models/benchmark_models.dart';
import '../../benchmarks/runner/benchmark.dart';
import '../../benchmarks/runner/benchmark_runner.dart';
import '../../benchmarks/reports/benchmark_report_generator.dart';

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── kDefaultBenchmarks definitions ───────────────────────────────────────────

  group('kDefaultBenchmarks', () {
    test('contains exactly 5 entries', () {
      expect(kDefaultBenchmarks.length, 5);
    });

    test('contains counter', () {
      expect(kDefaultBenchmarks.any((b) => b.designName == 'counter'), isTrue);
    });

    test('contains fsm', () {
      expect(kDefaultBenchmarks.any((b) => b.designName == 'fsm'), isTrue);
    });

    test('contains alu', () {
      expect(kDefaultBenchmarks.any((b) => b.designName == 'alu'), isTrue);
    });

    test('contains fifo', () {
      expect(kDefaultBenchmarks.any((b) => b.designName == 'fifo'), isTrue);
    });

    test('contains uart', () {
      expect(kDefaultBenchmarks.any((b) => b.designName == 'uart'), isTrue);
    });

    test('all fixture paths point to test/fixtures/rtl/', () {
      for (final bench in kDefaultBenchmarks) {
        expect(bench.fixturePath, startsWith('test/fixtures/rtl/'));
      }
    });

    test('all fixture paths end with .v', () {
      for (final bench in kDefaultBenchmarks) {
        expect(bench.fixturePath, endsWith('.v'));
      }
    });
  });

  // ── runBenchmarkSuite ─────────────────────────────────────────────────────────

  group('runBenchmarkSuite — structure', () {
    late BenchmarkSuiteResult suite;

    setUpAll(() async {
      suite = await runBenchmarkSuite();
    });

    test('returns BenchmarkSuiteResult', () {
      expect(suite, isNotNull);
    });

    test('totalDesigns equals 5', () {
      expect(suite.totalDesigns, 5);
    });

    test('results.length equals 5', () {
      expect(suite.results.length, 5);
    });

    test('successfulDesigns + failedDesigns == totalDesigns', () {
      expect(
        suite.successfulDesigns + suite.failedDesigns,
        suite.totalDesigns,
      );
    });

    test('all 5 fixtures succeed', () {
      expect(suite.successfulDesigns, 5);
    });

    test('no failures', () {
      expect(suite.failedDesigns, 0);
    });

    test('result order matches kDefaultBenchmarks order', () {
      for (int i = 0; i < kDefaultBenchmarks.length; i++) {
        expect(suite.results[i].designName, kDefaultBenchmarks[i].designName);
      }
    });
  });

  // ── Per-design results ───────────────────────────────────────────────────────

  group('runBenchmarkSuite — per-design results', () {
    late BenchmarkSuiteResult suite;

    setUpAll(() async {
      suite = await runBenchmarkSuite();
    });

    test('every result has non-negative runtimeMs', () {
      for (final r in suite.results) {
        expect(r.runtimeMs, greaterThanOrEqualTo(0),
            reason: '${r.designName} runtimeMs should be non-negative');
      }
    });

    test('every result has non-negative diagnosticCount', () {
      for (final r in suite.results) {
        expect(r.diagnosticCount, greaterThanOrEqualTo(0),
            reason: '${r.designName} diagnosticCount should be non-negative');
      }
    });

    test('every result has non-negative repairCount', () {
      for (final r in suite.results) {
        expect(r.repairCount, greaterThanOrEqualTo(0),
            reason: '${r.designName} repairCount should be non-negative');
      }
    });

    test('repairCount <= diagnosticCount for every result', () {
      for (final r in suite.results) {
        expect(r.repairCount, lessThanOrEqualTo(r.diagnosticCount),
            reason: '${r.designName}: repairs cannot exceed diagnostics');
      }
    });

    test('alu succeeds and has minimal diagnostics', () {
      final alu = suite.results.firstWhere((r) => r.designName == 'alu');
      expect(alu.success, isTrue);
      expect(alu.diagnosticCount, lessThan(3));
    });
  });

  // ── Custom suite ─────────────────────────────────────────────────────────────

  group('runBenchmarkSuite — custom benchmark list', () {
    test('custom list with 2 fixtures runs only those 2', () async {
      final result = await runBenchmarkSuite(benchmarks: const [
        Benchmark(designName: 'counter', fixturePath: 'test/fixtures/rtl/counter.v'),
        Benchmark(designName: 'alu',     fixturePath: 'test/fixtures/rtl/alu.v'),
      ]);
      expect(result.totalDesigns, 2);
      expect(result.results.length, 2);
    });

    test('empty benchmark list returns empty suite', () async {
      final result = await runBenchmarkSuite(benchmarks: const []);
      expect(result.totalDesigns, 0);
      expect(result.results, isEmpty);
    });
  });

  // ── Report generation (end-to-end) ───────────────────────────────────────────

  group('runBenchmarkSuite — report generation', () {
    late BenchmarkSuiteResult suite;

    setUpAll(() async {
      suite = await runBenchmarkSuite();
    });

    test('generates benchmark_results.md successfully', () {
      const generator = BenchmarkReportGenerator();
      generator.writeToFile(suite);
      final file = File('docs/evaluation/benchmark_results.md');
      expect(file.existsSync(), isTrue);
    });

    test('generated report contains main heading', () {
      final content =
          File('docs/evaluation/benchmark_results.md').readAsStringSync();
      expect(content, contains('# ChipLens Benchmark Results'));
    });

    test('generated report contains all 5 design names', () {
      final content =
          File('docs/evaluation/benchmark_results.md').readAsStringSync();
      for (final bench in kDefaultBenchmarks) {
        expect(content, contains(bench.designName),
            reason: '${bench.designName} should appear in report');
      }
    });

    test('generated report contains Summary section', () {
      final content =
          File('docs/evaluation/benchmark_results.md').readAsStringSync();
      expect(content, contains('## Summary'));
    });

    test('generated report shows 5 total designs', () {
      final content =
          File('docs/evaluation/benchmark_results.md').readAsStringSync();
      expect(content, contains('| Total Designs | 5 |'));
    });
  });
}
