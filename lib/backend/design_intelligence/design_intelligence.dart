// Barrel export for the Design Intelligence Framework.
//
// Consumers import only this file; the internal layout may evolve without
// breaking import paths.
export 'design_context.dart';
export 'rtl_preprocessor.dart';
export 'design_knowledge.dart';
export 'design_runner.dart';
export 'knowledge_models.dart';
export 'knowledge_provider.dart';
export 'knowledge_result.dart';

// Providers — re-exported so callers can supply a custom provider list.
export 'providers/clock_provider.dart';
export 'providers/counter_provider.dart';
export 'providers/fsm_provider.dart';
export 'providers/handshake_provider.dart';
export 'providers/module_provider.dart';
export 'providers/register_provider.dart';
export 'providers/reset_provider.dart';
