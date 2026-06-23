import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/counterexample/counterexample.dart';
import 'package:chiplens_lite/backend/formal/formal_result.dart';

// ── Test helpers ──────────────────────────────────────────────────────────────

FormalResult makeResult({
  bool success               = true,
  int  exitCode              = 0,
  List<String> proven        = const [],
  List<String> failed        = const [],
  List<String> unknown       = const [],
  String stdout              = '',
  String stderr              = '',
  Duration executionTime     = Duration.zero,
}) =>
    FormalResult(
      success:            success,
      exitCode:           exitCode,
      stdout:             stdout,
      stderr:             stderr,
      executionTime:      executionTime,
      provenProperties:   proven,
      failedProperties:   failed,
      unknownProperties:  unknown,
    );

FormalResult successResult({int n = 3}) => makeResult(
      success: true,
      proven:  List.generate(n, (i) => 'prop_$i'),
    );

FormalResult failureResult({int n = 1}) => makeResult(
      success: false,
      failed:  List.generate(n, (i) => 'prop_$i'),
    );

void main() {
  const analyzer = CounterexampleAnalyzer();
  const ctx      = CounterexampleContext();

  // ════════════════════════════════════════════════════════════════════════════
  // 1. CounterexampleContext
  // ════════════════════════════════════════════════════════════════════════════
  group('CounterexampleContext', () {
    test('defaults are sensible', () {
      const c = CounterexampleContext();
      expect(c.includeTrace,      true);
      expect(c.includeSignals,    true);
      expect(c.includeStatistics, true);
      expect(c.includeConfidence, true);
      expect(c.maximumSignals,    -1);
    });

    test('custom fields are stored', () {
      const c = CounterexampleContext(includeTrace: false, maximumSignals: 5);
      expect(c.includeTrace,   false);
      expect(c.maximumSignals, 5);
    });

    test('equality holds for identical fields', () {
      const a = CounterexampleContext(maximumSignals: 3);
      const b = CounterexampleContext(maximumSignals: 3);
      expect(a, b);
    });

    test('inequality when any field differs', () {
      const base = CounterexampleContext();
      expect(base, isNot(CounterexampleContext(includeTrace: false)));
      expect(base, isNot(CounterexampleContext(maximumSignals: 10)));
    });

    test('copyWith overrides only specified fields', () {
      const original = CounterexampleContext(maximumSignals: 4);
      final copy = original.copyWith(includeSignals: false);
      expect(copy.maximumSignals, 4);
      expect(copy.includeSignals, false);
      expect(copy.includeTrace,   true);
    });

    test('copyWith with no args equals original', () {
      const c = CounterexampleContext(maximumSignals: 2);
      expect(c.copyWith(), c);
    });

    test('toString is non-empty', () {
      expect(const CounterexampleContext().toString(), isNotEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 2. CounterexampleSignal
  // ════════════════════════════════════════════════════════════════════════════
  group('CounterexampleSignal', () {
    test('stores all fields', () {
      final s = CounterexampleSignal(name: 'clk', value: '1', step: 3, changed: true);
      expect(s.name,    'clk');
      expect(s.value,   '1');
      expect(s.step,    3);
      expect(s.changed, true);
    });

    test('step=0 is valid', () {
      expect(
        () => CounterexampleSignal(name: 'n', value: 'v', step: 0, changed: false),
        returnsNormally,
      );
    });

    test('equality by all fields', () {
      final a = CounterexampleSignal(name: 'x', value: 'v', step: 0, changed: false);
      final b = CounterexampleSignal(name: 'x', value: 'v', step: 0, changed: false);
      expect(a, b);
    });

    test('inequality when name differs', () {
      final a = CounterexampleSignal(name: 'a', value: 'v', step: 0, changed: false);
      final b = CounterexampleSignal(name: 'b', value: 'v', step: 0, changed: false);
      expect(a, isNot(b));
    });

    test('toString contains name and step', () {
      final s = CounterexampleSignal(name: 'data', value: 'FAIL', step: 2, changed: true);
      expect(s.toString(), contains('data'));
      expect(s.toString(), contains('2'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 3. CounterexampleTrace
  // ════════════════════════════════════════════════════════════════════════════
  group('CounterexampleTrace', () {
    test('stores all fields', () {
      final sig = CounterexampleSignal(name: 'p', value: 'FAIL', step: 0, changed: true);
      final t = CounterexampleTrace(
        signals: [sig], failedProperties: ['p'],
        firstFailure: 'p', estimatedDepth: 1,
      );
      expect(t.signals.length,          1);
      expect(t.failedProperties.first,  'p');
      expect(t.firstFailure,            'p');
      expect(t.estimatedDepth,          1);
    });

    test('signals are unmodifiable', () {
      final t = CounterexampleTrace(
        signals: [], failedProperties: [], firstFailure: '', estimatedDepth: 0,
      );
      final sig = CounterexampleSignal(name: 'n', value: 'v', step: 0, changed: false);
      expect(() => (t.signals as dynamic).add(sig), throwsUnsupportedError);
    });

    test('failedProperties are unmodifiable', () {
      final t = CounterexampleTrace(
        signals: [], failedProperties: ['p'], firstFailure: 'p', estimatedDepth: 1,
      );
      expect(() => (t.failedProperties as dynamic).add('q'), throwsUnsupportedError);
    });

    test('equality by all fields', () {
      final a = CounterexampleTrace(
        signals: [], failedProperties: ['p'], firstFailure: 'p', estimatedDepth: 1,
      );
      final b = CounterexampleTrace(
        signals: [], failedProperties: ['p'], firstFailure: 'p', estimatedDepth: 1,
      );
      expect(a, b);
    });

    test('input list mutation does not affect stored signals', () {
      final sigs = <CounterexampleSignal>[
        CounterexampleSignal(name: 'p', value: 'FAIL', step: 0, changed: true),
      ];
      final t = CounterexampleTrace(
        signals: sigs, failedProperties: [], firstFailure: '', estimatedDepth: 0,
      );
      sigs.clear();
      expect(t.signals.length, 1);
    });

    test('empty static instance has depth 0', () {
      expect(CounterexampleTrace.empty.estimatedDepth, 0);
      expect(CounterexampleTrace.empty.signals,        isEmpty);
    });

    test('toString contains depth and signal count', () {
      final t = CounterexampleTrace(
        signals: [], failedProperties: [], firstFailure: '', estimatedDepth: 3,
      );
      expect(t.toString(), contains('3'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 4. CounterexampleClassification
  // ════════════════════════════════════════════════════════════════════════════
  group('CounterexampleClassification', () {
    test('assertionFailure maps from failedProperties', () {
      final r = failureResult();
      expect(analyzer.analyze(r, ctx).classification,
          CounterexampleClassification.assertionFailure);
    });

    test('assumptionViolation for not-success with no properties', () {
      final r = makeResult(
        success: false, exitCode: 0,
        proven: [], failed: [], unknown: [],
      );
      expect(analyzer.analyze(r, ctx).classification,
          CounterexampleClassification.assumptionViolation);
    });

    test('timeout from exit code 124', () {
      final r = makeResult(success: false, exitCode: 124, unknown: ['p1']);
      expect(analyzer.analyze(r, ctx).classification,
          CounterexampleClassification.timeout);
    });

    test('unknown for inconclusive result (unknownProperties only)', () {
      final r = makeResult(success: false, exitCode: 0, unknown: ['p1']);
      expect(analyzer.analyze(r, ctx).classification,
          CounterexampleClassification.unknown);
    });

    test('engineFailure from unavailable engine', () {
      final r = FormalResult.unavailable();
      expect(analyzer.analyze(r, ctx).classification,
          CounterexampleClassification.engineFailure);
    });

    test('priority: engineFailure beats assertionFailure', () {
      final r = makeResult(success: false, exitCode: -1, failed: ['p1']);
      expect(analyzer.analyze(r, ctx).classification,
          CounterexampleClassification.engineFailure);
    });

    test('priority: timeout beats assertionFailure when exitCode=124', () {
      // exitCode 124 takes priority over failedProperties
      final r = makeResult(success: false, exitCode: 124, failed: ['p1']);
      expect(analyzer.analyze(r, ctx).classification,
          CounterexampleClassification.timeout);
    });

    test('all proven → unknown (no counterexample known)', () {
      final r = successResult();
      expect(analyzer.analyze(r, ctx).classification,
          CounterexampleClassification.unknown);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 5. CounterexampleConfidence
  // ════════════════════════════════════════════════════════════════════════════
  group('CounterexampleConfidence', () {
    test('all properties proven → veryHigh', () {
      final r = successResult(n: 5);
      expect(analyzer.analyze(r, ctx).confidence, CounterexampleConfidence.veryHigh);
    });

    test('single failure, no unknowns → high', () {
      final r = makeResult(
        success: false, failed: ['p1'], proven: ['p2', 'p3', 'p4'],
      );
      expect(analyzer.analyze(r, ctx).confidence, CounterexampleConfidence.high);
    });

    test('mixed failures and proven → medium', () {
      final r = makeResult(
        success: false, failed: ['p1', 'p2'], proven: ['p3', 'p4', 'p5', 'p6'],
      );
      expect(analyzer.analyze(r, ctx).confidence, CounterexampleConfidence.medium);
    });

    test('mostly unknown → low', () {
      final r = makeResult(
        success: false, unknown: ['p1', 'p2', 'p3', 'p4'], failed: [], proven: ['p5'],
      );
      expect(analyzer.analyze(r, ctx).confidence, CounterexampleConfidence.low);
    });

    test('engine failure → veryLow', () {
      final r = FormalResult.unavailable();
      expect(analyzer.analyze(r, ctx).confidence, CounterexampleConfidence.veryLow);
    });

    test('confidence is veryHigh when includeConfidence=false', () {
      final r = failureResult();
      final report = analyzer.analyze(r, ctx.copyWith(includeConfidence: false));
      expect(report.confidence, CounterexampleConfidence.veryHigh);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 6. CounterexampleStatistics
  // ════════════════════════════════════════════════════════════════════════════
  group('CounterexampleStatistics', () {
    test('empty constant has all zeros', () {
      expect(CounterexampleStatistics.empty.failedPropertyCount,  0);
      expect(CounterexampleStatistics.empty.unknownPropertyCount, 0);
      expect(CounterexampleStatistics.empty.signalCount,          0);
      expect(CounterexampleStatistics.empty.changedSignalCount,   0);
      expect(CounterexampleStatistics.empty.estimatedDepth,       0);
    });

    test('failed property count matches FormalResult', () {
      final r = failureResult(n: 3);
      final report = analyzer.analyze(r, ctx);
      expect(report.statistics.failedPropertyCount, 3);
    });

    test('unknown property count matches FormalResult', () {
      final r = makeResult(success: false, unknown: ['p1', 'p2']);
      final report = analyzer.analyze(r, ctx);
      expect(report.statistics.unknownPropertyCount, 2);
    });

    test('signal count matches generated signals', () {
      final r = failureResult(n: 2);
      final report = analyzer.analyze(r, ctx);
      expect(report.statistics.signalCount, 2);
    });

    test('changed signal count equals failed property count', () {
      final r = failureResult(n: 3);
      final report = analyzer.analyze(r, ctx);
      expect(report.statistics.changedSignalCount, 3);
    });

    test('estimated depth equals failed property count', () {
      final r = failureResult(n: 4);
      final report = analyzer.analyze(r, ctx);
      expect(report.statistics.estimatedDepth, 4);
    });

    test('statistics are empty when includeStatistics=false', () {
      final r = failureResult(n: 2);
      final report = analyzer.analyze(r, ctx.copyWith(includeStatistics: false));
      expect(report.statistics, CounterexampleStatistics.empty);
    });

    test('toString is non-empty', () {
      expect(CounterexampleStatistics.empty.toString(), isNotEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 7. CounterexampleSummary
  // ════════════════════════════════════════════════════════════════════════════
  group('CounterexampleSummary', () {
    test('overview mentions property count on failure', () {
      final r = failureResult(n: 2);
      final summary = analyzer.analyze(r, ctx).summary;
      expect(summary.overview, contains('2'));
    });

    test('primaryFailure is first failed property', () {
      final r = makeResult(success: false, failed: ['alpha', 'beta']);
      final summary = analyzer.analyze(r, ctx).summary;
      expect(summary.primaryFailure, 'alpha');
    });

    test('earliestFailure equals primaryFailure', () {
      final r = makeResult(success: false, failed: ['p1', 'p2']);
      final summary = analyzer.analyze(r, ctx).summary;
      expect(summary.earliestFailure, summary.primaryFailure);
    });

    test('dominantCategory is classification name', () {
      final r = failureResult();
      final report = analyzer.analyze(r, ctx);
      expect(report.summary.dominantCategory,
          CounterexampleClassification.assertionFailure.name);
    });

    test('primaryFailure is None when all proven', () {
      final r = successResult();
      final summary = analyzer.analyze(r, ctx).summary;
      expect(summary.primaryFailure, 'None');
    });

    test('summary equality is structural', () {
      final r = failureResult();
      expect(analyzer.analyze(r, ctx).summary, analyzer.analyze(r, ctx).summary);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 8. CounterexampleReport
  // ════════════════════════════════════════════════════════════════════════════
  group('CounterexampleReport', () {
    test('successful verification → isSuccessful=true, hasFailures=false', () {
      final report = analyzer.analyze(successResult(), ctx);
      expect(report.isSuccessful, true);
      expect(report.hasFailures,  false);
    });

    test('failed verification → hasFailures=true, isSuccessful=false', () {
      final report = analyzer.analyze(failureResult(), ctx);
      expect(report.hasFailures,  true);
      expect(report.isSuccessful, false);
    });

    test('engine failure → isSuccessful=false', () {
      final report = analyzer.analyze(FormalResult.unavailable(), ctx);
      expect(report.isSuccessful, false);
    });

    test('equality for identical FormalResult', () {
      final r = failureResult(n: 2);
      expect(analyzer.analyze(r, ctx), analyzer.analyze(r, ctx));
    });

    test('toString is non-empty', () {
      expect(analyzer.analyze(successResult(), ctx).toString(), isNotEmpty);
    });

    test('construction stores all required fields', () {
      final report = analyzer.analyze(failureResult(), ctx);
      expect(report.summary,        isA<CounterexampleSummary>());
      expect(report.trace,          isA<CounterexampleTrace>());
      expect(report.classification, isA<CounterexampleClassification>());
      expect(report.confidence,     isA<CounterexampleConfidence>());
      expect(report.statistics,     isA<CounterexampleStatistics>());
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 9. CounterexampleAnalyzer core
  // ════════════════════════════════════════════════════════════════════════════
  group('CounterexampleAnalyzer', () {
    test('successful verification produces empty trace', () {
      final report = analyzer.analyze(successResult(), ctx);
      expect(report.trace.failedProperties, isEmpty);
      expect(report.trace.firstFailure,     '');
    });

    test('single property failure produces single signal', () {
      final r = failureResult(n: 1);
      final report = analyzer.analyze(r, ctx);
      expect(report.trace.signals.length,         1);
      expect(report.trace.signals.first.changed,  true);
    });

    test('multiple failures produce matching signal count', () {
      final r = failureResult(n: 5);
      final report = analyzer.analyze(r, ctx);
      expect(report.trace.signals.length, 5);
    });

    test('unknown properties produce unchanged signals', () {
      final r = makeResult(success: false, unknown: ['u1', 'u2']);
      final report = analyzer.analyze(r, ctx);
      expect(report.trace.signals.every((s) => !s.changed), true);
    });

    test('timeout result is classified correctly', () {
      final r = makeResult(success: false, exitCode: 124);
      expect(analyzer.analyze(r, ctx).classification,
          CounterexampleClassification.timeout);
    });

    test('engine failure result is classified correctly', () {
      expect(analyzer.analyze(FormalResult.unavailable(), ctx).classification,
          CounterexampleClassification.engineFailure);
    });

    test('trace is empty when includeTrace=false', () {
      final r = failureResult();
      final report = analyzer.analyze(r, ctx.copyWith(includeTrace: false));
      expect(report.trace, CounterexampleTrace.empty);
    });

    test('maximumSignals limits signals in trace', () {
      final r = failureResult(n: 10);
      final report = analyzer.analyze(r, ctx.copyWith(maximumSignals: 3));
      expect(report.trace.signals.length, 3);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 10. Trace-specific tests
  // ════════════════════════════════════════════════════════════════════════════
  group('Trace construction', () {
    test('signal order matches failedProperties order', () {
      final r = makeResult(
        success: false, failed: ['alpha', 'beta', 'gamma'],
      );
      final sigs = analyzer.analyze(r, ctx).trace.signals;
      expect(sigs[0].name, 'alpha');
      expect(sigs[1].name, 'beta');
      expect(sigs[2].name, 'gamma');
    });

    test('failed properties list order is preserved', () {
      final r = makeResult(success: false, failed: ['z', 'a', 'm']);
      final props = analyzer.analyze(r, ctx).trace.failedProperties;
      expect(props, ['z', 'a', 'm']);
    });

    test('duplicate properties between failed and unknown are deduplicated', () {
      // Same ID in both failed and unknown → appears only once (as FAIL)
      final r = makeResult(
        success: false, failed: ['prop_dup'], unknown: ['prop_dup'],
      );
      final sigs = analyzer.analyze(r, ctx).trace.signals;
      expect(sigs.length, 1);
      expect(sigs.first.value, 'FAIL');
    });

    test('estimated depth equals failed property count', () {
      final r = failureResult(n: 7);
      expect(analyzer.analyze(r, ctx).trace.estimatedDepth, 7);
    });

    test('maximumSignals=0 produces empty signal list', () {
      final r = failureResult(n: 5);
      final report = analyzer.analyze(r, ctx.copyWith(maximumSignals: 0));
      expect(report.trace.signals, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 11. Determinism
  // ════════════════════════════════════════════════════════════════════════════
  group('Determinism', () {
    test('same input produces identical reports across 10 runs', () {
      final r = makeResult(
        success: false,
        failed:  ['prop_a', 'prop_b'],
        unknown: ['prop_c'],
      );
      final first = analyzer.analyze(r, ctx);
      for (int i = 0; i < 9; i++) {
        expect(analyzer.analyze(r, ctx), first);
      }
    });

    test('different analyzer instances produce equal output', () {
      final r = failureResult(n: 3);
      expect(
        const CounterexampleAnalyzer().analyze(r, ctx),
        const CounterexampleAnalyzer().analyze(r, ctx),
      );
    });

    test('classification is deterministic', () {
      final r = failureResult(n: 2);
      expect(
        analyzer.analyze(r, ctx).classification,
        analyzer.analyze(r, ctx).classification,
      );
    });

    test('signal ordering is deterministic', () {
      final r = makeResult(success: false, failed: ['z', 'a', 'm']);
      final a = analyzer.analyze(r, ctx).trace.signals.map((s) => s.name).toList();
      final b = analyzer.analyze(r, ctx).trace.signals.map((s) => s.name).toList();
      expect(a, b);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 12. Negative tests
  // ════════════════════════════════════════════════════════════════════════════
  group('Negative tests', () {
    test('exitCode < -1 throws ArgumentError', () {
      final r = makeResult(success: false, exitCode: -2);
      expect(() => analyzer.analyze(r, ctx), throwsArgumentError);
    });

    test('success=true with failedProperties throws StateError', () {
      final r = makeResult(success: true, exitCode: 0, failed: ['p1']);
      expect(() => analyzer.analyze(r, ctx), throwsStateError);
    });

    test('negative estimatedDepth in CounterexampleTrace throws ArgumentError', () {
      expect(
        () => CounterexampleTrace(
          signals: [], failedProperties: [],
          firstFailure: '', estimatedDepth: -1,
        ),
        throwsArgumentError,
      );
    });

    test('negative step in CounterexampleSignal throws ArgumentError', () {
      expect(
        () => CounterexampleSignal(name: 'x', value: 'v', step: -1, changed: false),
        throwsArgumentError,
      );
    });

    test('very negative exitCode throws ArgumentError', () {
      final r = makeResult(success: false, exitCode: -999);
      expect(() => analyzer.analyze(r, ctx), throwsArgumentError);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 13. Performance
  // ════════════════════════════════════════════════════════════════════════════
  group('Performance', () {
    test('100 failed properties analyzed within 100ms', () {
      final r = failureResult(n: 100);
      final sw = Stopwatch()..start();
      analyzer.analyze(r, ctx);
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('500 failed properties analyzed within 200ms', () {
      final r = failureResult(n: 500);
      final sw = Stopwatch()..start();
      analyzer.analyze(r, ctx);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });

    test('1000 failed properties analyzed within 400ms', () {
      final r = failureResult(n: 1000);
      final sw = Stopwatch()..start();
      analyzer.analyze(r, ctx);
      expect(sw.elapsedMilliseconds, lessThan(400));
    });
  });
}
