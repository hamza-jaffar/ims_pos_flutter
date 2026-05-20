import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/category.dart';
import 'package:ims_pos_system/services/category_service.dart';

class EditCategoryScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  final int categoryId;
  final Category? initialCategory;

  const EditCategoryScreen({
    super.key,
    required this.onRouteSelected,
    required this.categoryId,
    this.initialCategory,
  });

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;
  bool _isSaving = false;
  bool _isLoading = true;
  Category? _category;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _populateFields(widget.initialCategory!);
      _isLoading = false;
    } else {
      _loadCategory();
    }
  }

  Future<void> _loadCategory() async {
    final cat = await CategoryService.instance.getById(widget.categoryId);
    if (mounted) {
      if (cat != null) {
        _populateFields(cat);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category not found.'),
            backgroundColor: AppColors.danger,
          ),
        );
        widget.onRouteSelected(AppRoutes.categories);
      }
      setState(() => _isLoading = false);
    }
  }

  void _populateFields(Category cat) {
    _category = cat;
    _nameController.text = cat.name;
    _codeController.text = cat.code ?? '';
    _descriptionController.text = cat.description ?? '';
    _isActive = cat.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) return;

    final nameExists = await CategoryService.instance.nameExists(
      _nameController.text.trim(),
      excludeId: _category!.id,
    );
    if (nameExists && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A category with this name already exists.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updated = _category!.copyWith(
      name: _nameController.text.trim(),
      code: _codeController.text.trim().isEmpty
          ? null
          : _codeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: _isActive,
    );

    try {
      await CategoryService.instance.update(updated);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onRouteSelected(AppRoutes.categories);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update category: $error'),
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
                onPressed: () => widget.onRouteSelected('/categories'),
                icon: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Back to Categories',
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
            'Edit Category',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Update the details for "${_category?.name ?? ''}".',
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isNarrow = constraints.maxWidth < 600;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildField(
                              'Category Name *',
                              _nameController,
                              'e.g. Electronics',
                              required: true,
                            ),
                            const SizedBox(height: 20),
                            _buildField(
                              'Category Code',
                              _codeController,
                              'e.g. CAT-001',
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildField(
                                'Category Name *',
                                _nameController,
                                'e.g. Electronics',
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildField(
                                'Category Code',
                                _codeController,
                                'e.g. CAT-001',
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextArea(
                    'Description',
                    _descriptionController,
                    'Enter category description...',
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isNarrow = constraints.maxWidth < 450;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () =>
                                        widget.onRouteSelected(AppRoutes.categories),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
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
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _isSaving ? null : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                                      'Update Category',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () =>
                                        widget.onRouteSelected(AppRoutes.categories),
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
                                      'Update Category',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          style: TextStyle(
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
