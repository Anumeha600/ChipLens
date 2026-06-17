// On-device Verilog FSM extractor — no backend required.
// Handles the two common synthesizable FSM patterns:
//   • Two-always-block Moore/Mealy  (separate sequential + combinational)
//   • One-always-block              (state and output in single always)
// Returns a Map with the same shape the backend /fsm endpoint returns.

class LocalFsmExtractor {
  static Map<String, dynamic> extract(String verilog) {
    final code = _stripComments(verilog);

    // ── 1. Collect localparam state names ─────────────────────────────────────
    // Verilog constant format: 4'b0000  8'hFF  2'd3  or plain  0  1  2
    // Use double-quoted raw strings so the literal ' in Verilog constants is safe.
    final params = <String, String>{}; // identifier → raw value token

    // Grab everything between 'localparam' and ';' (may span many identifiers)
    final lpLineRe = RegExp(r'localparam\b(.+?);', multiLine: true, dotAll: true);
    for (final lm in lpLineRe.allMatches(code)) {
      final body = lm.group(1)!
          .replaceFirst(RegExp(r'^\s*\[\d+:\d+\]\s*'), ''); // strip [N:0]
      // Match:  IDENTIFIER = <value>
      // <value> can be  2'b01  8'hFF  3'd5  or plain decimal
      final assignRe = RegExp(r"([A-Z_][A-Z0-9_]*)\s*=\s*([\w']+)");
      for (final am in assignRe.allMatches(body)) {
        params[am.group(1)!] = am.group(2)!;
      }
    }

    // ── 2. Find the best-matching case(stateVar) block ────────────────────────
    final caseRe = RegExp(r'case\s*\(\s*(\w+)\s*\)', multiLine: true);
    String? stateVar;
    String? bestCaseBody;
    int bestScore = 0;

    for (final cm in caseRe.allMatches(code)) {
      final varName = cm.group(1)!;
      final body = _caseBody(code, cm.end);
      if (body == null) continue;
      // Score by how many known param names appear as case labels
      int score = 0;
      for (final pname in params.keys) {
        if (RegExp('\\b$pname\\b\\s*:').hasMatch(body)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        stateVar  = varName;
        bestCaseBody = body;
      }
    }

    // Fallback: numeric labels (no named localparams found)
    if (stateVar == null) {
      for (final cm in caseRe.allMatches(code)) {
        final body = _caseBody(code, cm.end);
        if (body == null) continue;
        // Numeric Verilog constant as label: 2'b00: or 2'd0:
        final numRe = RegExp(r"\d+[''][bBhHoOdD][0-9a-fA-Fx_]+\s*:");
        if (numRe.hasMatch(body)) {
          stateVar = cm.group(1)!;
          bestCaseBody = body;
          int idx = 0;
          for (final nl in numRe.allMatches(body)) {
            final label = nl.group(0)!.trim().replaceAll(':', '').trim();
            params.putIfAbsent('S$idx', () => label);
            idx++;
          }
          break;
        }
      }
    }

    // No case statement → combinational circuit, no FSM
    if (stateVar == null || bestCaseBody == null) return _empty();

    // Keep only params that appear as case labels
    final stateParams = <String, String>{};
    for (final e in params.entries) {
      if (RegExp('\\b${e.key}\\b\\s*:').hasMatch(bestCaseBody)) {
        stateParams[e.key] = e.value;
      }
    }
    if (stateParams.isEmpty) stateParams.addAll(params);
    if (stateParams.isEmpty) return _empty();

    final stateNames = stateParams.keys.toList();

    // ── 3. Entry state ────────────────────────────────────────────────────────
    // Look for:  if (!rst_n) state <= SOME_STATE
    String? entryState;
    final resetRe = RegExp(
        r'if\s*\(\s*[!~]\s*\w+\s*\)\s*(?:begin\s+)?\s*\w+\s*<=\s*(\w+)',
        multiLine: true);
    final rm = resetRe.firstMatch(code);
    if (rm != null && stateParams.containsKey(rm.group(1))) {
      entryState = rm.group(1);
    }
    if (entryState == null) {
      const candidates = ['IDLE', 'RESET', 'S_INIT', 'S0', 'START', 'INIT'];
      for (final c in candidates) {
        if (stateNames.contains(c)) { entryState = c; break; }
      }
    }
    entryState ??= stateNames.first;

    // ── 4. Extract transitions ────────────────────────────────────────────────
    final edges = <Map<String, dynamic>>[];

    for (final fromState in stateNames) {
      final branch = _branchBody(bestCaseBody, fromState);
      if (branch == null) {
        edges.add({'from': fromState, 'to': fromState, 'condition': 'hold'});
        continue;
      }

      // Try ternary first: next_state = COND ? A : B
      final ternaryRe = RegExp(
          r'(?:next[\w]*|' + RegExp.escape(stateVar) + r')\s*[<]?=\s*(\w+)\s*\?\s*(\w+)\s*:\s*(\w+)',
          multiLine: true);

      final found = <(String, String?)>[];

      for (final t in ternaryRe.allMatches(branch)) {
        final cond = t.group(1)!;
        final a    = t.group(2)!;
        final b    = t.group(3)!;
        if (stateParams.containsKey(a)) found.add((a, cond));
        if (stateParams.containsKey(b)) found.add((b, '!$cond'));
      }

      // Plain assignment: next_state = TARGET or state <= TARGET
      if (found.isEmpty) {
        final assignRe = RegExp(
            r'(?:next[\w]*|' + RegExp.escape(stateVar) + r')\s*[<]?=\s*(\w+)',
            multiLine: true);
        for (final a in assignRe.allMatches(branch)) {
          final target = a.group(1)!;
          if (stateParams.containsKey(target)) found.add((target, null));
        }
      }

      if (found.isEmpty) {
        // Keep state visible even if we couldn't parse transitions
        edges.add({'from': fromState, 'to': fromState, 'condition': 'hold'});
      } else {
        for (final (to, cond) in found) {
          edges.add({
            'from': fromState,
            'to':   to,
            if (cond != null) 'condition': cond,
          });
        }
      }
    }

    // ── 5. Reachability analysis ──────────────────────────────────────────────
    final adj = <String, List<String>>{};
    for (final e in edges) {
      adj.putIfAbsent(e['from'] as String, () => []).add(e['to'] as String);
    }
    final reachable = <String>{};
    final queue = [entryState];
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      if (!reachable.add(cur)) continue;
      queue.addAll(adj[cur] ?? []);
    }
    final unreachable = stateNames.where((s) => !reachable.contains(s)).toList();
    final hasOut = edges.map((e) => e['from'] as String).toSet();
    final dead   = stateNames
        .where((s) => !hasOut.contains(s) && s != entryState)
        .toList();

    return {
      'states':            stateNames,
      'edges':             edges,
      'unreachableStates': unreachable,
      'deadStates':        dead,
      'entryState':        entryState,
      'encodingStyle':     'localparam',
      'complexity': {
        'stateCount':      stateNames.length,
        'transitionCount': edges.length,
      },
      'stateStats': [
        for (final s in stateNames)
          {
            'name':   s,
            'outDeg': edges.where((e) => e['from'] == s).length,
            'inDeg':  edges.where((e) => e['to']   == s).length,
          },
      ],
    };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _empty() => {
    'states':            <String>[],
    'edges':             <Map<String, dynamic>>[],
    'unreachableStates': <String>[],
    'deadStates':        <String>[],
    'entryState':        null,
    'encodingStyle':     'none',
    'complexity':        {'stateCount': 0, 'transitionCount': 0},
    'stateStats':        <Map<String, dynamic>>[],
  };

  static String _stripComments(String code) {
    var s = code.replaceAll(RegExp(r'//[^\n]*'), '');
    s = s.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    return s;
  }

  // Extract everything from startAfterCase up to 'endcase'
  static String? _caseBody(String code, int startAfterCase) {
    final sub = code.substring(startAfterCase);
    final idx = sub.indexOf('endcase');
    return idx < 0 ? null : sub.substring(0, idx);
  }

  // Extract the body of a specific case branch
  static String? _branchBody(String caseBody, String stateName) {
    final labelRe = RegExp('\\b$stateName\\s*:', multiLine: true);
    final lm = labelRe.firstMatch(caseBody);
    if (lm == null) return null;
    final after = caseBody.substring(lm.end);
    // Next branch starts at another UPPERCASE_IDENTIFIER:
    final nextLabel = RegExp(r'\b[A-Z_][A-Z0-9_]*\s*:', multiLine: true)
        .firstMatch(after);
    return nextLabel != null ? after.substring(0, nextLabel.start) : after;
  }
}
