import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/todo.dart';

class ApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  static Future<List<Todo>> fetchTodos({int limit = 20}) async {
    final response = await http.get(Uri.parse('$baseUrl/todos?_limit=$limit'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Todo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load todos');
    }
  }

  static Future<List<Todo>> fetchTodosPage({
    required int page,
    int limit = 20,
  }) async {
    final int start = (page - 1) * limit;
    final response = await http.get(
      Uri.parse('$baseUrl/todos?_start=$start&_limit=$limit'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Todo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load todos page');
    }
  }

  static Future<List<Todo>> searchTodos(String query) async {
    final q = query.trim().toLowerCase();
    // Fetch a larger slice and filter client-side since the API has no search
    final List<Todo> all = await fetchTodos(limit: 100);
    if (q.isEmpty) return all;
    final int? id = int.tryParse(q);
    return all.where((t) {
      final title = t.title.toLowerCase();
      final byId = id != null && t.id == id;
      return title.contains(q) || byId;
    }).toList();
  }
}
