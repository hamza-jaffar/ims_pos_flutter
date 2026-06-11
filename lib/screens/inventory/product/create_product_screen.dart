import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/product.dart';
import 'package:ims_pos_system/models/brand.dart';
import 'package:ims_pos_system/models/category.dart';
import 'package:ims_pos_system/models/supplier.dart';
import 'package:ims_pos_system/models/room.dart';
import 'package:ims_pos_system/services/product_service.dart';
import 'package:ims_pos_system/services/brand_service.dart';
import 'package:ims_pos_system/services/category_service.dart';
import 'package:ims_pos_system/services/supplier_service.dart';
import 'package:ims_pos_system/services/room_service.dart';
import 'package:ims_pos_system/models/product_model.dart';
import 'package:ims_pos_system/services/product_model_service.dart';
import 'package:ims_pos_system/models/quality.dart';
import 'package:ims_pos_system/services/quality_service.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/widgets/searchable_dropdown.dart';

class CreateProductScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;

  const CreateProductScreen({super.key, required this.onRouteSelected});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '5');
  final _purchasePriceController = TextEditingController(text: '0.0');
  final _sellingPriceController = TextEditingController(text: '0.0');
  final _discountPriceController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _selectedBrandId;
  int? _selectedModelId;
  int? _selectedQualityId;
  int? _selectedCategoryId;
  int? _selectedSupplierId;
  int? _selectedRoomId;

  List<Brand> _brands = [];
  List<ProductModel> _models = [];
  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  List<Room> _rooms = [];
  List<Quality> _qualities = [];

  bool _isActive = true;
  bool _isLoadingDropdowns = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _discountPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    setState(() => _isLoadingDropdowns = true);
    try {
      final brands = await BrandService.instance.getAll();
      final models = await ProductModelService.instance.getAll();
      final categories = await CategoryService.instance.getAll();
      final suppliers = await SupplierService.instance.getAll();
      final rooms = await RoomService.instance.getActiveRooms();
      final qualities = await QualityService.instance.getActive();

      if (mounted) {
        setState(() {
          _brands = brands.where((b) => b.isActive).toList();
          _models = models.where((m) => m.isActive).toList();
          _categories = categories.where((c) => c.isActive).toList();
          _suppliers = suppliers.where((s) => s.isActive).toList();
          _rooms = rooms;
          _qualities = qualities;
          _isLoadingDropdowns = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoadingDropdowns = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load related data: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();

    // Check unique Name
    final nameExists = await ProductService.instance.nameExists(name);
    if (nameExists && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A product with this name already exists.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final double purchasePrice =
        double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final double sellingPrice =
        double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final double? discountPrice = _discountPriceController.text.trim().isEmpty
        ? null
        : double.tryParse(_discountPriceController.text.trim());

    final product = Product(
      name: name,
      code: '', // auto-generated in service
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      brandId: _selectedBrandId,
      modelId: _selectedModelId,
      categoryId: _selectedCategoryId,
      supplierId: _selectedSupplierId,
      roomId: _selectedRoomId,
      qualityId: _selectedQualityId,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
      minStockQuantity: int.tryParse(_minStockController.text.trim()) ?? 5,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      discountPrice: discountPrice,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: _isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ProductService.instance.create(product);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onRouteSelected(AppRoutes.products);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save product: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back nav
          TextButton.icon(
            onPressed: () => widget.onRouteSelected(AppRoutes.products),
            icon: const Icon(
              Icons.arrow_back,
              size: 18,
              color: AppColors.primary,
            ),
            label: const Text(
              'Back to Products',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create Product',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add a new product with stock, pricing, and discount information.',
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
            child: _isLoadingDropdowns
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isWide = constraints.maxWidth > 700;
                            return Column(
                              children: [
                                // Row 1: Product Name + Barcode
                                _buildResponsiveRow(
                                  isWide,
                                  _buildField(
                                    'Product Name *',
                                    _nameController,
                                    'Enter product name',
                                    required: true,
                                  ),
                                  _buildField(
                                    'Barcode',
                                    _barcodeController,
                                    'Scan or enter barcode',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Row 2: Category + Brand
                                _buildResponsiveRow(
                                  isWide,
                                  _buildCategoryDropdown(),
                                  _buildBrandDropdown(),
                                ),
                                const SizedBox(height: 20),
                                // Row 3: Model + Room
                                _buildResponsiveRow(
                                  isWide,
                                  _buildModelDropdown(),
                                  _buildRoomDropdown(),
                                ),
                                const SizedBox(height: 20),
                                // Row 4: Supplier + Status
                                _buildResponsiveRow(
                                  isWide,
                                  _buildSupplierDropdown(),
                                  _buildStatusToggle(),
                                ),
                                const SizedBox(height: 20),
                                // Row 5: Quality + Location
                                _buildResponsiveRow(
                                  isWide,
                                  _buildQualityDropdown(),
                                  _buildField(
                                    'Location / Shelf',
                                    _locationController,
                                    'e.g. Shelf A-1, Bin 3B',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Row 6: Opening Stock + Min Stock
                                _buildResponsiveRow(
                                  isWide,
                                  _buildField(
                                    'Opening Stock (Quantity)',
                                    _quantityController,
                                    'e.g. 100',
                                    isNumeric: true,
                                  ),
                                  _buildField(
                                    'Low Stock Alert Threshold',
                                    _minStockController,
                                    'e.g. 5',
                                    isNumeric: true,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Row 5: Purchase Price + Selling Price
                                _buildResponsiveRow(
                                  isWide,
                                  _buildField(
                                    'Purchase Price (${PlatformSettingsService.instance.settings.currencySymbol})',
                                    _purchasePriceController,
                                    'e.g. 10.0',
                                    isDecimal: true,
                                  ),
                                  _buildField(
                                    'Selling Price (${PlatformSettingsService.instance.settings.currencySymbol})',
                                    _sellingPriceController,
                                    'e.g. 15.0',
                                    isDecimal: true,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Row 6: Discount Price (half width)
                                _buildResponsiveRow(
                                  isWide,
                                  _buildDiscountField(),
                                  const SizedBox.shrink(),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTextArea(
                          'Description',
                          _descriptionController,
                          'Enter product details, specifications...',
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

  Widget _buildResponsiveRow(bool isWide, Widget child1, Widget child2) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child1),
          const SizedBox(width: 20),
          Expanded(child: child2),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [child1, const SizedBox(height: 20), child2],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    bool required = false,
    bool isNumeric = false,
    bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: (isNumeric || isDecimal)
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: _inputDecoration(hint),
          validator: (v) {
            if (required && (v == null || v.trim().isEmpty)) {
              return 'This field is required.';
            }
            if (v != null && v.trim().isNotEmpty) {
              if (isNumeric) {
                final n = int.tryParse(v.trim());
                if (n == null || n < 0) {
                  return 'Must be a non-negative whole number.';
                }
              }
              if (isDecimal) {
                final d = double.tryParse(v.trim());
                if (d == null || d < 0) {
                  return 'Must be a valid positive number.';
                }
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDiscountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discount Price (${PlatformSettingsService.instance.settings.currencySymbol})',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _discountPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDecoration('Leave empty for no discount'),
          validator: (v) {
            if (v != null && v.trim().isNotEmpty) {
              final disc = double.tryParse(v.trim());
              if (disc == null || disc < 0) {
                return 'Must be a valid positive number.';
              }
              final selling =
                  double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
              if (disc >= selling) {
                return 'Discount must be less than Selling Price (${PlatformSettingsService.instance.settings.currencySymbol}${selling.toStringAsFixed(2)})';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return SearchableDropdown<int>(
      label: 'Category',
      hint: 'Search and select category...',
      selectedValue: _selectedCategoryId,
      items: _categories
          .map((c) => SearchableDropdownItem<int>(value: c.id!, label: c.name))
          .toList(),
      onChanged: (val) => setState(() => _selectedCategoryId = val),
    );
  }

  Widget _buildBrandDropdown() {
    return SearchableDropdown<int>(
      label: 'Brand',
      hint: 'Search and select brand...',
      selectedValue: _selectedBrandId,
      items: _brands
          .map((b) => SearchableDropdownItem<int>(value: b.id!, label: b.name))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedBrandId = val;
          if (_selectedModelId != null) {
            final selectedModel = _models.firstWhere((m) => m.id == _selectedModelId, orElse: () => _models.first);
            if (selectedModel.brandId != val) {
              _selectedModelId = null;
            }
          }
        });
      },
    );
  }

  Widget _buildModelDropdown() {
    List<ProductModel> filteredModels = _models;
    if (_selectedBrandId != null) {
      filteredModels = _models.where((m) => m.brandId == _selectedBrandId).toList();
    }

    return SearchableDropdown<int>(
      label: 'Model',
      hint: 'Search and select model...',
      selectedValue: _selectedModelId,
      items: filteredModels
          .map((m) => SearchableDropdownItem<int>(value: m.id!, label: m.name))
          .toList(),
      onChanged: (val) => setState(() => _selectedModelId = val),
    );
  }

  Widget _buildQualityDropdown() {
    return SearchableDropdown<int>(
      label: 'Quality',
      hint: 'Search and select quality...',
      selectedValue: _selectedQualityId,
      items: _qualities
          .map((q) => SearchableDropdownItem<int>(value: q.id!, label: q.name))
          .toList(),
      onChanged: (val) => setState(() => _selectedQualityId = val),
    );
  }

  Widget _buildSupplierDropdown() {
    return SearchableDropdown<int>(
      label: 'Supplier',
      hint: 'Search and select supplier...',
      selectedValue: _selectedSupplierId,
      items: _suppliers
          .map((s) => SearchableDropdownItem<int>(value: s.id!, label: s.name))
          .toList(),
      onChanged: (val) => setState(() => _selectedSupplierId = val),
    );
  }

  Widget _buildRoomDropdown() {
    return SearchableDropdown<int>(
      label: 'Room',
      hint: 'Search and select room...',
      selectedValue: _selectedRoomId,
      items: _rooms
          .map((r) => SearchableDropdownItem<int>(value: r.id!, label: r.name))
          .toList(),
      onChanged: (val) => setState(() => _selectedRoomId = val),
    );
  }

  Widget _buildStatusToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Switch(
                value: _isActive,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withAlpha(100),
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(width: 8),
              Text(
                _isActive ? 'Active (Listed)' : 'Inactive (Hidden)',
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
        ),
      ],
    );
  }

  Widget _buildTextArea(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 450;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () => widget.onRouteSelected(AppRoutes.products),
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
                        'Save Product',
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
                  : () => widget.onRouteSelected(AppRoutes.products),
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
                      'Save Product',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        );
      },
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
}
