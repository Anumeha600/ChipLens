import '../../formal/formal_property.dart';
import '../../formal/formal_property_type.dart';
import '../property_context.dart';
import '../property_models.dart';
import '../property_provider.dart';
import '../property_result.dart';

// ─── SafetyPropertyProvider ───────────────────────────────────────────────────

/// Infers generic structural safety properties from [DesignKnowledge].
///
/// Strategy (in priority order):
///
/// 1. **Module output + sequential register** → registered output stable between
///    clock edges.
/// 2. **Module output + combinational register** → combinational output always
///    holds a defined (non-X) value.
/// 3. **Module output, type unknown** → generic "output always defined" property.
/// 4. **No module info but sequential registers present** → register-level
///    stability property (fallback for designs with no detected module boundary).
class SafetyPropertyProvider implements PropertyProvider {
  const SafetyPropertyProvider();

  @override
  String get providerKey => 'safety';

  @override
  Future<PropertyResult> infer(PropertyContext context) async {
    final dk    = context.knowledge;
    final props = <FormalProperty>[];

    final seqNames  = {for (final r in dk.registers.where((r) => r.isSequential))  r.name};
    final combNames = {for (final r in dk.registers.where((r) => r.isCombinational)) r.name};

    // Derive clock name for stable-output expressions.
    final clkName = dk.primaryClocks.isNotEmpty
        ? dk.primaryClocks.first.name
        : 'clk';

    if (dk.modules.isNotEmpty) {
      for (final mod in dk.modules) {
        for (final port in mod.outputs) {
          final safetyId = '${PropertyIdPrefix.safety}.${mod.name}.${port.name}';

          if (seqNames.contains(port.name)) {
            props.add(FormalProperty(
              id:           '$safetyId.stable',
              name:         '${port.name} (${mod.name}) registered output stable',
              description:  'Registered output ${port.name} must not change outside a clock edge.',
              propertyType: FormalPropertyType.safety,
              severity:     'error',
              expression:   'always(\$stable(${port.name}) || \$rose($clkName))',
              metadata: {
                'confidence': PropertyConfidence.likely.name,
                'module':     mod.name,
                'port':       port.name,
                'type':       'registered',
              },
            ));
          } else if (combNames.contains(port.name)) {
            props.add(FormalProperty(
              id:           '$safetyId.defined',
              name:         '${port.name} (${mod.name}) combinational output defined',
              description:  'Combinational output ${port.name} must always be driven to a defined value.',
              propertyType: FormalPropertyType.safety,
              severity:     'warning',
              expression:   'always(\$isunknown(${port.name}) == 0)',
              metadata: {
                'confidence': PropertyConfidence.candidate.name,
                'module':     mod.name,
                'port':       port.name,
                'type':       'combinational',
              },
            ));
          } else {
            props.add(FormalProperty(
              id:           '$safetyId.defined',
              name:         '${port.name} (${mod.name}) output always defined',
              description:  'Output ${port.name} must always hold a defined value.',
              propertyType: FormalPropertyType.safety,
              severity:     'warning',
              expression:   'always(\$isunknown(${port.name}) == 0)',
              metadata: {
                'confidence': PropertyConfidence.candidate.name,
                'module':     mod.name,
                'port':       port.name,
              },
            ));
          }
        }
      }
    } else if (seqNames.isNotEmpty) {
      // Fallback: no module boundary detected — emit register-level stability.
      for (final name in seqNames) {
        props.add(FormalProperty(
          id:           '${PropertyIdPrefix.safety}.register.$name.stable',
          name:         '$name sequential register stable',
          description:  'Sequential register $name must not change outside a clock edge.',
          propertyType: FormalPropertyType.safety,
          severity:     'warning',
          expression:   'always(\$stable($name) || \$rose($clkName))',
          metadata: {
            'confidence': PropertyConfidence.candidate.name,
            'register':   name,
          },
        ));
      }
    }

    return PropertyResult(providerKey: providerKey, properties: props);
  }
}
