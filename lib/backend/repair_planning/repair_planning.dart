// Barrel export for the Repair Planning Framework.
//
// Consumers import only this file; the internal layout may evolve without
// breaking import paths.

export 'repair_category.dart';
export 'repair_context.dart';
export 'repair_dependency.dart';
export 'repair_plan.dart';     // also exports RepairComplexity via repair_priority.dart
export 'repair_planner.dart';
export 'repair_priority.dart'; // exports RepairPriority + RepairComplexity
export 'repair_statistics.dart';
export 'repair_step.dart';
