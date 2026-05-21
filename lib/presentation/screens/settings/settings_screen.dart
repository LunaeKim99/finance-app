import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../blocs/usage/usage_bloc.dart';
import '../../blocs/usage/usage_state.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../auth/bloc/auth_state.dart';
import '../upgrade/upgrade_screen.dart';
import '../export_import/export_screen.dart';
import '../export_import/import_screen.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../widgets/toggle_switch.dart';

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
    final usageState = context.watch<UsageBloc>().state;
    final isPremium = usageState is UsageLoaded && usageState.isPremium;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final settings = state is SettingsLoaded ? state.settings : null;

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopAppBar(isPremium),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      _buildSectionTitle('Akun'),
                      _buildAccountCard(),
                      const SizedBox(height: AppSpacing.stackMd),
                      _buildSectionTitle('Tampilan'),
                      _buildAppearanceCard(settings?.isDarkMode ?? false),
                      const SizedBox(height: AppSpacing.stackMd),
                      _buildSectionTitle('Preferensi'),
                      _buildPreferencesCard(settings),
                      const SizedBox(height: AppSpacing.stackMd),
                      _buildSectionTitle('Data'),
                      _buildDataCard(),
                      const SizedBox(height: AppSpacing.stackMd),
                      _buildSectionTitle('Premium'),
                      _buildPremiumCard(isPremium),
                      const SizedBox(height: AppSpacing.stackMd),
                      _buildSectionTitle('Tentang'),
                      _buildAboutCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopAppBar(bool isPremium) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: cs.surfaceContainerHighest, width: 0.5)),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.containerPadding),
            Icon(Icons.account_balance_wallet_rounded, color: cs.primary, size: 28),
            const SizedBox(width: 8),
            Text('Uwangku', style: AppTypography.headlineSm.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: cs.primary)),
            const Spacer(),
            if (isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: cs.primary, borderRadius: AppRadius.fullRadius),
                child: Text('Premium', style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary)),
              )
            else
              OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen())),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(color: cs.primary),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Premium', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: AppSpacing.containerPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title.toUpperCase(), style: AppTypography.labelMono.copyWith(fontSize: 11, color: cs.onSurfaceVariant, letterSpacing: 2)),
    );
  }

  Widget _buildWhiteCard(List<Widget> children) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: cs.surfaceContainerHigh),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildAccountCard() {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final profile = authState is AuthAuthenticated ? authState.profile : null;
        final name = profile?.name ?? 'Pengguna';
        final email = profile?.email ?? '';

        return _buildWhiteCard([
          InkWell(
            onTap: () => _navigateToProfile(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Center(child: Text(name[0].toUpperCase(), style: AppTypography.headlineSm.copyWith(color: cs.primary))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
                        const SizedBox(height: 2),
                        Text(email, style: AppTypography.bodySm.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: cs.surfaceContainerLow, indent: 16, endIndent: 16),
          InkWell(
            onTap: () => _confirmLogout(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: cs.surfaceContainer, shape: BoxShape.circle),
                    child: Icon(Icons.logout_rounded, color: cs.onSurfaceVariant, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text('Keluar', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface)),
                ],
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildAppearanceCard(bool isDarkMode) {
    final cs = Theme.of(context).colorScheme;
    return _buildWhiteCard([
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: cs.surfaceContainer, shape: BoxShape.circle),
              child: Icon(Icons.dark_mode_rounded, color: cs.onSurfaceVariant, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text('Mode Gelap', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface))),
            ToggleSwitch(
              value: isDarkMode,
              onChanged: (_) => context.read<SettingsBloc>().add(const SettingsToggleDarkMode()),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildPreferencesCard(dynamic settings) {
    final cs = Theme.of(context).colorScheme;
    final preferredCurrency = settings?.preferredCurrency ?? 'IDR';
    final notificationsEnabled = settings?.notificationsEnabled ?? true;

    return _buildWhiteCard([
      InkWell(
        onTap: () => _showCurrencyPicker(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: cs.surfaceContainer, shape: BoxShape.circle),
                child: Icon(Icons.payments_rounded, color: cs.onSurfaceVariant, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text('Mata Uang', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface))),
              Text(preferredCurrency, style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700, color: cs.primary)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
      Divider(height: 1, color: cs.surfaceContainerLow, indent: 16, endIndent: 16),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: cs.surfaceContainer, shape: BoxShape.circle),
              child: Icon(Icons.notifications_outlined, color: cs.onSurfaceVariant, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text('Notifikasi', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface))),
            ToggleSwitch(
              value: notificationsEnabled,
              onChanged: (_) => context.read<SettingsBloc>().add(const SettingsToggleNotifications()),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildDataCard() {
    final cs = Theme.of(context).colorScheme;
    return _buildWhiteCard([
      InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen())),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: cs.surfaceContainer, shape: BoxShape.circle),
                child: Icon(Icons.file_upload_outlined, color: cs.onSurfaceVariant, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text('Ekspor Data', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface))),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
      Divider(height: 1, color: cs.surfaceContainerLow, indent: 16, endIndent: 16),
      InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen())),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: cs.surfaceContainer, shape: BoxShape.circle),
                child: Icon(Icons.file_download_outlined, color: cs.onSurfaceVariant, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text('Impor Data', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface))),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildPremiumCard(bool isPremium) {
    final cs = Theme.of(context).colorScheme;
    return _buildWhiteCard([
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.verified_rounded, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(isPremium ? 'Premium Aktif' : 'Upgrade ke Premium',
                style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: isPremium ? cs.primary.withValues(alpha: 0.1) : cs.secondaryContainer, borderRadius: AppRadius.fullRadius),
              child: Text(isPremium ? 'AKTIF' : 'FREE',
                style: AppTypography.labelMono.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: isPremium ? cs.primary : cs.secondary)),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildAboutCard() {
    final cs = Theme.of(context).colorScheme;
    return _buildWhiteCard([
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text('Versi Aplikasi', style: TextStyle(fontWeight: FontWeight.w500, color: cs.onSurface))),
            Text('1.7.0', style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    ]);
  }

  void _showCurrencyPicker(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Pilih Mata Uang', style: AppTypography.headlineSm.copyWith(color: cs.onSurface)),
            ),
            Divider(height: 1, color: cs.surfaceContainerHighest),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: AppCurrencies.supported.map((c) {
                  final isSelected = context.read<SettingsBloc>().state is SettingsLoaded &&
                      (context.read<SettingsBloc>().state as SettingsLoaded).settings.preferredCurrency == c.code;
                  return ListTile(
                    title: Text(c.code, style: AppTypography.bodyMd.copyWith(color: cs.onSurface)),
                    subtitle: Text(c.name, style: AppTypography.bodySm.copyWith(color: cs.onSurfaceVariant)),
                    trailing: isSelected ? Icon(Icons.check_rounded, color: cs.primary) : null,
                    onTap: () {
                      context.read<SettingsBloc>().add(SettingsSetCurrency(currency: c.code));
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _ProfileScreen()));
  }

  void _confirmLogout(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text('Keluar', style: TextStyle(color: cs.error)),
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
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final profile = state is AuthAuthenticated ? state.profile : null;
        final nameController = TextEditingController(text: profile?.name ?? '');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil'),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: cs.primary,
                  child: Text(
                    (profile?.name ?? '?')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
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
                  context.read<AuthBloc>().add(AuthUpdateProfileRequested(name: nameController.text.trim()));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil diperbarui')));
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Simpan Profil'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showChangePasswordDialog(context),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Ubah Password'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showDeleteAccountDialog(context),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Hapus Akun'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        title: const Text('Ubah Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password Saat Ini', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password baru tidak cocok')));
                return;
              }
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthChangePasswordRequested(currentPassword: currentCtrl.text, newPassword: newCtrl.text));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        title: const Text('Hapus Akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Semua data akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.', style: TextStyle(fontSize: 13, color: cs.error)),
            const SizedBox(height: 16),
            const Text('Ketik "HAPUS" untuk konfirmasi:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(controller: confirmCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'HAPUS')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              if (confirmCtrl.text != 'HAPUS') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ketik "HAPUS" untuk konfirmasi')));
                return;
              }
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthDeleteAccountRequested());
            },
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Hapus Akun Saya'),
          ),
        ],
      ),
    );
  }
}
