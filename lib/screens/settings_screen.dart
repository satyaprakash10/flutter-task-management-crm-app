import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _tab = 0; // 0 profile, 1 password

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 260),
          child: Material(
            elevation: 1,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile Settings'),
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Password Settings'),
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: _tab == 0
                  ? const _ProfileSettings()
                  : const _PasswordSettings(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSettings extends StatefulWidget {
  const _ProfileSettings();
  @override
  State<_ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<_ProfileSettings> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController company;

  @override
  void initState() {
    super.initState();
    final u = AuthService.currentUser.value;
    name = TextEditingController(text: u?.name ?? '');
    email = TextEditingController(text: u?.email ?? '');
    company = TextEditingController(text: u?.company ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    company.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: email,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email (read-only)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: company,
              decoration: const InputDecoration(
                labelText: 'Company',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                try {
                  await AuthService.updateProfile(
                    name: name.text,
                    company: company.text,
                  );
                  ToastService.success('Profile updated');
                } catch (e) {
                  ToastService.error('Failed to update profile');
                }
                setState(() {});
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordSettings extends StatefulWidget {
  const _PasswordSettings();
  @override
  State<_PasswordSettings> createState() => _PasswordSettingsState();
}

class _PasswordSettingsState extends State<_PasswordSettings> {
  final _form = GlobalKey<FormState>();
  final current = TextEditingController();
  final next = TextEditingController();
  final again = TextEditingController();

  String? _notEmpty(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    again.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: current,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: _notEmpty,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: next,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Min 6 chars' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: again,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (v) =>
                  v != next.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (_form.currentState!.validate()) {
                  try {
                    await AuthService.updatePassword(
                      currentPassword: current.text,
                      newPassword: next.text,
                    );
                    ToastService.success('Password updated');
                    current.clear();
                    next.clear();
                    again.clear();
                  } catch (e) {
                    ToastService.error(e.toString());
                  }
                }
              },
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}
