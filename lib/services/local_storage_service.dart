import 'dart:convert';
import '../models/todo.dart';
import 'kv_store.dart';

class LocalStorageService {
  static const String _tasksKeyPrefix = 'tasks_page_';
  static const String _tasksAllKey = 'tasks_all';
  static const String _totalKey = 'tasks_total_count';

  static Future<void> saveTasksForPage(int page, List<Todo> tasks) async {
    final key = '$_tasksKeyPrefix$page';
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await KVStore.setString(key, jsonEncode(jsonList));
  }

  static Future<List<Todo>> loadTasksForPage(int page) async {
    final key = '$_tasksKeyPrefix$page';
    final raw = await KVStore.getString(key);
    if (raw == null || raw.isEmpty) return <Todo>[];
    try {
      final List<dynamic> data = jsonDecode(raw);
      return data.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return <Todo>[];
    }
  }

  static Future<void> saveAllTasks(List<Todo> tasks) async {
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await KVStore.setString(_tasksAllKey, jsonEncode(jsonList));
    await saveTotalCount(tasks.length);

    // Clear old page caches and seed page 1 for immediate reads
    final keys = await KVStore.getKeys();
    for (final k in keys) {
      if (k.startsWith(_tasksKeyPrefix)) {
        await KVStore.remove(k);
      }
    }
    final firstPage = tasks.length <= 10 ? tasks : tasks.sublist(0, 10);
    await KVStore.setString(
      '${_tasksKeyPrefix}1',
      jsonEncode(firstPage.map((t) => t.toJson()).toList()),
    );
  }

  static Future<List<Todo>> loadAllTasks() async {
    final raw = await KVStore.getString(_tasksAllKey);
    if (raw == null || raw.isEmpty) return <Todo>[];
    try {
      final List<dynamic> data = jsonDecode(raw);
      return data.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return <Todo>[];
    }
  }

  static Future<void> saveTotalCount(int total) async {
    await KVStore.setInt(_totalKey, total);
  }

  static Future<int?> loadTotalCount() async {
    return KVStore.getInt(_totalKey);
  }
}
