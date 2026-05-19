import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../auth/bloc/auth_state.dart';
import '../upgrade/upgrade_screen.dart';
import '../export_import/export_screen.dart';
import '../export_import/import_screen.dart';
import '../categories/category_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(const SettingsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Pengaturan'),
        ),
        child: SafeArea(child: _buildBody(isDark)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsLoaded) {
          _applyTheme(context, state.settings.isDarkMode);
        }
      },
      builder: (context, state) {
        if (state is SettingsLoading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final settings = state is SettingsLoaded ? state.settings : null;

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // === AKUN ===
            _buildSectionHeader('Akun'),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final profile = authState is AuthAuthenticated
                    ? authState.profile
                    : null;
                return _buildProfileTile(
                  name: profile?.name ?? 'Pengguna',
                  email: profile?.email ?? '',
                  onTap: () => _navigateToProfile(context),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.logout_rounded,
              title: 'Keluar',
              trailing: null,
              onTap: () => _confirmLogout(context),
            ),
            const Divider(),

            // === TAMPILAN ===
            _buildSectionHeader('Tampilan'),
            _buildSwitchTile(
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: 'Mode Gelap',
              value: settings?.isDarkMode ?? false,
              onChanged: (_) => context
                  .read<SettingsBloc>()
                  .add(const SettingsToggleDarkMode()),
            ),
            const Divider(),

            // === PREFERENSI ===
            _buildSectionHeader('Preferensi'),
            _buildMenuTile(
              icon: Icons.currency_exchange_rounded,
              title: 'Mata Uang',
              trailing: Text(
                settings?.preferredCurrency ?? 'IDR',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _showCurrencyPicker(context),
            ),
            _buildMenuTile(
              icon: Icons.notifications_outlined,
              title: 'Notifikasi',
              trailing: _buildToggle(
                value: settings?.notificationsEnabled ?? true,
              ),
              onTap: () => context
                  .read<SettingsBloc>()
                  .add(const SettingsToggleNotifications()),
            ),
            const Divider(),

            // === DATA ===
            _buildSectionHeader('Data'),
            _buildMenuTile(
              icon: Icons.file_upload_outlined,
              title: 'Ekspor Data',
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportScreen()),
              ),
            ),
            _buildMenuTile(
              icon: Icons.file_download_outlined,
              title: 'Impor Data',
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              ),
            ),
            const Divider(),

            // === KATEGORI ===
            _buildSectionHeader('Kategori'),
            _buildMenuTile(
              icon: Icons.category_outlined,
              title: 'Kelola Kategori',
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryScreen()),
              ),
            ),
            const Divider(),

            // === PREMIUM ===
            _buildSectionHeader('Premium'),
            _buildMenuTile(
              icon: Icons.workspace_premium_rounded,
              title: settings?.isPremium == true
                  ? 'Premium Aktif'
                  : 'Upgrade ke Premium',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: settings?.isPremium == true
                      ? Colors.green
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  settings?.isPremium == true ? 'AKTIF' : 'FREE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                if (settings?.isPremium != true) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                  );
                }
              },
            ),
            const Divider(),

            // === TENTANG ===
            _buildSectionHeader('Tentang'),
            _buildMenuTile(
              icon: Icons.info_outline,
              title: 'Versi Aplikasi',
              trailing: const Text(
                '1.7.0',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {},
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  void _applyTheme(BuildContext context, bool isDarkMode) {
    // Theme is applied via MaterialApp's themeMode
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required String name,
    required String email,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(email, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    if (Platform.isIOS) {
      return ListTile(
        leading: Icon(icon, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        trailing: CupertinoSwitch(value: value, onChanged: onChanged),
      );
    }
    return SwitchListTile(
      secondary: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildToggle({required bool value}) {
    if (Platform.isIOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: (_) {},
      );
    }
    return Switch(
      value: value,
      onChanged: (_) {},
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    final currencies = ['IDR', 'USD', 'EUR', 'SGD', 'MYR', 'JPY', 'GBP', 'AUD'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pilih Mata Uang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ...currencies.map((c) => ListTile(
              title: Text(c),
              trailing: context
                      .read<SettingsBloc>()
                      .state
                      is SettingsLoaded
                  ? ((state) {
                      final s = state as SettingsLoaded;
                      return s.settings.preferredCurrency == c
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                          : null;
                    })(context.read<SettingsBloc>().state)
                  : null,
              onTap: () {
                context
                    .read<SettingsBloc>()
                    .add(SettingsSetCurrency(currency: c));
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      Platform.isIOS
          ? CupertinoPageRoute(builder: (_) => const _ProfileScreen())
          : MaterialPageRoute(builder: (_) => const _ProfileScreen()),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final profile = state is AuthAuthenticated ? state.profile : null;
        final nameController = TextEditingController(text: profile?.name ?? '');

        Widget body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  (profile?.name ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: profile?.email ?? ''),
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(
                  AuthUpdateProfileRequested(name: nameController.text.trim()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil diperbarui')),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Simpan Profil'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showChangePasswordDialog(context),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Ubah Password'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showDeleteAccountDialog(context),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Hapus Akun'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        );

        if (isIOS) {
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Profil'),
            ),
            child: SafeArea(child: body),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil'),
            centerTitle: true,
          ),
          body: body,
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Saat Ini',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Baru',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Password Baru',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password baru tidak cocok')),
                );
                return;
              }
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(
                AuthChangePasswordRequested(
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Semua data termasuk transaksi, aset, hutang, dan budget akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ketik "HAPUS" untuk konfirmasi:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'HAPUS',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (confirmCtrl.text != 'HAPUS') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ketik "HAPUS" untuk konfirmasi'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthDeleteAccountRequested());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus Akun Saya'),
          ),
        ],
      ),
    );
  }
}
