import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// A small helper that periodically fetches a JSON URL and exposes the last
/// fetched value. It uses a timer and will continue polling regardless of
/// whether any UI is listening. This runs in-app (not server-side).
class RemoteFetcher<T> {
  final String url;
  final Duration interval;
  final T Function(dynamic json) parser;

  Timer? _timer;
  T? _last;
  bool _isFetching = false;

  RemoteFetcher({required this.url, required this.interval, required this.parser});

  T? get last => _last;

  void start() {
    if (_timer != null) return; // already running
    // run immediately
    _fetchOnce();
    _timer = Timer.periodic(interval, (_) => _fetchOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetchOnce() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final jsonBody = json.decode(res.body);
        _last = parser(jsonBody);
      }
    } catch (_) {
      // ignore errors; keep last value
    } finally {
      _isFetching = false;
    }
  }
}
