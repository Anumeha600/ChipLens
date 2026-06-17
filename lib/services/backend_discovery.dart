import 'dart:convert';
import 'dart:io';
import '../config/app_config.dart';

/// Scans the local WiFi subnet to find the ChipLens backend.
///
/// Strategy:
///   1. Try the currently configured base URL (instant if IP hasn't changed).
///   2. Get the phone's local IP, derive the /24 subnet, scan all 254 hosts
///      in parallel with a 500 ms TCP timeout.
///   3. For any host with port 3000 open, send a GET /ping and check that the
///      response contains {"data":{"service":"chiplens"}}.
///   4. On success, call AppConfig.setResolvedBase() so all subsequent API
///      calls use the discovered URL.
class BackendDiscovery {
  static const int _port = 3000;
  static const Duration _timeout = Duration(milliseconds: 500);

  /// Run discovery. Returns the resolved base URL on success, null on failure.
  static Future<String?> discover() async {
    // Fast path — try whatever URL is currently configured.
    final current = AppConfig.apiBase;
    if (await _isChipLens(current)) return current;

    // Determine the subnet from the phone's own IP.
    final myIp = await _getLocalIp();
    if (myIp == null) return null;

    final prefix = myIp.split('.').take(3).join('.');
    final found = await _scanSubnet(prefix);

    if (found != null) {
      AppConfig.setResolvedBase(found);
    }

    return found;
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  /// Scan all 254 hosts on the /24 subnet concurrently.
  static Future<String?> _scanSubnet(String prefix) async {
    final futures = List.generate(
      254,
      (i) => _checkHost('$prefix.${i + 1}'),
    );

    // Return the first non-null result; ignore nulls.
    final results = await Future.wait(futures, eagerError: false);
    for (final r in results) {
      if (r != null) return r;
    }
    return null;
  }

  /// TCP-connect to port 3000 on [ip], then verify with an HTTP ping.
  static Future<String?> _checkHost(String ip) async {
    try {
      // TCP port check — much faster than a full HTTP round-trip.
      final socket = await Socket.connect(ip, _port, timeout: _timeout);
      socket.destroy();

      // Confirm this is actually the ChipLens backend.
      final base = 'http://$ip:$_port/api/v1';
      if (await _isChipLens(base)) return base;
    } catch (_) {
      // Host not reachable or not ChipLens — ignore.
    }
    return null;
  }

  /// Returns true iff [base]/ping responds with service=="chiplens".
  static Future<bool> _isChipLens(String base) async {
    try {
      final client = HttpClient()..connectionTimeout = _timeout;
      final req = await client.getUrl(Uri.parse('$base/ping'));
      final res = await req.close().timeout(_timeout);
      if (res.statusCode != 200) return false;

      final body = await res.transform(utf8.decoder).join().timeout(_timeout);
      final json = jsonDecode(body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      return data?['service'] == 'chiplens';
    } catch (_) {
      return false;
    }
  }

  /// Returns the device's first non-loopback IPv4 address.
  static Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }
}
