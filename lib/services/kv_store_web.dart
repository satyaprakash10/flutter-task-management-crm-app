import 'dart:html' as html;

class KVStore {
  static const String _cookiePath = '/';
  static const int _cookieDays = 3650; // ~10 years

  static String _httpDate(DateTime dt) {
    // RFC 1123: Wdy, DD Mon YYYY HH:MM:SS GMT
    const wdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mons = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final u = dt.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    final w = wdays[u.weekday - 1];
    final m = mons[u.month - 1];
    return '$w, ${two(u.day)} $m ${u.year} ${two(u.hour)}:${two(u.minute)}:${two(u.second)} GMT';
  }

  static void _setCookie(String key, String value) {
    final expires = _httpDate(DateTime.now().add(Duration(days: _cookieDays)));
    final encoded = Uri.encodeComponent(value);
    final maxAge = _cookieDays * 24 * 60 * 60;
    html.document.cookie =
        '$key=$encoded; Expires=$expires; Max-Age=$maxAge; Path=$_cookiePath; SameSite=Lax';
  }

  static String? _getCookie(String key) {
    final cookies = html.document.cookie ?? '';
    for (final part in cookies.split(';')) {
      final kv = part.trim().split('=');
      if (kv.length == 2 && kv[0] == key) {
        return Uri.decodeComponent(kv[1]);
      }
    }
    return null;
  }

  static void _removeCookie(String key) {
    final expires = _httpDate(
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    html.document.cookie =
        '$key=; Expires=$expires; Max-Age=0; Path=$_cookiePath; SameSite=Lax';
  }

  static Future<void> setString(String key, String value) async {
    html.window.localStorage[key] = value;
    _setCookie(key, value);
  }

  static Future<String?> getString(String key) async {
    final fromLs = html.window.localStorage[key];
    if (fromLs != null) return fromLs;
    return _getCookie(key);
  }

  static Future<void> setInt(String key, int value) async {
    final v = value.toString();
    html.window.localStorage[key] = v;
    _setCookie(key, v);
  }

  static Future<int?> getInt(String key) async {
    final v = html.window.localStorage[key] ?? _getCookie(key);
    return v == null ? null : int.tryParse(v);
  }

  static Future<Set<String>> getKeys() async {
    return html.window.localStorage.keys.toSet();
  }

  static Future<void> remove(String key) async {
    html.window.localStorage.remove(key);
    _removeCookie(key);
  }
}
