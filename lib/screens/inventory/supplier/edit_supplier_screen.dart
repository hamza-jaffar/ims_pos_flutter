import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/supplier.dart';
import 'package:ims_pos_system/services/supplier_service.dart';

class EditSupplierScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  final int supplierId;
  final Supplier? initialSupplier;

  const EditSupplierScreen({
    super.key,
    required this.onRouteSelected,
    required this.supplierId,
    this.initialSupplier,
  });

  @override
  State<EditSupplierScreen> createState() => _EditSupplierScreenState();
}

class _EditSupplierScreenState extends State<EditSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _taxIdController = TextEditingController();
  bool _isActive = true;
  bool _isSaving = false;
  bool _isLoading = true;
  Supplier? _supplier;

  @override
  void initState() {
    super.initState();
    if (widget.initialSupplier != null) {
      _populateFields(widget.initialSupplier!);
      _isLoading = false;
    } else {
      _loadSupplier();
    }
  }

  Future<void> _loadSupplier() async {
    final supplier = await SupplierService.instance.getById(widget.supplierId);
    if (mounted) {
      if (supplier != null) {
        _populateFields(supplier);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier not found.'),
            backgroundColor: AppColors.danger,
          ),
        );
        widget.onRouteSelected(AppRoutes.suppliers);
      }
      setState(() => _isLoading = false);
    }
  }

  void _populateFields(Supplier supplier) {
    _supplier = supplier;
    _nameController.text = supplier.name;
    _emailController.text = supplier.email ?? '';
    _phoneController.text = supplier.phone ?? '';
    _addressController.text = supplier.address ?? '';
    _cityController.text = supplier.city ?? '';
    _stateController.text = supplier.state ?? '';
    _countryController.text = supplier.country ?? '';
    _zipCodeController.text = supplier.zipCode ?? '';
    _contactPersonController.text = supplier.contactPerson ?? '';
    _paymentTermsController.text = supplier.paymentTerms ?? '';
    _taxIdController.text = supplier.taxId ?? '';
    _isActive = supplier.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipCodeController.dispose();
    _contactPersonController.dispose();
    _paymentTermsController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_supplier == null) return;

    final nameExists = await SupplierService.instance.nameExists(
      _nameController.text.trim(),
      excludeId: _supplier!.id,
    );
    if (nameExists && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A supplier with this name already exists.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updated = _supplier!.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty
          ? null
          : _stateController.text.trim(),
      country: _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim(),
      zipCode: _zipCodeController.text.trim().isEmpty
          ? null
          : _zipCodeController.text.trim(),
      contactPerson: _contactPersonController.text.trim().isEmpty
          ? null
          : _contactPersonController.text.trim(),
      paymentTerms: _paymentTermsController.text.trim().isEmpty
          ? null
          : _paymentTermsController.text.trim(),
      taxId: _taxIdController.text.trim().isEmpty
          ? null
          : _taxIdController.text.trim(),
      isActive: _isActive,
      updatedAt: DateTime.now(),
    );

    try {
      await SupplierService.instance.update(updated);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onRouteSelected(AppRoutes.suppliers);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update supplier: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => widget.onRouteSelected(AppRoutes.suppliers),
                icon: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Back to Suppliers',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Edit Supplier',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Update the details for "${_supplier?.name ?? ''}".',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Basic Information'),
                  const SizedBox(height: 16),
                  _buildField(
                    'Supplier Name *',
                    _nameController,
                    'e.g. ABC Supplies',
                    required: true,
                  ),
                  const SizedBox(height: 20),
                  _buildTwoColumnRow(
                    _buildField(
                      'Email',
                      _emailController,
                      'supplier@example.com',
                    ),
                    _buildField('Phone', _phoneController, '+1-234-567-8900'),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Contact Information'),
                  const SizedBox(height: 16),
                  _buildField(
                    'Contact Person',
                    _contactPersonController,
                    'Full name of contact',
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Address'),
                  const SizedBox(height: 16),
                  _buildField(
                    'Street Address',
                    _addressController,
                    '123 Business Street',
                  ),
                  const SizedBox(height: 20),
                  _buildTwoColumnRow(
                    _buildField('City', _cityController, 'New York'),
                    _buildField('State/Province', _stateController, 'NY'),
                  ),
                  const SizedBox(height: 20),
                  _buildTwoColumnRow(
                    _buildField('Country', _countryController, 'United States'),
                    _buildField('Zip/Postal Code', _zipCodeController, '10001'),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Business Details'),
                  const SizedBox(height: 16),
                  _buildTwoColumnRow(
                    _buildField('Tax ID', _taxIdController, 'XX-XXXXXXX'),
                    _buildField(
                      'Payment Terms',
                      _paymentTermsController,
                      'Net 30',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Status:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _isActive,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withAlpha(100),
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                      Text(
                        _isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 14,
                          color: _isActive
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
    );
  }

  Widget _buildTwoColumnRow(Widget col1, Widget col2) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(children: [col1, const SizedBox(height: 20), col2]);
        }
        return Row(
          children: [
            Expanded(child: col1),
            const SizedBox(width: 24),
            Expanded(child: col2),
          ],
        );
      },
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(hint),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty)
                    ? 'This field is required.'
                    : null
              : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 450) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () => widget.onRouteSelected(AppRoutes.suppliers),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Update Supplier',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () => widget.onRouteSelected(AppRoutes.suppliers),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Update Supplier',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        );
      },
    );
  }
}
