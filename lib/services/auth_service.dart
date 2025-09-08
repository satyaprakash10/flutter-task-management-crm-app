import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'kv_store.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String company;
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.company,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'company': company,
  };
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    company: json['company'] ?? '',
  );
}

class AuthService {
  static final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);
  static final ValueNotifier<bool> ready = ValueNotifier<bool>(false);
  static const String _kAuthUser = 'auth_current_user';
  static const String _kAuthPasswords = 'auth_passwords';
  static const String _kUsers = 'auth_users';

  // Demo credentials
  static const String _demoEmail = 'admin@demo.com';
  static const String _demoPassword = 'admin123';

  static final Map<String, String> _registry = <String, String>{};
  static final Map<String, User> _users = <String, User>{};

  static Future<void> init() async {
    // Load persisted user
    final raw = await KVStore.getString(_kAuthUser);
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(raw) as Map<String, dynamic>;
        currentUser.value = User.fromJson(data);
      } catch (_) {
        // ignore corrupt data
      }
    }

    // Load persisted password registry
    final reg = await KVStore.getString(_kAuthPasswords);
    if (reg != null && reg.isNotEmpty) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(reg) as Map<String, dynamic>;
        _registry
          ..clear()
          ..addAll(data.map((k, v) => MapEntry(k, (v ?? '').toString())));
      } catch (_) {}
    }

    // Load users map
    final usersRaw = await KVStore.getString(_kUsers);
    if (usersRaw != null && usersRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(usersRaw) as Map<String, dynamic>;
        _users
          ..clear()
          ..addAll(data.map((k, v) => MapEntry(k, User.fromJson(v))));
      } catch (_) {}
    }

    // Ensure demo user exists
    _users.putIfAbsent(
      _demoEmail,
      () => const User(
        id: '1',
        name: 'Admin',
        email: _demoEmail,
        company: 'Demo Inc.',
      ),
    );

    ready.value = true;
  }

  static Future<void> _persist(User? user) async {
    if (user == null) {
      await KVStore.remove(_kAuthUser);
    } else {
      await KVStore.setString(_kAuthUser, jsonEncode(user.toJson()));
    }
  }

  static Future<void> _persistRegistry() async {
    await KVStore.setString(_kAuthPasswords, jsonEncode(_registry));
  }

  static Future<void> _persistUsers() async {
    final map = _users.map((k, v) => MapEntry(k, v.toJson()));
    await KVStore.setString(_kUsers, jsonEncode(map));
  }

  static Future<User> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final hasCustom = _registry.containsKey(email);
    final valid = hasCustom
        ? _registry[email] == password
        : (email == _demoEmail && password == _demoPassword);
    if (valid) {
      final user =
          _users[email] ??
          User(id: '1', name: 'Admin', email: _demoEmail, company: 'Demo Inc.');
      currentUser.value = user;
      await _persist(user);
      return user;
    }
    throw Exception('Invalid credentials');
  }

  static Future<User> signUp({
    required String name,
    required String email,
    required String password,
    required String company,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_registry.containsKey(email) || email == _demoEmail) {
      throw Exception('Email already registered');
    }
    _registry[email] = password;
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      company: company,
    );
    _users[email] = user;
    await _persistRegistry();
    await _persistUsers();
    currentUser.value = user;
    await _persist(user);
    return user;
  }

  static Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    currentUser.value = null;
    await _persist(null);
  }

  static Future<User> updateProfile({String? name, String? company}) async {
    final user = currentUser.value;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    final updated = User(
      id: user.id,
      name: name?.trim().isNotEmpty == true ? name!.trim() : user.name,
      email: user.email,
      company: company?.trim().isNotEmpty == true
          ? company!.trim()
          : user.company,
    );
    currentUser.value = updated;
    _users[user.email] = updated;
    await _persist(updated);
    await _persistUsers();
    return updated;
  }

  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser.value;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    final email = user.email;
    final hasCustom = _registry.containsKey(email);
    final ok = hasCustom
        ? _registry[email] == currentPassword
        : (email == _demoEmail && currentPassword == _demoPassword);
    if (!ok) {
      throw Exception('Current password is incorrect');
    }
    _registry[email] = newPassword;
    await _persistRegistry();
  }
}
