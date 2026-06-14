import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';


// ────────────────────────────────────────────────────────────
//  Timezone & date-format options
// ────────────────────────────────────────────────────────────
const _timezones = [
  'UTC',
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'Asia/Dubai',
  'Asia/Karachi',
  'Asia/Kolkata',
  'Asia/Dhaka',
  'Asia/Bangkok',
  'Asia/Singapore',
  'Asia/Tokyo',
  'Australia/Sydney',
  'Pacific/Auckland',
];

const _dateFormats = [
  'dd/MM/yyyy',
  'MM/dd/yyyy',
  'yyyy-MM-dd',
  'dd-MM-yyyy',
  'dd.MM.yyyy',
  'MMMM dd, yyyy',
];

// ────────────────────────────────────────────────────────────
//  Main screen
// ────────────────────────────────────────────────────────────
class PlatformSettingsScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;

  const PlatformSettingsScreen({super.key, required this.onRouteSelected});

  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // ── Page header ──────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Platform Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Configure your store details, currency, tax & contact info.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Tab bar ──────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: AppColors.border),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(
                icon: Icon(Icons.store_outlined, size: 18),
                text: 'General',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: Icon(Icons.percent_rounded, size: 18),
                text: 'Currency & Tax',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: Icon(Icons.contact_phone_outlined, size: 18),
                text: 'Contact',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
            ],
          ),
        ),

        // ── Tab content ──────────────────────────────────────
        Container(
          height: 520,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            border: Border(
              left: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _GeneralTab(onRouteSelected: widget.onRouteSelected),
              _CurrencyTaxTab(onRouteSelected: widget.onRouteSelected),
              _ContactTab(onRouteSelected: widget.onRouteSelected),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
//  TAB 1 – General
// ============================================================
class _GeneralTab extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  const _GeneralTab({required this.onRouteSelected});

  @override
  State<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends State<_GeneralTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prefixController = TextEditingController();
  String _timezone = 'UTC';
  String _dateFormat = 'dd/MM/yyyy';
  String? _logoPath;
  bool _continueSelling = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = PlatformSettingsService.instance.settings;
    _nameController.text = s.platformName;
    _prefixController.text = s.invoicePrefix;
    _timezone = s.timezone;
    _dateFormat = s.dateFormat;
    _logoPath = s.logoPath;
    _continueSelling = s.continueSellingWhenStockEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final updated = PlatformSettingsService.instance.settings.copyWith(
      platformName: _nameController.text.trim(),
      invoicePrefix: _prefixController.text.trim(),
      timezone: _timezone,
      dateFormat: _dateFormat,
      logoPath: _logoPath,
      continueSellingWhenStockEmpty: _continueSelling,
    );
    try {
      await PlatformSettingsService.instance.updateSettings(updated);
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('General settings saved successfully!', AppColors.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Failed to save: $e', AppColors.danger);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Branding'),
            const SizedBox(height: 16),

            // Logo preview + picker row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo preview box
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _logoPath != null && File(_logoPath!).existsSync()
                      ? Image.file(File(_logoPath!), fit: BoxFit.contain)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No Logo',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Store Logo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Recommended: 200×200px PNG or JPG. Shown on invoices and the login screen.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Logo upload via manual path entry dialog
                          _showLogoPathDialog();
                        },
                        icon: const Icon(Icons.upload_rounded, size: 16),
                        label: const Text('Choose Image'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      if (_logoPath != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => setState(() => _logoPath = null),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 15,
                            color: AppColors.danger,
                          ),
                          label: const Text(
                            'Remove logo',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            _sectionTitle('Store Details'),
            const SizedBox(height: 16),
            _buildField(
              label: 'Platform Name *',
              controller: _nameController,
              hint: 'e.g. IMS POS',
              required: true,
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Invoice Prefix *',
              controller: _prefixController,
              hint: 'e.g. INV-',
              required: true,
              helperText: 'Invoices will be numbered INV-0001, INV-0002…',
            ),
            const SizedBox(height: 28),
            _sectionTitle('Locale'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Timezone',
                    value: _timezone,
                    items: _timezones,
                    onChanged: (v) => setState(() => _timezone = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Date Format',
                    value: _dateFormat,
                    items: _dateFormats,
                    onChanged: (v) => setState(() => _dateFormat = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _sectionTitle('Sales Rules'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                'Continue Selling When Stock is Empty',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              subtitle: const Text(
                'Allow products to be sold even if their available stock quantity is 0 or negative.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              value: _continueSelling,
              onChanged: (v) => setState(() => _continueSelling = v),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            _saveButton(_isSaving, _save),
          ],
        ),
      ),
    );
  }

  void _showLogoPathDialog() {
    final controller = TextEditingController(text: _logoPath ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Set Logo Path',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the absolute file path to your logo image.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'C:\\images\\logo.png',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final path = controller.text.trim();
              if (path.isNotEmpty) setState(() => _logoPath = path);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  TAB 2 – Currency & Tax
// ============================================================
class _CurrencyTaxTab extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  const _CurrencyTaxTab({required this.onRouteSelected});

  @override
  State<_CurrencyTaxTab> createState() => _CurrencyTaxTabState();
}

class _CurrencyTaxTabState extends State<_CurrencyTaxTab> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _symbolController = TextEditingController();
  final _taxNameController = TextEditingController();
  final _taxRateController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = PlatformSettingsService.instance.settings;
    _codeController.text = s.currencyCode;
    _symbolController.text = s.currencySymbol;
    _taxNameController.text = s.taxName;
    _taxRateController.text = s.taxRate.toString();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _symbolController.dispose();
    _taxNameController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final rate = double.tryParse(_taxRateController.text.trim()) ?? 0.0;
    final updated = PlatformSettingsService.instance.settings.copyWith(
      currencyCode: _codeController.text.trim(),
      currencySymbol: _symbolController.text.trim(),
      taxName: _taxNameController.text.trim(),
      taxRate: rate,
    );
    try {
      await PlatformSettingsService.instance.updateSettings(updated);
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Currency & Tax settings saved!', AppColors.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Failed to save: $e', AppColors.danger);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Currency'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'Currency Code *',
                    controller: _codeController,
                    hint: 'e.g. USD, PKR, EUR',
                    required: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    label: 'Currency Symbol *',
                    controller: _symbolController,
                    hint: 'e.g. \$, ₹, £, ₨',
                    required: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Live preview card
            _CurrencyPreviewCard(
              symbol: _symbolController,
              code: _codeController,
            ),

            const SizedBox(height: 32),
            const Divider(color: AppColors.border),
            const SizedBox(height: 24),
            _sectionTitle('Tax'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'Tax Name *',
                    controller: _taxNameController,
                    hint: 'e.g. VAT, GST, Sales Tax',
                    required: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    label: 'Tax Rate (%)',
                    controller: _taxRateController,
                    hint: 'e.g. 15',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final d = double.tryParse(v.trim());
                      if (d == null) return 'Enter a valid number';
                      if (d < 0 || d > 100) return '0–100 only';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tax info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The tax rate set here will be used as the default on new invoices. '
                      'You can override it per invoice.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.info.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _saveButton(_isSaving, _save),
          ],
        ),
      ),
    );
  }
}

// ── Live currency preview widget ─────────────────────────────
class _CurrencyPreviewCard extends StatefulWidget {
  final TextEditingController symbol;
  final TextEditingController code;

  const _CurrencyPreviewCard({required this.symbol, required this.code});

  @override
  State<_CurrencyPreviewCard> createState() => _CurrencyPreviewCardState();
}

class _CurrencyPreviewCardState extends State<_CurrencyPreviewCard> {
  @override
  void initState() {
    super.initState();
    widget.symbol.addListener(_rebuild);
    widget.code.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.symbol.removeListener(_rebuild);
    widget.code.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sym = widget.symbol.text.isEmpty ? '?' : widget.symbol.text;
    final code = widget.code.text.isEmpty ? '???' : widget.code.text;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                sym,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Currency Preview',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$sym 1,234.00',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                code,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  TAB 3 – Contact
// ============================================================
class _ContactTab extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  const _ContactTab({required this.onRouteSelected});

  @override
  State<_ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<_ContactTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = PlatformSettingsService.instance.settings;
    _emailController.text = s.contactEmail;
    _phoneController.text = s.contactPhone;
    _addressController.text = s.address;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final updated = PlatformSettingsService.instance.settings.copyWith(
      contactEmail: _emailController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );
    try {
      await PlatformSettingsService.instance.updateSettings(updated);
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Contact info saved successfully!', AppColors.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Failed to save: $e', AppColors.danger);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Contact Information'),
            const SizedBox(height: 4),
            Text(
              'This information will appear on invoices and receipts.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'Contact Email',
                    controller: _emailController,
                    hint: 'support@example.com',
                    icon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final emailRx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      return emailRx.hasMatch(v.trim())
                          ? null
                          : 'Enter a valid email';
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    label: 'Contact Phone',
                    controller: _phoneController,
                    hint: '+1 234 567 890',
                    icon: Icons.phone_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    'Enter your store/business address…',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _saveButton(_isSaving, _save),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Shared helpers (file-level functions)
// ============================================================

Widget _sectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.textMain,
      letterSpacing: 0.2,
    ),
  );
}

Widget _buildField({
  required String label,
  required TextEditingController controller,
  required String hint,
  bool required = false,
  IconData? icon,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters,
  String? helperText,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
      ),
      const SizedBox(height: 7),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: _inputDecoration(hint, prefixIcon: icon),
        validator:
            validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty)
                      ? 'This field is required.'
                      : null
                : null),
      ),
      if (helperText != null) ...[
        const SizedBox(height: 5),
        Text(
          helperText,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    ],
  );
}

Widget _buildDropdown({
  required String label,
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
      ),
      const SizedBox(height: 7),
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: _inputDecoration(''),
        style: const TextStyle(fontSize: 14, color: AppColors.textMain),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    ],
  );
}

Widget _saveButton(bool isSaving, VoidCallback onSave) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      ElevatedButton.icon(
        onPressed: isSaving ? null : onSave,
        icon: isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded, size: 17),
        label: Text(
          isSaving ? 'Saving…' : 'Save Changes',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ],
  );
}

InputDecoration _inputDecoration(String hint, {IconData? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary)
        : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}
