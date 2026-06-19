import 'dart:io';
import 'dart:math';

/// Low-level OS utilities shared by all [VerificationTool] implementations.
/// Has no imports from business layers — safe to import from any layer without
/// introducing circular dependencies.
abstract class ProcessUtilities {
  ProcessUtilities._();

  static final _rng = Random();

  static Future<ProcessResult> runProcess(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) =>
      Process.run(executable, arguments,
          workingDirectory: workingDirectory);

  /// Creates a uniquely-named temp directory.
  ///
  /// Uses both a microsecond timestamp and a random suffix so that concurrent
  /// invocations within the same microsecond don't collide.
  static Future<Directory> makeTempDir(String prefix) async {
    final ts   = DateTime.now().microsecondsSinceEpoch;
    final rand = _rng.nextInt(0xFFFF);
    final dir  = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}${prefix}_${ts}_$rand',
    );
    return dir.create(recursive: true);
  }

  static Future<void> cleanupDir(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  /// Creates a uniquely-named temp file.
  ///
  /// Uses both a microsecond timestamp and a random suffix so that concurrent
  /// invocations within the same microsecond don't collide.
  static Future<File> writeTempFile(
    String source, {
    required String prefix,
    required String extension,
  }) async {
    final ts   = DateTime.now().microsecondsSinceEpoch;
    final rand = _rng.nextInt(0xFFFF);
    final path =
        '${Directory.systemTemp.path}${Platform.pathSeparator}${prefix}_${ts}_$rand.$extension';
    final file = File(path);
    await file.writeAsString(source);
    return file;
  }

  static Future<void> deleteFile(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
