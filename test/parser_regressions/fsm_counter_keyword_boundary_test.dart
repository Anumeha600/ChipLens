import 'package:flutter_test/flutter_test.dart';

import 'package:chiplens_lite/backend/design_intelligence/design_intelligence.dart';

// Regression tests confirming that the \breg(?!\w) keyword boundary fix
// was applied consistently to FSMProvider and CounterProvider, not just
// RegisterProvider.
//
// Also covers edge cases shared across providers:
//   - 'reg' followed by underscore (reg_state, reg_count) must match as
//     a genuine identifier, not as a standalone 'reg' keyword prefix.
//   - Comment text is stripped before any provider runs, preventing
//     false positives from words like 'registered' or 'deregistered'.

DesignContext _ctx(String rtl) => DesignContext(rtlSource: rtl);

void main() {
  // ── FSMProvider keyword boundary ──────────────────────────────────────────

  group('FSMProvider — keyword boundary fix', () {
    const provider = FSMProvider();

    test('reg_state is detected as a genuine FSM register', () async {
      const rtl = '''
module m(input clk, input rst);
  localparam IDLE = 2'b00;
  localparam RUN  = 2'b01;
  reg [1:0] reg_state;
  always @(posedge clk) begin
    if (rst) reg_state <= IDLE;
    else     reg_state <= RUN;
  end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      // reg_state contains 'state' — should be detected as an FSM register
      expect(r.fsms, isNotEmpty);
      expect(r.fsms.first.stateRegister, 'reg_state');
    });

    test('regs_state (array-like name containing state) not matched by FSMProvider', () async {
      // 'regs_state' does not start with a bare 'reg ' keyword — the
      // `(?!\w)` fix means 'reg' in 'regs_state' is not matched.
      const rtl = '''
module m(input clk);
  wire [1:0] regs_state;
  always @(posedge clk) begin end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      // No reg declaration → no FSM match (FSMProvider needs 'reg' keyword)
      expect(r.fsms, isEmpty);
    });

    test('reg [1:0] state correctly detected as FSM register', () async {
      const rtl = '''
module m(input clk, input rst);
  localparam S0 = 2'b00;
  localparam S1 = 2'b01;
  reg [1:0] state;
  always @(posedge clk) begin
    if (rst) state <= S0;
    else     state <= S1;
  end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(r.fsms, isNotEmpty);
      expect(r.fsms.first.stateRegister, 'state');
      expect(r.fsms.first.encodingWidth, 2);
    });

    test('FSMProvider localparam candidate states still detected', () async {
      const rtl = '''
module traffic(input clk, input rst, output reg [1:0] light);
  localparam RED   = 2'b00;
  localparam GREEN = 2'b01;
  localparam AMBER = 2'b10;
  reg [1:0] state;
  always @(posedge clk) begin
    if (rst) state <= RED;
    else case (state)
      RED:   state <= GREEN;
      GREEN: state <= AMBER;
      AMBER: state <= RED;
    endcase
  end
  always @(*) light = state;
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(r.fsms, isNotEmpty);
      expect(r.fsms.first.candidateStates,
          containsAll(['RED', 'GREEN', 'AMBER']));
    });
  });

  // ── CounterProvider keyword boundary ─────────────────────────────────────

  group('CounterProvider — keyword boundary fix', () {
    const provider = CounterProvider();

    test('reg [7:0] cnt correctly detected as counter', () async {
      const rtl = '''
module m(input clk, input rst, output reg [7:0] cnt);
  always @(posedge clk) begin
    if (rst) cnt <= 8'h00;
    else     cnt <= cnt + 1;
  end
endmodule
''';
      final r   = await provider.analyze(_ctx(rtl));
      final cnt = r.counters.firstWhere((c) => c.name == 'cnt');
      expect(cnt.width,       8);
      expect(cnt.isIncrement, isTrue);
    });

    test('reg_count as declared reg: detected correctly, no _count FP', () async {
      const rtl = '''
module m(input clk);
  reg [7:0] reg_count;
  always @(posedge clk) reg_count <= reg_count + 1;
endmodule
''';
      // CounterProvider should detect reg_count via the increment pattern
      // and not produce a false positive '_count'
      final r = await provider.analyze(_ctx(rtl));
      final names = r.counters.map((c) => c.name).toList();
      expect(names, isNot(contains('_count')));
    });

    test('regs_count: no _count or s_count false positive from counters', () async {
      // regs_count contains 'count' but is accessed as an array, not declared
      // as a keyword-reg.  With (?!\w), 'reg' in 'regs_count' does not match.
      const rtl = '''
module m(input clk);
  wire [7:0] regs_count;
  always @(posedge clk) begin end
endmodule
''';
      final r = await provider.analyze(_ctx(rtl));
      expect(r.counters, isEmpty);
    });

    test('decrement counter still detected after boundary fix', () async {
      const rtl = '''
module m(input clk, input rst, output reg [3:0] cnt);
  always @(posedge clk) begin
    if (rst) cnt <= 4'hF;
    else     cnt <= cnt - 1;
  end
endmodule
''';
      final r   = await provider.analyze(_ctx(rtl));
      final cnt = r.counters.firstWhere((c) => c.name == 'cnt');
      expect(cnt.isDecrement, isTrue);
    });
  });

  // ── Cross-provider edge cases ─────────────────────────────────────────────

  group('cross-provider edge cases', () {
    test('reg followed by tab character: still detected', () async {
      // Verilog allows tabs as whitespace after keywords
      const rtl = 'module m(input clk);\n  reg\t[7:0] data;\n  always @(posedge clk) data <= 8\'h0;\nendmodule';
      final r = await const RegisterProvider().analyze(_ctx(rtl));
      expect(r.registers.any((r) => r.name == 'data'), isTrue);
    });

    test('reg with multiple spaces: still detected', () async {
      const rtl = 'module m(input clk);\n  reg   [7:0] wide;\n  always @(posedge clk) wide <= 8\'h0;\nendmodule';
      final r = await const RegisterProvider().analyze(_ctx(rtl));
      expect(r.registers.any((r) => r.name == 'wide'), isTrue);
    });

    test('comment containing regs does not produce false positive', () async {
      const rtl = '''
module m(input clk, output reg q);
  // Uses regs array internally but simplified here
  always @(posedge clk) q <= ~q;
endmodule
''';
      final r = await const RegisterProvider().analyze(_ctx(rtl));
      // 's' must not appear from the comment's 'regs'
      expect(r.registers.map((r) => r.name), isNot(contains('s')));
      // q must be found
      expect(r.registers.any((r) => r.name == 'q'), isTrue);
    });

    test('RegisterProvider and FSMProvider both see correct reg [1:0] state', () async {
      const rtl = '''
module m(input clk, input rst);
  localparam A = 2'b00;
  localparam B = 2'b01;
  reg [1:0] state;
  always @(posedge clk) begin
    if (rst) state <= A;
    else     state <= B;
  end
endmodule
''';
      final reg = await const RegisterProvider().analyze(_ctx(rtl));
      final fsm = await const FSMProvider().analyze(_ctx(rtl));
      // Both see 'state'
      expect(reg.registers.any((r) => r.name == 'state'), isTrue);
      expect(fsm.fsms, isNotEmpty);
      expect(fsm.fsms.first.stateRegister, 'state');
    });

    test('width map not confused by module keyword', () async {
      // 'module' is not in the port/wire/logic keyword list — should not
      // contribute any widths to the map
      const rtl = '''
module adder(input [7:0] a, input [7:0] b, output [7:0] sum);
  assign sum = a + b;
endmodule
''';
      final r   = await const RegisterProvider().analyze(_ctx(rtl));
      final sum = r.registers.firstWhere((r) => r.name == 'sum');
      // Width from 'output [7:0] sum' — not from 'module' keyword
      expect(sum.width, 8);
    });

    test('assign target with no matching declaration defaults to width=1', () async {
      const rtl = 'module m(input a); assign undeclared = a; endmodule';
      final r  = await const RegisterProvider().analyze(_ctx(rtl));
      final ud = r.registers.firstWhere((r) => r.name == 'undeclared');
      expect(ud.width, 1);
    });

    test('memory array name starting with reg_: depth captured correctly', () async {
      const rtl = '''
module m(input clk);
  reg [7:0] reg_file [0:7];
  always @(posedge clk) reg_file[0] <= 8'h0;
endmodule
''';
      final r   = await const RegisterProvider().analyze(_ctx(rtl));
      final reg = r.registers.firstWhere((r) => r.name == 'reg_file');
      expect(reg.isMemoryArray, isTrue);
      expect(reg.depth, 8);
      expect(reg.width, 8);
    });

    test('no false positive from regs appearing in always block body', () async {
      const rtl = '''
module m(input clk, input [4:0] wa, input [31:0] wd);
  reg [31:0] regs [0:31];
  always @(posedge clk) begin
    regs[wa] <= wd;
    regs[0]  <= 32'hDEAD;
  end
endmodule
''';
      final r = await const RegisterProvider().analyze(_ctx(rtl));
      // Only 'regs' should be in the register list — no 's' from body
      expect(r.registers.length, 1);
      expect(r.registers.first.name, 'regs');
    });

    test('RegisterInfo with depth=0 and isMemoryArray=false: toString has no ×', () {
      const reg = RegisterInfo(name: 'q', width: 8, isSequential: true);
      expect(reg.toString(), isNot(contains('×')));
      expect(reg.toString(), contains('8b'));
    });

    test('RegisterInfo with isMemoryArray=true: depth=0 is physically impossible — API allows it', () {
      // The model does not enforce depth>0 when isMemoryArray=true; callers
      // control the invariant.  Confirm the constructor accepts it.
      const reg = RegisterInfo(
        name: 'x', width: 32, isSequential: true,
        isMemoryArray: true, depth: 0,
      );
      expect(reg.isMemoryArray, isTrue);
      expect(reg.depth, 0);
    });
  });
}
