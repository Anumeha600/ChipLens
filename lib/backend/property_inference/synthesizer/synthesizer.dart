// Barrel export for the Property Synthesizer layer.
//
// Consumers import only this file; the internal layout may evolve without
// breaking import paths.

// Core types
export 'candidate_property_type.dart';
export 'candidate_property.dart';
export 'candidate_property_set.dart';
export 'synthesis_rule.dart';
export 'property_synthesizer.dart';

// Rules — re-exported so callers can supply a custom rule list.
export 'rules/counter_rule.dart';
export 'rules/fsm_rule.dart';
export 'rules/handshake_rule.dart';
export 'rules/register_rule.dart';
export 'rules/reset_rule.dart';
