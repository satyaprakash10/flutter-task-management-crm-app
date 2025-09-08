class KVStore {
  static final Map<String, String> _mem = <String, String>{};

  static Future<void> setString(String key, String value) async {
    _mem[key] = value;
  }

  static Future<String?> getString(String key) async {
    return _mem[key];
  }

  static Future<void> setInt(String key, int value) async {
    _mem[key] = value.toString();
  }

  static Future<int?> getInt(String key) async {
    final v = _mem[key];
    return v == null ? null : int.tryParse(v);
  }

  static Future<Set<String>> getKeys() async {
    return _mem.keys.toSet();
  }

  static Future<void> remove(String key) async {
    _mem.remove(key);
  }
}
