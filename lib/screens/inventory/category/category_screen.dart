import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/category.dart';
import 'package:ims_pos_system/services/category_service.dart';

class CategoryScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  final Map<String, dynamic>? args;

  const CategoryScreen({super.key, required this.onRouteSelected, this.args});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Category> _categories = [];
  List<Category> _filtered = [];
  bool _isLoading = true;
  final Set<int> _hoveredRows = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final data = await CategoryService.instance.getAll();
      if (mounted) {
        setState(() {
          _categories = data;
          _filtered = data;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _onSearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _categories
          : _categories.where((c) {
              return c.name.toLowerCase().contains(q) ||
                  (c.code?.toLowerCase().contains(q) ?? false);
            }).toList();
    });
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Category',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CategoryService.instance.delete(category.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${category.name}" deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadCategories();
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row / Column
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_categories.length} categories total',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          widget.onRouteSelected(AppRoutes.createCategory),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Category'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_categories.length} categories total',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        widget.onRouteSelected(AppRoutes.createCategory),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 20),

        // Search bar
        SizedBox(
          height: 42,
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 14, color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: 'Search categories by name or code...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
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
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Table / Card List
        Container(
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? _buildEmpty()
                  : (isMobile ? _buildCardList() : _buildTable()),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.category_outlined,
            size: 52,
            color: AppColors.textSecondary.withAlpha(100),
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? 'No results for "${_searchController.text}"'
                : 'No categories yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Try a different keyword.'
                : 'Click "Create Category" to get started.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: _headerCell('Name')),
              Expanded(flex: 2, child: _headerCell('Code')),
              Expanded(flex: 3, child: _headerCell('Description')),
              Expanded(flex: 1, child: _headerCell('Status')),
              Expanded(flex: 2, child: _headerCell('Created')),
              SizedBox(width: 80, child: _headerCell('Actions')),
            ],
          ),
        ),
        // Rows
        RefreshIndicator(
          onRefresh: _loadCategories,
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _filtered.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, index) => _buildRow(_filtered[index], index),
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildRow(Category category, int index) {
    final isHovered = _hoveredRows.contains(index);
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRows.add(index)),
      onExit: (_) => setState(() => _hoveredRows.remove(index)),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (category.id != null) {
            widget.onRouteSelected('${AppRoutes.editCategory}/${category.id}');
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: isHovered ? AppColors.background.withAlpha(40) : Colors.white,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  category.code ?? '—',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  category.description ?? '—',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: category.isActive
                        ? AppColors.successLight
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: category.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  category.createdAt != null
                      ? '${category.createdAt!.day}/${category.createdAt!.month}/${category.createdAt!.year}'
                      : '—',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 92,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.info,
                      tooltip: 'Edit',
                      onTap: () => widget.onRouteSelected(
                        '${AppRoutes.editCategory}/${category.id}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: Icons.delete_outline,
                      color: AppColors.danger,
                      tooltip: 'Delete',
                      onTap: () => _deleteCategory(category),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildCardList() {
    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _filtered.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: AppColors.border),
        itemBuilder: (_, index) => _buildCardItem(_filtered[index]),
      ),
    );
  }

  Widget _buildCardItem(Category category) {
    return InkWell(
      onTap: () {
        if (category.id != null) {
          widget.onRouteSelected('${AppRoutes.editCategory}/${category.id}');
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: category.isActive
                        ? AppColors.successLight
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: category.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (category.code != null && category.code!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.tag,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category.code!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              category.description ?? 'No description provided.',
              style: TextStyle(
                fontSize: 13,
                color: category.description != null
                    ? AppColors.textMain.withAlpha(200)
                    : AppColors.textSecondary.withAlpha(160),
                fontStyle: category.description != null
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.createdAt != null
                      ? 'Created: ${category.createdAt!.day}/${category.createdAt!.month}/${category.createdAt!.year}'
                      : '',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    _actionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.info,
                      tooltip: 'Edit',
                      onTap: () => widget.onRouteSelected(
                        '${AppRoutes.editCategory}/${category.id}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: Icons.delete_outline,
                      color: AppColors.danger,
                      tooltip: 'Delete',
                      onTap: () => _deleteCategory(category),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
