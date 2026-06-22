import 'explanation_context.dart';
import 'verification_explanation.dart';

// ─── ExplanationFormatter ─────────────────────────────────────────────────────

/// Converts a [VerificationExplanation] into a formatted string.
///
/// Supports four output formats via [ExplanationFormat]:
/// - [ExplanationFormat.structured] — key-value pairs, one per line.
/// - [ExplanationFormat.plainText]  — readable prose for terminal display.
/// - [ExplanationFormat.markdown]   — GitHub-flavoured Markdown.
/// - [ExplanationFormat.json]       — minimal JSON object.
///
/// Invariants:
/// - Does NOT modify [VerificationExplanation] in any way.
/// - Output is deterministic for identical input.
/// - Unsupported formats throw [ArgumentError].
/// - All methods are static; no instance state is required.
abstract class ExplanationFormatter {
  ExplanationFormatter._();

  /// Formats [explanation] according to [format].
  ///
  /// Throws [ArgumentError] for formats not handled by the current
  /// implementation.
  static String format(
    VerificationExplanation explanation,
    ExplanationFormat format,
  ) =>
      switch (format) {
        ExplanationFormat.structured => _formatStructured(explanation),
        ExplanationFormat.plainText  => _formatPlainText(explanation),
        ExplanationFormat.markdown   => _formatMarkdown(explanation),
        ExplanationFormat.json       => _formatJson(explanation),
      };

  // ── Structured ────────────────────────────────────────────────────────────

  static String _formatStructured(VerificationExplanation exp) {
    final trace = exp.trace;
    final lines = <String>[
      'propertyId: ${exp.propertyId}',
      'title: ${exp.title}',
      'type: ${trace.propertyType}',
      'confidence: ${trace.confidence.toStringAsFixed(4)}',
      'ranking: ${trace.rankingExplanation}',
      'emission: ${trace.emissionReason}',
    ];
    if (exp.description.isNotEmpty) {
      lines.insert(2, 'description: ${exp.description}');
    }
    if (trace.semanticEvidenceIds.isNotEmpty) {
      lines.add('evidence: [${trace.semanticEvidenceIds.join(', ')}]');
    }
    if (trace.verificationEngine.isNotEmpty) {
      lines.add('engine: ${trace.verificationEngine}');
    }
    return lines.join('\n');
  }

  // ── Plain text ────────────────────────────────────────────────────────────

  static String _formatPlainText(VerificationExplanation exp) {
    final trace = exp.trace;
    final buf   = StringBuffer();
    buf.writeln('Property:    ${exp.propertyId}');
    buf.writeln('Title:       ${exp.title}');
    if (exp.description.isNotEmpty) {
      buf.writeln('Description: ${exp.description}');
    }
    buf.writeln('Type:        ${trace.propertyType}');
    buf.writeln('Confidence:  ${trace.confidence.toStringAsFixed(4)}');
    buf.writeln('Ranking:     ${trace.rankingExplanation}');
    buf.writeln('Emission:    ${trace.emissionReason}');
    if (trace.semanticEvidenceIds.isNotEmpty) {
      buf.writeln('Evidence:    ${trace.semanticEvidenceIds.join(', ')}');
    }
    return buf.toString().trimRight();
  }

  // ── Markdown ──────────────────────────────────────────────────────────────

  static String _formatMarkdown(VerificationExplanation exp) {
    final trace = exp.trace;
    final buf   = StringBuffer();
    buf.writeln('## ${exp.title}');
    buf.writeln();
    buf.writeln('**Property ID:** `${exp.propertyId}`');
    if (exp.description.isNotEmpty) {
      buf.writeln();
      buf.writeln(exp.description);
    }
    buf.writeln();
    buf.writeln('| Field | Value |');
    buf.writeln('|---|---|');
    buf.writeln('| Type | `${trace.propertyType}` |');
    buf.writeln('| Confidence | ${trace.confidence.toStringAsFixed(4)} |');
    if (trace.semanticEvidenceIds.isNotEmpty) {
      final evStr = trace.semanticEvidenceIds.map((id) => '`$id`').join(', ');
      buf.writeln('| Evidence | $evStr |');
    }
    buf.writeln();
    buf.writeln('**Ranking:** ${trace.rankingExplanation}');
    buf.writeln();
    buf.writeln('**Emission:** ${trace.emissionReason}');
    return buf.toString().trimRight();
  }

  // ── JSON ──────────────────────────────────────────────────────────────────

  static String _formatJson(VerificationExplanation exp) {
    final trace  = exp.trace;
    final evJson = trace.semanticEvidenceIds
        .map((id) => '"${_esc(id)}"')
        .join(', ');

    return '{\n'
        '  "propertyId": "${_esc(exp.propertyId)}",\n'
        '  "title": "${_esc(exp.title)}",\n'
        '  "description": "${_esc(exp.description)}",\n'
        '  "type": "${_esc(trace.propertyType)}",\n'
        '  "confidence": ${trace.confidence},\n'
        '  "rankingExplanation": "${_esc(trace.rankingExplanation)}",\n'
        '  "emissionReason": "${_esc(trace.emissionReason)}",\n'
        '  "evidenceIds": [$evJson]\n'
        '}';
  }

  /// Escapes special characters for JSON string values.
  static String _esc(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
}
