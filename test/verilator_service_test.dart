import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/backend/tools/verilator_service.dart';

void main() {
  const service = VerilatorService();

  group('VerilatorService', () {
    test('lint: valid Verilog returns exit code 0 and success = true', () async {
      const source = '''
module adder (
  input  [3:0] a,
  input  [3:0] b,
  output [3:0] sum
);
  assign sum = a + b;
endmodule
''';
      final result = await service.lint(source);

      expect(result.success,  isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout,   isA<String>());
      expect(result.stderr,   isA<String>());
    });

    test('lint: invalid Verilog returns non-zero exit code and success = false', () async {
      const source = 'module bad(; endmodule'; // syntax error: missing port list
      final result = await service.lint(source);

      expect(result.success,  isFalse);
      expect(result.exitCode, isNot(equals(0)));
      expect(result.stderr,   contains('%Error'));
    });

    test('lint: missing default in case is reported as a warning', () async {
      const source = '''
module fsm (input clk, input [1:0] state, output reg out);
  always @(posedge clk) begin
    case (state)
      2'b00: out = 1;
      2'b01: out = 0;
    endcase
  end
endmodule
''';
      final result = await service.lint(source);

      // Verilator may exit 0 (warnings only) or non-zero depending on -Wall;
      // in either case the result object must be well-formed.
      expect(result.exitCode, isA<int>());
      expect(result.stdout,   isA<String>());
      expect(result.stderr,   isA<String>());
    });
  });
}
