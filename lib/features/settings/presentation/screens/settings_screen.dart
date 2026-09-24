import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/common.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/app_version.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Settings Screen — company-wide defaults backed by `public.settings`
///
/// Deliberately not cubit-driven: this screen is the only reader of its state —
/// one load, one save, no list and no filters, so a cubit would be a second
/// place to hold the same seven values.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService.instance;
  final _formKey = GlobalKey<FormState>();

  late final Map<String, TextEditingController> _controllers = {
    for (final key in SettingsService.defaults.keys) key: TextEditingController(),
  };

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final values = await _service.fetchGlobalSettings();
      if (!mounted) return;
      for (final entry in values.entries) {
        _controllers[entry.key]?.text = entry.value.toString();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      await _service.saveGlobalSettings({
        for (final entry in _controllers.entries)
          entry.key: SettingsService.numericKeys.contains(entry.key)
              ? _parseNumber(entry.value.text)
              : entry.value.text.trim(),
      });
      if (!mounted) return;
      context.showSuccessSnackBar('Settings saved');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(
        'Could not save settings: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// The rate fields accept decimals, so parse as [num]: `int.tryParse` returns
  /// null for "18.5" and the save would silently write 0% GST. Whole values are
  /// kept as ints so the stored JSONB matches the shape the seed wrote.
  static num _parseNumber(String raw) {
    final value = double.tryParse(raw.trim()) ?? 0;
    return value == value.roundToDouble() ? value.toInt() : value;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      activeNavigationId: 'settings',
      currentShowroomName: 'Administration',
      title: 'Settings',
      actions: [
        AppButton.secondary(
          label: 'Reload',
          leadingIcon: Icons.refresh_rounded,
          onPressed: _isLoading ? null : _load,
        ),
      ],
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) return AppSkeleton.form(sections: 3, fields: 2);

    if (_loadError != null) {
      return AppErrorState(
        title: 'Could not load settings',
        message: _loadError!,
        onRetry: _load,
      );
    }

    return SingleChildScrollView(
      padding: ResponsiveUtils.contentPadding(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Application Settings',
              subtitle:
                  'Company-wide defaults shared by every showroom. Stored in the settings table; '
                  'per-branch overrides are managed from the showroom itself.',
              trailing: AppButton.primary(
                label: 'Save Changes',
                leadingIcon: Icons.save_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing20),

            // ─── Branding & Identity ───
            AppFormSection(
              title: 'Branding & Identity',
              subtitle: 'Name shown across the ERP and the address customers are directed to',
              children: [
                ResponsiveFieldRow(
                  children: [
                    _textField(
                      'app_name',
                      label: 'Application Name',
                      hint: 'MYBIKE ERP',
                      icon: Icons.badge_outlined,
                    ),
                    _textField(
                      'support_email',
                      label: 'Support Email',
                      hint: 'support@mybike.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final clean = (value ?? '').trim();
                        if (clean.isEmpty) return 'Support email is required';
                        if (!clean.contains('@')) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // ─── Currency ───
            AppFormSection(
              title: 'Currency',
              subtitle: 'Formatting applied to every invoice, voucher and report total',
              children: [
                ResponsiveFieldRow(
                  children: [
                    _textField(
                      'currency_code',
                      label: 'Currency Code',
                      hint: 'INR',
                      icon: Icons.currency_exchange_rounded,
                      validator: (value) {
                        final clean = (value ?? '').trim();
                        if (clean.isEmpty) return 'Currency code is required';
                        if (clean.length != 3) return 'Use the 3-letter ISO code';
                        return null;
                      },
                    ),
                    _textField(
                      'currency_symbol',
                      label: 'Currency Symbol',
                      hint: '₹',
                      icon: Icons.currency_rupee_rounded,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // ─── Tax Defaults ───
            AppFormSection(
              title: 'Tax Defaults',
              subtitle:
                  'Pre-filled on new line items. Accessories & parts use the standard rate, '
                  'two-wheelers the vehicle rate, and electric models the concessional EV rate.',
              children: [
                ResponsiveFieldRow(
                  children: [
                    _rateField('default_gst_rate', label: 'Accessories & Parts GST %', hint: '18'),
                    _rateField('vehicle_gst_rate', label: 'Vehicle GST %', hint: '28'),
                    _rateField('ev_gst_rate', label: 'Electric Vehicle GST %', hint: '5'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // ─── Appearance ───
            AppFormSection(
              title: 'Appearance',
              subtitle: 'Display theme for this device. Saved locally, not shared with other users.',
              children: [
                BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, state) => AppDropdown<ThemeMode>(
                    label: 'Theme Mode',
                    value: state.themeMode,
                    items: ThemeMode.values,
                    itemLabel: _themeLabel,
                    prefixIcon: Icons.palette_outlined,
                    onChanged: (mode) {
                      if (mode != null) context.read<ThemeCubit>().setThemeMode(mode);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // ─── System Information (read-only) ───
            AppCard(
              title: 'System Information',
              subtitle: 'Runtime diagnostics — the same values are printed to the console at start-up',
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Application',
                    value: '${AppVersion.appName} · ${AppVersion.displayVersion}',
                  ),
                  _InfoRow(
                    icon: Icons.bolt_outlined,
                    label: 'Environment',
                    value: AppConfig.current.environment.name.toUpperCase(),
                  ),
                  _InfoRow(
                    icon: Icons.build_outlined,
                    label: 'Build Channel',
                    value: '${AppVersion.buildChannel} · ${AppVersion.fullVersion}',
                  ),
                  _InfoRow(
                    icon: SupabaseConfig.isLive
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    label: 'Supabase',
                    value: SupabaseConfig.isLive
                        ? 'Connected · ${SupabaseConfig.url}'
                        : SupabaseConfig.isConfigured
                            ? 'Credentials rejected — running on local demo data'
                            : 'Not configured — running on local demo data',
                    valueColor: SupabaseConfig.isLive ? AppColors.success : AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacing32),

            // ─── Action Buttons ───
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.ghost(
                  label: 'Discard Changes',
                  onPressed: _isSaving ? null : _load,
                ),
                const SizedBox(width: AppDimensions.spacing12),
                AppButton.primary(
                  label: 'Save Changes',
                  leadingIcon: Icons.save_rounded,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    String key, {
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return AppTextField(
      controller: _controllers[key],
      label: label,
      hint: hint,
      isRequired: true,
      prefixIcon: icon,
      keyboardType: keyboardType,
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) return '$label is required';
            return null;
          },
    );
  }

  Widget _rateField(String key, {required String label, String? hint}) {
    return AppTextField(
      controller: _controllers[key],
      label: label,
      hint: hint,
      isRequired: true,
      keyboardType: TextInputType.number,
      prefixIcon: Icons.percent_rounded,
      validator: (value) {
        final parsed = double.tryParse((value ?? '').trim());
        if (parsed == null) return 'Enter a number';
        if (parsed < 0 || parsed > 100) return 'Must be between 0 and 100';
        return null;
      },
    );
  }

  static String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };
}

/// Read-only label/value line used by the System Information card.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppDimensions.iconSm,
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
          const SizedBox(width: AppDimensions.spacing12),
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ??
                    (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
