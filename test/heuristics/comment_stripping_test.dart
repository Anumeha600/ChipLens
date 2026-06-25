import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

// ─── comment_stripping_test ───────────────────────────────────────────────────
//
// Verifies that RtlPreprocessor.stripComments() correctly removes Verilog
// single-line (//) and block (/* */) comments without disturbing RTL tokens,
// and that DesignRunner.analyze() no longer produces false-positive identifiers
// from comment text.
//
// Root cause this validates: the word "registered" in a comment caused
// RegisterProvider to capture "istered" as a register name.

void main() {
  // ── RtlPreprocessor.stripComments unit tests ─────────────────────────────

  group('stripComments — empty and no-op inputs', () {
    test('empty string returns empty string', () {
      expect(RtlPreprocessor.stripComments(''), '');
    });

    test('source with no comments is returned unchanged', () {
      const src = 'module foo; reg x; endmodule';
      expect(RtlPreprocessor.stripComments(src), src);
    });

    test('source with only whitespace is returned unchanged', () {
      const src = '   \n\t  \n';
      expect(RtlPreprocessor.stripComments(src), src);
    });
  });

  group('stripComments — single-line comments', () {
    test('removes // comment to end of line', () {
      const src = 'wire a; // this is a comment\nwire b;';
      final result = RtlPreprocessor.stripComments(src);
      expect(result, contains('wire a;'));
      expect(result, contains('wire b;'));
      expect(result, isNot(contains('this is a comment')));
    });

    test('preserves the newline after a // comment', () {
      const src = 'reg x; // comment\nreg y;';
      final result = RtlPreprocessor.stripComments(src);
      expect(result, contains('\n'));
      expect(result, contains('reg y;'));
    });

    test('removes comment from the beginning of a line', () {
      const src = '// full line comment\nreg x;';
      final result = RtlPreprocessor.stripComments(src);
      expect(result, isNot(contains('full line comment')));
      expect(result, contains('reg x;'));
    });

    test('multiple // comments on separate lines all removed', () {
      const src = 'reg a; // first\nreg b; // second\nreg c;';
      final result = RtlPreprocessor.stripComments(src);
      expect(result, isNot(contains('first')));
      expect(result, isNot(contains('second')));
      expect(result, contains('reg a;'));
      expect(result, contains('reg b;'));
      expect(result, contains('reg c;'));
    });

    test('// at end of file with no newline is removed', () {
      const src = 'assign x = 1; // trailing';
      final result = RtlPreprocessor.stripComments(src);
      expect(result, isNot(contains('trailing')));
      expect(result, contains('assign x = 1;'));
    });

    test('/* in a // comment is not treated as block comment start', () {
      const src = 'reg x; // open /* here\nreg y;';
      final result = RtlPreprocessor.stripComments(src);
      expect(result, contains('reg y;'));
      expect(result, isNot(contains('open')));
    });
  });

  group('stripComments — block comments', () {
    test('removes single-line block comment /* ... */', () {
      const src = 'reg /* foo */ x;';
      final result = RtlPreprocessor.stripComments(src);
      expect(result, isNot(contains('foo')));
      expect(result, contains('x;'));
    });

    test('removes multi-line block comment', () {
      const src = 'reg x; /* this spans\n   multiple\n   lines */ reg y;';
      final result = RtlPreprocessor.stripComments(src);
      expect(result, isNot(contains('spans')));
      expect(result, isNot(contains('multiple')));
      expect(result, isNot(contains('lines')));
      expect(result, contains('reg x;'));
      expect(result, contains('reg y;'));
    });

    test('preserves newlines inside block comment', () {
      const src = 'a\n/* b\nc */\nd';
      final result = RtlPreprocessor.stripComments(src);
      final lines = result.split('\n');
      expect(lines.length, greaterThanOrEqualTo(3),
          reason: 'newlines inside block comment must be preserved');
    });

    test('// inside block comment is not treated as line comment', () {
      const src = '/* this has // inside */ reg x;';
      final result = RtlPreprocessor.stripComments(src);
      expect(result, contains('reg x;'));
      expect(result, isNot(contains('inside')));
    });

    test('block comment immediately before a token preserves token', () {
      const src = '/*comment*/reg x;';
      final result = RtlPreprocessor.stripComments(src);
      expect(result, contains('reg x;'));
      expect(result, isNot(contains('comment')));
    });

    test('unterminated block comment does not throw', () {
      const src = 'reg x; /* unterminated';
      expect(() => RtlPreprocessor.stripComments(src), returnsNormally);
    });
  });

  group('stripComments — false positive regression (istered)', () {
    // This is the root-cause regression: the word "registered" in a comment
    // caused RegisterProvider to match "istered" as a register name.
    const rtlWithCommentedRegistered = '''
module skidbuffer (
    input  wire i_clk,
    output reg  o_valid,
    output reg  o_ready
);
    reg r_valid;

    // o_valid: registered output valid
    always @(posedge i_clk)
        o_valid <= r_valid;

    always @(*)
        o_ready = !r_valid;

endmodule
''';

    test('stripComments removes "registered" from comment text', () {
      final result = RtlPreprocessor.stripComments(rtlWithCommentedRegistered);
      expect(result, isNot(contains('registered')));
    });

    test('stripComments preserves "reg r_valid" declaration', () {
      final result = RtlPreprocessor.stripComments(rtlWithCommentedRegistered);
      expect(result, contains('reg r_valid'));
    });

    test('DesignRunner.analyze does not capture istered from comment', () async {
      final knowledge = await DesignRunner.analyze(
        DesignContext(rtlSource: rtlWithCommentedRegistered),
      );
      final names = knowledge.registers.map((r) => r.name).toList();
      expect(names, isNot(contains('istered')));
    });

    test('DesignRunner.analyze still detects legitimate registers', () async {
      final knowledge = await DesignRunner.analyze(
        DesignContext(rtlSource: rtlWithCommentedRegistered),
      );
      final names = knowledge.registers.map((r) => r.name).toList();
      expect(names, contains('r_valid'));
    });

    test('register count is correct after comment strip (no istered)', () async {
      final knowledge = await DesignRunner.analyze(
        DesignContext(rtlSource: rtlWithCommentedRegistered),
      );
      // o_valid, o_ready, r_valid = 3 real, no false positive
      expect(knowledge.registers.length, lessThan(5));
      expect(knowledge.registers.length, greaterThan(0));
    });
  });

  group('stripComments — mixed comment styles', () {
    test('handles both // and /* */ in the same source', () {
      const src = '''
// module header
/* block comment */
module foo; // inline
  reg x; /* width */ // name
endmodule
''';
      final result = RtlPreprocessor.stripComments(src);
      expect(result, contains('module foo;'));
      expect(result, contains('reg x;'));
      expect(result, isNot(contains('module header')));
      expect(result, isNot(contains('block comment')));
      expect(result, isNot(contains('inline')));
      expect(result, isNot(contains('width')));
      expect(result, isNot(contains('name')));
    });

    test('multiple block comments on the same line all removed', () {
      const src = 'reg /* a */ x /* b */;';
      final result = RtlPreprocessor.stripComments(src);
      expect(result, contains('x'));
      expect(result, isNot(contains('a')));
      expect(result, isNot(contains(' b ')));
    });

    test('source that is entirely comments produces whitespace only', () {
      const src = '// comment\n/* block */\n// another';
      final result = RtlPreprocessor.stripComments(src);
      expect(result.trim(), isEmpty);
    });
  });
}
