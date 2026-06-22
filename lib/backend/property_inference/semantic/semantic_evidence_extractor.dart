import '../../design_intelligence/design_knowledge.dart';
import '../../design_intelligence/knowledge_models.dart';
import 'semantic_category.dart';
import 'semantic_evidence.dart';
import 'semantic_evidence_set.dart';

// ─── SemanticEvidenceExtractor ────────────────────────────────────────────────

/// Pure transformation from [DesignKnowledge] to [SemanticEvidenceSet].
///
/// This class has **no dependencies** on:
/// - Formal Framework
/// - Repair Framework
/// - Verification Framework
/// - Flutter
/// - UI
///
/// It only translates structured design observations into semantic evidence
/// objects that downstream synthesizers can reason over.
abstract class SemanticEvidenceExtractor {
  SemanticEvidenceExtractor._();

  // ── Confidence constants ──────────────────────────────────────────────────

  static const _confCertain     = 1.0;  // structurally guaranteed
  static const _confVeryLikely  = 0.95; // detected from formal structural pattern
  static const _confLikely      = 0.85; // detected from common RTL idiom
  static const _confProbable    = 0.75; // inferred from heuristic
  static const _confCandidate   = 0.7;  // name-based heuristic only
  static const _confUnknown     = 0.5;  // insufficient structural evidence

  static const _handshakeConf = <String, double>{
    'valid_ready': _confVeryLikely,
    'req_ack':     _confVeryLikely,
    'start_done':  _confLikely,
    'enable_done': _confLikely,
  };

  // ── Public API ────────────────────────────────────────────────────────────

  /// Extracts semantic evidence from all domains in [knowledge].
  ///
  /// The returned [SemanticEvidenceSet] is immutable and safe to share across
  /// async boundaries.
  static SemanticEvidenceSet extract(DesignKnowledge knowledge) {
    final items = <SemanticEvidence>[];
    _extractClocks(knowledge.clocks, items);
    _extractResets(knowledge.resets, items);
    _extractFSMs(knowledge.fsms, items);
    _extractCounters(knowledge.counters, items);
    _extractRegisters(knowledge.registers, items);
    _extractHandshakes(knowledge.handshakes, items);
    return SemanticEvidenceSet(items);
  }

  // ── Domain extractors ─────────────────────────────────────────────────────

  static void _extractClocks(
      List<ClockInfo> clocks, List<SemanticEvidence> out) {
    for (final clk in clocks) {
      final double confidence;
      final String tag;
      if (clk.isPrimaryClock) {
        confidence = _confCertain;
        tag = 'primary';
      } else if (clk.isCandidate) {
        confidence = _confCandidate;
        tag = 'candidate';
      } else {
        confidence = _confUnknown;
        tag = 'detected';
      }

      out.add(SemanticEvidence(
        id:             'clock.${clk.name}',
        category:       SemanticCategory.clock,
        confidence:     confidence,
        description:    '${clk.name} is a $tag clock signal.',
        sourceProvider: 'clock_extractor',
        metadata: {
          'signal':       clk.name,
          'isPrimary':    clk.isPrimaryClock,
          'isCandidate':  clk.isCandidate,
          'isGenerated':  clk.isGenerated,
        },
      ));
    }
  }

  static void _extractResets(
      List<ResetInfo> resets, List<SemanticEvidence> out) {
    for (final rst in resets) {
      final confidence = rst.isAsynchronous ? _confVeryLikely : _confLikely;
      final polarity   = rst.isActiveLow ? 'active-low' : 'active-high';
      final kind       = rst.isAsynchronous ? 'asynchronous' : 'synchronous';

      out.add(SemanticEvidence(
        id:             'reset.${rst.name}',
        category:       SemanticCategory.reset,
        confidence:     confidence,
        description:    '${rst.name} is a $kind $polarity reset signal.',
        sourceProvider: 'reset_extractor',
        metadata: {
          'signal':        rst.name,
          'isAsynchronous': rst.isAsynchronous,
          'isSynchronous':  rst.isSynchronous,
          'isActiveLow':    rst.isActiveLow,
          'isActiveHigh':   rst.isActiveHigh,
        },
      ));
    }
  }

  static void _extractFSMs(
      List<FSMInfo> fsms, List<SemanticEvidence> out) {
    for (final fsm in fsms) {
      final double confidence;
      if (fsm.candidateStates.isEmpty) {
        confidence = _confUnknown;
      } else if (fsm.encodingStyle == 'localparam' ||
                 fsm.encodingStyle == 'parameter') {
        confidence = _confVeryLikely;
      } else {
        confidence = _confProbable;
      }

      out.add(SemanticEvidence(
        id:             'fsm.${fsm.stateRegister}',
        category:       SemanticCategory.fsm,
        confidence:     confidence,
        description:    'State machine register ${fsm.stateRegister} detected '
                        'with ${fsm.candidateStates.length} candidate state(s).',
        sourceProvider: 'fsm_extractor',
        metadata: {
          'stateRegister':  fsm.stateRegister,
          'encodingWidth':  fsm.encodingWidth,
          'stateCount':     fsm.candidateStates.length,
          'encodingStyle':  fsm.encodingStyle,
          'candidateStates': List.unmodifiable(fsm.candidateStates),
        },
      ));
    }
  }

  static void _extractCounters(
      List<CounterInfo> counters, List<SemanticEvidence> out) {
    for (final ctr in counters) {
      final double confidence;
      final String tag;

      if (ctr.isIncrement && ctr.isDecrement) {
        confidence = _confVeryLikely;
        tag = 'bidirectional';
      } else if (ctr.isIncrement) {
        confidence = _confVeryLikely;
        tag = 'increment-only';
      } else if (ctr.isDecrement) {
        confidence = _confLikely;
        tag = 'decrement-only';
      } else {
        confidence = _confUnknown;
        tag = 'name-only';
      }

      out.add(SemanticEvidence(
        id:             'counter.${ctr.name}',
        category:       SemanticCategory.counter,
        confidence:     confidence,
        description:    '${ctr.name} is a ${ctr.width}-bit $tag counter.',
        sourceProvider: 'counter_extractor',
        metadata: {
          'counter':     ctr.name,
          'width':       ctr.width,
          'isIncrement': ctr.isIncrement,
          'isDecrement': ctr.isDecrement,
        },
      ));
    }
  }

  static void _extractRegisters(
      List<RegisterInfo> registers, List<SemanticEvidence> out) {
    for (final reg in registers) {
      final SemanticCategory category;
      final double confidence;
      final String kind;

      if (reg.isSequential) {
        category   = SemanticCategory.sequential;
        confidence = _confLikely;
        kind       = 'sequential';
      } else if (reg.isCombinational) {
        category   = SemanticCategory.combinational;
        confidence = 0.8;
        kind       = 'combinational';
      } else {
        category   = SemanticCategory.register;
        confidence = _confUnknown;
        kind       = 'unclassified';
      }

      out.add(SemanticEvidence(
        id:             'register.${reg.name}',
        category:       category,
        confidence:     confidence,
        description:    '${reg.name} is a ${reg.width}-bit $kind register.',
        sourceProvider: 'register_extractor',
        metadata: {
          'register':        reg.name,
          'width':           reg.width,
          'isSequential':    reg.isSequential,
          'isCombinational': reg.isCombinational,
        },
      ));
    }
  }

  static void _extractHandshakes(
      List<HandshakeInfo> handshakes, List<SemanticEvidence> out) {
    for (final hs in handshakes) {
      final confidence =
          _handshakeConf[hs.protocolHint] ?? _confUnknown;
      // Build a stable ID from the first two signal names.
      final signalKey = hs.signals.take(2).join('_');

      out.add(SemanticEvidence(
        id:             'handshake.${hs.protocolHint}.$signalKey',
        category:       SemanticCategory.handshake,
        confidence:     confidence,
        description:    'Handshake protocol "${hs.protocolHint}" detected '
                        'involving signals: ${hs.signals.join(', ')}.',
        sourceProvider: 'handshake_extractor',
        metadata: {
          'protocolHint': hs.protocolHint,
          'signals':      List.unmodifiable(hs.signals),
        },
      ));
    }
  }
}
